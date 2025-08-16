function t = plot_harmony(experiment)
    A_coeffs = experiment.A_responses;%(:, 1:harmony_count);
    B_coeffs = experiment.B_responses;%(:, 1:harmony_count);
    % iter_num = (0:harmony_count-1);
    iter_num = (0:size(A_coeffs, 2)-1);
    figure;
    t = tiledlayout(2, 1, "TileSpacing","compact");
    nexttile;
    hold on;
    grid on;
    higher_harmonics = (2:size(A_coeffs, 1));
    for row = higher_harmonics
        plot(iter_num, A_coeffs(row, :), "-o")
    end
    
    nexttile;
    hold on;
    grid on;
    for row = higher_harmonics
        plot(iter_num, B_coeffs(row, :), "-o")
    end
    xlabel(t, "Iteration Number")
    ylabel(t, "Coefficient Value")
    legend(string(higher_harmonics), Location="best")
end