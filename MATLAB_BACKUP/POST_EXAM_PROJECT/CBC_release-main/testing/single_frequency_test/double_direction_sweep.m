%% Initialization
clear; clc;

% Initialize signal_interface
rtc = signal_interface('MAportConfig.xml');
rtc.par.Frequency = 0;
rtc.par.Amp = 0;
rtc.par.Amp = 2.0;

% Set frequency sweep parameters
freq_forward = 5:0.2:6;
freq_backward = 6:-0.2:5;
frequencies_all = [freq_forward, freq_backward];

% Sampling parameters
fs = 1000; dt = 1 / fs;
sample_sens = 1;

% Data storage
bifurcation_freq = [];
bifurcation_points = {};
bifurcation_color = [];  % 'b' for forward, 'r' for backward
time_series_data = {};
peak_force = NaN(size(frequencies_all));

% Output folder
saved_path = 'D:\OneDrive\Imperial_College_London\OneDrive - Imperial College London\Imperial\FYP\Experiment\04072025\5_6Hz_02step_20Amp_double_direction_1st';
if ~exist(saved_path, 'dir'); mkdir(saved_path); end

% Initialize bifurcation diagram
F = figure();
ax = axes(F);
xlabel(ax, 'Frequency (Hz)');
ylabel(ax, 'Displacement Amplitude (mm)');
title(ax, 'Real-Time Bifurcation Diagram');
hold(ax, 'on'); grid(ax, 'on');
h_forward = plot(ax, NaN, NaN, '.b', 'MarkerSize', 20);
h_backward = plot(ax, NaN, NaN, '^r', 'MarkerSize', 6);
xlim(ax, [min(frequencies_all), max(frequencies_all)]);

%% Run both forward and backward sweeps
for i = 1:length(freq_forward)
    process_freq(freq_forward(i), i, 'b');
end

for i = 1:length(freq_backward)
    process_freq(freq_backward(i), length(freq_forward) + i, 'r');
end

%% Save bifurcation diagram
fig_bif = figure('Visible','off');
colors = evalin('base','bifurcation_color');
frequencies = evalin('base','bifurcation_freq');
ydata = cell2mat(evalin('base','bifurcation_points'));
is_b = strcmp(colors, 'b');
is_r = strcmp(colors, 'r');
scatter(frequencies(is_b), ydata(is_b), 20, 'b', 'filled'); hold on;
scatter(frequencies(is_r), ydata(is_r), 25, '^r', 'filled');
xlabel('Frequency (Hz)'); ylabel('Displacement Amplitude (mm)');
title('Bifurcation Diagram: Forward (Blue) & Backward (Red)');
grid on;
exportgraphics(fig_bif, fullfile(saved_path, 'bifurcation_diagram_fwdrev.png'), 'Resolution', 300);
close(fig_bif);

%% Save Data
save(fullfile(saved_path, 'sweep_data_fwdrev.mat'), 'freq_forward', 'freq_backward', 'frequencies', 'bifurcation_freq', 'bifurcation_points', 'bifurcation_color', 'time_series_data', 'peak_force');
rtc.par.Frequency = 0;
rtc.par.Amp = 0;
%% Local function (must be at end of script)
function process_freq(freq, idx, tag)
    fs = evalin('base', 'fs');
    dt = evalin('base', 'dt');
    sample_sens = evalin('base', 'sample_sens');
    rtc = evalin('base', 'rtc');
    saved_path = evalin('base', 'saved_path');

    rtc.par.Frequency = freq;
    fprintf('[%d] Sweeping %.2f Hz (%s)', idx, freq, tag);
    pause(60);
    data = rtc.run_stream('stream_id', 1);

    N = length(data.disp_in2);
    t = (0:N-1) * dt;
    disp_signal = data.disp_in2;
    force_signal = data.force_in1;
    acc_signal = data.acc_in3;

    [peaks, locs] = findpeaks(disp_signal, 'MinPeakProminence', 0.02);
    pos_idx = find(peaks > 0);
    peaks_pos = peaks(pos_idx);
    locs_pos = locs(pos_idx);
    t0 = t(1);
    if ~isempty(peaks_pos)
        top_N = min(3, length(peaks_pos));
        [~, sort_idx] = sort(peaks_pos(1:top_N), 'descend');
        t0 = t(locs_pos(sort_idx(1)));
    end

    T_force = 1 / freq;
    sample_times = t0:T_force:t(end);
    sampled_disp = interp1(t, disp_signal, sample_times, 'linear');
    sampled_disp = unique(round(sampled_disp, sample_sens));

    assignin('base', 'bifurcation_freq', [evalin('base', 'bifurcation_freq'); freq * ones(length(sampled_disp), 1)]);
    assignin('base', 'bifurcation_points', [evalin('base', 'bifurcation_points'); num2cell(sampled_disp(:))]);
    assignin('base', 'bifurcation_color', [evalin('base', 'bifurcation_color'); repmat({tag}, length(sampled_disp), 1)]);

    ts.t = t; ts.disp = disp_signal; ts.force = force_signal; ts.acc = acc_signal; ts.t0 = t0; ts.T_force = T_force;
    assignin('base', 'time_series_data', subsasgn(evalin('base','time_series_data'), substruct('{}',{idx}), ts));

    [pks_force, ~] = findpeaks(force_signal, 'MinPeakProminence', 0.05);
    pf = NaN; if ~isempty(pks_force), pf = max(pks_force); end
    pf_arr = evalin('base', 'peak_force'); pf_arr(idx) = pf;
    assignin('base', 'peak_force', pf_arr);

    if tag == "b"
        h = evalin('base', 'h_forward');
    else
        h = evalin('base', 'h_backward');
    end
    xdata = get(h, 'XData');
ydata = get(h, 'YData');
xdata = xdata(:);
ydata = ydata(:);
set(h, 'XData', [xdata; freq * ones(length(sampled_disp),1)], 'YData', [ydata; sampled_disp(:)]);
    drawnow;

    % === Displacement Time Series ===
    fig = figure('Visible','off');
    plot(t, disp_signal, 'b'); hold on;
    plot(sample_times, interp1(t, disp_signal, sample_times, 'linear'), 'ro', 'MarkerFaceColor', 'r');
    xlabel('Time (s)'); ylabel('Displacement (mm)');
    title(sprintf('Displacement @ %.2f Hz (%s)', freq, tag));
    exportgraphics(fig, fullfile(saved_path, sprintf('f%.1f_%s_disp.png', freq, tag)), 'Resolution', 300);
savefig(fig, fullfile(saved_path, sprintf('f%.1f_%s_disp.fig', freq, tag)));
    close(fig);

    % === Force Time Series ===
    fig = figure('Visible','off');
    plot(t, force_signal, 'k');
    xlabel('Time (s)'); ylabel('Force (N)');
    title(sprintf('Force @ %.2f Hz (%s)', freq, tag));
    exportgraphics(fig, fullfile(saved_path, sprintf('f%.1f_%s_force.png', freq, tag)), 'Resolution', 300);
savefig(fig, fullfile(saved_path, sprintf('f%.1f_%s_force.fig', freq, tag)));
    close(fig);

    % === Acceleration Time Series ===
    fig = figure('Visible','off');
    plot(t, acc_signal, 'g');
    xlabel('Time (s)'); ylabel('Acceleration (m/s^2)');
    title(sprintf('Acceleration @ %.2f Hz (%s)', freq, tag));
    exportgraphics(fig, fullfile(saved_path, sprintf('f%.1f_%s_acc.png', freq, tag)), 'Resolution', 300);
savefig(fig, fullfile(saved_path, sprintf('f%.1f_%s_acc.fig', freq, tag)));
    close(fig);

    % === FFT of Displacement ===
    L = length(disp_signal);
    window = hann(L);
    signal_win = disp_signal(:) .* window;
    f_axis = fs*(0:(L/2))/L;
    fft_result = fft(signal_win);
    P2 = abs(fft_result / L);
    P1 = P2(1:floor(L/2)+1);
    P1(2:end-1) = 2*P1(2:end-1);
    fig = figure('Visible','off');
    plot(f_axis, P1);
    xlabel('Frequency (Hz)'); ylabel('Amplitude');
    title(sprintf('FFT of Displacement @ %.2f Hz (%s)', freq, tag));
    grid on;
    exportgraphics(fig, fullfile(saved_path, sprintf('f%.1f_%s_fft.png', freq, tag)), 'Resolution', 300);
savefig(fig, fullfile(saved_path, sprintf('f%.1f_%s_fft.fig', freq, tag)));
    close(fig);

    % === Phase Portrait & Poincaré Section ===
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
    fig = figure('Visible','off');
    plot(disp_col, vel_signal, 'b'); hold on;
    plot(sample_disp, sample_vel, 'ro', 'MarkerFaceColor', 'r');
    xlabel('Displacement (mm)'); ylabel('Velocity (mm/s)');
    title(sprintf('Phase Portrait & Poincaré Section @ %.2f Hz (%s)', freq, tag));
    legend('Phase trajectory', 'Poincaré points');
    grid on;
    exportgraphics(fig, fullfile(saved_path, sprintf('f%.1f_%s_phase.png', freq, tag)), 'Resolution', 300);
savefig(fig, fullfile(saved_path, sprintf('f%.1f_%s_phase.fig', freq, tag)));
    close(fig);
end
