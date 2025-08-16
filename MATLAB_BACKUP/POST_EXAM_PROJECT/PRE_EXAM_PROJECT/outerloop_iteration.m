% initial things for newton rapson
x0 = [];
y0 = [];
step = 0.0001;
x1 = [];
y1 = [];
dy = [];

for m = (1:30) % number of newton raphson iterations
    [input_out, trial_out] = closedloop_test2(model, input, trial, control);
    [t_lin, x_lin] = get_last_n_periods(trial_out.t_span, input_out.f_history, 20);
    [A_vec,B_vec] = get_fft_components(t_lin, x_lin, input_out.w0, 7);
    
    [tm_lin, xm_lin] = get_last_n_periods(trial_out.t_span, trial_out.X_less(:, 1), 10);
    [Am_vec,Bm_vec] = get_fft_components(tm_lin, xm_lin, input_out.w0, control.k_num);

    % record t and x data
    experiment.t_span = [experiment.t_span; trial_out.t_span];
    experiment.X_less = [experiment.X_less; trial_out.X_less];

    % record measured forcing harmonics
    experiment.A_history = [experiment.A_history, A_vec];
    experiment.B_history = [experiment.B_history, B_vec];

    %record response components
    experiment.Am_history = [experiment.Am_history, Am_vec];
    experiment.Bm_history = [experiment.Bm_history, Bm_vec];

    % record target values 
    experiment.A_target = [experiment.A_target, control.target_vec(:, 1)];
    experiment.B_target = [experiment.B_target, control.target_vec(:, 2)];

    % ITERATE TO REMOVE HARMONICS---------------------------------------
    % Newton Rapson method
    harmonic_mag = sqrt(sum([A_vec(2), B_vec(2)].^2));
    coeff_vec = [A_vec(3:end), B_vec(3:end)];
    coeff_tol = sum(abs(coeff_vec), "all");

    progress = "iteration num: " +string(m)+" || coeff error: "+string(coeff_tol/(control.coeff_tol*harmonic_mag))
    if (coeff_tol < control.coeff_tol*harmonic_mag)
        m+" | Non-invasiveness Achieved with a tolerance of: " + control.coeff_tol*harmonic_mag
        break;
    end

    % more precise newton raphson
    % - calc f(x)
    % - calc f(x + h), h = control.coeff_tol.*x
    % - calc f'(x) = (f(x+h) - f(x)) / h
    % x_new = x_prev - f(x)/f'(x)
    temp_control = control;
    delta_coeff = harmonic_mag.*ones(size(temp_control.target_vec)).*temp_control.coeff_tol./(10*temp_control.k_num);
    temp_control.target_vec = temp_control.target_vec+delta_coeff;

    [input_out2, trial_out2] = closedloop_test2(model, input, trial, temp_control);
    [t_lin2, x_lin2] = get_last_n_periods(trial_out2.t_span, input_out2.f_history, 10);
    [A_vec2,B_vec2] = get_fft_components(t_lin2, x_lin2, input_out.w0, temp_control.k_num);
    
    fx = [A_vec(2:end), B_vec(2:end)];
    fxh = [A_vec2(2:end), B_vec2(2:end)];
    df = (fxh - fx)./delta_coeff;
    control.target_vec = control.target_vec - fx./df;

    %reset variable for next outer loop itteration
    trial.x_init = trial_out.x_init;
    trial.t_span = trial.t_span + trial.t_length;
    trial.X_less = [trial.x_init];

    % progress logging
    progress = "iteration num: " +string(m)+" || coeff error: "+string(coeff_tol/(control.coeff_tol*harmonic_mag))

end




% % initial things for newton rapson
% x0 = [];
% y0 = [];
% step = 0.0001;
% x1 = [];
% y1 = [];
% dy = [];
% 
% for m = (1:100)
%     % for r = (1:20) % loop to find best control target to minimise forcing amp
%     [input_out, trial_out] = closedloop_test(model, input, trial, control);
%     [t_lin, x_lin] = get_last_n_periods(trial_out.t_span, input_out.f_history, 20);
%     [A_vec,B_vec] = get_fft_components(t_lin, x_lin, input_out.w0, 7);
%     % end
% % plot trial
% % [f] = plot_CL_inner(input_out, trial_out, control);
%     % [t_lin, x_lin] = get_last_n_periods(trial_out.t_span, input_out.f_history, 20);
%     % [A_vec,B_vec] = get_fft_components(t_lin, x_lin, input_out.w0, 7);
%     % record t and x data
%     experiment.t_span = [experiment.t_span; trial_out.t_span];
%     experiment.X_less = [experiment.X_less; trial_out.X_less];
% 
%     % record measured forcing harmonics
%     experiment.A_history = [experiment.A_history, A_vec];
%     experiment.B_history = [experiment.B_history, B_vec];
% 
%     % record target values 
%     experiment.A_target = [experiment.A_target, control.target_vec(:, 1)];
%     experiment.B_target = [experiment.B_target, control.target_vec(:, 2)];
% 
%     % ITERATE TO REMOVE HARMONICS---------------------------------------
%     % Newton Rapson method
%     % method: 
%     coeff_vec = [A_vec(3:end), B_vec(3:end)];
% 
%     if(sum(abs(coeff_vec), "all") < control.coeff_tol)
%         coeff_vec
%         break
%     end
% 
%     if (m == 1)
%         x0 = control.target_vec(2:end, :);
%         y0 = coeff_vec;
%         x1 = x0 + step;
%         control.target_vec(2:end, :) = x1;
%     else
%         y1 = coeff_vec;
%         dy = (y1 - y0)./(x1 - x0);
%         x_new = x1 - y1./dy;
%         control.target_vec(2:end, :) = x_new;
% 
%         y0 = y1;
%         x0 = x1;
%         x1 = x_new;
%     end
% 
%     %reset variable for next outer loop itteration
%     trial.x_init = trial_out.x_init;
%     trial.t_span = trial.t_span + trial.t_length;
%     trial.X_less = [trial.x_init];
%     "Newton-Raphson Iteration: "+string(m)
% end