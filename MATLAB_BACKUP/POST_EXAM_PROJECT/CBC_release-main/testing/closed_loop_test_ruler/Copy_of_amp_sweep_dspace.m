% clear; clc;
% set_freq = 13;
addpath("funcs");

% === Setup ===
rtc = signal_interface('MAportConfig.xml');
rtc.par.fund_frequency = set_freq;  % Set constant signal frequency
freq_str = strrep(sprintf('%.2f', rtc.par.fund_frequency), '.', '_');

%set controller gains
rtc.par.controller_Kd = 0.001;
rtc.par.controller_Kp = 0.2;
rtc.par.controller_Ki = 0.0000;

target_range = 0.5:0.1:4;
n_points = length(target_range);
results = zeros(n_points, 4);  % [freq, signal amp, response amp, invasiveness]

% === Setup Live Scatter ===
figure;
hold on;
grid on;

scatter(0, 0, 50, 'r', 'filled');   % <-- scatter handle
xlabel('Signal Amplitude');
ylabel('Response Amplitude');
title("Live S-Curve Tracking: " + set_freq);


% === reset reference coefficients ===
rtc.par.fund_amp = 0;
rtc.par.control_switch = 1;
rtc.par.target_adjustments = 0;
pause(10);
rtc.par.ss_trigger = 1; pause(0.1); rtc.par.ss_trigger = 0;
rtc.par.target_adjustments = 1;


% === Main S-Curve Loop ===
prev_target_vec = zeros(1+2*k_harmonics, 1);
prev_target_vec(2+k_harmonics) = target_range(1);
rtc.par.target_vec = prev_target_vec;

rtc.par.control_switch = 2;
for i = 1:n_points
    amp = target_range(i);
    % rtc.par.target_amp = amp;
    rtc.par.target_vec(2+k_harmonics) = amp;
    % rtc.par.target_adjustments = 0;

    retry_counter = 4;
    min_invasiveness = 1;
    retry_counter2 = 1;
    while min_invasiveness > 0.05
        while retry_counter > 0
            % Wait before triggering steady-state detection
            disp("Waiting 10 sec...");
            pause(10);
            data = rtc.run_stream('stream_id', 1);
    
            % Extract last values (scalars)
            sig_amp = data.sig_amp(end);
            res_amp = data.res_amp(end);
            inv     = data.invasiveness(end);
            min_invasiveness = min(min_invasiveness, inv);
            fprintf("Data results -> amp %.2f: inv = %.3f\n", amp, inv);
    
            if inv < 0.05
                results(i, :) = [rtc.par.fund_frequency, sig_amp, res_amp, inv];
                break
            end
            retry_counter = retry_counter - 1;
            rtc.par.ss_trigger = 1; pause(0.1); rtc.par.ss_trigger = 0;
            rtc.par.target_adjustments = 1;
        end
        if retry_counter2 < 0
            
            break;

        end
        new_kd = max(rtc.par.controller_Kd - 0.00005, 0.0001);
        disp("reduce Kd to: " + new_kd);
        rtc.par.controller_Kd = new_kd;
        retry_counter2 = retry_counter-1;
    end

    % update persistent variables:
    prev_target_vec = rtc.par.ref_vec;
    prev_fund_amp = target_range(i);

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
