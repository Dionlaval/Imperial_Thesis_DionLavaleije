function [scores, elapsed_scoring, bestIdx, det_best] = score_candidates( ...
    Xcand, C, Base, tau, R, weightMode)
% Scores candidates using expected soft-band change; returns best details too.
t0 = tic;
scores = zeros(size(Xcand,1),1);
det_best = struct();
bestIdx = 1; bestScore = -inf;
for i = 1:size(Xcand,1)
    xstar    = Xcand(i,:);
    [s, det] = score_candidate_soft(xstar, C, Base, tau, R, weightMode);
    scores(i) = s;
    if s > bestScore
        bestScore = s; bestIdx = i; det_best = det;
    end
end
elapsed_scoring = toc(t0);
end