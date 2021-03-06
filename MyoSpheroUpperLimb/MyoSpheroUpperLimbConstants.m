classdef (HandleCompatible) MyoSpheroUpperLimbConstants < handle
  properties (Constant)
    SAMPLE_RATE = 50
    SPHERO_REMOTE_NAME = 'Sphero-WPP'
    SPHERO_FRAME_RATE  = 50 % 50
    SPHERO_FRAME_COUNT = 4 % 2
    SPHERO_SENSORS = {'Q0','Q1','Q2','Q3'}
    % the upper dims conform to: dLU = [LENGTH;0;OFFSET]
    DEFAULT_LENGTH_UPPER = 280
    OFFSET_UPPER = 35
    DEFAULT_LENGTH_LOWER = 290
    % default dSH = [LENGTH_HAND;0;-38(radius of sphero)]
    DEFAULT_LENGTH_HAND  = 50
    RADIUS_SPHERO = 38
    
    % geometry
    rc2c1 = [0;197.67;0];
    rc2c3 = [350.07;0;0];
    rc3c1 = [-350.07;197.67;0];
    
    DEFAULT_DT = [300;-250;-250];
    DEFAULT_RT = eye(3);
    
  end
end