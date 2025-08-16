function Xcand = choose_candidates_by_variance(Base, X_query, Mpick)
% Choose top-M candidates by latent variance (fast and effective)
[~, idxv] = maxk(Base.varf, Mpick);
Xcand = X_query(idxv, :);
end