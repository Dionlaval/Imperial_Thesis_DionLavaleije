function [input_out, trial_out] = closedloop_test2(model, input, trial, control)

    for u = (1:30)
        input_out = input;
        trial_out = trial;
     % Control targets are not changed in the inner loop
        w0 = input_out.w0;
        A_target = control.target_vec(:, 1);
        B_target = control.target_vec(:, 2);
        k_num = control.k_num;
        wk = w0*(1:k_num)';
    
        ref_x = @(t) sum(A_target.*cos(wk.*t) + B_target.*sin(wk.*t));
        ref_v = @(t) sum(-A_target.*wk.*sin(wk.*t) + B_target.*wk.*cos(wk.*t));
        % ref_a = @(t) sum(-A_target.*(wk.^2).*cos(wk.*t) - B_target.*(wk.^2).*sin(wk.*t));


        % Simulation loop
        for i = 1:length(trial.t_span)-1
            % External forcing (needs to updated each dt for active control)
            p_external = @(t) input_out.f_control;
        
            % Define ODE function
            odefun = @(t, X) [X(2); 
                              (1 / model.m) * (p_external(t) - model.c * X(2) - model.k * X(1) - model.alpha * X(1)^3)];
        
            % Simulate between time steps
            [t_segment, X_segment] = ode45(odefun, [trial.t_span(i), trial.t_span(i+1)], trial.x_init);
            
            % Update current state and record results
            input_out.x_init = X_segment(end, :);

            trial_out.X_less = [trial_out.X_less; X_segment(end, :)];
    
            % Error calc:
            tm = t_segment(end);
            Xm = X_segment(end, :); % measured x state
            xd = ref_x(tm);
            vd = ref_v(tm);
    
            control.error_vec = [xd, vd] - Xm;
    
            % [xd, vd]
            input_out.e_history = [input_out.e_history, control.error_vec'];
            kp_term = control.Kp.*control.error_vec(1);
            kd_term = control.Kd.*control.error_vec(2);
            ki_term = 0; % control.Ki.*(control.error_vec - control.error_prev).*trial.dt;
            
            input_out.f_control = kp_term + kd_term + ki_term;
            input_out.f_history = [input_out.f_history, input_out.f_control];
        end




        % ITRATE TO GET RIGHT AMPlITUDE:
        [t_lin2, x_lin2] = get_last_n_periods(trial_out.t_span, trial_out.X_less(:, 1), 10);
        [x_A_vec, x_B_vec] = get_fft_components(t_lin2, x_lin2, input_out.w0, control.k_num);
        response_amp = sqrt(sum([x_A_vec, x_B_vec].^2, "all"));
        max_amp_error = 0.01*control.target_amplitude;
    
        if (abs(control.target_amplitude - response_amp) > control.target_amplitude*control.amp_tol)
            adjustment_factor = control.target_amplitude/response_amp;
            control.target_vec = control.target_vec.*adjustment_factor;
            u+" | ratio: " + response_amp / control.target_amplitude
            % u+"| adjusted: " + adjustment_factor
            % " | new target mag: " + sqrt(sum(control.target_vec.^2, "all"))*adjustment_factor
            continue;
        else
            % u + "| response amplitude within tolerance"
            u+" | ratio: " + response_amp / control.target_amplitude
            break;
        end
    end
end