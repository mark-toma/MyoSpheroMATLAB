%% Myo Sphero MATLAB Workfile



clear all
close all
clc


[y,z,x] = cylinder()

rad = 5;
len = 200;

surf(len*x,rad*y,rad*z)


%%



s = Sphero('Sphero-WPP')

%%

s.SetStabilization(false)
%%
s.SetBackLEDOutput(1)


