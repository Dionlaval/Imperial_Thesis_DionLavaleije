%% auto frequency sweep

% freq_range = linspace(13, 16, 21);
% freq_range = 12.1:0.15:12.85;
freq_range = (15.7:-0.45:10.75)-0.15;
% freq_range = (15.7:-0.45:12.55)-0.3;
% freq_range = freq_range(1:end-1);

for l = 1:length(freq_range)
    l
    set_freq = freq_range(l);
    rtc.par.fund_frequency = set_freq;  % Set constant signal frequency
    
    % target_range = linspace(20, 1, 51);
    % target_range = target_range(1:end);
    % Copy_2_of_amp_sweep_dspace;

    % target_range = linspace(1, 20, 51);
    % target_range = target_range(1:12);
    % Copy_of_amp_sweep_dspace

    target_range = linspace(45, 20, 11);
    Copy_3_of_amp_sweep_dspace;

    % target_range = linspace(1, 20, 51);
    % target_range = linspace(1, 10, 51);
    % target_range = target_range(1:30);
    % target_range = target_range(1:20);
    % Copy_4_of_amp_sweep_dspace;
    s_curve_plotter;
end

disp("full sweep completed");