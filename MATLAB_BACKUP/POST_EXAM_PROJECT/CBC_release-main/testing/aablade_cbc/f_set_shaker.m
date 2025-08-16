function [complete] = f_set_shaker(rtc,f0,amp)
    rtc.par.fund_frequency = f0;  % Hz
    rtc.par.Amp = amp;
    complete = 1;
end