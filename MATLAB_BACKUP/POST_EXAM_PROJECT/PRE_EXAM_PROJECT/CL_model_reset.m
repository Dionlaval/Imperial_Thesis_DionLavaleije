function [model, input, trial, control] = CL_model_reset(w0,target, x_init, periods, dt)
    % model
    model.m = 1;            % Mass (kg)
    model.c = 0.05;         % Damping coefficient (Ns/m)
    model.k = 10;           % Stiffness (N/m)
    model.alpha = 1;        % Nonlinear stiffness coefficient (N/m^3)
    
    % input defines
    input.w0 = w0;
    input.T = (2*pi)/w0;
    % trial defines:
        % trial.t_span 
        % trial.x_init
    trial.dt = dt;
    trial.t_length = periods*input.T;
    trial.t_span = (0:trial.dt:trial.t_length)';
    trial.x_init = x_init;
    
    % control defines:
        % control.k_num
        % control.target_vec
        % control.Kp
        % control.Kd
    
    control.k_num = 7;
    control.target_amp = target;
    control.target_vec = zeros(control.k_num, 2);
    control.target_vec(1,:) = [0, target];

    % experiment
    % harmonizer:
    harmony_iter = 50;
        % response histories
    control.experiment.A_responses = zeros(control.k_num, harmony_iter);
    control.experiment.B_responses = zeros(control.k_num, harmony_iter);
    control.experiment.A_targets = zeros(control.k_num, harmony_iter);
    control.experiment.B_targets = zeros(control.k_num, harmony_iter);
        % set all first harmonics
    control.experiment.A_targets(1, :) = 0;
    control.experiment.B_targets(1, :) = target;

end