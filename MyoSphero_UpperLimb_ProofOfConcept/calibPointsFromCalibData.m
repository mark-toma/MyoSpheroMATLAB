function [pts,lv] = calibPointsFromCalibData(varargin)
% calibPointsFromCalibData(varargin)
rs = 1;

d = [varargin{:}];
assert( isstruct(d),...
  'Inputs must be structs with identical fields.');
assert( isstruct(d) && isvector(d) && all(isfield(d,{'RU','RL','RH','N'})),...
  'Inputs must be struct containing fields ''RU'', ''RL'', and ''RH''');

% assume proper format of data in struct fields
Nv = [d.N];

% build matrices
M = length(d);
pts = zeros(M,3); % stores calibration points
lv = zeros(1,3);
Ag = zeros(3*sum(Nv),3*(M+1));
bg = zeros(3*sum(Nv),1);
for ii = 1:length(d)
  % for each calibration point, make subblocks of global matrix
  N = d(ii).N;
  RU = d(ii).RU;
  RL = d(ii).RL;
  RH = d(ii).RH;
  A = zeros(3*N,3);
  b = zeros(3*N,1);
  for jj = 1:N
    % for each realization, assign part of submatrices
    r = 3*(jj-1)+1;
    A(r:r+2,:) = [...
      RU(:,1,jj),...
      RU(:,:,jj)*RL(:,1,jj),...
      RU(:,:,jj)*RU(:,:,jj)*RH(:,1,jj)];
    b(3*(jj-1)+1:3*jj) = ...
      RU(:,:,jj)*RU(:,:,jj)*RH(:,3,jj);
  end
  % stuff subblocks into global matrices
  % put A subblock into Ag
  rg = sum(3*Nv(1:ii-1))+1; % insertion row index
  Ag(rg:rg+3*N-1,1:3) = A;
  % but identity subblock in Ag
  cg = 3*(ii-1)+1+3; % insertion column index
  Ag(rg:rg+3*N-1,cg:cg+2) = repmat(-eye(3),[N,1]);
  % put b subblock into bg
  bg(rg:rg+3*N-1) = b;
end

xg = (Ag'*Ag)\(Ag'*bg);

lv = xg(1:3)';
pts = reshape(xg(4:end),3,[])';

end