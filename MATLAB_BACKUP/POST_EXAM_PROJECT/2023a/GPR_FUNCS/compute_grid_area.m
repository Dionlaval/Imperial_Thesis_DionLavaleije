function [dFF, dRR, dA] = compute_grid_area(freq_range, resp_range)
% Returns grid spacings and cell area (assumes regular grid).
dFF = median(diff(freq_range));
dRR = median(diff(resp_range));
dA  = dFF * dRR;
end