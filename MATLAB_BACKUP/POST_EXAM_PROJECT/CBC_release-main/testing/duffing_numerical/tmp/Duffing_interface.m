classdef Duffing_interface < simulink_interface
    % Duffing_interface: Simplified interface to a Simulink model for a Duffing oscillator.
    % This class loads the Simulink model, sets up simulation parameters,
    % configures signal logging, and provides basic control over the simulation.

    properties
        model;                           % Name of the Simulink model
        fourier;                         % Structure holding Fourier analysis indices
        datafields;                      % Logged signal names for data recording
        OriginalOptimizeBlockIOStorage;  % Original setting for OptimizeBlockIOStorage
    end

    methods
        function obj = Duffing_interface()
            % Constructor: Initialise the interface and start the simulation.

            % Set simulation parameters in the base workspace.
            Nsamples = 5000;
            assignin('base', 'Nsamples', Nsamples);  % Number of logged samples
            assignin('base', 'DeltaT', 0.001);       % Fixed simulation time step

            % Set the model name.
            obj.model = 'duffing_cbc';

            % Load the Simulink model.
            load_system(obj.model);

            % Configure simulation settings.
            set_param(obj.model, 'SimulationMode', 'normal');
            set_param(obj.model, 'StopTime', 'Inf');
            obj.add_simulink_var('time_step', obj.model, 'FixedStep');

            % Save and override OptimizeBlockIOStorage to ensure synchronisation.
            obj.OriginalOptimizeBlockIOStorage = get_param(obj.model, 'OptimizeBlockIOStorage');
            if strcmp(obj.OriginalOptimizeBlockIOStorage, 'on')
                warning('Turning off OptimizeBlockIOStorage for synchronisation purposes.');
                set_param(obj.model, 'OptimizeBlockIOStorage', 'off');
            end

            % Start the simulation.
            set_param(obj.model, 'SimulationCommand', 'start');

            % Add Simulink variables (settable parameters) with dynamic model path.
            obj.add_simulink_var('forcing_amp', [obj.model '/Amplitude'], 'Value');
            obj.add_simulink_var('forcing_freq', [obj.model '/Frequency'], 'Value');
            obj.add_simulink_var('x_target_coeffs', [obj.model '/Target_Coeff'], 'Value');
            obj.add_simulink_var('control_switch', [obj.model '/ControlSwitch'], 'Value');
            obj.add_simulink_var('Kp', [obj.model '/PD_Control/Kp'], 'Value');
            obj.add_simulink_var('Kd', [obj.model '/PD_Control/Kd'], 'Value');

            % Add Simulink observables (read-only signals).
            obj.add_simulink_obs('x', [obj.model '/duffing/Integrator']);
            obj.add_simulink_obs('x_coeffs', [obj.model '/Fourier Series 1/Sum']);
            obj.add_simulink_obs('x_coeffs_ave', [obj.model '/MATLAB Function1'], 1);
            obj.add_simulink_obs('x_coeffs_var', [obj.model '/MATLAB Function1'], 2);
            obj.add_simulink_obs('force_total', [obj.model '/Sum1']);
            obj.add_simulink_obs('force_total_coeffs', [obj.model '/Fourier Series 2/Sum']);
            obj.add_simulink_obs('force_total_coeffs_ave', [obj.model '/MATLAB Function2'], 1);
            obj.add_simulink_obs('force_total_coeffs_var', [obj.model '/MATLAB Function2'], 2);
            obj.add_simulink_obs('x_target', [obj.model '/ControlTarget/Sum']);
            obj.add_simulink_obs('x_error', [obj.model '/Sum']);
            obj.add_simulink_obs('control', [obj.model '/PD_Control/Sum2']);

            % Set default control parameter values.
            obj.par.x_target_coeffs(:) = 0;
            obj.par.control_switch = 0;
            obj.par.Kp = 2;
            obj.par.Kd = 1;
            obj.par.forcing_amp = 0;

            % Configure Fourier analysis indices.
            n_coeff = 15;  % control target coefficients
            obj.fourier.n_modes = (n_coeff - 1) / 2;
            obj.fourier.idx_DC = 1;
            obj.fourier.idx_AC = 2:n_coeff;
            obj.fourier.idx_fund = [2, 2 + obj.fourier.n_modes];
            obj.fourier.idx_higher = [(3:1 + obj.fourier.n_modes), (3 + obj.fourier.n_modes:n_coeff)];
            obj.fourier.idx_sin = 2 + obj.fourier.n_modes:n_coeff;
            obj.fourier.idx_cos = 2:1 + obj.fourier.n_modes;
            obj.fourier.idx_iteration = [obj.fourier.idx_DC, obj.fourier.idx_higher];

            % Configure data logging: ensure these names match the signals logged in the model.
            obj.opt.samples = Nsamples;
            obj.datafields.stream_fields = {'x', 'Target', 'ForceRaw', 'error', 'ForceTotal', 'ControlSignal', 'time'};
        end

        function delete(obj)
            % delete: Stop then clean up the interface to Simulink.
            obj.stop_simulation()
            if bdIsLoaded(obj.model)
                set_param(obj.model, 'OptimizeBlockIOStorage', obj.OriginalOptimizeBlockIOStorage);
            end
        end

        function stop_simulation(obj)
            % stop_simulation: Stop the running Simulink simulation.
            set_param(obj.model, 'SimulationCommand', 'stop');
        end
    end
end
