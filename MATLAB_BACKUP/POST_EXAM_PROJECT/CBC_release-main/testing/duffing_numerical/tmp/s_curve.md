clear all
close all

rtc = Duffing_interface();

npts = 20;
step = 0.2;
freq = 1.9/(2*pi);
idx_cont = rtc.fourier.idx_fund(1);
tol_err = 1e-2;
pause_sec = 6;
secant_prediction = false;

rtc.par.forcing_freq = freq;
rtc.par.forcing_amp = 0.01;
rtc.par.control_switch = 1;
rtc.par.Kd = 1;
rtc.par.Kp = 2;

f = figure();
a = axes(f);
xlabel(a, 'Forcing Amp');
ylabel(a, 'Response Amp');
xlim(a, [0 6]);
ylim(a, [0 5]);
hold(a, 'on');
h = plot(a, NaN, NaN, '.-r', 'MarkerFaceColor', 'r', 'LineWidth', 1.2);

sol.f = nan(npts, 1);
sol.x = nan(npts, 1);
sol.x_target_coeffs = nan(npts, 15);

itercont = 0;
sol_prev = [];  % will hold the converged solution from the previous iteration
sol_curr = [];  % converged solution from the current iteration

while true
    if itercont < 2 || ~secant_prediction
        % simple increment
        predicted_target = rtc.par.x_target_coeffs;
        predicted_target(idx_cont) = predicted_target(idx_cont) + step;
    else
        % secant prediction
        secant = sol_curr - sol_prev;
        secant = secant / norm(secant);
        predicted_target = sol_curr + secant * step;
    end
    rtc.par.x_target_coeffs = predicted_target;
    pause(pause_sec);
    
    % Picard iteration to drive higher harmonic error below tol_err
    while true
        force_total_ave = rtc.par.force_total_coeffs_ave;
        err_val = norm(force_total_ave(rtc.fourier.idx_iteration));
        fprintf("err: %1.2e\n", err_val);
        if err_val < tol_err
            fprintf("Continuation step %i converged.\n", itercont);
            break; 
        end
        x_asy = rtc.par.x_coeffs;
        rtc.par.x_target_coeffs(rtc.fourier.idx_iteration) = x_asy(rtc.fourier.idx_iteration);
        pause(pause_sec/2);
    end
    
    % Store the solution
    force_amp_sol = norm(rtc.par.force_total_coeffs(rtc.fourier.idx_fund));
    x_amp_sol = norm(rtc.par.x_coeffs);
    sol.f(itercont+1) = force_amp_sol;
    sol.x(itercont+1) = x_amp_sol;
    sol.x_target_coeffs(itercont+1, :) = rtc.par.x_target_coeffs;
    set(h, 'XData', sol.f, 'YData', sol.x);
    
    % Update memory for secant prediction
    if itercont == 0 || ~secant_prediction
        sol_curr = rtc.par.x_target_coeffs;
    else
        sol_prev = sol_curr;
        sol_curr = rtc.par.x_target_coeffs;
    end
    
    itercont = itercont + 1;
    if itercont > npts, break; end
end
