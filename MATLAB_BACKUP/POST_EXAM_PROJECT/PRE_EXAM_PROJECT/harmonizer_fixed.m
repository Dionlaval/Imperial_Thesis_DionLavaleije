function [experiment, input_out, trial_out, control_out] = harmonizer(tracking_tol, invasive_tol, model, input, trial, control)
    % methodology
    harmony_iter = 30;
    Kp_init = control.Kd;
    
    %init stuctures for CL runs
    % [model, input, trial, control] = CL_model_reset(w0,target, x_init, periods, dt);
    %create history arrays
    experiment.A_responses = zeros(size(control.target_vec, 1), harmony_iter);
    experiment.B_responses = zeros(size(control.target_vec, 1), harmony_iter);
    
    experiment.A_targets = zeros(size(control.target_vec, 1), harmony_iter);
    experiment.B_targets = zeros(size(control.target_vec, 1), harmony_iter);
    experiment.A_targets(1, :) = control.target_vec(1, 1);
    experiment.B_targets(1, :) = control.target_vec(1, 2);
    
    
    %----------------------- do initial run ----------------------%
        %set initial target
    experiment.A_targets(:, 1) = control.target_vec(:, 1);
    experiment.B_targets(:, 1) = control.target_vec(:, 2);
    
    %----------------------- Kd_tuner ----------------------%
    % [input_out, trial_out, control_out] = Kd_tuner_newton(Kp_init, tracking_tol, model, input, trial, control);
    [input_out, trial_out, control_out] = target_tuner(Kp_init, tracking_tol, model, input, trial, control);
    Kp_init = control_out.Kd; % reassign Kd_init for next iteration;
    %----------------------- invasive analyzer ----------------------%
    [t_lin, x_lin] = get_last_n_periods(trial_out.t_span, input_out.f_history, 10);
    [A_vec,B_vec] = get_fft_components(t_lin, x_lin, input_out.w0, control.k_num);
    
        %record responses
    experiment.A_responses(:, 1) = A_vec(2:end);
    experiment.B_responses(:, 1) = B_vec(2:end);

        % check if within tolerance or if max iterations reached
    f_vec = [A_vec,B_vec];
    welcome = sqrt(0.5*sum(f_vec(1:2, :).^2, "all")); 
    invasive = sqrt(0.5*sum(f_vec(3:end, :).^2, "all")); % RMS (half power method)
    inv_percent = invasive/welcome;
    "Harmonizer: Invasiveness = " + inv_percent*100 + "%"
    if(inv_percent < invasive_tol)
        "Harmoniser: invasiveness already within tolerance with target_vec = " + control.target_vec
        experiment.A_responses = experiment.A_responses(:, 1);
        experiment.B_responses = experiment.B_responses(:, 1);
        experiment.A_targets = experiment.A_targets(:, 1);
        experiment.B_targets = experiment.B_targets(:, 1);
        return;
    end


    %----------------------- do next run ----------------------%
    
    
    %apply offsets for next run
    % offsets are 10% of main harmonics halved at each additonal harmonic
    A_offset = experiment.A_targets(1,1)*0.1*(0.5.^(1:control.k_num-1)) + 0.00001;
    B_offset = experiment.B_targets(1,1)*0.1*(0.5.^(1:control.k_num-1)) + 0.00001;
    experiment.A_targets(:, 2) = experiment.A_targets(:,1) + [0;A_offset'];
    experiment.B_targets(:, 2) = experiment.B_targets(:,1) + [0;B_offset'];
    [experiment.A_targets(:, 2), experiment.B_targets(:, 2)];
    %start iteration loop
    for harmony_count = (2:harmony_iter)
        % run naive control model
        control.target_vec = [experiment.A_targets(:, harmony_count), experiment.B_targets(:, harmony_count)];
        % control.target_vec
        %----------------------- Kd_tuner ----------------------%
        % [input_out, trial_out, control_out] = Kd_tuner_newton(Kp_init, tracking_tol, model, input, trial, control);
        [input_out, trial_out, control_out] = target_tuner(Kp_init, tracking_tol, model, input, trial, control);
        Kp_init = control_out.Kd; % reassign Kd_init for next iteration;
        %----------------------- invasive analyzer ----------------------%
        [t_lin, x_lin] = get_last_n_periods(trial_out.t_span, input_out.f_history, 10);
        [A_vec,B_vec] = get_fft_components(t_lin, x_lin, input_out.w0, control_out.k_num);
        [control_out.target_vec, A_vec(2:end),B_vec(2:end)]
    
            %record responses
        experiment.A_responses(:, harmony_count) = A_vec(2:end);
        experiment.B_responses(:, harmony_count) = B_vec(2:end);
    
        % check if within tolerance or if max iterations reached
        f_vec = [A_vec,B_vec];
        welcome = sqrt(0.5*sum(f_vec(1:2, :).^2, "all")); 
        invasive = sqrt(0.5*sum(f_vec(3:end, :).^2, "all")); % RMS (half power method)
        inv_percent = invasive/welcome;
        "Harmonizer: " + harmony_count + " Invasiveness = " + inv_percent*100 + "%"
        plot_CL_inner(input_out, trial_out, control)
    
        tol_cond = abs(inv_percent) < invasive_tol;
        iter_cond = harmony_count == harmony_iter;
        if(tol_cond)
            "Harmoniser: invasiveness within tolerance with target_vec = " + control.target_vec
            experiment.A_responses = experiment.A_responses(:, 1:harmony_count);
            experiment.B_responses = experiment.B_responses(:, 1:harmony_count);
            experiment.A_targets = experiment.A_targets(:, 1:harmony_count);
            experiment.B_targets = experiment.B_targets(:, 1:harmony_count);
            break;
        elseif(iter_cond)
            "Harmoniser: couldnt converge in " + harmony_iter + " iterations"
            experiment.A_responses = experiment.A_responses(:, 1:harmony_count-1);
            experiment.B_responses = experiment.B_responses(:, 1:harmony_count-1);
            experiment.A_targets = experiment.A_targets(:, 1:harmony_count-1);
            experiment.B_targets = experiment.B_targets(:, 1:harmony_count-1);
            break;
        end
    
    
        % fixed point iteration
        f_vec2 = [experiment.A_responses(:, harmony_count-1), experiment.B_responses(:, harmony_count-1)];
        x_new = f_vec(2:end, :) + 0.01.*(f_vec(2:end, :) - f_vec2);
        experiment.A_targets(2:end, harmony_count+1) = x_new(2:end, 1);
        experiment.B_targets(2:end, harmony_count+1) = x_new(2:end, 2);
    end

end