%% calibration_workfile

% manually load calib data first...
clc
close all
clearvars -except calibPointData

% initial transform of T from F
RTFinit = eye(3); % defined by t pose and T frame definition

% point 1
% this.dTFinit = [175;-255;-180]; % extimated by user
% point 2
% this.dTFinit = [0;-255;-180]; % extimated by user
% point 3
this.dTFinit = [350;-255;-180]; % extimated by user

this.DEFAULT_LU = 250;
this.DEFAULT_LL = 250;
this.DEFAULT_LH = 90;
this.SPHERO_RADIUS = 36.5;

% measured from solidworks
this.dC1T = [0;197.67;0];
this.dC2T = [0;0;0];
this.dC3T = [-350.07;0;0];

rC2C1T = this.dC2T - this.dC1T;
rC3C2T = this.dC3T - this.dC2T;
rC1C3T = this.dC1T - this.dC3T;

rC2C1 = norm(rC2C1T)
rC3C2 = norm(rC3C2T)
rC1C3 = norm(rC1C3T)

% objective function
[AG,bG] = calibObjectiveFcnFromCalibPointData(calibPointData,this);
QG = AG'*AG

% initial design vector
linit = [this.DEFAULT_LU;this.DEFAULT_LL;this.DEFAULT_LH];
dC1Finit = this.dTFinit + RTFinit*this.dC1T
dC2Finit = this.dTFinit + RTFinit*this.dC2T
dC3Finit = this.dTFinit + RTFinit*this.dC3T

xGinit = [linit;dC1Finit;dC2Finit;dC3Finit];

% LB = [0;0;0;repmat(-inf,[9,1])];
LB = [125;125;45;repmat(-inf,[9,1])];
UB = repmat(inf,[12,1]);

%% lsqlin
% optimOpts = optimoptions('lsqlin',...
%   'tolfun',1e-9,...
%   'display','iter');
% X = lsqlin(AG,bG,[],[],[],[],LB,UB,xGinit,optimOpts) 

%% fmincon
% X = fmincon(FUN,X0,A,B,Aeq,Beq,LB,UB,NONLCON,OPTIONS) minimizes with
optimOpts = optimoptions('fmincon',...
  'display','iter',...
  'algorithm','sqp',...
  'gradobj','on',...
  'gradconstr','on',...
  'hessian','on',...
  'maxfunevals',1e8,...
  'maxiter',1000,...
  'tolcon',1e-9);

x = fmincon(@(x)myoSpheroObjFun(x,AG,bG),xGinit,...
  [],[],[],[],...
  LB,UB,...
  @(x)myoSpheroNonlinConFun(x,this),...
  optimOpts);

%%
reshape(x,[3,4])
[linit,dC1Finit dC2Finit dC3Finit]
