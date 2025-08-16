function [input_out, trial_out, control] = Kd_tuner(Kp_init, tracking_tol, model, input, trial, control)
    target = sqrt(sum(control.target_vec(1, :).^2, "all"));
    % pid_count is counter for number of iterations till desired tracking is achieved
    pid_iter = 30;
    Kt_history = zeros(pid_iter, 1);
    Kt_history(1) = Kp_init;
    % min_Kd = 150;
    error_history = zeros(size(Kt_history));
    
    %init stuctures for CL runs
    % [model, input, trial, control] = CL_model_reset(w0,target, x_init, periods, dt);
    % restart_flag = true;
    % while restart_flag
    %     restart_flag = false;

    %do initial run
    control = set_control_gain(Kt_history(1), input, control);

    [input_out, trial_out] = closedloop_test(model, input, trial, control);
    
    %check if tolerance cond already satisfied
    [~, x_lin] = get_last_n_periods(trial_out.t_span, trial_out.X(:, 1), 10);
    ss_amp = max(x_lin);
    error_factor = ss_amp/target - 1; % percent error
    "Kd_tuner: Kd_value = " + Kp_init
    "Kd_tuner: %Error = " + error_factor*100 + "%"
    error_history(1) = error_factor;
    if (abs(error_factor) < tracking_tol)
        "Kd_tuner: control already within tolerance with Kp = " + control.Kp
        control.Kt_history = Kt_history(Kt_history>0);
        return;
    end
    
    %init next Kd val
    Kt_history(2) = Kt_history(1)*1.1;
    
    for pid_count = (2:pid_iter)
        % run naive control model
        control = set_control_gain(Kt_history(pid_count), input, control);
        trying = true;
        while trying
            try
                [input_out, trial_out] = closedloop_test(model, input, trial, control);
                % [f] = plot_CL_inner(input_out, trial_out, control);
                [~, x_lin] = get_last_n_periods(trial_out.t_span, trial_out.X(:, 1), 10);
                trying = false;
                break;
            catch
                Kt_history(pid_count) = Kt_history(pid_count)*0.1;
                trying = true;
                "Kd_tuner: Trying again... Kp = " + Kt_history(pid_count)
            end
        end
        ss_amp = max(x_lin);
        error_factor = ss_amp/target - 1; % percent error
        %debug logs
        "Kd_tuner: Kp_value = " + control.Kp
        "Kd_tuner: %Error = " + error_factor*100 + "%"
    
        % check if within tolerance or if max iterations reached
        tol_cond = abs(error_factor) < tracking_tol;
        iter_cond = pid_count == pid_iter;
        if(tol_cond)
            "Kd_tuner: control within tolerance with Kp = " + control.Kp
            control.Kt_history = Kt_history(Kt_history>0);
            return;
        elseif(iter_cond)
            "Kd_tuner: couldnt converge in " + pid_iter + " iterations"
            control.Kt_history = Kt_history(Kt_history>0);
            return;
        end
    
        % secant iteration
        error_history(pid_count) = error_factor;
        xn = Kt_history(pid_count-1:pid_count);
        fx = error_history(pid_count-1:pid_count);
        new_x  = xn(2) - fx(2)*((xn(2)-xn(1))/(fx(2)-fx(1)));
        if (new_x <= 0)
            new_x = xn(2)*0.1;
        end
        % if(new_x < 0.5)
        %     min_Kd = min_Kd/2
        %     restart_flag = true;
        %     control = set_control_gain(Kt_history(1), min_Kd, control);
        %     "restarting because Kp is too low: " + new_x
        %     break
        % elseif(new_x > 10000)
        %     min_Kd = min_Kd*2
        %     restart_flag = true;
        %     "restarting because Kp is too high: " + new_x
        %     break
        % end
        Kt_history(pid_count+1) = new_x;%min(abs(new_x), 50000); % limits maximum kd
    end
    % end
end