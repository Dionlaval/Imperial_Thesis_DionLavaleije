function [response, target, inv_score] = get_response_target(input, trial, control)
        %record responses
    [t_lin, x_lin] = get_last_n_periods(trial.t_span, input.f_history, 10);
    [A_vec,B_vec] = get_fft_components(t_lin, x_lin, input.w0, control.k_num);

    response = [A_vec(2:end),B_vec(2:end)]; %remove a0 and b0
    target = control.target_vec;
    % 
    % num_score = sqrt(sum(response(1, :).^2, "all"));
    % den_score = sqrt(sum(response(2:end, :).^2, "all"));

    %compare main to next largest coeff
    num_score = max(sum(response(2:end, :).^2, 2));
    den_score = sum(response(1, :).^2, 2);
    inv_score = sqrt(num_score./den_score);

    [~, x_lin] = get_last_n_periods(trial.t_span, trial.X(:, 1), 10);
    "get_response_target: response amp -> " + max(x_lin)
end