%% Sphero Simulink Library and Examples
% This example describes the Simulink library for the Sphero Connectivity
% package, and how the blocks from the library can be used to control a
% Sphero.

%% Sphero Simulink blocks
% The Sphero Connectivity Package comes equipped with a Simulink library
% containing basic sensing and actuation blocks.
%
% <matlab:open('sphero_lib') Open the library>

open('sphero_lib');
%%
% Specifically, the *Setup* block is needed to select a preexisting workspace
% Sphero object for simulation. That preexisiting Sphero object is then used 
% during the simulation by the other blocks that specify the same name. 
% If you want to use different Spheros in the same simulation then each 
% of them must have its own Setup block. 
% 
% The *Real Time Pacer* block can be used to slow down a fast simulation 
% so it can track real time. 
% 
% The *Read Sensor* block calls the MATLAB "readSensor" function, which
% returns the value of a specified sensor.
% 
% The *Read Locator* block calls the MATLAB "readLocator" function, which
% returns the current location and velocity components of the Sphero.
% 
% The *Roll* block calls the MATLAB "roll" function to move the Sphero.
%
% The *Raw Motor* block calls the MATLAB "rawMotor" function to directly (and
% independently) command the speed ot the two sphero motors (wheels). 
% 
% Also note that you can open the simulink example models (which will be shown
% shortly thereafter), by double clicking on the three blocks on the right.

close_system('sphero_lib');

%% Using the Read Sensors blocks to read acceleration
%
% <matlab:open('accel_sim') Open the example>

open('accel_sim');

%%
% This example uses three Read Sensor Roll blocks to sense acceleration 
% along the three body axis of the Sphero.
% 
% The readSensor block can be used to sense any of the following signals:
% 'accelX', 'accelY', 'accelZ', 'gyroX', 'gyroY', 'gyroZ','rmotorEmfRaw', 
% 'lmotorEmfRaw', 'lmotorPwmRaw', 'rmotorPwmRaw','imuPitch', 'imuRoll', 
% 'imuYaw', 'accelXFilt', 'accelYFilt','accelZFilt', 'gyroXFilt', 
% 'gyroYFilt', 'gyroZFilt','rmotorEmfFilt', 'lmotorEmfFilt', 
% 'Q0', 'Q1', 'Q2', 'Q3', 'distX','distY', 'accelOne', 'velX', 'velY'
%
% A sphero object must be created in the workspace before starting the
% simulation.

% Create a Sphero object (if it does not exist)
if ~exist('sph','var'),
    sph = sphero(); % Create a Sphero object
end

% make sure the object is connected
connect(sph);

% ping it
result = ping(sph);

% interrupt the example if ping was not successful
if ~result, 
    disp('Example aborted due to unsuccessful ping');
    return, 
end

% now we can actually perform the simulation: you can move the sphero around 
% to see the components of the acceleration along its 3 body axes changing
sim('accel_sim');

% and close the system when the simulation is terminated
close_system('accel_sim');

f1 = figure(1);
plot(yout(:, 1), yout(:, 2:4)); grid
title('Acceleration of Sphero along its X,Y and Z body axis')
xlabel('time (sec)');ylabel('acceleration');
legend('accelX','accelY','accelZ');

%% Open-loop simulation example using Roll block
%
% <matlab:open('roll_sim') Open the example>

open('roll_sim');

%%
% This example uses the Roll block to move the sphero, along a direction
% specified by a sinusoid, with a constant speed of 70/255. This should 
% move the sphero along a path resembling an eight figure.
% 
% The Read Locator block is used to gather the Sphero's position and velocity.
%
% A sphero object must be created in the workspace before starting the
% simulation.

% Create a Sphero object (if it does not exist)
if ~exist('sph','var'),
    sph = sphero(); % Create a Sphero object
end

% make sure the object is connected
connect(sph);

% ping it
result = ping(sph);

% interrupt the example if ping was not successful
if ~result, 
    disp('Example aborted due to unsuccessful ping');
    return, 
end

% reset the calibration of the Sphero
calibrate(sph, 0);

% now we can actually perform the simulation
sim('roll_sim');

% and close the system when the simulation is terminated
close_system('roll_sim');

f2 = figure(2);
plot(yout(:, 2), yout(:, 3), '*')
title({'x-y position of Sphero when running', 'open-loop simulation example with Roll block'})

%% Open-loop simulation example with Raw Motor block
%
% <matlab:open('rawmotor_sim') Open the example>

open('rawmotor_sim');
%%
% This example uses the Raw Motor block to independently command the
% speed of the two sphero wheels, following two sinusoids with a pi/2 phase
% difference. This should move the sphero along a circular path.
% 
% The Read Locator block is used to gather the Sphero's position and velocity.

% ping the sphero
result = ping(sph);

% interrupt the example if ping was not successful
if ~result, 
    disp('Example aborted due to unsuccessful ping');
    return, 
end

% reset the calibration of the Sphero
calibrate(sph, 0);

% now we can actually perform the simulation
sim('rawmotor_sim');

% and close the system when the simulation is terminated
close_system('rawmotor_sim');

f3 = figure(3);
plot(yout(:, 2), yout(:, 3), '*')
title({'x-y position of Sphero when running', 'open-loop simulation example with Raw Motor block'})

%% Closed-loop simulation example using Roll block
%
% <matlab:open('sph_control_sim') Open the example>

open('sph_control_sim');
%%
% In this example, the "desired speed" block works as a controller. It 
% commands the desired velocity (speed and angle) of the sphero, in order
% to minimize the difference between a reference and the measured position 
% and velocity. 
%
% The reference position and velocity are generated by the
% "Reference" block, depending on a set of points (arranged in a square) 
% to be visited at a particular time. Both point positions and time are 
% parameters of the block.
% 
% The sphero position and velocity are retrieved by the "Read
% Locator" block.

% ping the sphero
result = ping(sph);

% interrupt the example if ping was not successful
if ~result, 
    disp('Example aborted due to unsuccessful ping');
    return, 
end

% reset the calibration of the Sphero
calibrate(sph, 0);

% now we can actually perform the simulation
sim('sph_control_sim');

% and close the system when the simulation is terminated
close_system('sph_control_sim');

f4 = figure(4);
plot(yout(:, 2), yout(:, 3), '*')
title({'x-y position of Sphero when running', 'closed-loop simulation example'})

%%

% Close all figures if required
% close(f1); close(f2); close(f3); close(f4);

% Disconnect the Sphero
disconnect(sph);
%% See Also
% <matlab:showdemo('sphero_examples') Sphero Connectivity Package Examples>

%%
% Copyright 2015, The MathWorks, Inc.