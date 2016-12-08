%% MyoSpheroUpperLimb_workfile


%% Animate calibration sequences

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

ms = MyoSpheroUpperLimb;
conSpec = {};
conSpec(end+1) = {'dist'};
conSpec(end+1) = {'ortho'};
% conSpec(end+1) = {'planar'};
% conSpec(end+1) = {'normalVert'};
conSpec(end+1) = {'normalVertIneq'};
% conSpec(end+1) = {'normalHorz'};

params = ms.makeCalibParams(calib,data,conSpec);
[xs,~,~,~,lambda] = ms.computeCalibration(params);
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



