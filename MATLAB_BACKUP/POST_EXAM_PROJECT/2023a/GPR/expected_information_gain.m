function avg_info_gain = expected_information_gain(x_star, mu_star, sigma_star, ...
    X_train, Y_train, X_query, total_before, M, data)

    info_after = zeros(M, 1);
    for i = 1:M
        % Sample from predictive distribution at x*
        y_sample = mu_star + sigma_star * randn;

        % Virtual training set
        X_aug = [X_train; x_star];
        Y_aug = [Y_train; y_sample];

        % Train temporary GPR
        model_temp = train_gpr_model(X_aug, Y_aug);

        % Predict over full grid
        [~, sigma_temp] = predict_with_gpr(model_temp, X_query);

        % Compute information
        info_after(i) = compute_total_uncertainty(sigma_temp);
    end

    avg_info_gain = total_before - mean(info_after);
end
