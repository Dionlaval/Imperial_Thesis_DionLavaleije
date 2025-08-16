function [t_lin, x_lin] = f_get_last_n_periods(t, x, n)
    % Extract the last 10 periods of the response
    num_periods = n;
    x_inverted = flip(x);
    zero_crossings = find(x_inverted(1:end-1) <= 0 & x_inverted(2:end) > 0);
    
    if length(zero_crossings) < num_periods + 1
        figure();
        plot(t, x);
        error("Not enough zero crossings detected to extract " + n + " full periods.");
    end
    
    t_last_index = zero_crossings(1);
    t_first_index = zero_crossings(num_periods + 1);
    t_last = length(t) - t_last_index + 1;
    t_first = length(t) - t_first_index + 1;
    
    t_trim = t(t_first:t_last);
    x_trim = x(t_first:t_last);

    %linearizes data points
    t_lin = linspace(t_trim(1), t_trim(end), length(t_trim));
    x_lin = interp1(t_trim, x_trim, t_lin);
end