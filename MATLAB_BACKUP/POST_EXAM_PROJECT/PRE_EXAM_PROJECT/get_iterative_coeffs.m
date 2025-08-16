function [trial] = get_iterative_coeffs(i, curr_t, curr_x, input, trial)
    % Initialize amplitude estimation
    A = trial.A;
    B = trial.B;

    w = input.w0;
    dt = trial.dt;

    % create windows of appropriate length for each harmonic
    try
        house = trial.house;
        if(trial.house.k ~= trial.k)
            error("k vals dont match");
        end
    catch                        
        house.k = trial.k;    % number of harmonics
        for i = (1:house.k)
            house.w(i) = w*i;
            house.T(i) = 2*pi/(w*1); %using a window length of period of 1st harmonic gives best result
            
            win_len = round(house.T(i)/dt);
            house.A{i} = zeros(1, win_len);
            house.B{i} = zeros(1, win_len);
        end
    end
    
    % get current reading
    time = curr_t;
    x_n = curr_x;

    for k = (1:house.k)
        add_A = (2 * dt / house.T(k)) * x_n * cos(house.w(k) * time);
        add_B = (2 * dt / house.T(k)) * x_n * sin(house.w(k) * time);
        
        % setting new coeffs 
        A(k,i+1) = A(k, i) + add_A - house.A{k}(1);
        B(k,i+1) = B(k, i) + add_B - house.B{k}(1);

        % adjust window
        house.A{k} = circshift(house.A{k}, -1);
        house.B{k} = circshift(house.B{k}, -1);

        house.A{k}(end) = add_A;
        house.B{k}(end) = add_B;

        % subtract estimation from reading to allow for better accuracy for
        % higher harmonic estimation
        x_recon = A(k,i+1).*cos(house.w(k)*time) + B(k,i+1).*sin(house.w(k)*time);
        x_n = x_n - x_recon;

        alpha = 0.005; % Smoothing factor (0 < alpha <= 1)
        a_s = filter(alpha, [1 alpha-1], trial.A(k, 1:i+1));
        b_s = filter(alpha, [1 alpha-1], trial.B(k, 1:i+1));
        trial.A_smooth(k, i+1) = a_s(end);
        trial.B_smooth(k, i+1) = b_s(end);
    end


    trial.house = house;
    trial.A(:, i+1) = A(:, i+1);
    trial.B(:, i+1) = B(:, i+1);
end