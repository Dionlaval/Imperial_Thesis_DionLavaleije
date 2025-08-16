function K = ardSE_kernel(A,B,ell,sigmaF)
% A: m×D, B: n×D, ell: 1×D
m = size(A,1); n = size(B,1);
Z = zeros(m,n);
for d = 1:size(A,2)
    diff = (A(:,d) - B(:,d)')./ell(d);
    Z = Z + diff.^2;
end
K = (sigmaF^2) * exp(-0.5 * Z);
end