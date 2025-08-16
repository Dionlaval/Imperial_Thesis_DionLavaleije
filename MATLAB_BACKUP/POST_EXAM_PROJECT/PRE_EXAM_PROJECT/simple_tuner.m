function [input_out, trial_out, control_out] = simple_tuner(model, input, trial, control)
    control_out = control;
        
     % WORKS for going up
    %  % T_settle
    % Ts_desired = (2*pi)/(input.w0*5);          % Desired settling time (sec)
    % zeta = 0.7;                                  % Damping ratio
    % 
    % wn = 4 / (zeta * Ts_desired);
    % Kp = wn^2 - model.k;
    % Kp = Kp
    % Kd = 2 * zeta * wn - model.c;
    % Kd = Kd*10 % 6


    % T_settle
    Ts_desired = (2*pi)/(input.w0*5);          % Desired settling time (sec)
    zeta = 0.7;                                  % Damping ratio

    wn = 4 / (zeta * Ts_desired);
    Kp = wn^2 - model.k;
    Kp = Kp;
    % Kp = 10;
    Kd = 2 * zeta * wn - model.c;
    Kd = Kd*6 % 6
    Kp = Kd

    control_out.Kp = Kp;
    control_out.Kd = Kd;

    [input_out, trial_out] = closedloop_test(model, input, trial, control_out);
end