    for n = (1:4)
        for m = (1:4)
            % disp("Update Secondary:" + m);
            secondaries = vec2mat(response_vector);
            secondaries(1, :) = 0;
            target = primaries + secondaries;
            rtc.par.target_vec = [0; target(:, 1); target(:, 2)];

            % Wait before triggering steady-state detection
            disp("Waiting 5 sec...");
            pause(5);
            sig_amp = rtc.par.sig_amp;
            res_amp = rtc.par.res_amp;
            invasiveness = rtc.par.invasiveness;
            transience = rtc.par.sig_transience;
            fprintf("Data results %.1f: [amp %.2f, inv = %.3f, Kd = %.5f]\n", m, amp, invasiveness, rtc.par.controller_Kd);
            
            % norm inv and trans based on thresholds
            norm_inv = invasiveness/inv_thresh;
            norm_trans = transience/trans_thresh;

            converge_cond = norm_inv < 1 && norm_trans < 1;
                        %debug
            disp([norm_inv, norm_trans, converge_cond])
            if(converge_cond)
                results(i, :) = [rtc.par.fund_frequency, sig_amp, res_amp, invasiveness, transience, amp];
                ideal_target.Kp = rtc.par.controller_Kp;
                ideal_target.Kd = rtc.par.controller_Kd;
                ideal_target.vec = rtc.par.target_vec;
                conditions{i, 1} = ideal_target;
                break
            end

            % next picard iteration
            response_vector = rtc.par.response_vec;
        end

        %dont iterate Kd if converged
        if(converge_cond)
            converge_cond = false;
            break
        end

        %if it cant converge after 4 picard iterations we need to adjust Kd
        kd_buffer(:, 1) = [rtc.par.controller_Kd; norm_inv; norm_trans];
        kd_buffer = circshift(kd_buffer, 1, 2);
        if(n == 1) % first iteration just do a blind step based on current errors
            if norm_trans > 1
                Kd_offset = 1 + 0.001;
            else 
                Kd_offset = 1 - 0.001;
            end
            rtc.par.controller_Kd = rtc.par.controller_Kd*Kd_offset;
            continue;
        else % next iterations based on previous values
            v1 = kd_buffer(:, 3);
            v2 = kd_buffer(:, 2);

            term1 = v1(2) - v1(3);
            term2 = v2(3) - v2(2);
            
            x1 = v1(1);
            x2 = v2(1);
            x_new = (x2*term1 + x1*term2)/(term2 + term1);
    
            delta_x = x_new - rtc.par.controller_Kd;
            %avoid negative Kd
            rtc.par.controller_Kd = max(x_new-0.5*delta_x, 0.00001);
        end
    end