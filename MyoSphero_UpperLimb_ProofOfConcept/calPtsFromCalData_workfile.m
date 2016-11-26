%% calPtsFromCalData_workfile





N = 4;

d1.RU = repmat(eye(3),[1,1,N]);
d1.RL = repmat(eye(3),[1,1,N]);
d1.RH = repmat(eye(3),[1,1,N]);
d1.N = N;

d2 = d1;

% call calibPointsFromCalibData
[pts,lv] = calibPointsFromCalibData(d1,d2)



%%



d = [d1,d2];


