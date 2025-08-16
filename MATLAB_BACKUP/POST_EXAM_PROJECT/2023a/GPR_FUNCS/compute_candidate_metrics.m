function M = compute_candidate_metrics(M, det, Base, dA, C, bestX, X_data, training_idx, elapsed_scoring)
% Adds candidate-specific metrics to M, including EIVR, gains, s2, diversity, timing.
% Primary utility
M.EDelta_best = mean(det.Delta_r);             % same as best score (kept for clarity)
M.EDelta_std  = std(det.Delta_r, 0, 2);        % MC variability of E[Δ]

% EIVR (latent variance reduction, outcome-independent)
% Δv_f(x) = c(x)^2 / s2  => integrate over grid
M.EIVR       = sum( (det.c.^2) / det.s2 ) * dA;

% Gain norms
M.g_norm1    = sum(abs(det.g))  * dA;
M.gD_norm1   = sum(abs(det.gD)) * dA;
M.gD_max     = max(abs(det.gD));

% Candidate predictive variance (obs)
M.s2_candidate = det.s2;

% Diversity from history (standardized distance)
Xstd_train = (X_data(training_idx,:) - C.loc) ./ C.scale;
xstd_star  = (bestX - C.loc) ./ C.scale;
M.min_dist_std = min( sqrt(sum( (Xstd_train - xstd_star).^2, 2 )) );

% Practical timing and sizes
M.time_scoring = elapsed_scoring;
M.n_train      = numel(training_idx);
M.n_cand       = numel(det.g);            % same as grid size m
M.grid_size    = numel(det.g);
end