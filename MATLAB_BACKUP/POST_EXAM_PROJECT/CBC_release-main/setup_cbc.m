% setup_cbc.m - MATLAB Setup Script for Library
clear;
warning('off','MATLAB:RMDIR:RemovedFromPath');

% Change to script directory
if isdeployed || ~usejava('desktop') % Running from command line
    scriptPath = mfilename('fullpath');
else % Running from MATLAB editor
    tmp = matlab.desktop.editor.getActive;
    if isempty(tmp) || ~isfield(tmp, 'Filename') || isempty(tmp.Filename)
        % Fallback to mfilename if tmp is empty or does not contain Filename
        scriptPath = mfilename('fullpath');
    else
        scriptPath = tmp.Filename;
    end
end
cd(fileparts(scriptPath));

% Define the base folders
srcFolder = fullfile(pwd, 'src');
libraryFolder = fullfile(pwd, 'library');
docFolder = fullfile(pwd, 'doc');

% Display start message
fprintf('Starting setup in folder: %s\n', srcFolder);

% Ensure the src folder exists
if ~isfolder(srcFolder)
    error('Error: The "src" folder does not exist in the current directory.');
end

% Find all .mlproj files in src and its subfolders
mlprojFiles = dir(fullfile(srcFolder, '**', '*.mlproj'));

% Store extracted project folders for later path addition
extractedFolders = {};

% Extract each .mlproj file into a new folder (named after the file)
for k = 1:length(mlprojFiles)
    mlprojFilePath = fullfile(mlprojFiles(k).folder, mlprojFiles(k).name);
    [~, projectName, ~] = fileparts(mlprojFiles(k).name);
    outputFolder = fullfile(mlprojFiles(k).folder, projectName);
    
    if isfolder(outputFolder)
        parts = strsplit(outputFolder, filesep);
        fprintf('Removing existing folder: %s\n', parts{end});
        rmdir(outputFolder, 's');
    end
    
    mkdir(outputFolder);
    
    try
        unzip(mlprojFilePath, outputFolder);
        rmdir(fullfile(outputFolder,"_rels"),'s');
        rmdir(fullfile(outputFolder,"metadata"),'s');
        delete(fullfile(outputFolder,"[Content_Types].xml"));
        copyfile(fullfile(outputFolder,"fsroot/*"),outputFolder);
        rmdir(fullfile(outputFolder,"fsroot"),'s');
        fprintf('Extracted %s \n', mlprojFiles(k).name);
        extractedFolders{end+1} = outputFolder;
    catch ME
        fprintf('Failed to extract %s: %s\n', mlprojFiles(k).name, ME.message);
    end
end

% Close any open projects to prevent auto-staging issues
proj = matlab.project.rootProject;
if ~isempty(proj)
    close(proj);
end

% Add src and doc and all its subfolders to the MATLAB path
addpath(genpath(srcFolder));
addpath(genpath(docFolder));

% Add each extracted folder to the MATLAB path
for i = 1:length(extractedFolders)
    addpath(genpath(extractedFolders{i}));
    parts = strsplit(extractedFolders{i}, filesep);
    fprintf('Added extracted folder: %s to the MATLAB path.\n', parts{end});
end

% Add library and all its subfolders to the MATLAB path
if isfolder(libraryFolder)
    addpath(genpath(libraryFolder));
    fprintf('Added %s and all subfolders to the MATLAB path.\n', libraryFolder);
end

%% Load .mat Files from Extracted Projects
% This section recursively finds and loads any .mat files from the extracted folders.
% Each variable from the .mat files is assigned directly into the base workspace.
loadedVarNames = {};  % To record the names of variables loaded from .mat files

% for i = 1:length(extractedFolders)
%     matFiles = dir(fullfile(extractedFolders{i}, '**', '*.mat'));
%     for j = 1:length(matFiles)
%         matFilePath = fullfile(matFiles(j).folder, matFiles(j).name);
%         try
%             % Load the .mat file into a temporary structure.
%             s = load(matFilePath);
%             fn = fieldnames(s);
%             % Assign each field into the base workspace.
%             for idx = 1:length(fn)
%                 assignin('base', fn{idx}, s.(fn{idx}));
%             end
%             loadedVarNames = [loadedVarNames, fn']; %#ok<AGROW>
%             parts = strsplit(matFilePath, filesep);
%             fprintf('Loaded .mat file: %s\n', parts{end});
%         catch ME
%             fprintf('Failed to load .mat file %s: %s\n', matFilePath, ME.message);
%         end
%     end
% end

%% Final Message and Workspace Cleanup
% Print the final message before cleaning the workspace.
fprintf('Setup completed successfully in folder: %s\n', srcFolder);

% Build and evaluate a clear command that keeps only the loaded .mat variables.
if ~isempty(loadedVarNames)
    keepCommand = ['clearvars -except ' strjoin(loadedVarNames, ' ')];
    eval(keepCommand);
else
    clear;
end
addpath("C:\Program Files\dSPACE RCPHIL 2023-A\MATLAB\RTI\RTI1202\TLC");
k_harmonics = 7;
load('C:\Users\dionl\Desktop\AME_MASTERS\MATLAB\POST_EXAM_PROJECT\CBC_release-main\src\dspace\Filters\LMS_Filter_protected\LMS_Filter_BaseWorkspace.mat');