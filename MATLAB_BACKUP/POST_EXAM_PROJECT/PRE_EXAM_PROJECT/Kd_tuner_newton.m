function [input_out, trial_out, control] = Kd_tuner_newton(Kp_init, tracking_tol, model, input, trial, control)
    target = sqrt(sum(control.target_vec(1, :).^2, "all"));
    % pid_count is counter for number of iterations till desired tracking is achieved
    pid_iter = 30;
    Kt_history = zeros(pid_iter, 1);
    Kt_history(1) = Kp_init;
    Kd_multiplier = 1;
    
    for pid_count = (1:pid_iter)
        trying = true;
        while trying
            try
                control.Kd_multiplier
                control = set_control_gain(Kt_history(pid_count), input, control);
                [input_out, trial_out] = closedloop_test(model, input, trial, control);
        
                    %check if tolerance cond already satisfied
                [t_lin, x_lin] = get_last_n_periods(trial_out.t_span, trial_out.X(:, 1), 10);
                ss_amp = max(x_lin);
                target_amp = max(input_out.ref{1}(t_lin));
                error_factor = ss_amp/target_amp - 1; % percent error
                "Kd_tuner_newton1: Kp_value = " + Kt_history(pid_count)
                "Kd_tuner_newton2: %Error = " + error_factor*100 + "%"
                error_history(1) = error_factor;
                if (abs(error_factor) < tracking_tol)
                    "Kd_tuner_newton3: control already within tolerance with Kp = " + control.Kd
                    control.Kt_history = Kt_history(Kt_history>0);
                    return;
                end
                    
                    %run for derivative + 1%
                delta_x = tracking_tol*Kt_history(pid_count)/2;
                control = set_control_gain(Kt_history(pid_count)+delta_x, input, control);
                [~, trial_out2] = closedloop_test(model, input, trial, control);
                [t_lin2, x_lin2] = get_last_n_periods(trial_out2.t_span, trial_out2.X(:, 1), 10);
                target_amp2 = max(input_out.ref{1}(t_lin2));
                ss_amp2 = max(x_lin2);
                error_factor2 = ss_amp2/target_amp2 - 1; % percent error
        
                fx = error_factor;
                dfx = (error_factor2 - error_factor)/delta_x;
                next_x = Kt_history(pid_count) - fx/dfx;
                trying = false;
                if(next_x > 500)
                    next_x = 1;
                    control.Kd_multiplier = control.Kd_multiplier*2;
                    "Kd_tuner_newton6: next Kp too large Kd multiplier adjusted = "
                    [next_x, control.Kd_multiplier]
                    trying = true;
                elseif(next_x < 0.01)
                    next_x = 1;
                    control.Kd_multiplier = control.Kd_multiplier/2;
                    "Kd_tuner_newton6: next Kp too small Kd multiplier adjusted = "
                    [next_x, control.Kd_multiplier]
                    trying = true;
                end
                Kt_history(pid_count + 1) = abs(next_x);

            catch
                "Kd_tuner_newton4: Kp too weird. Kp = "+Kt_history(pid_count)

                if(pid_count > 2)
                    Kt_history(pid_count) = (Kt_history(pid_count-1) + Kt_history(pid_count-2))/2;
                else
                    Kt_history(pid_count) = rand(1)*5+5;
                end
                "Kd_tuner_newton5: Kp is now = "+Kt_history(pid_count)
            end
        end




    end
end