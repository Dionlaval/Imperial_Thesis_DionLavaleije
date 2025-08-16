%% auto frequency sweep

freq_range = 14:14;

for i = 1:length(freq_range)
    set_freq = freq_range(i);
    rtc.par.fund_frequency = set_freq;  % Set constant signal frequency
    
    Copy_of_amp_sweep_dspace;
end

disp("full sweep completed");