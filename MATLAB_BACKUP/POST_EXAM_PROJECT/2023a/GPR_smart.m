%% Load Data
load("data_save.mat");  % 'data' = [forcing_amp, forcing_freq, response_amp]

forcing_amp   = data(:, 1);  % predicted variable
forcing_freq  = data(:, 2);  % input
response_amp  = data(:, 3);  % input

%% Initial Training Subset
n_init = 5;
idx_train = randperm(size(data, 1), n_init);
X_train = data(idx_train, [3, 2]);  % [response_amp, forcing_freq]
Y_train = data(idx_train, 1);      % forcing_amp

%% Prediction Grid
resp_range = linspace(min(response_amp), max(response_amp), 50);
freq_range = linspace(min(forcing_freq), max(forcing_freq), 50);
[RR, FF] = meshgrid(resp_range, freq_range);
X_query = [RR(:), FF(:)];

%% Setup tiled layout for persistent visualization
fig = figure;
t = tiledlayout(fig, 1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

% Pre-allocate axes for reuse
ax1 = nexttile(t, 1);  % Left tile: GPR prediction
ax2 = nexttile(t, 2);  % Right tile: Confidence surface

%% Iterative GPR update
n_iter = 20;

for step = 1:n_iter
    % Train GPR
    gpr_model = fitrgp(X_train, Y_train, ...
        'KernelFunction', 'squaredexponential', ...
        'Standardize', true);

    % Predict and reshape
    [Y_pred, Y_std] = predict(gpr_model, X_query);
    AA = reshape(Y_pred, size(RR));  % GPR prediction
    STD = reshape(Y_std, size(RR));  % Uncertainty

    % --- Plot GPR prediction (left) ---
    cla(ax1);
    surf(ax1, FF, AA, RR, 'EdgeColor', 'none', 'FaceAlpha', 0.9);
    hold(ax1, 'on');
    scatter3(ax1, forcing_freq, forcing_amp, response_amp, 10, 'k', 'filled');
    scatter3(ax1, X_train(:, 2), Y_train, X_train(:, 1), 40, 'r', 'filled');
    xlabel(ax1, 'Forcing Frequency'); ylabel(ax1, 'Forcing Amplitude'); zlabel(ax1, 'Response Amplitude');
    title(ax1, ['GPR Prediction (Step ', num2str(step), ')']);
    view(ax1, 135, 30); grid(ax1, 'on');

    % --- Plot uncertainty (right) ---
    cla(ax2);
    surf(ax2, RR, FF, STD, 'EdgeColor', 'none', 'FaceAlpha', 0.9);
    xlabel(ax2, 'Response Amplitude'); ylabel(ax2, 'Forcing Frequency'); zlabel(ax2, 'Prediction Std Dev');
    title(ax2, ['Prediction Uncertainty (Step ', num2str(step), ')']);
    view(ax2, 90, 90); grid(ax2, 'on');

    drawnow;

    % Select next point with max uncertainty
    [~, max_idx] = max(Y_std);
    new_x = X_query(max_idx, :);

    % Find closest real data point
    [~, closest_idx] = min(vecnorm(data(:, [3, 2]) - new_x, 2, 2));

    % Add to training set if not already included
    if ~ismember(closest_idx, idx_train)
        idx_train(end+1) = closest_idx;
        X_train = [X_train; data(closest_idx, [3, 2])];
        Y_train = [Y_train; data(closest_idx, 1)];
    end
end
