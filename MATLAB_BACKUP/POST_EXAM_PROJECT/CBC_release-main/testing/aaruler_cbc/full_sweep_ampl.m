clear; clc;
addpath("funcs");

% === Constants ===
k_harmonics = 7;
alpha = 0;
fs = 10000;           % Hz
dt = 1/fs;
T = 2.5;                % seconds per amplitude point

% === What to sweep ===
freqs_to_test     = 10.3:0.45:16.15;   % fixed frequencies to run
amplitude_min     = 1;%0.15;
amplitude_max     = 2.5;
amplitude_step    = 0.1;

% === Amplitude sweep definitions (UP/DOWN) ===
sweeps(1).name  = "up";
sweeps(1).amps  = amplitude_min:amplitude_step:amplitude_max;
sweeps(1).color = 'b';

sweeps(2).name  = "down";
sweeps(2).amps  = amplitude_max:-amplitude_step:amplitude_min;
sweeps(2).color = 'r';

% === Setup signal interface ===
rtc = signal_interface('MAportConfig.xml');

% === Prepare master figure ===
figure;
hold on; grid on;
xlabel("Amplitude [V]");          % <— x-axis is amplitude now
ylabel("Frequency [Hz]");
zlabel("Response Amplitude");
title("Real-Time Amplitude Sweep");
view([45, 25]);

% Safe initialisation
rtc.par.fund_amp = 0;
rtc.par.control_switch = 1;
pause(10);

% === Outer loop: over FREQUENCIES (fixed), inner: amplitude sweeps ===
freqs_to_test = freqs_to_test(1:7);
for f_val = freqs_to_test
    rtc.par.fund_frequency = f_val;

    for sweep_idx = 1:1  %numel(sweeps)
        sweep = sweeps(sweep_idx);
        amps  = sweep.amps;

        response_amplitudes = zeros(size(amps));
        signal_amplitudes   = zeros(size(amps));
        forces              = zeros(size(amps));
        rtc.par.fund_amp = amps(1);
        pause(5);
        for i = 1:numel(amps)
            a_now = amps(i);
            fprintf("[Freq %.2f Hz | %s] Sweeping amplitude = %.2f ...\n", f_val, sweep.name, a_now);

            rtc.par.fund_amp = a_now;

            % Let the rig settle & measure
            pause(T);

            % Read back latest values (adjust field names if needed)
            response_amplitudes(i) = rtc.par.res_amp;
            signal_amplitudes(i)   = rtc.par.fund_amp;
            forces(i)              = rtc.par.force_amp;

            % Live plot (note: x=Amplitude, y=Frequency, z=Response)
            scatter3(a_now, f_val, response_amplitudes(i), 25, sweep.color, 'filled');

            % -------- Optional: FFT-based extraction (kept from your code) --------
            % data = rtc.run_stream('stream_id', 1);
            % N = length(data.disp_in2);
            % t = (0:N-1) * dt;
            % disp_signal  = data.disp_in2;
            % force_signal = data.force_in1;
            % [t_trim, x_trim]   = f_get_last_n_periods(t, disp_signal, 10);
            % t_lin = t_trim - t_trim(1);
            % x_trim([1 end]) = 0;
            % [a_vec, b_vec] = f_get_fft_components(t_lin, x_trim, 2*pi*f_val, k_harmonics);
            % response_amplitudes(i) = norm([a_vec, b_vec]);
            % [t_trimf, f_trim] = f_get_last_n_periods(t, force_signal, 10);
            % t_linf = t_trimf - t_trimf(1);
            % f_trim([1 end]) = 0;
            % [a_vecf, b_vecf] = f_get_fft_components(t_linf, f_trim, 2*pi*f_val, k_harmonics);
            % forces(i) = norm([a_vecf, b_vecf]);
            % ---------------------------------------------------------------------
        end

        % === Save results ===
        freq_str = strrep(sprintf('%05.2f', f_val), '.', '_');   % e.g. '13_00'
        out_dir  = "saves/OL_blade_" + sweep.name;
        if ~exist(out_dir, 'dir'), mkdir(out_dir); end

        % For clarity include the (constant) frequency column as well
        % Columns: [Amplitude, Frequency, ResponseAmp, SignalAmp, ForceAmp]
        data_out = [amps(:), f_val*ones(numel(amps),1), ...
                    response_amplitudes(:), signal_amplitudes(:), forces(:)];

        save(out_dir + "/ruler_freq2_" + freq_str + ".mat", "data_out");

        drawnow;
    end
end

% === Reset system ===
rtc.par.fund_amp = 0;
rtc.par.fund_frequency = 0;
disp("✅ Full amplitude-sweep (at multiple frequencies) completed.");
