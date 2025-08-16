% requirements
% input defines
    % input.w0
    % input.f_control (controller output /forcing)
    % input.e_history (error history array)
    % input.f_history (controller output array)

% trial defines:
    % trial.t_span 
    % trial.x_init
    % trial.X

% control defines:
    % control.target_vec
    % control.k_num
    % control.error_vec
    % control.Kp
    % control.Kd

function [input, trial] = closedloop_test(model, input, trial, control)
    % Control targets are not changed in the inner loop
    w0 = input.w0;
    A_target = control.target_vec(:, 1);
    B_target = control.target_vec(:, 2);
    k_num = control.k_num;
    wk = w0*(1:k_num)';

    ref_x = @(t) sum(A_target.*cos(wk.*t) + B_target.*sin(wk.*t));
    ref_v = @(t) sum(-A_target.*wk.*sin(wk.*t) + B_target.*wk.*cos(wk.*t));
    input.ref = {ref_x, ref_v};
    % ref_a = @(t) sum(-A_target.*(wk.^2).*cos(wk.*t) - B_target.*(wk.^2).*sin(wk.*t));

    %init control:
    input.f_control = 0;

    %define output arrays (history)
    input.f_history = [input.f_control];
    input.e_history = [0;0];
    trial.X = zeros(length(trial.t_span), 2);
    trial.X(1, :) = trial.x_init;

    % Simulation loop
    for i = 1:length(trial.t_span)-1
        % External forcing (needs to updated each dt for active control)
        p_external = @(t) input.f_control;
        
        % Define ODE function
        odefun = @(t, X) [X(2); 
                          (1 / model.m) * (p_external(t) - model.c * X(2) - model.k * X(1) - model.alpha * X(1)^3)];
    
        % Simulate between time steps
        [t_segment, X_segment] = ode45(odefun, [trial.t_span(i), trial.t_span(i+1)], trial.x_init);
        
        % Update current state and record results
        trial.x_init = X_segment(end, :);
        trial.X(i+1, :) = X_segment(end, :);

        % Error calc:
        tm = t_segment(end);
        Xm = X_segment(end, :); % measured x state
        xd = ref_x(tm);
        vd = ref_v(tm);

        control.error_vec = [xd, vd] - Xm;

        % [xd, vd]
        input.e_history = [input.e_history, control.error_vec'];
        kp_term = control.Kp.*control.error_vec(1);
        kd_term = control.Kd.*control.error_vec(2);
        ki_term = 0; % control.Ki.*(control.error_vec - control.error_prev).*trial.dt;
        
        input.f_control = kp_term + kd_term + ki_term;
        input.f_history = [input.f_history, input.f_control];
    end
end