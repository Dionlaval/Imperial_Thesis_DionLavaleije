function model_build(modelFile)
    % MODEL_BUILD Build a Simulink model after loading required .mat files for Models and protected blocks.
    %
    %   MODEL_BUILD('path/model_name.slx') opens the model, searches for all blocks,
    %   and for each model block (i.e. those having a 'ModelFile' parameter),
    %   it constructs the filename <xxx_BaseWorkspace.mat> from the value of
    %   'ModelFile' (e.g. xxx.slxp) and loads it if it exists. Finally, it builds
    %   the C code of the model.
    %
    %   Example:
    %       model_build('dspace_sample_model/sample_model.slx');
    %
    %   If the model file is located in a subdirectory, this function will change
    %   into that directory for the build process so that the build files are saved
    %   alongside the model.

        % Check if a model file is provided.
        if nargin < 1
            error('A model file name must be provided, e.g., model_build("sample_model.slx")');
        end

        % Extract the directory, file name, and extension.
        [modelDir, modelNameOnly, ext] = fileparts(modelFile);

        % Save the current working directory.
        origDir = pwd;

        % If a directory is specified, convert it to an absolute path (if needed)
        % and change to that directory.
        if ~isempty(modelDir)
            if ~isfolder(modelDir)
                % If modelDir is relative, convert it to an absolute path.
                modelDir = fullfile(origDir, modelDir);
                if ~isfolder(modelDir)
                    error('The directory %s does not exist.', char(modelDir));
                end
            end
            cd(modelDir);
            % Reconstruct modelFile as just the file name.
            modelFile = modelNameOnly + ext;
        end

        % Load the Simulink model (returns a model handle).
        try
            modelHandle = load_system(modelFile);
        catch ME
            error('Could not open model %s: %s', char(modelFile), ME.message);
        end

        % Retrieve the top-level model's name (for display and building).
        topModelName = get_param(modelHandle, 'Name');

        % Find all blocks in the model.
        blocks = find_system(modelHandle, 'FollowLinks', 'on', ...
                             'LookUnderMasks', 'all', 'Type', 'Block');

        % Loop through each block to check for a 'ModelFile' parameter.
        for i = 1:numel(blocks)
            try
                % Attempt to retrieve the 'ModelFile' parameter.
                blockFile = get_param(blocks(i), 'ModelFile');
                % Proceed only if a non-empty string is returned.
                if ~isempty(blockFile)
                    % Extract the base file name (without extension).
                    [~, baseName, ~] = fileparts(blockFile);
                    % Construct the expected MAT file name.
                    matFileName = [baseName, '_BaseWorkspace.mat'];
                    % Check if the MAT file exists.
                    if exist(matFileName, 'file') == 2
                        fprintf('Loading %s\n', matFileName);
                        evalin('base', sprintf('load(''%s'')', matFileName));
                    end
                end
            catch
                % Ignore if 'ModelFile' is not a valid parameter for the block, since
                % then the block is not a Model block (protected or masked).
            end
        end

        % Build the model to generate C code.
        fprintf('Building model %s...\n', topModelName);
        rtwbuild(topModelName);

        % Close the model without saving changes.
        close_system(modelHandle, 0);

    end
