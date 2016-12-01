s = sphero('Sphero-WPP')

%%
rate = 50;
frames_per_packet = 5;
packets = 0; % indefinite

logSensors(s,rate,frames_per_packet,packets,...
  'sensorname',{'Q0','Q1','Q2','Q3'},...
  'filename','sphero_data.mat') 

%%
% SIZEMYVAR = SIZE(MATOBJ,'VARNAME')

matObj = matfile('sphero_data.mat')


%%







