%% msul_constraints
% derivation on constraint formulas

clear all; close all; clc;

% Calibration fixture diagram
%
%          o c1
%          |
%          | rc2c1
%          |
%         \|/
% xT<----- o <----------------o c3
%       zT |c2     rc2c3
%          |
%         \|/
%          yT

%% Initialize

syms lU lL lH d1x d1y d1z d2x d2y d2z d3x d3y d3z
% calculated variables
l  = [lU;lL;lH];
d1 = [d1x;d1y;d1z];
d2 = [d2x;d2y;d2z];
d3 = [d3x;d3y;d3z];
x = [l;d1;d2;d3];
rc2c3 = d2-d3;
rc2c1 = d2-d1;
rc3c1 = d3-d1;

% constants
zero = sym('0');
one  = sym('1');
half = sym('1/2');
e1 = [one;zero;zero];
e2 = [zero;one;zero];
e3 = [zero;zero;one];
S1 = skew(e1);
S2 = skew(e2);
S3 = skew(e3);
Z = sym(zeros(3));
I = eye(3);

%% Geometry constraints

h = transpose(rc2c3)*rc2c3
[Q,r]=f2Q(h,x)

Q23 = 2*[...
  Z, Z,  Z,  Z;...
  Z, Z,  Z,  Z;...
  Z, Z,  I, -I;...
  Z, Z, -I,  I];

h = transpose(rc2c1)*rc2c1
[Q,r]=f2Q(h,x)

Q21 = 2*[...
  Z,  Z,  Z, Z;...
  Z,  I, -I, Z;...
  Z, -I,  I, Z;...
  Z,  Z,  Z, Z];

h = transpose(rc3c1)*rc3c1
[Q,r]=f2Q(h,x)

Q31 = 2*[...
  Z,  Z,  Z,  Z;...
  Z,  I,  Z, -I;...
  Z,  Z,  Z,  Z;...
  Z, -I,  Z,  I];

%% ortho

% dot product of xT and yT
h = transpose(rc2c3)*rc2c1
[Q_,r]=f2Q(h,x)

Q = [...
  Z,  Z,   Z,  Z;...
  Z,  Z,  -I,  I;...
  Z, -I, 2*I, -I;...
  Z,  I,  -I,  Z];


%% Orientation constraints - normalVert and normalHorz
% Only the variable terms are calculated.
% There are five constraints on 9 free parameters.
% The first 3 are nonlinear (quadratic), and they enforce the fact that the
% normal to the calibration plane nT is parallel to zF.
%   h1 = 1/2*x'*Q1*x               = 0 % nT(1) = 0
%   h2 = 1/2*x'*Q2*x               = 0 % nT(2) = 0
%   h2 = 1/2*x'*Q2*x - rc2c3*rc2c1 = 0 % nT(3) = rc2c3*rc2c1
% The next two are linear, and they enforce that the two

nT = skew(rc2c3)*rc2c1;

% 3 nonlinear constraints
h1 = transpose(e1)*nT; % = 0
h2 = transpose(e2)*nT; % = 0 
h3 = transpose(e3)*nT; % - rc2c1*rc2c3 = 0

[Q1,r1] = f2Q(h1,x)
[Q2,r2] = f2Q(h2,x)
[Q3,r3] = f2Q(h3,x)

Q1_ = sym(zeros(12));
Q1_(4:end,4:end) = skewBlock(S1);
all(Q1_(:)==Q1(:))

Q2_ = sym(zeros(12));
Q2_(4:end,4:end) = skewBlock(S2);
all(Q2_(:)==Q2(:))

Q3_ = sym(zeros(12));
Q3_(4:end,4:end) = skewBlock(S3);
all(Q3_(:)==Q3(:))


%%
% 2 linear constraints ...
h4 = transpose(e3)*rc2c1; % = 0
h5 = transpose(e3)*rc2c3; % = 0

[A4,r4] = b2A(h4,x);
[A5,r5] = b2A(h5,x);

% A4 = [ 0, 0, 0, 0, 0, -1, 0, 0, 1, 0, 0,  0]; % h=A*x=0
% A5 = [ 0, 0, 0, 0, 0,  0, 0, 0, 1, 0, 0, -1]; % h=A*x=0

