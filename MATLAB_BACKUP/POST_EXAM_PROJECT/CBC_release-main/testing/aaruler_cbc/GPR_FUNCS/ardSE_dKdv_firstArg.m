function J = ardSE_dKdv_firstArg(A,B,ell,sigmaF,vdim)
% derivative wrt v-dimension of the FIRST argument (rows of A)
% J_{ij} = ∂/∂A_v k(A_i, B_j) = k(A_i,B_j) * (B_j(v) - A_i(v)) / ell_v^2
K = ardSE_kernel(A,B,ell,sigmaF);
J = K .* ((B(:,vdim)' - A(:,vdim)) / (ell(vdim)^2));
end
