clear; clc;
addpath("funcs");
k_harmonics = 7;
alpha = 0;

% === Setup signal interface ===
rtc = signal_interface('MAportConfig.xml');
rtc.par.filter_alpha = alpha;

% === Sweep parameters ===
freq_start = 165;      % Hz
freq_end   = 155;     % Hz
freq_step  = -0.1;      % Hz
frequencies = freq_start:freq_step:freq_end;

% === Forcing parameters ===
rtc.par.Amp = 10;  % Constant amplitude

% === Sampling settings ===
fs = 10000;    % Hz
dt = 1/fs;
T = 3;       % Duration per frequency (seconds)

% === Prepare figure ===
amplitudes = zeros(size(frequencies));
forces = zeros(size(frequencies));

% === Sweep loop ===
for i = 1:length(frequencies)
    f_now = frequencies(i);
    fprintf("Sweeping at %.2f Hz...\n", f_now);

    % Set frequency
    rtc.par.fund_frequency = f_now;

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
    [a_vec, b_vec] = f_get_fft_components(t_lin, x_trim, 2*pi*f_now, k_harmonics);
    % [t_rec, x_rec] = f_get_reconstructed_wave(a_vec, b_vec, t_lin, 2*pi*f_now);
    estimated_amplitude = norm([a_vec, b_vec]);
    amplitudes(i) = estimated_amplitude;
    
    % get coeffs
    [t_trimf, f_trim] = f_get_last_n_periods(t, force_signal, 10);
    t_linf = t_trimf - t_trimf(1);
    f_trim(1) = 0;
    f_trim(end) = 0;
    [a_vecf, b_vecf] = f_get_fft_components(t_linf, f_trim, 2*pi*f_now, k_harmonics);
    % [t_rec, x_rec] = f_get_reconstructed_wave(a_vec, b_vec, t_lin, 2*pi*f_now);
    estimated_amplitudef = norm([a_vecf, b_vecf]);
    forces(i) = estimated_amplitudef;

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
scatter3(frequencies, forces, amplitudes)


data = [frequencies', amplitudes', forces'];
amp_str = sprintf('%05.2f', rtc.par.Amp);         % e.g.,  4.60 → '04.60'
amp_str = strrep(amp_str, '.', '_');              %         → '04_60'

rtc.par.Amp = 0;

save("saves\OL_blade_18_07_2025\amp_" + amp_str + ".mat", "data");


disp("✅ Sweep complete.");
