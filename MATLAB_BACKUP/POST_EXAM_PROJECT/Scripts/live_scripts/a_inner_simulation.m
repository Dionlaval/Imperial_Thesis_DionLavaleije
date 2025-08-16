% Initial state: [eta1, eta2, eta_dot1, eta_dot2, I, psi]
x0 = zeros(5,1);

% Store history
t_all = t_vec';
x_all = zeros(t_num, 5);
v_all = zeros(t_num, 1);
a_all = zeros(t_num, 2);
eta_e1_prev = 0;


% Recompute eta_star and eta_ddot_star using updated target vectors
omega_h = model.omega * (1:model.harmonics)';
model.eta_star = @(t) A_vec_target.' * cos(omega_h * t) + B_vec_target.' * sin(omega_h * t);
model.eta_ddot_star = @(t) - (A_vec_target .* omega_h.^2).' * cos(omega_h * t) ...
                      - (B_vec_target .* omega_h.^2).' * sin(omega_h * t);



% simulate itteration:
for k = 1:length(t_vec)-1
    tk = t_all(k);
    tkp1 = t_all(k+1);
    tspan = [tk, tkp1];
    
    % control force:
    dx = f_beam_shaker_model(tk, x_all(k, :)', model);

    ei = dx(3) - model.eta_ddot_star(tk)*model.k1; % gain shaping

    % update psi
    if psi >= psi_lim
        psi = psi_lim;
    else
        psi_dot = model.k2 * ei^2;
        psi = psi + psi_dot * Ts;  % Euler integration
    end

    a_all(k+1, 1) = psi;
    control_volt = psi * ei;
    v_all(k) = control_volt;
    model.u_fun = @(t) control_volt;
    if control_volt > 1e9
        "control_volt too high: " + control_volt
        break
    end

    % simulate between samples
    [t_seg, x_seg] = ode45(@(t,x) f_beam_shaker_model(t, x, model), tspan, x0);

    x0 = x_seg(end,:)';
    x_all(k+1, :) = x0';
end