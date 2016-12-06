%% MyoSpheroUpperLimb_workfile

ms = MyoSpheroUpperLimb();
%%
ms.connectDevices();
s = ms.sphero
%%
drawArmTest('start',ms,10)
view(180,30)
%% 
ms.myoOneIsUpper = false
%%
ms.setHomePose()


%% Animate calibration sequences

% delete(timerfindall);

% clear classes; close all; clc;

% get info about saved calibration datasets
appDataPath = MyoSpheroUpperLimb.appDataPath();
fileList = cellstr(ls(appDataPath));
ids = ~cellfun('isempty',strfind(fileList,'cal-'));
fileList = fileList(ids);

% select one of them
idx = 4;
calFile = fileList{idx};

% load the data
ws = load(fullfile(appDataPath,calFile));
calib = ws.calib;
data = ws.calibPointsData;
clear ws

ms = MyoSpheroUpperLimb;
params = ms.makeCalibParams(calib,data)
xs = ms.computeCalibration(params);
[lengths,dT,RT] = ms.interpretCalibResult(xs);

ms.lengthUpper = lengths(1);
ms.lengthLower = lengths(2);
ms.lengthHand  = lengths(3);
ms.dT = dT;
ms.RT = RT;



%%
for jj=1:3
  ms.animatePlotUpperLimb(20,'test',calib,data(jj));
  if jj==3, continue; end
  input('press a key to continue');
end



