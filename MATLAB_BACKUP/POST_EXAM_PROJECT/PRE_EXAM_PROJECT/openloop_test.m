function [trial] = openloop_test(model, input, trial)

    % Simulation loop --------------------------------------------------------
    p_external = @(t) input.a*cos(input.w0 * t) + input.b * sin(input.w0 * t);
    % Define ODE function
    odefun = @(t, X) [X(2); 
                      (1 / model.m) * (p_external(t) - model.c * X(2) - model.k * X(1) - model.alpha * X(1)^3)];
    
    % Simulate between time steps
    [trial.t, trial.X] = ode15s(odefun, trial.t_init + [trial.t_span(1), trial.t_span(end)], trial.x_init);
    
    %calc get steady state periods-------------------------------------
    num_periods = 10;
    
    [t_lin, x_lin] = get_last_n_periods(trial.t, trial.X(:,1), num_periods);
    
    % harmonics = 7;%number of harmonics of interest
    [A_vec,B_vec] = get_fft_components(t_lin, x_lin, input.w0, trial.harmonics);

    trial.ss_response_amp = sqrt(sum(A_vec.^2 + B_vec.^2, "all"));
    
    % Update current state and record results
    trial.x_init = trial.X(end, :);
    trial.t_init = trial.t(end);

end