function total_uncertainty = compute_total_uncertainty(sigma)
    % sigma: [N x 1] vector of standard deviations
    total_uncertainty = sum(sigma.^2);
end
