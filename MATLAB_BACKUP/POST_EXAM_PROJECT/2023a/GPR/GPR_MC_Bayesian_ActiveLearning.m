%% GPR Active Learning with Monte Carlo Expected Information Gain
% Step 1. Load and structure data
load("data_save.mat");  % 'data' = [forcing_amp, forcing_freq, response_amp]
forcing_amp   = data(:, 1);
forcing_freq  = data(:, 2);
response_amp  = data(:, 3);

% Step 2. Build prediction grid
resp_range = linspace(min(response_amp), max(response_amp), 50);
freq_range = unique(forcing_freq)';
[RR, FF] = meshgrid(resp_range, freq_range);
X_grid = [RR(:), FF(:)];

% Step 3. Initialize random training set
n_init = 5;
total_pts = size(data, 1);
idx_train = randperm(total_pts, n_init);
X_train = data(idx_train, [3, 2]);
Y_train = data(idx_train, 1);

% Step 4. Begin iterative sampling loop
n_iter = 20;
candidate_points = X_grid;  % Initially all grid points are candidates

for step = 1:n_iter
    fprintf("Step %d: training set size = %d\n", step, size(X_train, 1));

    % Step 4a. Train current GPR
    gpr_model = fitrgp(X_train, Y_train, ...
        'KernelFunction', 'squaredexponential', ...
        'Standardize', true, ...
        'FitMethod', 'none', ...
        'PredictMethod', 'exact');

    % Step 4b. Compute current total information
    [~, std_full] = predict(gpr_model, X_grid);
    total_info_before = sum(std_full.^2);

    % Step 4c. Evaluate expected reduction in uncertainty at each candidate
    best_gain = -inf;
    best_idx = NaN;

    for j = 1:size(candidate_points, 1)
        x_candidate = candidate_points(j, :);
        [~, std_here] = predict(gpr_model, x_candidate);
        sigma_c = std_here;

        N_samples = 10;
        y_samples = normrnd(predict(gpr_model, x_candidate), sigma_c, [N_samples, 1]);

        total_info_samples = zeros(N_samples, 1);
        for k = 1:N_samples
            % Form augmented training set with virtual point
            X_aug = [X_train; x_candidate];
            Y_aug = [Y_train; y_samples(k)];

            % Train new GPR model
            gpr_virtual = fitrgp(X_aug, Y_aug, ...
                'KernelFunction', 'squaredexponential', ...
                'Standardize', true, ...
                'FitMethod', 'none', ...
                'PredictMethod', 'exact');

            % Compute total information
            [~, std_aug] = predict(gpr_virtual, X_grid);
            total_info_samples(k) = sum(std_aug.^2);
        end

        expected_reduction = total_info_before - mean(total_info_samples);

        if expected_reduction > best_gain
            best_gain = expected_reduction;
            best_idx = j;
        end
    end

    % Step 4d. Update training set
    new_x = candidate_points(best_idx, :);
    [~, real_idx] = min(vecnorm(data(:, [3, 2]) - new_x, 2, 2));
    if ~ismember(real_idx, idx_train)
        idx_train(end+1) = real_idx;
        X_train = [X_train; data(real_idx, [3, 2])];
        Y_train = [Y_train; data(real_idx, 1)];
    end

    % Step 4e. Remove chosen point from candidates
    candidate_points(best_idx, :) = [];

    % Step 4f. Optional: update plots
    figure(1); clf;
    [YP, STD] = predict(gpr_model, X_grid);
    surf(reshape(X_grid(:,2), size(RR)), reshape(YP, size(RR)), reshape(X_grid(:,1), size(RR)), 'EdgeColor', 'none');
    hold on;
    scatter3(X_train(:,2), Y_train, X_train(:,1), 30, 'r', 'filled');
    xlabel("Forcing Frequency"); ylabel("Forcing Amplitude"); zlabel("Response Amplitude");
    title(sprintf("Step %d", step));
    drawnow;
end
