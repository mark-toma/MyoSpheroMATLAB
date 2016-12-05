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
idx = 3;
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
conSpec(end+1) = {'normalVert'};
% conSpec(end+1) = {'normalHorz'};
% conSpec(end+1) = {'planar'};

params = MyoSpheroUpperLimb.makeCalibParams(calib,data,conSpec)

[xs,fval,exitFlag,output,lambda] = MyoSpheroUpperLimb.computeCalibration(params)
[l,d,R] = MyoSpheroUpperLimb.interpretCalibResult(xs);






