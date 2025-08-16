%% Initialization
clear; clc;

% Initialize signal_interface
rtc = signal_interface('MAportConfig.xml');

% For safety, initialize frequency and amplitude to zero
rtc.par.Frequency = 0;
rtc.par.Amp = 0;

% Set fixed amplitude (adjustable)
rtc.par.Amp = 1.7; %% Change

% Set frequency sweep parameters
freq_start = 6; %% Change
freq_end = 5; %% Change
freq_step = -0.2; %% Change
frequencies = freq_start:freq_step:freq_end; %% Change

% Sampling frequency (known from system)
fs = 1000;  % Hz
dt = 1 / fs;
sample_sens = 1; % to distinguish 2 dot 2 means 小數點後兩位

% Data storage
bifurcation_freq = [];
bifurcation_points = {};
time_series_data = {};
peak_force = NaN(size(frequencies));  % store max peak of force at each frequency

% Output folder (user-specified)
saved_path = 'C:\Users\dionl\Desktop\AME_MASTERS\MATLAB\POST_EXAM_PROJECT\CBC_release-main\testing\single_frequency_test\output_data\test1';
if ~exist(saved_path, 'dir')
    mkdir(saved_path);
end

% Initialize bifurcation diagram
F = figure();
ax = axes(F);
xlabel(ax, 'Frequency (Hz)');
ylabel(ax, 'Displacement Amplitude (mm)');
title(ax, 'Real-Time Bifurcation Diagram');
hold(ax, 'on'); grid(ax, 'on');
h = plot(ax, NaN, NaN, '.b','MarkerSize', 20);
xlim(ax, [min(freq_start, freq_end), max(freq_start, freq_end)]);

%% Frequency sweep
for i = 1:length(frequencies)
    freq = frequencies(i);
    rtc.par.Frequency = freq;
    fprintf('Now sweeping frequency: %.2f Hz\n', freq);
    pause(10);  % Wait for transients to decay

    % Acquire real-time data
    data = rtc.run_stream('stream_id', 1);

    % Construct time axis
    N = length(data.disp_in2);
    t = (0:N-1) * dt;
    disp_signal = data.disp_in2;
    force_signal = data.force_in1;
    acc_signal=data.acc_in3;

    % 尋找所有顯著正向峰值
    [peaks, locs] = findpeaks(disp_signal, 'MinPeakProminence', 0.02);

    % 選出正向（>0）的峰
    pos_idx = find(peaks > 0);
    peaks_pos = peaks(pos_idx);
    locs_pos = locs(pos_idx);

    % fallback
    t0 = t(1);

    % 如果有三個以上正向主峰
    if length(peaks_pos) >= 1
        % 取前3個正向主峰（最多三個）
        top_N = min(3, length(peaks_pos));
        [~, sort_idx] = sort(peaks_pos(1:top_N), 'descend');  % 取最大
        t0 = t(locs_pos(sort_idx(1)));  % 最大的那個對應時間
    end


    % Sampling using forcing period from first peak
    T_force = 1 / freq;
    sample_times = t0:T_force:t(end);
    sampled_disp = interp1(t, disp_signal, sample_times, 'linear');
    sampled_disp = unique(round(sampled_disp, sample_sens));

    % Store for bifurcation plot
    bifurcation_freq = [bifurcation_freq; freq * ones(length(sampled_disp), 1)];
    bifurcation_points = [bifurcation_points; num2cell(sampled_disp(:))];

    % Store full time series and sampling info
    time_series_data{i}.t = t;
    time_series_data{i}.disp = disp_signal;
    time_series_data{i}.force = force_signal;
    time_series_data{i}.acc=acc_signal;
    time_series_data{i}.t0 = t0;
    time_series_data{i}.T_force = T_force;

    % Extract peak force for this frequency
    [pks_force, ~] = findpeaks(force_signal, 'MinPeakProminence', 0.05);
    if ~isempty(pks_force)
        peak_force(i) = max(pks_force);
    end

    % Update bifurcation diagram
    set(h, 'XData', bifurcation_freq, 'YData', cell2mat(bifurcation_points));
    drawnow;

    % === Auto Save All Figures for This Frequency ===
    sample_times = t0:T_force:t(end);
    sampled_disp = interp1(t, disp_signal, sample_times, 'linear');

    % Displacement Time Series
    fig1 = figure('Visible','off');
    plot(t, disp_signal, 'b'); hold on;
    plot(sample_times, sampled_disp, 'ro', 'MarkerFaceColor', 'r');
    xlabel('Time (s)'); ylabel('Displacement (mm)');
    title(sprintf('Displacement @ %.2f Hz', freq));
    legend('Displacement', 'Sampled Points');
    exportgraphics(fig1, fullfile(saved_path, sprintf('f%.1f_displacement.png', freq)), 'Resolution', 300);
    close(fig1);

    % Force Time Series
    fig2 = figure('Visible','off');
    plot(t, force_signal, 'k');
    xlabel('Time (s)'); ylabel('Force (N)');
    title(sprintf('Force @ %.2f Hz', freq));
    exportgraphics(fig2, fullfile(saved_path, sprintf('f%.1f_force.png', freq)), 'Resolution', 300);
    close(fig2);

    % FFT
    L = length(disp_signal);
    window = hann(L);
    signal_win = disp_signal(:) .* window;
    f_axis = fs*(0:(L/2))/L;
    fft_result = fft(signal_win);
    P2 = abs(fft_result / L);
    P1 = P2(1:floor(L/2)+1);
    P1(2:end-1) = 2*P1(2:end-1);
    fig3 = figure('Visible','off');
    plot(f_axis, P1);
    xlabel('Frequency (Hz)'); ylabel('Amplitude');
    title(sprintf('FFT of Displacement @ %.2f Hz', freq));
    grid on;
    exportgraphics(fig3, fullfile(saved_path, sprintf('f%.1f_fft.png', freq)), 'Resolution', 300);
    close(fig3);

    % Phase Portrait + Poincare
    disp_col = disp_signal(:);
    %數值微分法求速度
    vel_signal = [0; diff(disp_col) * fs];
    vel_signal = smoothdata(vel_signal, 'movmean', 5);
    if length(vel_signal) > length(t)
        vel_signal = vel_signal(1:length(t));
    elseif length(vel_signal) < length(t)
        t = t(1:length(vel_signal));
    end
    sample_disp = interp1(t, disp_col, sample_times, 'linear');
    sample_vel = interp1(t, vel_signal, sample_times, 'linear');
    fig4 = figure('Visible','off');
    plot(disp_col, vel_signal, 'b'); hold on;
    plot(sample_disp, sample_vel, 'ro', 'MarkerFaceColor', 'r');
    xlabel('Displacement (mm)'); ylabel('Velocity (mm/s)');
    title(sprintf('Phase Portrait & Poincaré Section @ %.2f Hz', freq));
    legend('Phase trajectory', 'Poincaré points');
    grid on;
    exportgraphics(fig4, fullfile(saved_path, sprintf('f%.1f_phase.png', freq)), 'Resolution', 300);
    close(fig4);
    % Acc Time Series
    fig5 = figure('Visible','off');
    plot(t, acc_signal, 'g');
    xlabel('Time (s)'); ylabel('Acceleration (m/s^2)');
    title(sprintf('Acceleration @ %.2f Hz', freq));
    exportgraphics(fig5, fullfile(saved_path, sprintf('f%.1f_acceleration.png', freq)), 'Resolution', 300);
    close(fig5);
end

%% Save final bifurcation diagram
fig_bif = figure('Visible', 'off');
plot(bifurcation_freq, cell2mat(bifurcation_points), '.b', 'MarkerSize', 20);
xlabel('Frequency (Hz)');
ylabel('Displacement Amplitude (mm)');
title('Bifurcation Diagram');
grid on;
exportgraphics(fig_bif, fullfile(saved_path, 'bifurcation_diagram.png'), 'Resolution', 300);
close(fig_bif);

%% Sweep complete
disp('🎉 Frequency sweep completed!');
rtc.par.Frequency = 0;
rtc.par.Amp = 0;

% Display peak forces
fprintf('\nPeak force amplitudes at each frequency:\n');
for i = 1:length(frequencies)
    fprintf('  %.2f Hz: %.4f N\n', frequencies(i), peak_force(i));
end
fprintf('Overall average peak force amplitude = %.4f N\n', nanmean(peak_force));

% Save MAT data
save(fullfile(saved_path, 'sweep_data.mat'), ...
    'frequencies', 'bifurcation_freq', 'bifurcation_points', 'time_series_data', 'peak_force');

%% Time series viewer (manual inspection)
while true
    prompt = 'Enter a frequency to view its time series (Hz), or "q" to quit: ';
    str = input(prompt, 's');
    if strcmpi(str, 'q')
        break;
    end
    f_query = str2double(str);
    [~, idx] = min(abs(frequencies - f_query));
    if isempty(idx) || idx < 1 || idx > length(frequencies)
        fprintf('❌ No data found for that frequency.\n');
        continue;
    end

    ts = time_series_data{idx};
    t = ts.t;
    disp_signal = ts.disp;
    force_signal = ts.force;
    acc_signal= ts.acc;
    T_force = ts.T_force;
    t0 = ts.t0;
    sample_times = t0:T_force:t(end);
    sampled_disp = interp1(t, disp_signal, sample_times, 'linear');

    % Plot with interactive Data Tips
    figure; datacursormode on;
    plot(t, disp_signal, 'b'); hold on;
    plot(sample_times, sampled_disp, 'ro', 'MarkerFaceColor', 'r');
    xlabel('Time (s)'); ylabel('Displacement (mm)');
    title(sprintf('Displacement @ %.2f Hz', frequencies(idx)));
    legend('Displacement', 'Sampled Points');

    figure; datacursormode on;
    plot(t, force_signal, 'k');
    xlabel('Time (s)'); ylabel('Force (N)');
    title(sprintf('Force @ %.2f Hz', frequencies(idx)));

    figure; datacursormode on;
    plot(t, acc_signal, 'g');
    xlabel('Time (s)'); ylabel('Acceleration (m/s2)');
    title(sprintf('Acceleration @ %.2f Hz', frequencies(idx)));

    L = length(disp_signal);
    window = hann(L);
    signal_win = disp_signal(:) .* window;
    f_axis = fs*(0:(L/2))/L;
    fft_result = fft(signal_win);
    P2 = abs(fft_result / L);
    P1 = P2(1:floor(L/2)+1);
    P1(2:end-1) = 2*P1(2:end-1);

    figure; datacursormode on;
    plot(f_axis, P1);
    xlabel('Frequency (Hz)'); ylabel('Amplitude');
    title(sprintf('FFT of Displacement @ %.2f Hz', frequencies(idx)));
    grid on;

    disp_col = disp_signal(:);
    vel_signal = [0; diff(disp_col) * fs];
    vel_signal = smoothdata(vel_signal, 'movmean', 5);
    if length(vel_signal) > length(t)
        vel_signal = vel_signal(1:length(t));
    elseif length(vel_signal) < length(t)
        t = t(1:length(vel_signal));
    end
    sample_disp = interp1(t, disp_col, sample_times, 'linear');
    sample_vel = interp1(t, vel_signal, sample_times, 'linear');
    figure; datacursormode on;
    plot(disp_col, vel_signal, 'b'); hold on;
    plot(sample_disp, sample_vel, 'ro', 'MarkerFaceColor', 'r');
    xlabel('Displacement (mm)'); ylabel('Velocity (mm/s)');
    title(sprintf('Phase Portrait & Poincaré Section @ %.2f Hz', frequencies(idx)));
    legend('Phase trajectory', 'Poincaré points');
    grid on;
end
