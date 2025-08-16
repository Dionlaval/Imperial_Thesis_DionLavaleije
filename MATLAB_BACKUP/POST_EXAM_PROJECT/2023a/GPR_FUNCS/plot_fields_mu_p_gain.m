function plot_fields_mu_p_gain(MU, p0m, gM, FF, RR, bestX)
% Quick three-panel diagnostic: μ, p-band, gain at the best candidate.
figure;
subplot(3,1,1); imagesc(FF(1,:), RR(:,1), MU); axis xy; colorbar;
title('\mu(FF,RR)'); xlabel('FF'); ylabel('RR'); hold on; plot(bestX(1), bestX(2), 'rx', 'LineWidth', 2);

subplot(3,1,2); imagesc(FF(1,:), RR(:,1), p0m); axis xy; colorbar;
title('p(|\partial\mu/\partial v|<\tau)'); xlabel('FF'); ylabel('RR'); hold on; plot(bestX(1), bestX(2), 'rx', 'LineWidth', 2);

subplot(3,1,3); imagesc(FF(1,:), RR(:,1), gM); axis xy; colorbar;
title('gain g(x) at best x^*'); xlabel('FF'); ylabel('RR'); hold on; plot(bestX(1), bestX(2), 'rx', 'LineWidth', 2);
end