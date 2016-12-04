%% MyoSpheroUpperLimb_workfile

ms = MyoSpheroUpperLimb();
%%
ms.connectDevices();
%%
drawArmTest('start',ms,10)
view(180,30)
%% 
ms.myoOneIsUpper = false

%%
ms.spheroSamplesRetard = 20;

%%
ms.setHomePose()
%%
data = ms.popRotData();
%%

data = ms.popRotData();
calib = ms.calibStruct();
save('data','data');

%%
load('data')
ms = MyoSpheroUpperLimb;
ms.animatePlotUpperLimb('test',calib,data);
