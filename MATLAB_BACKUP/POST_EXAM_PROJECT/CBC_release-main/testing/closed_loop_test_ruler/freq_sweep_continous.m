clear; clc;
addpath("funcs");

% === Constants ===
k_harmonics = 7;
alpha = 0;
fs = 10000;           % Hz
dt = 1/fs;
T = 3;                % seconds per frequency
amp_val = 0.7;        % constant forcing amplitude

% === Setup signal interface ===
rtc = signal_interface('MAportConfig.xml');
rtc.par.Amp = amp_val;
% rtc.par.filter_alpha = alpha; % Optional

% === Frequency sweep definitions ===
sweeps(1).name = "up";
sweeps(1).frequencies = 12:0.2:22;
sweeps(2).name = "down";
sweeps(2).frequencies = 22:-0.2:12;

% === Main Loop for Both Sweeps ===
for sweep_idx = 1:2
    sweep = sweeps(sweep_idx);
    frequencies = sweep.frequencies;
    amplitudes = zeros(size(frequencies));
    forces = zeros(size(frequencies));

    for i = 1:length(frequencies)
        f_now = frequencies(i);
        fprintf("[%s] Sweeping at %.2f Hz...\n", sweep.name, f_now);
        rtc.par.fund_frequency = f_now;

        pause(T);
        data = rtc.run_stream('stream_id', 1);

        % Time vector
        N = length(data.disp_in2);
        t = (0:N-1) * dt;
        disp_signal = data.disp_in2;
        force_signal = data.force_in1;

        % === Displacement processing ===
        [t_trim, x_trim] = f_get_last_n_periods(t, disp_signal, 10);
        t_lin = t_trim - t_trim(1);
        x_trim([1 end]) = 0;
        [a_vec, b_vec] = f_get_fft_components(t_lin, x_trim, 2*pi*f_now, k_harmonics);
        amplitudes(i) = norm([a_vec, b_vec]);

        % === Force processing ===
        [t_trimf, f_trim] = f_get_last_n_periods(t, force_signal, 10);
        t_linf = t_trimf - t_trimf(1);
        f_trim([1 end]) = 0;
        [a_vecf, b_vecf] = f_get_fft_components(t_linf, f_trim, 2*pi*f_now, k_harmonics);
        forces(i) = norm([a_vecf, b_vecf]);
    end

    % === Save results ===
    amp_str = sprintf('%05.2f', amp_val);  % e.g. '04.60'
    amp_str = strrep(amp_str, '.', '_');   % → '04_60'
    data_out = [frequencies', amplitudes', forces'];

    save("saves/OL_blade_" + sweep.name + "/ruler_amp_" + amp_str + ".mat", "data_out");

    % === Plot sweep result ===
    figure;
    scatter3(frequencies, forces, amplitudes, 25, 'filled');
    xlabel("Frequency [Hz]");
    ylabel("Force Amplitude");
    zlabel("Response Amplitude");
    title("Sweep Direction: " + sweep.name);
    grid on;
end
rtc.par.Amp = 0;
disp("✅ Both sweeps complete.");
