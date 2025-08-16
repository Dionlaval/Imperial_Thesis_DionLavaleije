clear; clc;

%% Initialization: Start Test
rtc = signal_interface('MAportConfig.xml');

% Safety init
rtc.par.Frequency = 10;
rtc.par.Amp = 1;
pause(30);

% 資料收集
data = rtc.run_stream('stream_id', 1);

% 結束激勵
rtc.par.Frequency = 0;
rtc.par.Amp = 0;

% === 根據 disp_in2 長度與取樣頻率建立時間軸 ===
Fs = 1000;                   % 取樣率為 1000 Hz
dt = 1 / Fs;                 % 取樣間隔 = 1/1000 秒
N = length(data.disp_in2);  % 總點數
t = (0:N-1) * dt;            % 時間軸

% === 繪圖 ===
plot(t, data.disp_in2);
xlabel('Time (s)');
ylabel('Displacement (unit)');
title('Displacement vs Time');
grid on;

