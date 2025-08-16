k_harmonics = 7;

% === Setup signal interface ===
rtc = signal_interface('MAportConfig.xml');
rtc.par.control_switch = 1; % 1: no control, 2:control

% === Define sine forcing parameters ===
rtc.par.fund_frequency = 18;  % Hz
rtc.par.fund_amp = 0;        % Amplitude (adjust as needed)

% === Sampling settings ===
fs = 1000;         % Hz
dt = 1/fs;
T = 10;            % Duration in seconds

% === Wait for steady-state and stream ===
pause(T);
data = rtc.run_stream('stream_id', 1);

% === Extract and build time vector ===
N = length(data.disp_in2);
t = (0:N-1) * dt;

% === Optional: assign for clarity ===
disp_signal = data.disp_in2;
force_signal = data.force_in1;
acc_signal   = data.acc_in3;

% === Plot (optional) ===
figure;
subplot(3,1,1); plot(t, disp_signal); ylabel('Disp'); grid on;
subplot(3,1,2); plot(t, force_signal); ylabel('Force'); grid on;
subplot(3,1,3); plot(t, acc_signal); ylabel('Accel'); xlabel('Time [s]'); grid on;


% === Done ===
disp('✅ Finished fixed-frequency actuation.');

% rtc.par.fund_frequency = 0;  % Hz
rtc.par.fund_amp = 0;        % Amplitude (adjust as needed)
rtc.stop_stream;

r_disp = var(disp_signal)
r_acc = var(acc_signal)