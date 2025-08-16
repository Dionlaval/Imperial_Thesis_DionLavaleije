function [vector2d] = sim2mat(vector1d)
    n = length(vector1d)-1;
    vector2d = [vector1d(2:n/2+1), vector1d(n/2+2:end)];
end