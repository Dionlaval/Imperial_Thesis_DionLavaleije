function [experiment, input3, trial3, control2] = harmonizer_newton(invasive_tol, model, input, trial, control)
    
    experiment = experiment_reset(control);

    %tune Kp and Kd and spit out initial run
    [input2, trial2, control2] = simple_tuner(model, input, trial, control);

    % get response and target
    [response, target, ~] = get_response_target(input2, trial2, control2);
        % record data
    experiment.A_responses(:, 1) = response(:, 1);
    experiment.B_responses(:, 1) = response(:, 2);
    experiment.A_targets(:, 1) = target(:, 1);
    experiment.B_targets(:, 1) = target(:, 2);
    
    % next run
    experiment.A_targets(2:end, 2) = target(2:end, 1).*1.05 + 0.001;
    experiment.B_targets(2:end, 2) = target(2:end, 2).*1.05 + 0.001;
    
    for i = (2:experiment.harmony_iter)
        % adjust control targets
        control2.target_vec = [experiment.A_targets(:, i), experiment.B_targets(:, i)];
        % run closed loop test
        [input3, trial3] = closedloop_test(model, input2, trial2, control2);
        [response, target, inv_score] = get_response_target(input3, trial3, control2);
        "Harmony Loop: " + i + " -> invasiveness: " + inv_score*100
        [response, target]
            % record data
        experiment.A_responses(:, i) = response(:, 1);
        experiment.B_responses(:, i) = response(:, 2);
        
    
        % break cond
        if abs(inv_score) < invasive_tol
            "~~~~~~~~~~~~~~~~~~~~~~~~~~ Non-invasive control achieved! ~~~~~~~~~~~~~~~~~~~~~~~~~~"
            experiment.A_targets = experiment.A_targets(:, 1:i);
            experiment.B_targets = experiment.B_targets(:, 1:i);
            experiment.A_responses = experiment.A_responses(:, 1:i);
            experiment.B_responses = experiment.B_responses(:, 1:i);
            [response, target]
            success = true;
            break;
        end
            % break cond
        if i == experiment.harmony_iter
            "%%%%%%%%%%%%%%%%%%%%%%%%%%%% COULDNT CONVERGE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
            success = false;
            break;
        end
    
        %run for derivative
        control5 = control2;
        dtarget = [experiment.A_targets(:, i), experiment.B_targets(:, i)];
        ddtarget = dtarget.*max(min(0.1, inv_score/20), 0.05);
        ddtarget(1, :) = 0;
        control5.target_vec = dtarget - ddtarget;

        % run closed loop test
        [input5, trial5] = closedloop_test(model, input2, trial2, control5);
        [response5, target5, inv_score5] = get_response_target(input5, trial5, control5);
        "Harmony Loop: d" + i + " -> invasiveness: " + inv_score5*100
        [response5, target5]

        % set next target
        fx = response;
        fx2 = response5;
        % delta_x;
        dfx = (fx - fx2)./ddtarget;
        next_x = target - fx./dfx;
        experiment.A_targets(2:end, i + 1) = next_x(2:end, 1);
        experiment.B_targets(2:end, i + 1) = next_x(2:end, 2);

    end
end