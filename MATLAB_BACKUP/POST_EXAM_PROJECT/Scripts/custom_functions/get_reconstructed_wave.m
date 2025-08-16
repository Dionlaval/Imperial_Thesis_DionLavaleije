function [t_lin, x_reconstructed] = get_reconstructed_wave(A_vec, B_vec, t_lin, w0)
    x_reconstructed = 0;
    % Add harmonics
    for j = 1:length(A_vec)
        x_reconstructed = x_reconstructed + A_vec(j) * cos(j * w0 * t_lin) + B_vec(j) * sin(j * w0 * t_lin);
    end
end