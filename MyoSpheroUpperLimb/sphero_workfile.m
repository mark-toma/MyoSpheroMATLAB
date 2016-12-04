% sphero_workfile


%% Connection routine
s = sphero('Sphero-WPP');
s.Handshake = 1;
assert( s.ping()==1,'Sphero failed Ping().');
result = s.stabilization(0)
s.BackLEDBrightness = 1
s.Color = 'g';
result = s.logSensors(50,4,0,'sensorname',{'Q0','Q1','Q2','Q3'});
assert(result==1,'Sphero logging failed.');
