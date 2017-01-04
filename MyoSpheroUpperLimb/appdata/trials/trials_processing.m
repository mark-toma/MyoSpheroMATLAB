%% trials_processing.m
% calibrate, analyze data and 
clear all; close all; clc;

% get filenames from directory listing
names = dir;
names = {names.name};
% filter by names that contain 'trial' and '.mat'
ids = cellfun(@(x)~isempty(x),strfind(names,'trial')) & ...
  cellfun(@(x)~isempty(x),strfind(names,'.mat'));
names = names(ids);

%%

ms = MyoSpheroUpperLimb;

ii = 1;
fName = names{ii};
load(fName);
dataRaw = data;

% time table for calibration point
timesCalib = [3,5;12,15;22,25];
timesReach = [7,10;17,20;27,30];

for jj = 1:2%size(timesCalib,1)
  ids = 50*timesCalib(jj,1):50*timesCalib(jj,2);
  ids = ids(ids<dataRaw.numSamples);
  RU = dataRaw.RU(:,:,ids);
  RL = dataRaw.RL(:,:,ids);
  RH = dataRaw.RH(:,:,ids);
  for kk=1:size(RH,3);
    tmp(kk) =det(RH(:,:,kk))
  end
  dataCalib(jj) = ms.makeDataStruct(RU,RL,RH);
end
for jj = 1:2%size(timesReach,1)
  ids = 50*timesReach(jj,1):50*timesReach(jj,2);
  RU = dataRaw.RU(:,:,ids);
  RL = dataRaw.RL(:,:,ids);
  RH = dataRaw.RH(:,:,ids);
  dataReach(jj) = ms.makeDataStruct(RU,RL,RH);
end

%% Compute calibration
ms.setCalib(calib);
ms.calibrate(dataCalib);

%% Make calibrated movie from dataRaw

% tmp = dataRaw;
% tmp.RU = dataRaw.RL;
% tmp.RL = dataRaw.RU;
% ms.animatePlotUpperLimb(20,'test',calib,tmp);


for jj=1:2:dataRaw.numSamples
  dr = ms.makeDataStruct(...
    dataRaw.RU(:,:,jj),...
    dataRaw.RL(:,:,jj),...
    dataRaw.RH(:,:,jj));
  ms.drawPlotUpperLimb('test',calib,dr);
  pause(0.04); drawnow;
end
ms.removePlotUpperLimb('test');

%% Make excel table of results





