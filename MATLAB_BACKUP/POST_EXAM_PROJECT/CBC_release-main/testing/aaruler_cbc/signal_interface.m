classdef signal_interface < dspace_interface_XILAPI
    % Interface to a signal generation/recording.
    % Simulink model associated with 'sample_model.slx' and the configuration
    % file 'MAPortConfig.xml'.

    % To create the interface, simply type
    %   `ds_rtc = signal_interface('MAPortConfig.xml');' in
    % Matlab's command line. The variable `ds_rtc' will allow to read and
    % modify the parameters of the Simulink model defined in the
    % constructor function below.

    % V0 by Ludovic Renson (l.renson@imperial.ac.uk) 2024
    % V1 by Amir Bagheri (a.bagheri20@imperial.ac.uk) 2025

    properties
        datafields;
    end

    methods
        function obj = signal_interface(maPortConfigFile)

            obj.maPortConfigFile = maPortConfigFile ;
            obj = dspace_interface_init(obj) ;
            %inputs
            obj.add_dspace_var('fund_amp','Model Root/base_amp/Value'); %shaker Frequency
            obj.add_dspace_var('fund_frequency', 'Model Root/Fundamental_Frequency/Value');  % fund freq
            obj.add_dspace_var('target_vec', 'Model Root/target_vec/Value');  % 
            obj.add_dspace_var('response_vec', 'Model Root/MAT_xcoeff/In1');  % 
            obj.add_dspace_var('sig_transience', 'Model Root/Transience_Estimator_sig/norm_transience');  % 

            %outputs
            obj.add_dspace_var('force_in1', 'Model Root/dSPACE in/Out1');  % Input 1
            obj.add_dspace_var('disp_in2', 'Model Root/dSPACE in/Out2');  % Input 2
            obj.add_dspace_var('acc_in3', 'Model Root/dSPACE in/Out3');  % Input 3
            obj.add_dspace_var('disp_offset', 'Model Root/dSPACE in/disp_offset/Value');  %displacement offset

            %control and safety
            obj.add_dspace_var('control_switch', 'Model Root/ControlSwitch/Value');
            obj.add_dspace_var('input_thresh', 'Model Root/input_thresh/Value');
            obj.add_dspace_var('displacement_thresh', 'Model Root/displacement_thresh/Value');


            obj.add_dspace_var('controller_Kp', 'Model Root/PD_Control/Kp/Value');
            obj.add_dspace_var('controller_Kd', 'Model Root/PD_Control/Kd/Value');
            obj.add_dspace_var('controller_Ki', 'Model Root/PD_Control/Ki/Value');

            %kalman filter
            obj.add_dspace_var('accel_bias', 'Model Root/dSPACE in/bias/Value');
            obj.add_dspace_var('Q1', 'Model Root/Q1/Value');
            obj.add_dspace_var('Q2', 'Model Root/Q2/Value');
            obj.add_dspace_var('R_matrix', 'Model Root/R_matrix/Value');
            
            %s-curve tracking
            obj.add_dspace_var('sig_amp', 'Model Root/amplitude_estimator_sig/amplitude');
            obj.add_dspace_var('force_amp', 'Model Root/amplitude_estimator_force/amplitude');
            obj.add_dspace_var('res_amp', 'Model Root/amplitude_estimator/amplitude');
            obj.add_dspace_var('invasiveness', 'Model Root/invasiveness_estimator/invasiveness');

            obj.datafields.dynamic_fields = {'force_in1','disp_in2','acc_in3',...
                                            'sig_amp', 'res_amp', 'invasiveness', 'force_amp'} ;

            % Set device name and test
            obj.set_stream(1,obj.datafields.dynamic_fields,10000,0);
            obj.opt.device = [obj.opt.device ' - sample_model'];
            obj.test_interface ;
        end
    end
end
