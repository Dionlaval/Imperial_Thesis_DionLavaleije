forcing_amp   = results(:, 2);   % y (what we predict)
forcing_freq  = results(:, 1);   % x1
response_amp  = results(:, 3);   % x2

X_train = results(:, [1,3]);
y_train = results(:, 2);
%% Fit GPR
gpr_model = fitrgp(X_train, y_train, ...
    'KernelFunction', 'ardsquaredexponential', ...
    'Standardize', true);

%% Quick surface from MATLAB predict (for visual only)
[Y_pred, Y_std] = predict(gpr_model, X_query);
AA  = reshape(Y_pred, size(RR));     % mean surface (forcing amp)
STD = reshape(Y_std,  size(RR));     % obs std surface

%% GET NEXT TEST POINT
params.vdim       = 2;          % derivative along RR (column 2)
params.tau        = 0.05;       % threshold for |∂μ/∂v|
params.R          = 64;         % MC draws per candidate
params.weightMode = 'sigmaD';   % 'none' | 'sigmaD' | 'gain2'
params.Mpick      = 500;        % top-M variance candidates

C     = gpr_build_caches(gpr_model, X_query, params.vdim);
Base  = gpr_baseline_fields(C);

% Baseline soft-band probability over the grid
p0_vec = soft_band_prob(Base.muD, Base.sigD, params.tau);   % m×1
p0m    = reshape(p0_vec, size(FF));

% ===== METRICS: baseline, before picking a candidate =====
M = compute_baseline_metrics(Base, p0_vec, dA);
%% Candidate set (top-M by latent variance)
Xcand = choose_candidates_by_variance(Base, X_query, params.Mpick);

%% Score candidates (expected band change). Track timing + diagnostics for best.
[scores, elapsed_scoring, bestIdx, det_best] = score_candidates( ...
    Xcand, C, Base, params.tau, params.R, params.weightMode);

bestX      = Xcand(bestIdx, :);
bestScore  = scores(bestIdx);
fprintf('Best candidate: [FF, RR] = [%.4g, %.4g],  E[Δ] = %.4g\n', bestX(1), bestX(2), bestScore);

% ===== METRICS: candidate-specific =====
% M = compute_candidate_metrics(M, det_best, Base, dA, C, bestX, X_data, training_idx, elapsed_scoring);
M = compute_candidate_metrics(M, det_best, Base, dA, C, bestX, X_train, (1:size(X_train,1)), elapsed_scoring);

% Print a compact summary
summarize_metrics(M);
metric_history{1, i} = M;

%% Visuals: μ, p-band, gain for the best candidate
MU  = reshape(Base.mu, size(FF));
gM  = reshape(det_best.g, size(FF));


% for k = 0:5:360
tiledlayout(3,4, "TileSpacing","tight")
nexttile([3,3]); hold on; grid on;
xlabel("Forcing Amplitude"); ylabel("Forcing Frequency"); zlabel("Response Amplitude");
% zlim([min(response_amp), 1.7]);
surf_opt = struct("CData", AA, "FaceAlpha",0.7, "EdgeColor","interp");
surf(AA, FF , RR, surf_opt); %colorbar
scatter3(forcing_amp, forcing_freq, response_amp, 10, "filled", "k")
% scatter3(forcing_amp(training_idx), forcing_freq(training_idx), response_amp(training_idx), 20, "filled", "r")
view(75, 20)

nexttile; imagesc(FF(1,:), RR(:,1), MU); axis xy; %colorbar;
hold on; scatter(forcing_freq, response_amp, 5, "black", "filled")

title('\mu(FF,RR)'); xlabel('FF'); ylabel('RR'); hold on; plot(bestX(1), bestX(2), 'rx', 'LineWidth', 2);
nexttile; imagesc(FF(1,:), RR(:,1), p0m); axis xy;% colorbar;
hold on; scatter(forcing_freq, response_amp, 5, "black", "filled")


title('p(|\partial\mu/\partial v|<\tau)'); xlabel('FF'); ylabel('RR'); hold on; plot(bestX(1), bestX(2), 'rx', 'LineWidth', 2);
nexttile; imagesc(FF(1,:), RR(:,1), gM); axis xy;% colorbar;
hold on; scatter(forcing_freq, response_amp, 5, "black", "filled")

title('gain g(x) at best x^*'); xlabel('FF'); ylabel('RR'); hold on; plot(bestX(1), bestX(2), 'rx', 'LineWidth', 2);
% plot_fields_mu_p_gain(MU, p0m, gM, FF, RR, bestX);

%% Map bestX back to nearest feasible test in your dataset (as you had)
% [best_index, nextX] = nearest_feasible(bestX, X_data);
% plot(nextX(1), nextX(2), 'gx', 'LineWidth', 2);
% pause(5/360*5)
% end


% training_idx = [training_idx, best_index]