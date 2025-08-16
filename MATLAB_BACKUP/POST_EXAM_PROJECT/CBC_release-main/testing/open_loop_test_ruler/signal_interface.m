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

            % variables related to filters and harmonic basis generator
            % obj.add_dspace_var('frq_fund', 'Tunable Parameters/hrmbas_var_frq');  % harmonic basis generator: fundamental frequency
            % obj.add_dspace_var('harmonics', 'Tunable Parameters/hrmbas_var_harmonics');  % harmonic basis generator: coefficients of harmonics
            % obj.add_dspace_var('lms_gain', 'Tunable Parameters/lms_var_gain');  % LMS filter gain
            % obj.add_dspace_var('rls_delta', 'Tunable Parameters/rls_var_delta');  % RLS filter regularisation factor
            % obj.add_dspace_var('rls_lambda', 'Tunable Parameters/rls_var_lambda');  % RLS filter forgetting factor

            % dSPACE output variables
            % obj.add_dspace_var('out_thr', 'Model Root/Threshold/Value');  % Threshold of dSPACE output signals
            % obj.add_dspace_var('out_res', 'Model Root/Reset/Value');  % reset variable for dSPACE output signals
            % obj.add_dspace_var('out1', 'Model Root/dSPACE out/Out1');  % Output 1
            % obj.add_dspace_var('out2', 'Model Root/dSPACE out/Out2');  % Output 2

            % dSPACE input variables
            % obj.add_dspace_var('in1_amp', 'Model Root/dSPACE in/amp1/Value');  % Amplifier gain of dSPACE input 1
            % obj.add_dspace_var('in1_sns', 'Model Root/dSPACE in/sens_gain1/Gain');  % Sensitivity of dSPACE input 1
            % obj.add_dspace_var('in2_amp', 'Model Root/dSPACE in/amp2/Value');  % Amplifier gain of dSPACE input 2
            % obj.add_dspace_var('in2_sns', 'Model Root/dSPACE in/sens_gain2/Gain');  % Sensitivity of dSPACE input 2
            % obj.add_dspace_var('in1', 'Model Root/dSPACE in/Out1');  % Input 1
            obj.add_dspace_var('fund_frequency', 'Model Root/Fundamental_Frequency/Value');  % fund freq
            obj.add_dspace_var('force_in1', 'Model Root/dSPACE in/Out1');  % Input 1
            obj.add_dspace_var('disp_in2', 'Model Root/dSPACE in/Out2');  % Input 2
            obj.add_dspace_var('acc_in3', 'Model Root/dSPACE in/Out3');  % Input 3
            obj.add_dspace_var('disp_trans', 'Model Root/Transience_Estimator/norm_transience');  % Input 3
            obj.add_dspace_var('filter_alpha', 'Model Root/dSPACE in/alpha/Value');  % Input 3
            obj.add_dspace_var('f_switch', 'Model Root/Freq_switch/Value');  % Input 3
            obj.add_dspace_var('f_ramp_init', 'Model Root/ramp_init/Value');  % Input 3
            obj.add_dspace_var('f_ramp_slope', 'Model Root/ramp_slope/Value');  % Input 3
            obj.add_dspace_var('f_ramp_reset', 'Model Root/ramp_reset/Value');  % Input 3

            % Data fields used to organise/group names of variables (useful for streams)
            % obj.datafields.static_fields = {'frq_fund', 'harmonics', 'lms_gain','rls_delta','rls_lambda'} ;
            % obj.datafields.dynamic_fields = {'out1','out2','in1','in2'} ;
            % obj.datafields.my_field = {} ; % your desired field

            % Single sine variables
            % obj.add_dspace_var('Frequency','Model Root/Single_sine/Frequency/Gain'); %shaker Frequency
            obj.add_dspace_var('Amp','Model Root/Single_sine/Amp/Gain'); %shaker Frequency

            obj.datafields.dynamic_fields = {'Amp','force_in1','disp_in2','acc_in3', 'disp_trans',...
                'fund_frequency', 'filter_alpha', 'f_switch', 'f_ramp_init', 'f_ramp_slope', 'f_ramp_reset'} ;

            % Set device name and test
            obj.set_stream(1,obj.datafields.dynamic_fields,10000,0);
            obj.opt.device = [obj.opt.device ' - sample_model'];
            obj.test_interface ;
        end
    end
end
