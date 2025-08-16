clear; clc;

fs = 1000;       % Sampling frequency (Hz)
T_total = 10;    % Total signal duration (s)
t = 0:1/fs:T_total;

frequencies = 9:0.2:18;   % 模擬掃頻範圍
bifurcation_freq = [];
bifurcation_points = {};

figure;
ax = axes();
xlabel('Frequency (Hz)');
ylabel('Displacement Sampled Points');
title('Simulated Bifurcation Diagram');
hold on;
h = plot(NaN, NaN, 'k.');  % 初始空圖

for i = 1:length(frequencies)
    f = frequencies(i);
    T = 1/f;

    % === 模擬系統響應根據頻率改變週期性 ===
    if f < 10
        % P1：正弦
        disp_signal = 1.0 * sin(2*pi*f*t);
    elseif f < 13
        % P2：兩種頻率混合造成週期翻倍
        disp_signal = 1.0 * sin(2*pi*f*t) + 0.5*sin(2*pi*f/2*t);
    else
        % quasi-chaotic：加入隨機成分
        disp_signal = 1.0 * sin(2*pi*f*t) + 0.3*randn(size(t));
    end

    % === 儲存時間序列資料 ===
    time_series_data{i}.t = t;
    time_series_data{i}.disp = disp_signal;
    time_series_data{i}.force = sin(2*pi*f*t);  % 模擬施力信號（純正弦）

    % === 做 bifurcation 採樣（兩組採樣點） ===
    t_sample1 = t(1):T:t(end);
    t_sample2 = t(1) + 0.5*T : T : t(end);  % 平移半週期
    y_sample1 = interp1(t, disp_signal, t_sample1, 'linear');
    y_sample2 = interp1(t, disp_signal, t_sample2, 'linear');

    % 合併兩組並去除重複點
    y_combined = [y_sample1, y_sample2];
    y_sample_unique = unique(round(y_combined, 5));  % 根據精度去除重複

    % === 存入分岔圖資料 ===
    bifurcation_freq = [bifurcation_freq; f * ones(length(y_sample_unique), 1)];
    bifurcation_points = [bifurcation_points; num2cell(y_sample_unique(:))];

    % === 更新繪圖 ===
    set(h, 'XData', bifurcation_freq, 'YData', cell2mat(bifurcation_points));
    drawnow;
end

while true
    prompt = 'Enter a frequency to view its time series (Hz), or "q" to quit: ';
    str = input(prompt, 's');
    if strcmpi(str, 'q')
        break;
    end
    f_query = str2double(str);
    [~, idx] = min(abs(frequencies - f_query));
    if isempty(idx) || idx < 1 || idx > length(frequencies)
        fprintf('❌ No data found for that frequency.\n');
        continue;
    end

    % 抽出時間序列資料
    ts = time_series_data{idx};
    t = ts.t;
    disp_signal = ts.disp;
    force_signal = ts.force;
    freq = frequencies(idx);
    T = 1 / freq;   % 施力週期

    % ===== 採樣點（兩組：原始與偏移） =====
    t_sample1 = t(1):T:t(end);
    t_sample2 = t(1)+0.5*T:T:t(end);
    y_sample1 = interp1(t, disp_signal, t_sample1, 'linear');
    y_sample2 = interp1(t, disp_signal, t_sample2, 'linear');
    t_combined = [t_sample1, t_sample2];
    y_combined = [y_sample1, y_sample2];
    % 去除 NaN 和重複
    valid_idx = ~isnan(y_combined);
    t_combined = t_combined(valid_idx);
    y_combined = y_combined(valid_idx);

    % ===== 繪圖 =====
    figure;

    subplot(2,1,1);
    plot(t, disp_signal, 'b'); hold on;
    plot(t_combined, y_combined, 'ro', 'MarkerFaceColor', 'r');
    xlabel('Time (s)');
    ylabel('Displacement (mm)');
    title(sprintf('Displacement @ %.2f Hz with Sampled Points', freq));
    legend('Displacement', 'Sampled Points');

    subplot(2,1,2);
    plot(t, force_signal, 'k');
    xlabel('Time (s)');
    ylabel('Force (N)');
    title(sprintf('Force @ %.2f Hz', freq));
end
