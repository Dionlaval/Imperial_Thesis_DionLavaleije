% === Load and plot all S-curve result files ===
clear; clc;

save_folder = "saves/SCURVE";
files = dir(fullfile(save_folder, 's_curve_freq_*.mat'));

all_data = [];

for k = 1:length(files)
    filepath = fullfile(save_folder, files(k).name);
    S = load(filepath);
    if isfield(S, 'results')
        all_data = [all_data; S.results];  % concatenate [freq, sig_amp, res_amp, invasiveness]
    end
end

if isempty(all_data)
    error("No valid results found in %s", save_folder);
end

% === 3D Scatter Plot ===
figure;
scatter3(all_data(:,2), all_data(:,1), all_data(:,3), 50, all_data(:,1), 'filled'); % color by frequency
xlabel('Signal Amplitude');
ylabel('Signal Frequency (Hz)');
zlabel('Response Amplitude');
title('S-Curve Result Map');
grid on;
view(45, 25); % adjust viewing angle
colorbar;
