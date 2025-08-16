function [dx] = f_controlled_beam_shaker_model(t, x, model)
% Summary: Simulates modal beam-shaker system with CBC-style modal control (continuous-time)

    % Unpack model parameters
    R = model.R;
    L = model.L;
    G = model.G;
    kappa = model.kappa;
    Phiell = model.Phiell;
    Phid = model.Phid;

    % State variables
    eta     = x(1:2);
    eta_dot = x(3:4);
    I       = x(5);
    psi     = x(6);

    % Nonlinear stiffness force
    nonlinear_force = kappa * Phiell * (Phiell' * eta)^3;

    % Compute modal acceleration
    rhs_eta_ddot = G * Phid * I - nonlinear_force;
    eta_ddot = model.M \ (rhs_eta_ddot - model.C * eta_dot - model.K * eta);

    % Control law: acceleration error on mode 1
    eta_ddot_star = model.eta_ddot_star(t);
    ei = eta_ddot(1) - eta_ddot_star;

    % Continuous-time control law
    psi_dot = model.k2 * ei^2;
    u = model.k1 * psi * ei;

    % Shaker circuit dynamics
    I_dot = (1/L) * (u - R * I - G * Phid' * eta_dot);

    % Assemble state derivative
    dx = [eta_dot; eta_ddot; I_dot; psi_dot];
end
