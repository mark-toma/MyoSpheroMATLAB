%% msul_constraints

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

syms lU lL lH d1x d1y d1z d2x d2y d2z d3x d3y d3z
l  = [lU;lL;lH];
d1 = [d1x;d1y;d1z];
d2 = [d2x;d2y;d2z];
d3 = [d3x;d3y;d3z];
x = [l;d1;d2;d3];

zero = sym('0');
one  = sym('1');
half = sym('1/2');
e1 = [one;zero;zero];
e2 = [zero;one;zero];
e3 = [zero;zero;one];
Z = sym(zeros(3));

rc2c3 = d2-d3;
rc2c1 = d2-d1;
rc3c1 = d3-d1;

%% Orientation constraints cont ...
% five constraints on 9 free parameters
nT = skew(rc2c3)*rc2c1;

% 3 nonlinear constraints
h1 = transpose(e1)*nT; % = 0
h2 = transpose(e2)*nT; % = 0 
h3 = transpose(e3)*nT; % - rc2c1*rc2c3 = 0

[Q1,r1] = f2Q(h1,x)
[Q2,r2] = f2Q(h2,x)
[Q3,r3] = f2Q(h3,x)


S1 = skew(e1);
Q1_ = sym(zeros(12));
Q1_(4:end,4:end) = skewBlock(S1);
all(Q1_(:)==Q1(:))

S2 = skew(e2);
Q2_ = sym(zeros(12));
Q2_(4:end,4:end) = skewBlock(S2);
all(Q2_(:)==Q2(:))

S3 = skew(e3);
Q3_ = sym(zeros(12));
Q3_(4:end,4:end) = skewBlock(S3);
all(Q3_(:)==Q3(:))


%%
% 2 linear constraints ...
h4 = transpose(e3)*rc2c1; % = 0
h5 = transpose(e3)*rc3c1; % = 0

[A4,r4] = b2A(h4,x);
[A5,r5] = b2A(h5,x);

A4 = [ 0, 0, 0, 0, 0, -1, 0, 0, 1, 0, 0, 0]; % h=A*x=0
A5 = [ 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 1]; % h=A*x=0

