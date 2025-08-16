function [best_index, nextX] = nearest_feasible(bestX, X_data)
% Map the continuous bestX back to the nearest existing data point in X_data.
nbias   = min(X_data, [], 1);
nscale  = max(X_data, [], 1);
nX_data = (X_data - nbias) ./ nscale;
nbestX  = (bestX  - nbias) ./ nscale;
[~, best_index] = min( sum(abs(nX_data - nbestX), 2) );
nextX = X_data(best_index, :);
end