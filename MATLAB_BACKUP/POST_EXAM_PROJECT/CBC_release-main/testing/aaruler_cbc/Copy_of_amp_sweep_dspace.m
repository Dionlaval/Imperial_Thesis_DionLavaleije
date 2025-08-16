% clear; clc;
% set_freq = 14.5;
addpath("funcs");

% === Setup ===
rtc = signal_interface('MAportConfig.xml');
rtc.par.fund_frequency = set_freq;  % Set constant signal frequency
freq_str = strrep(sprintf('%.2f', rtc.par.fund_frequency), '.', '_');
rtc.par.displacement_thresh = 25;
rtc.par.input_thresh = 4;


%set controller gains
rtc.par.controller_Kd = 0.0003;
rtc.par.controller_Kp = 0.1;
rtc.par.controller_Ki = 0.0000;

% target_range = 1:0.2:15;
n_points = length(target_range);
results = zeros(n_points, 5);  % [freq, signal amp, response amp, invasiveness]
conditions = cell(n_points, 1);
kd_buffer = zeros(3,3); %[kd; norm_inv; norm_trans, etc..]


% === Setup Live Scatter ===
set_default_fig;
figure;
hold on;
grid on;

% scatter(0, 0, 50, 'r', 'filled');   % <-- scatter handle
xlabel('Signal Amplitude');
ylabel('Response Amplitude');
title("Live S-Curve Tracking: " + set_freq);


% === reset reference coefficients ===
rtc.par.fund_amp = 0;
rtc.par.control_switch = 1;
rtc.par.target_vec = zeros(1+2*k_harmonics, 1);
pause(10);
rtc.par.disp_offset = rtc.par.disp_in2; % set displacement offset



% === Main S-Curve Loop ===
rtc.par.control_switch = 2;
response_vector = zeros(1+2*k_harmonics, 1);

vec2mat = @(vec) reshape(vec(2:end), k_harmonics, 2);

for i = 1:n_points
    amp = target_range(i);

    % disp("Setting Primary: " + );
    primaries = zeros(k_harmonics, 2);
    primaries(1, 2) = amp;
    
    trans_thresh = 0.005;
    inv_thresh = 0.05;

    for n = (1:6)
        for m = (1:4)
            % disp("Update Secondary:" + m);
            secondaries = vec2mat(response_vector);
            secondaries(1, :) = 0;
            target = primaries + secondaries;
            rtc.par.target_vec = [0; target(:, 1); target(:, 2)];

            % Wait before triggering steady-state detection
            disp("Waiting 5 sec...");
            pause(5);
            sig_amp = rtc.par.sig_amp;
            res_amp = rtc.par.res_amp;
            invasiveness = rtc.par.invasiveness;
            transience = rtc.par.sig_transience;
            fprintf("Data results %.1f: [amp %.2f, inv = %.3f, Kd = %.5f]\n", m, amp, invasiveness, rtc.par.controller_Kd);
            
            % norm inv and trans based on thresholds
            norm_inv = invasiveness/inv_thresh;
            norm_trans = transience/trans_thresh;

            converge_cond = norm_inv < 1 && norm_trans < 1;
                        %debug
            disp([norm_inv, norm_trans, converge_cond])
            if(converge_cond)
                results(i, :) = [rtc.par.fund_frequency, sig_amp, res_amp, invasiveness, transience];
                ideal_target.Kp = rtc.par.controller_Kp;
                ideal_target.Kd = rtc.par.controller_Kd;
                ideal_target.vec = rtc.par.target_vec;
                conditions{i} = ideal_target;
                break
            end

            % next picard iteration
            response_vector = rtc.par.response_vec;
        end

        %dont iterate Kd if converged
        if(converge_cond)
            converge_cond = false;
            break
        end

        %if it cant converge after 4 picard iterations we need to adjust Kd
        kd_buffer(:, 1) = [rtc.par.controller_Kd; norm_inv; norm_trans];
        kd_buffer = circshift(kd_buffer, 1, 2);
        if(n == 1) % first iteration just do a blind step based on current errors
            if norm_trans > 1
                Kd_offset = 1 + 0.001;
            else 
                Kd_offset = 1 - 0.001;
            end
            rtc.par.controller_Kd = rtc.par.controller_Kd*Kd_offset;
            continue;
        else % next iterations based on previous values
            v1 = kd_buffer(:, 3);
            v2 = kd_buffer(:, 2);

            term1 = v1(2) - v1(3);
            term2 = v2(3) - v2(2);
            
            x1 = v1(1);
            x2 = v2(1);
            x_new = (x2*term1 + x1*term2)/(term2 + term1);
    
            delta_x = x_new - rtc.par.controller_Kd;
            %avoid negative Kd
            rtc.par.controller_Kd = max(x_new-0.5*delta_x, 0.00001);
        end
    end


    results(i, :) = [rtc.par.fund_frequency, sig_amp, res_amp, invasiveness, transience];
    ideal_target.Kp = rtc.par.controller_Kp;
    ideal_target.Kd = rtc.par.controller_Kd;
    ideal_target.vec = rtc.par.target_vec;
    conditions{i} = ideal_target;
    % Update scatter plot
    scatter(sig_amp, res_amp, 50, 'r', 'filled');
    drawnow;
end

rtc.par.target_vec = zeros(1+2*k_harmonics, 1);
rtc.par.control_switch = 1;
rtc.par.fund_amp = 0;        % Amplitude (adjust as needed)


% === Save result ===
save_folder = "saves/SCURVE";
if ~exist(save_folder, 'dir'), mkdir(save_folder); end
fname = sprintf("s_curve_freq_%s.mat", freq_str);
fname2 = sprintf("conds_s_curve_freq_%s.mat", freq_str);
save(fullfile(save_folder, fname), 'results');
save(fullfile(save_folder, fname2), 'conditions');

% ------


% reset coefficients^^



disp("✅ S-curve complete.");
