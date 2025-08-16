%% Initialization: Start Test
rtc = signal_interface('MAportConfig.xml');

% Safety init
rtc.par.Frequency = 0;
rtc.par.Amp = 0;

% Set test parameters
test_freq = 5;      % Hz
test_amp  = 1;      % unit as needed (N)
rtc.par.Frequency = test_freq;
rtc.par.Amp = test_amp;

% Wait for transient to decay
disp('Waiting for system to stabilize...');
pause(20);  % seconds

% Run test and acquire data
data = rtc.run_stream('stream_id', 1);  % Adjust stream_id if needed

% Construct time axis (assuming known sampling rate)
fs = 1000;                 % Sampling frequency in Hz (adjust if needed)
dt = 1 / fs;
N = length(data.force_in1);
t = (0:N-1) * dt;

% Extract force signal
force_signal = data.force_in1;

% Find peaks in force signal
[pks, locs] = findpeaks(force_signal, 'MinPeakProminence', 0.05);

% Report results
if isempty(pks)
    disp('No peaks found in force signal.');
    force_amplitude = NaN;
else
    force_amplitude = max(pks);  % or use mean(pks) if preferred
    fprintf('Force peak amplitude at %.2f Hz = %.4f N\n', test_freq, force_amplitude);
end

% Optional: Plot for verification
figure;
plot(t, force_signal, 'b'); hold on;
plot(t(locs), pks, 'ro', 'MarkerFaceColor', 'r');
xlabel('Time (s)');
ylabel('Force (N)');
title(sprintf('Force signal at %.2f Hz', test_freq));
legend('Force signal', 'Detected Peaks');
grid on;
rtc.par.Frequency = 0;
rtc.par.Amp = 0;
