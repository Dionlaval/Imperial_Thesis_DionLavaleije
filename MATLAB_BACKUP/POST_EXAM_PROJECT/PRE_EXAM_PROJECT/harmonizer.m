function [experiment, input3, trial3, control2, success] = harmonizer(invasive_tol, model, input, trial, control)
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
    
        % set next target
            % secant method
        xn = target;
        xn1 = [experiment.A_targets(:,i-1), experiment.B_targets(:,i-1)];
        fx = response;
        fx1 = [experiment.A_responses(:, i-1), experiment.B_responses(:, i-1)];
        x_new = xn - fx.*((xn-xn1)./(fx-fx1));
        x_new(isnan(x_new)) = 0.001; % Nan proof it
            % only adjust > a2, b2
        experiment.A_targets(2:end, i+1) = x_new(2:end, 1);
        experiment.B_targets(2:end, i+1) = x_new(2:end, 2);
    end
end