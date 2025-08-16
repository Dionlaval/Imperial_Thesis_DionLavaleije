function [model, input, trial, control] = CL_model_reset(w0,target, x_init, periods, dt)
    % model
    model.m = 1;            % Mass (kg)
    model.c = 0.4;         % Damping coefficient (Ns/m)
    model.k = 1;           % Stiffness (N/m)
    model.alpha = 3;        % Nonlinear stiffness coefficient (N/m^3)
    
    % input defines
    input.w0 = w0;
    input.T = (2*pi)/w0;
    input.force = 0;
    % trial defines:
        % trial.t_span 
        % trial.x_init
    trial.dt = dt;
    trial.t_length = periods*input.T;
    trial.t_span = (0:trial.dt:trial.t_length)';
    trial.x_init = x_init;
    
    trial.psi_history = zeros(length(trial.t_span), 1);
    trial.force_history = zeros(length(trial.t_span), 1);
    trial.tip_history = zeros(length(trial.t_span), 1);

    
    % control defines:
        % control.k_num
        % control.target_vec
        % control.Kp
        % control.Kd
    
    control.k_num = 7;
    control.target_amp = target;
    control.target_vec = zeros(control.k_num, 2);
    control.target_vec(1,:) = [0, target];

    control.Kd = 10;
    control.Kp = 100;

    % experiment
    % harmonizer:
    control.harmony_iter = 50;
        % response histories
    control.experiment.A_responses = zeros(control.k_num, control.harmony_iter);
    control.experiment.B_responses = zeros(control.k_num, control.harmony_iter);
    control.experiment.A_targets = zeros(control.k_num, control.harmony_iter);
    control.experiment.B_targets = zeros(control.k_num, control.harmony_iter);
        % set all first harmonics
    control.experiment.A_targets(1, :) = 0;
    control.experiment.B_targets(1, :) = target;

end