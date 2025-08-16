% Clear workspace and initialize parameters
close all;
clear all;
addpath('../custom_functions')  % use correct relative path


% % System parameters
m = 0.04;
c = 1.5874;
k = 1.0197e+04;
model.R = 1;
model.L = 250 * 1e-06;
model.G = 12.3;
model.kappa = 42.5e+05;

omega1 = 2*pi*14.6;
omega2 = 2*pi*200;
xi1 = 0.03;
xi2 = 0.09;

model.Phiell = [-7.382136522799137;7.360826867549465];
model.Phid = [-0.328118182993717;-1.714004051780882];
Phiell = model.Phiell;
Phid = model.Phid;

Z=[2*xi1*omega1 0;0 2*xi2*omega2];
Omega=[omega1^2 0;0 omega2^2];

model.M = eye(2) + m*Phid*Phid';
model.C = Z + c*Phid*Phid';
model.K = Omega + k*Phid*Phid';

% model harmonics
model.harmonics = 3;


% Initial conditions: [eta0; eta_dot0; I0]
x0 = zeros(5,1);

% Define forcing
model.F = 10;
model.omega = 2*pi*37.6799;

% Control input (function of time)
model.u_fun = @(t) model.F * sin(model.omega * t);  % no control input for now
eta_ddot_star = @(t) -A_target * omega^2 * sin(omega * t);

% Time span
tspan = [0 0.5];

model.Ts = 1/1000;