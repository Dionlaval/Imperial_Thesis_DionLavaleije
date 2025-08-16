function [EDelta, details] = score_candidate_soft(xstar, C, Base, tau, R, weightMode)
% xstar: 1×2 in ORIGINAL units [FF, RR]
% weightMode: 'none' | 'sigmaD' | 'gain2'

% Standardize candidate
xS = (xstar - C.loc) ./ C.scale;

% k(X, x★) and solves
kXs = C.k(C.Xs, xS);         % n×1
w   = C.L \ kXs;             % n×1

% Latent variance at x★ (then obs var)
vstar = C.sigmaF^2 - (w.'*w);
vstar = max(vstar, 0);
s2    = vstar + C.sigmaN^2;  % scalar

% Cross-covariance c(x) over the grid and derivative ∂_v c(x)
k_qx = C.k(C.XqS, xS);                               % m×1 = k(Xq, x★)
c    = k_qx - (C.Wq.' * w);                          % m×1

% ∂/∂v_x k(x, x★) (derivative w.r.t. grid v-dim)
J_qx = C.dk(C.XqS, xS);                               % m×1
dc   = J_qx - (C.Vq.' * w);                           % m×1

% Gains (grid-sized vectors)
g   = c  ./ s2;                                       % m×1
gD  = dc ./ s2;                                       % m×1

% Weights over grid (optional)
switch lower(weightMode)
    case 'sigmad'
        W = Base.sigD;                 % emphasize high derivative-uncertainty
    case 'gain2'
        W = g.^2;                      % emphasize where candidate has leverage
    otherwise
        W = ones(size(Base.mu));       % uniform
end

% Baseline probability
p0 = soft_band_prob(Base.muD, Base.sigD, tau);        % m×1

% Monte-Carlo draws: δ ~ N(0, s2), R samples
delta = sqrt(s2) .* randn(1, R);                      % 1×R (μ★ cancels in shift)

% Updated derivative mean for all R in one shot: m×R
muD_new = Base.muD + gD * delta;                      % bsxfun

% Probabilities after draws
p_new = soft_band_prob(muD_new, Base.sigD, tau);      % m×R

% Grid cell area (assume rectangular grid in original units)
% If you have FF, RR matrices, pass ΔA externally; here we infer from XqS in original units
% Better: compute ΔA outside once and feed in. For now: ΔA = 1 (scale-free).
dA = 1;

% L1 change, weighted, averaged over draws
absdiff = abs(p_new - p0);                            % m×R
Delta_r = dA * (W.' * absdiff) / numel(W);            % 1×R (normalize by #pts to be scale-free)
EDelta  = mean(Delta_r);

if nargout > 1
    details.g   = g;
    details.gD  = gD;
    details.c   = c;
    details.dc  = dc;
    details.s2  = s2;
    details.vstar = vstar;
    details.Delta_r = Delta_r;
end
end
