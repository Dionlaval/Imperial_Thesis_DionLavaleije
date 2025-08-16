% gain shaping
for n = 1:50
    % Initial state: [eta1, eta2, eta_dot1, eta_dot2, I, psi]
    x0 = zeros(5,1);
    
    % Store history
    t_all = t_vec';
    x_all = zeros(t_num, 5);
    v_all = zeros(t_num, 1);
    a_all = zeros(t_num, 2);
    eta_e1_prev = 0;


    % simulate itteration:
    psi = psi_init;
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
        elseif k == 1
            "nothing";
        else
            % Compute raw psi_dot
            psi_dot = model.k2 * ei^2;
            
            % Apply rate limiter
            psi_dot = min(psi_dot, psi_rate_lim);  % e.g. psi_dot_max = 10 or tuned empirically

            psi = psi + psi_dot * Ts;  % Euler integration
        end
    
        a_all(k, 1) = psi;
    
        control_volt = psi * ei;
        v_all(k) = control_volt;
        model.u_fun = @(t) control_volt;
    
        % simulate between samples
        [t_seg, x_seg] = ode15s(@(t,x) f_beam_shaker_model(t, x, model), tspan, x0);
    
        x0 = x_seg(end,:)';
        x_all(k+1, :) = x0';
    end
    
    % % extract amplitude
    [t_lin, x_lin] = f_get_last_n_periods(t_all, x_all(:, 1), 5);
    [A_vec,B_vec] = f_get_fft_components(t_lin, x_lin, model.omega, model.harmonics);
    amplitude = sqrt(sum(A_vec.^2 + B_vec.^2));
    % % adjust gain shaping
    amp_err = target_amp/amplitude
    if abs(amp_err-1) < 0.01
        "within tolerance > model.k1 = " + model.k1
        break
    else
        model.k1 = model.k1 + 0.1*model.k1 * (amp_err-1);
    end
end

tiledlayout(3, 1, "TileSpacing","compact")
nexttile()
hold on;
plot(t_all, x_all(:, 1), ".-")
plot(t_all, arrayfun(model.eta_star,t_all))
ylabel("\eta_1")
nexttile
plot(t_all, v_all./1000);
ylabel("Input Voltage [mV]");
nexttile
plot(t_all, a_all(:,1), ".-")
xlabel("Time [s]");
ylabel("\psi")