%% calibration_compute

clear all; close all; clc;


%% Load and prepare data

% get info about saved calibration datasets
appDataPath = MyoSpheroUpperLimb.appDataPath();
fileList = cellstr(ls(appDataPath));
ids = ~cellfun('isempty',strfind(fileList,'cal-'));
fileList = fileList(ids);

% select one of them
idx = 1;
calFile = fileList{idx};

% load the data
ws = load(fullfile(appDataPath,calFile));
calib = ws.calib;
calibPointsData = ws.calibPointsData;
clear ws

% apply home pose to the data
calibPointsDataHomed = calibPointsData;
for ii=1:3
  for kk = 1:calibPointsDataHomed(ii).numSamples
    calibPointsDataHomed(ii).RU(:,:,kk) = calib.RFNU'*calibPointsDataHomed(ii).RU(:,:,kk);
    calibPointsDataHomed(ii).RL(:,:,kk) = calib.RFNL'*calibPointsDataHomed(ii).RL(:,:,kk);
    calibPointsDataHomed(ii).RH(:,:,kk) = calib.RFNH'*calibPointsDataHomed(ii).RH(:,:,kk);
  end
end


%% Init params

params.dTguess = [300;-250;-250];
params.lengthUpper = 280;
params.lengthLower = 290;
params.lengthHand  = 50;
params.rc2c1 = [0;197.67;0];
params.rc2c3 = [350.07;0;0];
params.rc3c1 = [-350.07;197.67;0];

params.SPHERO_RADIUS = 38; % mm -- i think
params.calibPointsDataHomed = calibPointsDataHomed;

[Ag,bg] = objFunParams(params);
params.Ag = Ag;
params.bg = bg;


%% Configure constraints

% See the following about constraint functions with gradients
% https://www.mathworks.com/help/optim/ug/nonlinear-constraints-with-gradients.html
% [c,ceq,Dc,Dceq] = conFunGrad(x,...)

% select constraints
params.conSpec = {};
params.conSpec(end+1) = {'dist'};         % nonlinear distance constraints
% params.conSpec(end+1) = {'orientNormal'}; % nonlinear constraints on nT vertical
params.conSpec(end+1) = {'orientPlanar'}; % linear constraints on vectors in the horizontal plane

% modify constraints (currently not supported)
% params.conSpec(end+1) = {'distIneq'};         % use the inequality variant
% params.conSpec(end+1) = {'orientNormalIneq'}; % use the inequality variant


%% Set up bounds and linear constraints

LB = [0;0;0;repmat(-inf,[9,1])];
UB = repmat(inf,[12,1]);

Aeq = []; beq = [];
[Aeq_,beq_] = MyoSpheroUpperLimb.orientPlanarFun(params);
Aeq = [Aeq;Aeq_]; beq = [beq;beq_];

A = []; b = [];

x0 = [...
  params.lengthUpper;...
  params.lengthLower;...
  params.lengthHand;...
  params.dTguess - params.rc2c1;...
  params.dTguess;...
  params.dTguess - params.rc2c3];

%% Run optimization


[xs,fval,exitFlag] = ...
  fmincon(@(x)objFun(x,params),x0,...
  A,b,Aeq,beq,LB,UB,...
  @(x)nonlinConFunGrad(x,params),...
  [])






