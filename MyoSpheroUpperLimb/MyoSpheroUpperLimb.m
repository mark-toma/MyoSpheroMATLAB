classdef MyoSpheroUpperLimb < handle & MyoSpheroUpperLimbConstants
  properties
    DEBUG_FLAG = true
    % handles to the devices
    myoMex
    sphero
    idxHead = 1
    RU_sourceBaseShift = 0
    RL_sourceBaseShift = 0
    RH_sourceBaseShift = 0
    timeOffset = 0
    myoOneIsUpper = true
    lengthUpper
    lengthLower
    lengthHand
    plotTable = {}
    RFNU = eye(3)
    RFNL = eye(3)
    RFNH = eye(3)
    DUMMY_FILENAME = 'do-not-touch-me.mat'
    calibData
    dT
    RT
  end
  properties (Dependent)
    data
    data_log
    logAvailableLengths
    RU_source
    RL_source
    RH_source
    idxTail
    calib
  end
  
  methods
    %% --- Object management
    function this = MyoSpheroUpperLimb()
      this.lengthUpper = this.DEFAULT_LENGTH_UPPER;
      this.lengthLower = this.DEFAULT_LENGTH_LOWER;
      this.lengthHand = this.DEFAULT_LENGTH_HAND;
      this.dT = this.DEFAULT_DT;
      this.RT = this.DEFAULT_RT;
      
      this.DUMMY_FILENAME = fullfile(this.installRootPath(),this.DUMMY_FILENAME);
    end
    function delete(this)
      if ~isempty(this.sphero)
        this.sphero.interruptSensorPolling();
        this.sphero.BackLEDBrightness = 0;
        this.sphero.stabilization(1);
        this.sphero.delete();
      end
      if ~isempty(this.myoMex)
        delete(this.myoMex);
      end
    end
    function val = get.data(this)
      d = this.data_log;
      val = this.makeDataStruct(d.RU(:,:,end),d.RL(:,:,end),d.RH(:,:,end));
    end
    function val = get.data_log(this)
      idx = this.idxHead:this.idxTail;
      val = this.makeDataStruct(...
        this.RU_source(:,:,this.RU_sourceBaseShift+idx),...
        this.RL_source(:,:,this.RL_sourceBaseShift+idx),...
        this.RH_source(:,:,this.RH_sourceBaseShift+idx));
    end
    function val = get.RU_source(this)
      if this.myoOneIsUpper
        val = this.myoMex.myoData(1).rot_log;
      else
        val = this.myoMex.myoData(2).rot_log;
      end
    end
    function val = get.RL_source(this)
      if this.myoOneIsUpper
        val = this.myoMex.myoData(2).rot_log;
      else
        val = this.myoMex.myoData(1).rot_log;
      end
    end
    function val = get.RH_source(this)
      val = this.sphero.rot_log;
    end
    function val = get.logAvailableLengths(this)
      val = [...
        size(this.RU_source,3)-this.RU_sourceBaseShift,...
        size(this.RL_source,3)-this.RL_sourceBaseShift,...
        size(this.RH_source,3)-this.RH_sourceBaseShift];
    end
    function val = get.idxTail(this)
      vals = this.logAvailableLengths();
      val = min(vals);
    end
    function val = get.calib(this)
      val.RFNU = this.RFNU;
      val.RFNL = this.RFNL;
      val.RFNH = this.RFNH;
      % TODO ... and more
    end
    function setCalib(this,val)
      this.RFNU = val.RFNU;
      this.RFNL = val.RFNL;
      this.RFNH = val.RFNH;
    end
    %% --- Device
    function connectDevices(this)
      % connectDevices  Connects to the Myos and Sphero
      
      % Connect Sphero
      this.sphero = sphero(this.SPHERO_REMOTE_NAME);
      this.sphero.Handshake = 1;
      assert( this.sphero.ping()==1,'Sphero failed ping().');
      assert( this.sphero.stabilization(0)==1,'Sphero failed stabilization(0)');
      this.sphero.BackLEDBrightness = 1;
      this.sphero.Color = 'g';
      result = this.sphero.logSensors(...
        this.SPHERO_FRAME_RATE,this.SPHERO_FRAME_COUNT,0,...
        'sensorname',this.SPHERO_SENSORS,...
        'filename',this.DUMMY_FILENAME);
      assert(result==1,'Sphero logSensors(...) failed.');
      
      % Connect Myos
      this.myoMex = MyoMex(2);
      
    end
    
    %% --- Data
    function calibrate(this,calibPointsData)
      calib = this.calib;
      data = calibPointsData;
      params = this.makeCalibParams(calib,data,{'ortho','dist','normalVert'});
      [xs,fval,exitFlag,output,lambda] = this.computeCalibration(params);
      [lengths,dT,RT] = this.interpretCalibResult(xs);
      this.lengthUpper = lengths(1);
      this.lengthLower = lengths(2);
      this.lengthHand  = lengths(3);
      this.dT = dT;
      this.RT = RT;
    end
    function val = popRotData(this)
      % maybe we need to leave a sample in here...
      idxHead = this.idxHead;
      idxTail = this.idxTail;
      idx = idxHead:(idxTail-1); % idxTail;
      % read nn samples starting at idxHead
      val = this.makeDataStruct(...
        this.RU_source(:,:,this.RU_sourceBaseShift+idx),...
        this.RL_source(:,:,this.RL_sourceBaseShift+idx),...
        this.RH_source(:,:,this.RH_sourceBaseShift+idx));
      % update idxHead
      this.idxHead = idxTail; % idxTail + 1;
    end
    function setHomePose(this)
      d = this.data;
      this.RFNU = d.RU;
      this.RFNL = d.RL;
      this.RFNH = d.RH;
    end
    function removePlotUpperLimb(this,nameStr)
      % find name in table
      if ~isempty(this.plotTable)
        idx = find(strcmp(nameStr,this.plotTable{:,1}));
      end
      if ~isempty(idx)
        % pop the idx-th row out of plotTable
        this.plotTable(idx,:) = [];
      end
    end
    function hx = drawPlotUpperLimb(this,nameStr,calibStruct,dataSample)
      % drawPlotUpperLimb(hAxes)
      %
      % Transform structure:
      % F                       Fixed
      % |-- T                   Task
      %     |-- Tgfx            Task graphics
      % |-- U                   Upper arm
      %     |-- Ugfx            Upper arm graphics
      %     |-- LU              Lower arm
      %         |-- Lgfx        Lower arm graphics
      %         |-- HL          Hand
      %             |-- Hgfx    Hand graphics
      
      % TODO validate hAxes
      
      if nargin<3
        calibStruct = [];
        dataSample=[];
      end
      
      % enforce axes properties
      
      % find name in table
      if ~isempty(this.plotTable)
        idx = find(strcmp(nameStr,this.plotTable{:,1}));
      end
      
      if isempty(this.plotTable) || isempty(idx)
        % init plots and store in plotTable
        hx.hFigure = figure();
        colorFig = get(hx.hFigure,'color');
        hx.hAxes = axes('parent',hx.hFigure,...
          'color',colorFig);
        set(hx.hAxes,...
          'nextplot','add',...
          'xlim',700*[-1,1],...
          'ylim',700*[-1,1],...
          'zlim',700*[-1,1],...
          'dataaspectratio',[1,1,1],...
          'xtick',[],'ytick',[],'ztick',[],...
          'xcolor',colorFig,'ycolor',colorFig,'zcolor',colorFig);
        view(180,30);
        lighting(hx.hAxes,'phong');
        % initialize transforms
        hx.F     = hgtransform('parent',hx.hAxes);
        hx.T     = hgtransform('parent',hx.F);
        hx.Tgfx  = hgtransform('parent',hx.T);
        hx.U     = hgtransform('parent',hx.F);
        hx.Ugfx  = hgtransform('parent',hx.U);
        hx.LU    = hgtransform('parent',hx.U);
        hx.Lgfx  = hgtransform('parent',hx.LU);
        hx.HL    = hgtransform('parent',hx.LU);
        hx.Hgfx  = hgtransform('parent',hx.HL);
        hx.SH    = hgtransform('parent',hx.HL);
        % initialize graphics
        % TODO draw the task environment
        this.drawSTL(hx.Tgfx,...
          fullfile(this.installRootPath,'res','TASK_SPACE.stl'),0.5*[1,1,1],0.5);
        this.drawSTL(hx.Ugfx,...
          fullfile(this.installRootPath,'res','LEFT_UPPER.stl'),'r',0.5);
        this.drawSTL(hx.Lgfx,...
          fullfile(this.installRootPath,'res','LEFT_LOWER.stl'),'g',0.5);
        this.drawSTL(hx.Hgfx,...
          fullfile(this.installRootPath,'res','LEFT_HAND.stl'),'b',0.5);
        this.drawTriad(hx.U,100,4);
        this.drawTriad(hx.LU,100,4);
        this.drawTriad(hx.HL,100,4);
        this.drawTriad(hx.SH,100,4);
        this.drawTriad(hx.F,400,4);
        this.drawTriad(hx.T,400,4);
        
        [xs,ys,zs] = sphere(20);
        rs = 38;
        surf(rs*xs,rs*ys,rs*zs,...
          'parent',hx.SH,...
          'facecolor','w',...
          'facealpha',0.5);
        
        % store in plotTable
        this.plotTable{end+1,1} = nameStr; % push name
        this.plotTable{end,2} = hx;        % place handles
      else
        % find transforms
        hx = this.plotTable{idx,2};
      end
      % draw current pose
      if isempty(dataSample)
        % take internal object pose
        d = this.data;
        c = this.calib;
      else
        % take provided pose and calibration
        d = dataSample;
        c = calibStruct;
      end
      %       c
      %       d
      
      RU = d.RU; RL = d.RL; RH = d.RH;
      RFNU = c.RFNU; RFNL = c.RFNL; RFNH = c.RFNH;
      if isempty(RU) || isempty(RL) || isempty(RH)
        RU = eye(3); RL = eye(3); RH = eye(3);
      end
      
      % remove home calibration offset
      RU = RFNU'*RU;
      RL = RFNL'*RL;
      RH = RFNH'*RH;
      
      RLU = RU'*RL;
      RHL = RL'*RH;
      dLU = [this.lengthUpper;0;this.OFFSET_UPPER];
      dHL = [this.lengthLower;0;0];
      
      set(hx.U,'matrix',r2t(RU));
      set(hx.LU,'matrix',rt2tr(RLU,dLU));
      set(hx.HL,'matrix',rt2tr(RHL,dHL));
      
      % scale graphics
      sxU = this.lengthUpper/this.DEFAULT_LENGTH_UPPER;
      sxL = this.lengthLower/this.DEFAULT_LENGTH_LOWER;
      sxH = this.lengthHand/this.DEFAULT_LENGTH_HAND;
      
      set(hx.Ugfx,'matrix',scaleX(sxU));
      set(hx.Lgfx,'matrix',scaleX(sxL));
      set(hx.Hgfx,'matrix',scaleX(sxH));
      
      % sphero
      set(hx.SH,'matrix',rt2tr(eye(3),[this.lengthHand;0;-38]));
      
      % task space update
      set(hx.T,'matrix',rt2tr(this.RT,this.dT));
      
      drawnow;
      
      function val = scaleX(sx)
        val = eye(4);
        val(1,1) = sx;
      end
    end
    
    function animatePlotUpperLimb(this,rate,nameStr,calibStruct,dataStruct)
      % animatePlotUpperLimb(this,nameStr,dataStruct)
      %   Animate a data sequence
      % dispatch timer
      updateRate = 25; % hz
      sampleIncrement = ceil(updateRate/50);
      tmr = timer(...
        'executionmode','fixedrate',...
        'period',updateRate,...
        'taskstoexecute',dataStruct.numSamples,...
        'busymode','queue',...
        'timerfcn',@(src,evt)this.animatePlotUpperLimbCallback(src,evt,nameStr,calibStruct,dataStruct,e,sampleIncrement),...
        'stopfcn',@(src,evt)delete(src));
      start(tmr);
    end
    function animatePlotUpperLimbCallback(this,src,evt,nameStr,calibStruct,dataStruct,sampleIncrement)
      idx = src.UserData; % holds the next index to plot
      if isempty(idx), idx = 1; end
      if idx >= dataStruct.numSamples
        stop(src);
        return;
      end
      dataSample = this.makeDataStruct(...
        dataStruct.RU(:,:,idx),...
        dataStruct.RL(:,:,idx),...
        dataStruct.RH(:,:,idx));
      this.drawPlotUpperLimb(nameStr,calibStruct,dataSample);
      src.UserData = idx+sampleIncrement;
    end
  end
  methods (Static)
    function data = makeDataStruct(RU,RL,RH)
      data.numSamples = size(RU,3);
      data.RU = RU;
      data.RL = RL;
      data.RH = RH;
    end
    function drawSTL(h,fname,FC,FA)
      % [v,f,n,c]
      [v,f,~,c] = stlread(fname);
      patch('Faces',f,'Vertices',v,'FaceVertexCData',c,...
        'parent',h,'edgecolor','none',...
        'facecolor',FC,'facealpha',FA);
    end
    function drawTriad(h,length,thick)
      z = [0,0];
      a = [0,length];
      plot3(h,a,z,z,'r','linewidth',thick);
      plot3(h,z,a,z,'g','linewidth',thick);
      plot3(h,z,z,a,'b','linewidth',thick);
    end
    function fn = timestampedFilename(name,ext)
      ts = datestr(now,'yyyymmdd-HHMMSS');
      fn = sprintf('%s-%s.%s',name,ts,ext);
    end
    function val = installRootPath();
      val = fileparts(mfilename('fullpath'));
    end
    function val = appDataPath()
      val = fullfile(MyoSpheroUpperLimb.installRootPath,'appdata');
    end
    function [Aeq,beq] = planarFun(params)
      Aeq = [];
      beq = [];
      if ~ismember('planar',params.conSpec), return; end
      Aeq = [...
        0, 0, 0, 0, 0, -1, 0, 0, 1, 0, 0,  0;...
        0, 0, 0, 0, 0,  0, 0, 0, 1, 0, 0, -1];
      beq = [0;0];
    end
    function [c,ceq,Dc,Dceq] = nonlinConFunGrad(x,params)
      % nonlinConFunGrad(x,params)
      %
      % Required params:
      %   params.rc2c3
      %   params.rc2c1
      %   params.rc3c1
      % Specifies param:
      %   params.conSpec = Cell array of strings
      %     'dist' - select the distance constraints
      %     'ortho' - xT and yT orthogonal
      %     'normalVert' - nT vertical component
      %     'normalVertIneq' - nT vertical component
      %     'normalHorz' - nT horizontal components
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
        [f,feq,Df,Dfeq] = MyoSpheroUpperLimb.distFunGrad(x,params);
        pushNewCons();
      end
      if ismember('ortho',params.conSpec)
        [f,feq,Df,Dfeq] = MyoSpheroUpperLimb.orthoFunGrad(x,params);
        pushNewCons();
      end
      if ismember('normalVert',params.conSpec)
        [f,feq,Df,Dfeq] = MyoSpheroUpperLimb.normalVertFunGrad(x,params);
        pushNewCons();
      end
      if ismember('normalVertIneq',params.conSpec)
        [f,feq,Df,Dfeq] = MyoSpheroUpperLimb.normalVertIneqFunGrad(x,params);
        pushNewCons();
      end
      if ismember('normalHorz',params.conSpec)
        [f,feq,Df,Dfeq] = MyoSpheroUpperLimb.normalHorzFunGrad(x,params);
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
      Q23 = 2*Qij(2,3);
      Q21 = 2*Qij(2,1);
      Q31 = 2*Qij(3,1);
      function Q = Qij(ii,jj)
        Q = zeros(12);
        Q(3*ii+(1:3),3*ii+(1:3)) = eye(3);
        Q(3*jj+(1:3),3*jj+(1:3)) = eye(3);
        Q(3*ii+(1:3),3*jj+(1:3)) = -eye(3);
        Q(3*jj+(1:3),3*ii+(1:3)) = -eye(3);
      end
      feq(1,1) = 1/2*x'*Q23*x - params.rc2c3'*params.rc2c3;
      feq(1,2) = 1/2*x'*Q21*x - params.rc2c1'*params.rc2c1;
      feq(1,3) = 1/2*x'*Q31*x - params.rc3c1'*params.rc3c1;
      
      Dfeq(:,1) = Q23*x;
      Dfeq(:,2) = Q21*x;
      Dfeq(:,3) = Q31*x;
    end
    function [f,feq,Df,Dfeq] = orthoFunGrad(x,params)
      % h  = 1/2*x'*Q*x = 0
      % Dh = Q*x
      f = []; feq = []; Df = []; Dfeq = [];
      I = eye(3);
      Z = zeros(3);
      Q = [...
        Z,  Z,   Z,  Z;...
        Z,  Z,  -I,  I;...
        Z, -I, 2*I, -I;...
        Z,  I,  -I,  Z];
      feq = 1/2*x'*Q*x;
      Dfeq = Q*x;
    end
    function [f,feq,Df,Dfeq] = normalHorzFunGrad(x,params)
      % h  = 1/2*x'*Q*x - rc2c3j*rc2c1 = 0
      % Dh = Q*x
      f = []; feq = []; Df = []; Dfeq = [];
      Q1 = zeros(12);
      Q2 = zeros(12);
      Z = zeros(3);
      S1 = skew([1;0;0]);
      S2 = skew([0;1;0]);
      inds = 4:12;
      Q1(inds,inds) = skewBlock(S1);
      Q2(inds,inds) = skewBlock(S2);
      feq(1,1) = 1/2*x'*Q1*x;
      Dfeq(:,1) = Q1*x;
      feq(1,2) = 1/2*x'*Q2*x;
      Dfeq(:,2) = Q2*x;
    end
    function [f,feq,Df,Dfeq] = normalVertFunGrad(x,params)
      % h  = 1/2*x'*Q*x - rc2c3j*rc2c1 = 0
      % Dh = Q*x
      f = []; feq = []; Df = []; Dfeq = [];
      Q3 = zeros(12);
      S3 = skew([0;0;1]);
      inds = 4:12;
      Q3(inds,inds) = skewBlock(S3);
      feq(1,1) = 1/2*x'*Q3*x - norm(params.rc2c3)*norm(params.rc2c1);
      Dfeq(:,1) = Q3*x;
    end
    function [f,feq,Df,Dfeq] = normalVertIneqFunGrad(x,params)
      % h  = -1/2*x'*Q*x <= 0
      % Dh = Q*x
      f = []; feq = []; Df = []; Dfeq = [];
      Q3 = zeros(12);
      S3 = skew([0;0;1]);
      inds = 4:12;
      Q3(inds,inds) = skewBlock(S3);
      f(1,1) = 1/2*x'*Q3*x - norm(params.rc2c3)*norm(params.rc2c1);
      Df(:,1) = Q3*x;
    end
    function [Ag,bg] = objFunParams(calibPointsDataHomed,spheroRadius)
      rs = spheroRadius;
      data = calibPointsDataHomed;
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
    function dataHomed = homeData(calib,data)
      dataHomed = data;
      for ii=1:length(data)
        for kk = 1:data(ii).numSamples
          dataHomed(ii).RU(:,:,kk) = calib.RFNU'*data(ii).RU(:,:,kk);
          dataHomed(ii).RL(:,:,kk) = calib.RFNL'*data(ii).RL(:,:,kk);
          dataHomed(ii).RH(:,:,kk) = calib.RFNH'*data(ii).RH(:,:,kk);
        end
      end
    end
    function [f,Df] = objFun(x,params)
      A = params.Ag;
      b = params.bg;
      f = 0.5*x'*A'*A*x - x'*A'*b+b'*b;
      Df = A'*A*x - A'*b;
    end
    function params = makeCalibParams(calib,data,conSpec)
      % About conSpec:
      
      if nargin<3 || isempty(conSpec)
        conSpec = {'dist','ortho','normalVert'};
      end
      
      % make a dummy object to fetch default params
      msc = MyoSpheroUpperLimbConstants();
      
      params.calib = calib;
      params.data = data;
      
      dataHomed = MyoSpheroUpperLimb.homeData(calib,data);
      params.dataHomed = dataHomed;
      
      [Ag,bg] = MyoSpheroUpperLimb.objFunParams(dataHomed,38);
      params.Ag = Ag;
      params.bg = bg;
      
      params.dT0 = msc.DEFAULT_DT;
      
      params.lengthUpper = msc.DEFAULT_LENGTH_UPPER;
      params.lengthLower = msc.DEFAULT_LENGTH_LOWER;
      params.lengthHand  = msc.DEFAULT_LENGTH_HAND;
      
      params.rc2c1 = msc.rc2c1;
      params.rc2c3 = msc.rc2c3;
      params.rc3c1 = msc.rc3c1;
      
      params.conSpec = conSpec;
      
    end
    function [xs,fval,exitFlag,output,lambda] = computeCalibration(params)
      
      LB = [0;0;0;-inf(9,1)];
      UB = inf(12,1);
      Aeq = []; beq = [];
      [Aeq_,beq_] = MyoSpheroUpperLimb.planarFun(params);
      Aeq = [Aeq;Aeq_]; beq = [beq;beq_];
      A = []; b = [];
      x0 = [...
        params.lengthUpper;...
        params.lengthLower;...
        params.lengthHand;...
        params.dT0 - params.rc2c1;...
        params.dT0;...
        params.dT0 - params.rc2c3];
      optimOpts = optimoptions('fmincon',...
        'display','iter',...
        'gradobj','on',...
        'gradconstr','on');
      objFunGrad = @(x)MyoSpheroUpperLimb.objFun(x,params);
      nonlinConFunGrad = @(x)MyoSpheroUpperLimb.nonlinConFunGrad(x,params);
      [xs,fval,exitFlag,output,lambda] = ...
        fmincon(objFunGrad,x0,...
        A,b,Aeq,beq,LB,UB,...
        nonlinConFunGrad,...
        optimOpts);
      if exitFlag<1
        warning('Calibration may not be successful!');
      end
    end
    function [lengths,dT,RT] = interpretCalibResult(xs)
      
      lengths = xs(1:3);
      
      dc1 = xs(4:6);
      dc2 = xs(7:9);
      dc3 = xs(10:12);
      rc2c3 = dc2-dc3;
      rc2c1 = dc2-dc1;
      rc3c1 = dc3-dc1;
      
      dT = dc2;
      
      xT = rc2c3/norm(rc2c3);
      yT = rc2c1/norm(rc2c1);
      zT = skew(xT)*yT;
      RT = [xT,yT,zT];
      
      %%%
      % DEBUG STUFF BELOW ...
      
      msc = MyoSpheroUpperLimbConstants();
      
      nT = skew(rc2c3)*rc2c1;
      
      % relative vector lengths
      fprintf('dist\n');
      fprintf('rc2c1 delta = %f\n',abs(norm(msc.rc2c1)-norm(rc2c1)));
      fprintf('rc2c3 delta = %f\n',abs(norm(msc.rc2c3)-norm(rc2c3)));
      fprintf('rc3c1 delta = %f\n',abs(norm(msc.rc3c1)-norm(rc3c1)));
      fprintf('\n');
      
      % check xT,yT orthogonality
      fprintf('ortho\n');
      fprintf('xT''*yT = %f\n',xT'*yT)
      fprintf('\n');
      
      % check xT,yT vertical components
      fprintf('planar\n');
      fprintf('xT(3) = %f\n',xT(3));
      fprintf('yT(3) = %f\n',yT(3));
      fprintf('\n');
      
      fprintf('normalHorz\n');
      fprintf('nT(1) = %f\n',nT(1));
      fprintf('nT(2) = %f\n',nT(2));
      fprintf('\n');
      
      fprintf('normalVert\n');
      fprintf('nT(3) delta = %f\n',nT(3)-norm(rc2c3)*norm(rc2c1));
      fprintf('\n');
      
    end
  end
end
