function [f] = plot_CL_inner(input_out, trial_out, control)
    f = figure;
    tiledlayout(3,1, "TileSpacing","compact");
    
    nexttile;

    desired_wave = input_out.ref{1}(trial_out.t_span');
    hold on;
    plot(trial_out.t_span, trial_out.X(:,1), 'b');
    % plot(trial_out.t_span, trial_out.X(:,2), 'g');
    plot(trial_out.t_span, desired_wave, 'r--');
    title("Response Plot")
    high_bound = trial_out.t_span(end);
    low_bound = high_bound*0.8;%high_bound - 1;
    xlim([low_bound, high_bound])
    % ylim([6.2, 6.6])
    % xlim([25, 27])
    legend("Actual", "Desired")
    
    nexttile;
    amp_error = desired_wave-trial_out.X(:, 1)';
    hold on;
    plot(trial_out.t_span, amp_error)
    title("Tracking Error")
    xlim([low_bound, high_bound])

    nexttile;
    hold on;
    plot(trial_out.t_span, input_out.f_history, 'b')
    title("Forcing")
    l = length(input_out.f_history);
    max_force = max(input_out.f_history(round(l/2):end));
    ylim([-max_force, max_force].*1.05)
    xlim([low_bound, high_bound])
    
end