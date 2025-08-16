function info = f_compute_total_uncertainty(gpr_model, X_query)
    [~, Y_std] = predict(gpr_model, X_query);
    info = sum(Y_std.^2);
end
