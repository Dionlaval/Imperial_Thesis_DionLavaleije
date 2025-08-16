clear; clc;
addpath("funcs");

% === Constants ===
k_harmonics = 7;
alpha = 0;
fs = 10000;           % Hz
dt = 1/fs;
T = 5;                % seconds per frequency
amplitudes_to_test = 0.5:0.05:1;

% === Frequency sweep definitions ===
sweeps(1).name = "up";
sweeps(1).frequencies = 10.3:0.45:16.15;
sweeps(1).color = 'b';
sweeps(2).name = "down";
sweeps(2).frequencies = 16.15:-0.45:10.3;
sweeps(2).color = 'r';

% === Setup signal interface ===
rtc = signal_interface('MAportConfig.xml');

% === Prepare master figure ===
figure;
hold on;
xlabel("Frequency [Hz]");
ylabel("Signal Amplitude");
zlabel("Response Amplitude");
title("Real-Time Frequency Sweep");
grid on;
view([45, 25]);
rtc.par.fund_amp = 0;
rtc.par.control_switch = 1;
pause(10);
% === Outer loop: over amplitude levels ===
for amp_val = amplitudes_to_test
    rtc.par.fund_amp = amp_val;

    for sweep_idx = 1:2
        sweep = sweeps(sweep_idx);
        frequencies = sweep.frequencies;
        response_amplitudes = zeros(size(frequencies));
        signal_amplitudes = zeros(size(frequencies));
        forces = zeros(size(frequencies));

        for i = 1:length(frequencies)
            f_now = frequencies(i);
            fprintf("[Amp %.2f | %s] Sweeping at %.2f Hz...\n", amp_val, sweep.name, f_now);
            rtc.par.fund_frequency = f_now;

            pause(T);
            response_amplitudes(i) = rtc.par.res_amp;
            signal_amplitudes(i) = rtc.par.fund_amp;
            forces(i) = rtc.par.force_amp;
            scatter3(f_now, signal_amplitudes(i), response_amplitudes(i), 25, sweep.color, 'filled');

            % data = rtc.run_stream('stream_id', 1);
            % 
            % % Time vector
            % N = length(data.disp_in2);
            % t = (0:N-1) * dt;
            % disp_signal = data.disp_in2;
            % force_signal = data.force_in1;
            % 
            % % === Displacement processing ===
            % [t_trim, x_trim] = f_get_last_n_periods(t, disp_signal, 10);
            % t_lin = t_trim - t_trim(1);
            % x_trim([1 end]) = 0;
            % [a_vec, b_vec] = f_get_fft_components(t_lin, x_trim, 2*pi*f_now, k_harmonics);
            % amplitudes(i) = norm([a_vec, b_vec]);
            % 
            % % === Force processing ===
            % [t_trimf, f_trim] = f_get_last_n_periods(t, force_signal, 10);
            % t_linf = t_trimf - t_trimf(1);
            % f_trim([1 end]) = 0;
            % [a_vecf, b_vecf] = f_get_fft_components(t_linf, f_trim, 2*pi*f_now, k_harmonics);
            % forces(i) = norm([a_vecf, b_vecf]);
        end

        % === Save results ===
        amp_str = sprintf('%05.2f', amp_val);  % e.g. '04.60'
        amp_str = strrep(amp_str, '.', '_');   % → '04_60'
        data_out = [frequencies', response_amplitudes', signal_amplitudes' ,forces'];
        save("saves/OL_blade_" + sweep.name + "/ruler_amp_" + amp_str + ".mat", "data_out");

        % === Incremental plot update ===
        % scatter3(frequencies, forces, amplitudes, 25, sweep.color, 'filled');
        drawnow;
    end
end

% === Reset system ===
rtc.par.fund_amp = 0;
rtc.par.fund_frequency = 0;
disp("✅ Full amplitude + frequency sweep completed.");
