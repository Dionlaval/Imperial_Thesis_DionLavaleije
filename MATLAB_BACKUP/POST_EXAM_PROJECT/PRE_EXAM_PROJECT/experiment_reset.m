function [experiment] = experiment_reset(control)
    experiment.harmony_iter = 50;
        % response histories
    experiment.A_responses = zeros(control.k_num, experiment.harmony_iter);
    experiment.B_responses = zeros(control.k_num, experiment.harmony_iter);
    experiment.A_targets = zeros(control.k_num, experiment.harmony_iter);
    experiment.B_targets = zeros(control.k_num, experiment.harmony_iter);
        % set all first harmonics
    experiment.A_targets(1, :) = 0;
    experiment.B_targets(1, :) = control.target_amp;
end