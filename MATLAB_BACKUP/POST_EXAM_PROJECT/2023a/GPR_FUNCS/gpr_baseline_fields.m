function Base = gpr_baseline_fields(C)
% Compute baseline μ, latent var, derivative μ_D, derivative var, and soft p(x)

L      = C.L;  Wq = C.Wq;  Vq = C.Vq;
KqX    = C.KqX;  JqX = C.JqX;
alpha  = C.alpha;  beta = C.beta;
sigmaF = C.sigmaF; sigmaN = C.sigmaN; ell = C.ell; vdim = C.vdim;

m = size(KqX,1);

% Mean on grid
mu = KqX * alpha + beta;                % m×1

% Latent variance: k_** = σ_f^2 (RBF at x=x)
varf = sigmaF^2 - sum(Wq.^2,1)';        % m×1
varf = max(varf, 0);                    % clamp numeric noise
stdy = sqrt(varf + sigmaN^2);           % obs std (if you need it)

% Derivative mean & variance
muD   = JqX * alpha;                    % m×1
prior = sigmaF^2 / (ell(vdim)^2);       % ∂_{vv'}k|_{x'=x}
sigD2 = prior - sum(Vq.^2, 1)';         % m×1
sigD2 = max(sigD2, 0);
sigD  = sqrt(sigD2);

Base.mu    = mu;
Base.varf  = varf;
Base.sigy  = stdy;
Base.muD   = muD;
Base.sigD  = sigD;

end
