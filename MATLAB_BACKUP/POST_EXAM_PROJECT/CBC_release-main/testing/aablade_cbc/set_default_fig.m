% Get the screen size
screenSize = get(0, 'ScreenSize');
screenWidth = screenSize(3);
screenHeight = screenSize(4);
% Define the default figure width and height
figWidth = 400;  % Default MATLAB figure width
figHeight = 300; % Default MATLAB figure height
% Define an offset from the top of the screen
topOffset = 70;  % Adjust this value as needed
% Calculate the position for the new figures
position = [0, screenHeight-figHeight-topOffset, figWidth, figHeight];
% Set the default figure position
set(0, 'DefaultFigurePosition', position);