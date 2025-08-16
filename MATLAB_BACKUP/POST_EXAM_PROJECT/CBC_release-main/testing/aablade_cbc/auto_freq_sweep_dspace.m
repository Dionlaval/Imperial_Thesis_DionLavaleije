%% auto frequency sweep

freq_range = 13.6:0.15:14.6;

for i = 1:length(freq_range)
    set_freq = freq_range(i);
    if set_freq == 15
        continue
    elseif set_freq == 15.5
        continue
    end
    rtc.par.fund_frequency = set_freq;  % Set constant signal frequency
    
    Copy_of_amp_sweep_dspace;
end

disp("full sweep completed");