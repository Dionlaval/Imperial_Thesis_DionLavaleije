% clear; clc;
set_freq = 13;
addpath("funcs");

% === Setup ===

rtc = signal_interface('MAportConfig.xml');
rtc.par.fund_frequency = set_freq;  % Set constant signal frequency
freq_str = strrep(sprintf('%.2f', rtc.par.fund_frequency), '.', '_');
rtc.par.controller_Kp = 0.3;
rtc.par.controller_Kd = 0.01;


target_range = 1:0.1:10;
n_points = length(target_range);
results = zeros(n_points, 4);  % [freq, signal amp, response amp, invasiveness]

% === Setup Live Scatter ===
figure;
scatter(0, 0, 50, 'r', 'filled');   % <-- scatter handle
xlabel('Signal Amplitude');
ylabel('Response Amplitude');
title("Live S-Curve Tracking: " + freq_str);
grid on;
% xlim([min(target_range) max(target_range)]);
% ylim([0 5]);
hold on;
rtc.par.fund_amp = 0.1;
rtc.par.control_switch = 1;
pause(10);
rtc.par.ss_trigger = 1; pause(0.1); rtc.par.ss_trigger = 0;

% === Main S-Curve Loop ===
rtc.par.control_switch = 2;
% rtc.par.fund_amp = 0;
for i = 1:n_points
    amp = target_range(i);
    rtc.par.target_amp = amp;

    % Wait before triggering steady-state detection
    pause(5);
    rtc.par.ss_trigger = 1; pause(0.1); rtc.par.ss_trigger = 0;

    pause(10);
    data = rtc.run_stream('stream_id', 1);

    % Extract last values (scalars)
    sig_amp = data.sig_amp(end);
    res_amp = data.res_amp(end);
    inv     = data.invasiveness(end);

    fprintf("Trying amp %.2f: inv = %.3f\n", amp, inv);

    % Retry if invasiveness too high
    inv_thresh = 0.05;
    max_retry = 5;
    retry = 0;
    inv_log = inv;

    while inv > inv_thresh && retry < max_retry
        rtc.par.ss_trigger = 1; pause(0.1); rtc.par.ss_trigger = 0;
        pause(10);
        data = rtc.run_stream('stream_id', 1);

        inv_new = data.invasiveness(end);
        fprintf("↻ Retry #%d: inv = %.4f (Δ = %.4f)\n", retry+1, inv_new, abs(inv_new - inv));
        if inv_new < inv_thresh || inv - inv_new < 0.005 || inv_new > inv
            inv = inv_new;
            break;
        end
        inv = inv_new;
        retry = retry + 1;
    end

    % Final data collection for this point
    sig_amp = data.sig_amp(end);
    res_amp = data.res_amp(end);
    inv     = data.invasiveness(end);

    results(i, :) = [rtc.par.fund_frequency, sig_amp, res_amp, inv];

    % Update scatter plot
    scatter(sig_amp, res_amp, 50, 'r', 'filled');
    drawnow;
end

rtc.par.control_switch = 1;
rtc.par.target_amp = 0;
rtc.par.fund_amp = 0;        % Amplitude (adjust as needed)


% === Save result ===
save_folder = "saves/SCURVE";
if ~exist(save_folder, 'dir'), mkdir(save_folder); end
fname = sprintf("s_curve_freq_%s.mat", freq_str);
save(fullfile(save_folder, fname), 'results');

% ------
rtc.par.ss_trigger = 1; pause(0.1); rtc.par.ss_trigger = 0;
pause(5)
rtc.par.ss_trigger = 1; pause(0.1); rtc.par.ss_trigger = 0;
% reset coefficients^^



disp("✅ S-curve complete.");
