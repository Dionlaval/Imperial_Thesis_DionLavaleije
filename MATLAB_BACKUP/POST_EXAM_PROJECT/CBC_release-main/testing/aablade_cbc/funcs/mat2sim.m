function [vector1d] = mat2sim(vector2d)
    vector1d = [0; vector2d(:, 1); vector2d(:, 2)];
end