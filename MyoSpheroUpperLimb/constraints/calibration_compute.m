%% calibration_compute

clear all; close all; clc;

ms = MyoSpheroUpperLimb();

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
data = ws.calibPointsData;
clear ws

% expect inputs:

conSpec = {};
conSpec(end+1) = {'dist'};
conSpec(end+1) = {'ortho'};
% conSpec(end+1) = {'normalVert'};
% conSpec(end+1) = {'normalHorz'};
conSpec(end+1) = {'planar'};

params = MyoSpheroUpperLimb.makeCalibParams(calib,data,conSpec)

[xs,fval,exitFlag,output,lambda] = MyoSpheroUpperLimb.computeCalibration(params)


%%
[l,d,R] = MyoSpheroUpperLimb.interpretCalibResult(xs);
l

%%
[c,ceq,Dc,Dceq] = MyoSpheroUpperLimb.nonlinConFunGrad(xs,params)


%%
tr2rpy(R)*180/pi


%%
%
% default  
%   1  240.0471  252.4854  67.0900
%   2  320.1644  226.7555  76.4783
%   3  235.4160  278.1602  73.0362
%   4  308.3064  292.5293  26.0216


