function p = soft_band_prob(muD, sigD, tau)
% p(x) = P(|D| < τ), D ~ N(muD, sigD^2)
z1 = (tau - muD) ./ (sigD + eps);
z2 = (-tau - muD) ./ (sigD + eps);
p = normcdf(z1) - normcdf(z2);
end
