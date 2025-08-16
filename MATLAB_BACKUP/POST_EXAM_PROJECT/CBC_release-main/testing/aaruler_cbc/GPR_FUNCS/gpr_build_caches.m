function C = gpr_build_caches(gpr_model, X_query, vdim)
% Build all reusable caches from a fitrgp model for fast what-if updates.

% --- Pull internals ---
Xraw   = gpr_model.X;      % n×2 original inputs
y      = gpr_model.Y;      % n×1 outputs
beta   = gpr_model.Beta;   % scalar mean
sigmaN = gpr_model.Sigma;  % noise std

theta  = gpr_model.KernelInformation.KernelParameters;
names  = gpr_model.KernelInformation.KernelParameterNames;

% Parse ARD params: [ℓ1 ... ℓD, σ_f] (this is the usual order)
D = size(Xraw,2);
ell    = theta(1:D)';      % 1×D
sigmaF = theta(end);       % scalar

% Standardization (since 'Standardize' was true)
loc   = gpr_model.PredictorLocation';  % 1×D
scale = gpr_model.PredictorScale';     % 1×D
Xs    = (Xraw - loc) ./ scale;        % n×D (std)
XqS   = (X_query - loc) ./ scale;     % m×D (std)
[n, D2] = size(Xs);                   %#ok<ASGLU>
m = size(XqS,1);

% --- Kernel helpers (ARD SE) ---
ardSE = @(A,B) ardSE_kernel(A,B,ell,sigmaF);
dK_dv = @(A,B) ardSE_dKdv_firstArg(A,B,ell,sigmaF,vdim); % ∂/∂x_v k(x,B)

% --- Training matrix & Cholesky ---
K   = ardSE(Xs,Xs);
Kn  = K + (sigmaN^2)*eye(n);
% jitter for safety
try
    L = chol(Kn,'lower');
catch
    L = chol(Kn + 1e-9*eye(n),'lower');
end
alpha = L'\(L\(y - beta));    % α = K_n^{-1}(y-β)

% --- Grid cross-covs and their L-solves (cache once) ---
KqX = ardSE(XqS, Xs);         % m×n  = k(Xq, X)
Wq  = L \ KqX.';              % n×m  = L^{-1} k(X, Xq)

% Derivative cross-covs wrt grid v-dimension
JqX = dK_dv(XqS, Xs);         % m×n  = ∂_v k(Xq, X)
Vq  = L \ JqX.';              % n×m  = L^{-1} ∂_v k(X, Xq)^T

% --- Pack caches ---
C.gpr   = gpr_model;
C.beta  = beta;
C.sigmaN= sigmaN;
C.ell   = ell;
C.sigmaF= sigmaF;
C.loc   = loc;
C.scale = scale;
C.L     = L;
C.alpha = alpha;
C.Xs    = Xs;
C.XqS   = XqS;
C.KqX   = KqX;
C.Wq    = Wq;
C.JqX   = JqX;
C.Vq    = Vq;
C.vdim  = vdim;

% --- Function handles (reuse elsewhere) ---
C.k   = ardSE;
C.dk  = dK_dv;

end

