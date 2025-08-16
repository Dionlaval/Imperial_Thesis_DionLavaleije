function [A_vec,B_vec] = f_get_fft_components(t_lin, x_lin, w0, harmonics)
    %calc A and B coeff vectors
    N = length(t_lin);
    fs = N/(t_lin(end) - t_lin(1));
    frequencies = (0:N-1) * (fs / N); % Frequency vector
    w0_hz = w0/(2*pi);

    Xfft = fft(x_lin);
    % magnitude_spectrum = 2*abs(Xfft / N); % Normalize by N
    harmonic_frequencies = (1:harmonics) * w0_hz;
    k_harmonics = arrayfun(@(f) find(abs(frequencies - f) == min(abs(frequencies - f))), harmonic_frequencies);
    
    A0 = 2 * real(Xfft(1)) / N; % DC offset (A0 / 2)
    B0 = 0; %2 * imag(Xfft(1)) / N; % DC offset (A0 / 2)
    A = 2 * real(Xfft(k_harmonics)) / N; % Cosine coefficients (real part)
    B = -2 * imag(Xfft(k_harmonics)) / N; % Sine coefficients (imaginary part)

    A_vec = [A0; A'];
    B_vec = [B0; B'];

    % A_vec = A';
    % B_vec = B';
end