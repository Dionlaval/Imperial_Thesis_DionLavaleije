function [mu, sigma] = predict_with_gpr(gpr_model, X_query)
    [mu, sigma] = predict(gpr_model, X_query);
end
