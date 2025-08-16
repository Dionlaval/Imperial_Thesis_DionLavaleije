function M = compute_baseline_metrics(Base, p0_vec, dA)
% Computes baseline metrics before candidate selection.
% Base: struct with fields varf (m×1), muD (m×1), sigD (m×1)
M = struct();
% Global field uncertainty
M.IV = sum(Base.varf) * dA;                        % Integrated latent variance
% Bifurcation band health
p_clip   = min(max(p0_vec, eps), 1 - eps);         % avoid log(0)
M.A_p    = sum(p_clip) * dA;                       % probabilistic band area
M.H_band = sum( -p_clip.*log(p_clip) - (1-p_clip).*log(1-p_clip) ) * dA; % entropy
M.U_D    = sum(Base.sigD) * dA;                    % derivative-uncertainty mass
end