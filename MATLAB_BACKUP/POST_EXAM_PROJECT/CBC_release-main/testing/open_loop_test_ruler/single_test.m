k_harmonics = 7;
w0 = 22; %hz
% alpha = exp(-2*pi*30*w0*k_harmonics/1000);
alpha = 0;

% === Setup signal interface ===
rtc = signal_interface('MAportConfig.xml');
rtc.par.f_switch = 1;

% === Define sine forcing parameters ===
rtc.par.filter_alpha = alpha;
rtc.par.fund_frequency = w0;  % Hz
rtc.par.Amp = 2;        % Amplitude (adjust as needed)

% === Sampling settings ===
fs = 10000;         % Hz
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
disp_transience = data.disp_trans;

% === Plot (optional) ===
figure;
subplot(4,1,1); plot(t, disp_signal); ylabel('Disp'); grid on;
subplot(4,1,2); plot(t, force_signal); ylabel('Force'); grid on;
subplot(4,1,3); plot(t, acc_signal); ylabel('Accel'); xlabel('Time [s]'); grid on;
subplot(4,1,4); plot(t, disp_transience); ylabel('Norm Transience'); xlabel('Time [s]'); grid on;


% === Done ===
disp('✅ Finished fixed-frequency actuation.');

% rtc.par.fund_frequency = 0;  % Hz
rtc.par.Amp = 0;        % Amplitude (adjust as needed)
rtc.stop_stream;