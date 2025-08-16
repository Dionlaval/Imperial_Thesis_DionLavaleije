close all;
clear all;

% Define model parameters
w0 = 2*pi;
x_init = [0, 0];
periods = 30;
dt = 1/1000;

% Define amplitude targets and configuration
amplitude_targets = (1.8:0.2:2.8)
step_size = 0.1;
lambda = 0.3;                  % smoothing factor for harmonic update
invasiveness_threshold = 0.05;
m_response_amplitudes = zeros(length(amplitude_targets), 1);
m_forcing_amplitudes = zeros(length(amplitude_targets), 1);
[model, input, trial, control] = CL_model_reset(w0, amplitude_targets(1), x_init, periods, dt);
saved_base_target = zeros(control.k_num, 2);

figure;
hold on;

for i = 1:length(amplitude_targets)
    i
    amplitude_target = amplitude_targets(i);
    gain_shape = amplitude_target;

    % Reset model with initial gain-shaped reference
    [model, input, trial, control] = CL_model_reset(w0, gain_shape, x_init, periods, dt);

    % ========== Step 1: Amplitude Matching ==========
    for n = 1:control.harmony_iter
        n
        control.target_vec(2:end, :) = saved_base_target(2:end, :);  % base reference template
        [input_out, trial_out] = closedloop_test(model, input, trial, control);
        
        tip_disp = trial_out.X(:, 1);
        [t_lin, x_lin] = f_get_last_n_periods(trial_out.t_span, tip_disp, 5);
        [A_vec, B_vec] = f_get_fft_components(t_lin, x_lin, input_out.w0, control.k_num);
        
        response_amp = norm([A_vec(1), B_vec(1)])
        tip_response_error = amplitude_target - response_amp;
        norm_error = tip_response_error / amplitude_target;
    
        if abs(norm_error) < 0.01
            disp("Gain matched.");
            break;
        end

        % Update gain_shape using bounded step
        step_adjusted = sign(tip_response_error) * min(abs(tip_response_error), step_size);
        gain_shape = gain_shape + step_adjusted;

        % Recalculate reference with new gain
        [model, input, trial, control] = CL_model_reset(w0, gain_shape, x_init, periods, dt);

        % plot point
        [t_lin, f_lin] = f_get_last_n_periods(trial_out.t_span, input_out.f_history, 5);
        [Af_vec, Bf_vec] = f_get_fft_components(t_lin, f_lin, input_out.w0, control.k_num);
        f_amp = sqrt(sum(Af_vec.^2 + Bf_vec.^2, "all"));
        scatter(f_amp, response_amp, 'kx')

    end

    % ========== Step 2: Harmonic Reduction (Non-Invasiveness) ==========
    for m = 1:control.harmony_iter
        m
        [input_out, trial_out] = closedloop_test(model, input, trial, control);

        force_history = input_out.f_history;
        [t_lin, f_lin] = f_get_last_n_periods(trial_out.t_span, force_history, 5);
        [A_force, B_force] = f_get_fft_components(t_lin, f_lin, input_out.w0, control.k_num);

        primary = norm([A_force(1), B_force(1)]);
        secondary = sum(vecnorm([A_force(2:end), B_force(2:end)]', 2));
        invasiveness = secondary / primary;
        disp("Invasiveness: " + invasiveness);


        if invasiveness < invasiveness_threshold
            % Record final results
            tip_disp = trial_out.X(:, 1);
            [t_lin, x_lin] = f_get_last_n_periods(trial_out.t_span, tip_disp, 5);
            [A_vec, B_vec] = f_get_fft_components(t_lin, x_lin, input_out.w0, control.k_num);

            m_response_amplitudes(i) = norm([A_vec(1), B_vec(1)]);
            m_forcing_amplitudes(i) = primary;
            scatter(primary, norm([A_vec(1), B_vec(1)]), 'r.')
            break;
        end

        % Harmonic update: subtract current harmonics from target (smoothed)
        delta = secondary;
        new_target = (1 - lambda) * control.target_vec(2:end, :) - lambda * delta;
        control.target_vec(2:end, :) = new_target;

        % Optional: normalize total reference energy
        % ref_norm = norm(control.target_vec(:));
        % control.target_vec = control.target_vec / ref_norm * norm(saved_base_target(:));
    end

    % Plot current step
    plot_CL_inner(input_out, trial_out, control);
end