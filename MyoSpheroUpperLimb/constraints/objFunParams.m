function [Ag,bg] = objFunParams(params)
rs   = params.SPHERO_RADIUS;
data = params.calibPointsDataHomed;

M = length(data); % should be 3 points

% assume proper format of data in struct fields
Pvec = [data.numSamples];

% build matrices
Ag = zeros(3*sum(Pvec),3*(M+1));
bg = zeros(3*sum(Pvec),1);
for ii = 1:length(data)
  % for each calibration point, make subblocks of global matrix
  P = Pvec(ii);
  RU = data(ii).RU;
  RL = data(ii).RL;
  RH = data(ii).RH;
  A = zeros(3*P,3);
  b = zeros(3*P,1);
  for kk = 1:P
    % for each realization, assign part of submatrices
    r = 3*(kk-1)+1;
    A(r:r+2,:) = [RU(:,1,kk),RL(:,1,kk),RH(:,1,kk)];
    b(3*(kk-1)+1:3*kk) = rs*RH(:,3,kk);
  end
  % stuff subblocks into global matrices
  % put A subblock into Ag
  rg = 3*sum(Pvec(1:ii-1))+1; % insertion row index
  Ag(rg:rg+3*P-1,1:3) = A;
  % put identity subblock in Ag
  cg = 3*(ii-1)+1+3; % insertion column index
  Ag(rg:rg+3*P-1,cg:cg+2) = repmat(-eye(3),[P,1]);
  % put b subblock into bg
  bg(rg:rg+3*P-1) = b;
end


end