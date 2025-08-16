clear; clc;
addpath("funcs");
k_harmonics = 7;
alpha = 0;

% === Setup signal interface ===
rtc = signal_interface('MAportConfig.xml');
rtc.par.filter_alpha = alpha;

% === Sweep parameters ===
frequency = 162;

% === Forcing parameters ===
g_start = 5;
g_end = 14;
g_step = 0.2;
gains = g_start:g_step:g_end;
amplitudes = zeros(size(gains));
forces = zeros(size(gains));
% rtc.par.Amp = 14;  % Constant amplitude

% === Sampling settings ===
fs = 10000;    % Hz
dt = 1/fs;
T = 3;       % Duration per frequency (seconds)

% === Sweep loop ===

% Set frequency
rtc.par.fund_frequency = frequency;

for i = 1:length(gains)
    gain_now = gains(i);
    rtc.par.Amp = gain_now;
    fprintf("Sweeping at %.2f Gain...\n", gain_now);

    % Wait and record
    pause(T);
    data = rtc.run_stream('stream_id', 1);

    % Time vector
    N = length(data.disp_in2);
    t = (0:N-1) * dt;

    % Extract signal
    disp_signal = data.disp_in2;
    force_signal = data.force_in1;

    % get coeffs
    [t_trim, x_trim] = f_get_last_n_periods(t, disp_signal, 10);
    t_lin = t_trim - t_trim(1);
    x_trim(1) = 0;
    x_trim(end) = 0;
    [a_vec, b_vec] = f_get_fft_components(t_lin, x_trim, 2*pi*frequency, k_harmonics);
    % [t_rec, x_rec] = f_get_reconstructed_wave(a_vec, b_vec, t_lin, 2*pi*frequency);
    estimated_amplitude = norm([a_vec, b_vec]);
    amplitudes(i) = estimated_amplitude;

    % get force coeffs
    [t_trim, x_trim] = f_get_last_n_periods(t, force_signal, 10);
    t_lin = t_trim - t_trim(1);
    x_trim(1) = 0;
    x_trim(end) = 0;
    [a_vec, b_vec] = f_get_fft_components(t_lin, x_trim, 2*pi*frequency, k_harmonics);
    % [t_rec, x_rec] = f_get_reconstructed_wave(a_vec, b_vec, t_lin, 2*pi*frequency);
    estimated_amplitude = norm([a_vec, b_vec]);
    forces(i) = estimated_amplitude;

    
    %plot figure
    % figure;
    % hold on;
    % plot(t_lin, x_trim)
    % plot(t_lin, x_rec)
    % ylabel(sprintf('%.1f Hz', f_now));
    % xlabel('Time [s]');
end


% === Reset system ===
% rtc.par.fund_frequency = 0;


figure
hold on;
scatter(forces, amplitudes)


data = [gains', amplitudes', forces'];
freq_str = sprintf('%05.2f', rtc.par.fund_frequency);         % e.g.,  4.60 → '04.60'
freq_str = strrep(freq_str, '.', '_');              %         → '04_60'
save("saves\OL_blade_17_07_2025\freq_" + freq_str + ".mat", "data");

rtc.par.Amp = 0;

disp("✅ Sweep complete.");
