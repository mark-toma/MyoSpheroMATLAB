function [c,ceq,Dc,Dceq] = nonlinConFunGrad(x,params)
% nonlinConFunGrad(x,params)
%
% Required params:
%   params.rc2c3
%   params.rc2c1
%   params.rc3c1
% Specifies param:
%   params.nonlinConFunGradSpec = Cell array of strings
%     'dist' - select the distance constraints
%     'orient' - select the orientation constraint
%     'distIneq' - optionally select the inequality formulation for dist
%     'orientIneq' - optionally select the inequality formulation for orient
%
% Note on dimensions of constraintf f and constraint gradients Df...
%   * List scalar constraints across the columns of a row vector.
%   * List column vector constraint gradients across the corresponding
%     columns of a matrx.

c = [];
ceq = [];
Dc = [];
Dceq = [];

if ismember('dist',params.conSpec)
  [f,feq,Df,Dfeq] = distFunGrad(x,params);
  pushNewCons();
end

if ismember('orientNormal',params.conSpec)
  [f,feq,Df,Dfeq] = orientNormalFunGrad(x,params);
  pushNewCons();
end

  function pushNewCons()
    c = [c,f];
    ceq = [ceq,feq];
    Dc = [Dc,Df];
    Dceq = [Dceq,Dfeq];
  end

end

function [f,feq,Df,Dfeq] = distFunGrad(x,params)
% hij  = 1/2*x'*Qij*x - rcicj^2 = 0; i=2,2,3; j=3,1,1
% Dhij = Qij*x
f = []; feq = []; Df = []; Dfeq = [];

Z = zeros(3);
I = eye(3);
Q23 = 2*[...
  Z, Z,  Z,  Z;...
  Z, Z,  Z,  Z;...
  Z, Z,  I, -I;...
  Z, Z, -I,  I];
Q21 = 2*[...
  Z,  Z,  Z, Z;...
  Z,  I, -I, Z;...
  Z, -I,  I, Z;...
  Z,  Z,  Z, Z];
Q31 = 2*[...
  Z,  Z,  Z,  Z;...
  Z,  I,  Z, -I;...
  Z,  Z,  Z,  Z;...
  Z, -I,  Z,  I];

if ismember('distIneq',params.conSpec)
  error('Spec ''distIneq'' not yet supported');
else
  feq(1,1) = 1/2*x'*Q23*x - params.rc2c3'*params.rc2c3;
  feq(1,2) = 1/2*x'*Q21*x - params.rc2c1'*params.rc2c1;
  feq(1,3) = 1/2*x'*Q31*x - params.rc3c1'*params.rc3c1;
  
  Dfeq(:,1) = Q23*x;
  Dfeq(:,2) = Q21*x;
  Dfeq(:,3) = Q31*x;
end
end

function [f,feq,Df,Dfeq] = orientNormalFunGrad(x,params)
% h  = 1/2*x'*Q*x - rc2c3j*rc2c1 = 0
% Dh = Q*x
f = []; feq = []; Df = []; Dfeq = [];

Q1 = zeros(12);
Q2 = zeros(12);
Q3 = zeros(12);

Z = zeros(3);
S1 = skew([1;0;0]);
S2 = skew([0;1;0]);
S3 = skew([0;0;1]);
inds = 4:12;
Q1(inds,inds) = skewBlock(S1);
Q2(inds,inds) = skewBlock(S2);
Q3(inds,inds) = skewBlock(S3);

if ismember('orientNormalIneq',params.conSpec)
  error('Spec ''orientNormalIneq'' not yet supported');
else
  feq(1,1) = 1/2*x'*Q1*x;
  Dfeq(:,1) = Q1*x;
  feq(1,2) = 1/2*x'*Q2*x;
  Dfeq(:,2) = Q2*x;
  feq(1,3) = 1/2*x'*Q3*x - norm(params.rc2c3)*norm(params.rc2c1);
  Dfeq(:,3) = Q3*x;
end

end
