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




%%
data = ms.data_log;
%%

data = ms.popRotData();
calib = ms.calibStruct();
save('data','data');

%%
load('data')
ms = MyoSpheroUpperLimb;
ms.animatePlotUpperLimb('test',calib,data);
