function [input_out, trial_out, control] = target_tuner(K_init, tracking_tol, model, input, trial, control)
    target_amp = control.target_amp;
    Kp_init = K_init;
    % pid_count is counter for number of iterations till desired tracking is achieved
    pid_iter = 30;
    Kt_history = zeros(pid_iter, 1);
    error_history = zeros(pid_iter, 1);
    Kt_history(1) = target_amp;

    control = set_control_gain(Kp_init, input, control);
    control.target_vec(1, :) = [0, Kt_history(1)];
    [input_out, trial_out] = closedloop_test(model, input, trial, control);

    counter = 3
    while counter > 0
        try
                    %check if tolerance cond already satisfied
            [t_lin, x_lin] = get_last_n_periods(trial_out.t_span, trial_out.X(:, 1), 10);
            ss_amp = max(x_lin);
            % desired_amp = max(input_out.ref{1}(t_lin));
            error_factor = ss_amp/target_amp - 1; % percent error
            "target_tuner_newton1: t_value = " + Kt_history(1)
            "target_tuner_newton2: %Error = " + error_factor*100 + "%"
            error_history(1) = error_factor;
            if (abs(error_factor) < tracking_tol)
                "target_tuner_newton3: control already within tolerance with Kp = " + control.Kd
                control.Kt_history = Kt_history(Kt_history>0);
                return;
            end
            Kt_history(1) = Kt_history(1).*1.05;
        
            
            for i = (2:pid_iter)
                control = set_control_gain(Kp_init, input, control);
                control.target_vec(1, :) = [0, Kt_history(i)];
                [input_out, trial_out] = closedloop_test(model, input, trial, control);
        
                    %check if tolerance cond already satisfied
                [t_lin, x_lin] = get_last_n_periods(trial_out.t_span, trial_out.X(:, 1), 10);
                ss_amp = max(x_lin);
                % desired_amp = max(input_out.ref{1}(t_lin));
                error_factor = ss_amp/target_amp - 1; % percent error
                "target_tuner_newton1: t_value = " + Kt_history(i)
                "target_tuner_newton2: %Error = " + error_factor*100 + "%"
                error_history(i) = error_factor;
                if (abs(error_factor) < tracking_tol)
                    "target_tuner_newton3: control already within tolerance with Kp = " + control.Kd
                    control.Kt_history = Kt_history(Kt_history>0);
                    return;
                end
        
                        % secant iteration
                xn = Kt_history(i);
                xn1 = Kt_history(i-1);
        
                fx = error_history(i);
                fx1 = error_history(i-1);
                next_x = xn - fx.*((xn-xn1)/(fx-fx1));
                next_x = min(abs(next_x), 1000);
                if next_x == 1000
                    Kp_init = Kp_init*2;
                    next_x = 1;
                end
                Kt_history(i+1) = min(abs(next_x), 1000);
        
        
                %     %run for derivative + 1%
                % delta_x = Kt_history(i).*(tracking_tol/2);
                % control = set_control_gain(Kp_init, input, control);
                % control.target_vec(1, :) = [0, Kt_history(i)+delta_x];
                % [~, trial_out2] = closedloop_test(model, input, trial, control);
                % [t_lin2, x_lin2] = get_last_n_periods(trial_out2.t_span, trial_out2.X(:, 1), 10);
                % % desired_amp2 = max(input_out.ref{1}(t_lin2));
                % ss_amp2 = max(x_lin2);
                % error_factor2 = ss_amp2/target_amp - 1; % percent error
                % 
                % fx = error_factor;
                % dfx = (error_factor2 - error_factor)/delta_x;
                % next_x = Kt_history(i) - fx/dfx;
                % 
                % next_x
                % Kt_history(i+1) = next_x;
            end

            return
        catch
            % Kp_init = K_init/2;
            % counter = counter-1;
            return
        end
    end
end