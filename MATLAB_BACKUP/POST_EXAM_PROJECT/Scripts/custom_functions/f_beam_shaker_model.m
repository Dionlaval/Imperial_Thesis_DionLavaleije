function [dx] = f_beam_shaker_model(t, x, model)
%Summary: takes init state x and model parameters, returns derivative of x
    R = model.R;
    L = model.L;
    G = model.G;
    kappa = model.kappa;
    Phiell = model.Phiell;
    Phid = model.Phid;

    % state variables
    eta = x(1:2);
    eta_dot = x(3:4);
    I = x(5);

    % Nonlinear term: (Phiell' * eta)^3 * Phiell
    nonlinear_force = kappa * Phiell * (Phiell' * eta)^3;

    % RHS of first equation: G*Phid*I - nonlinear term
    rhs_eta_ddot = G * Phid * I - nonlinear_force;

    % Solve for eta_ddot
    eta_ddot = model.M \ (rhs_eta_ddot - model.C * eta_dot - model.K * eta);

    % Compute I_dot from second equation
    eta_dot_proj = Phid' * eta_dot;
    u = model.u_fun(t);  % external control input
    I_dot = (1/L) * (u - R * I - G * eta_dot_proj);

    % Return derivative
    dx = [eta_dot; eta_ddot; I_dot];
end