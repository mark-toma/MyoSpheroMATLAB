classdef MyoSpheroUpperLimb < handle
  properties
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
    appDataPath
  end
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
  end
  
  methods
    %% --- Object management
    function this = MyoSpheroUpperLimb()
      this.lengthUpper = this.DEFAULT_LENGTH_UPPER;
      this.lengthLower = this.DEFAULT_LENGTH_LOWER;
      this.lengthHand = this.DEFAULT_LENGTH_HAND;
      this.DUMMY_FILENAME = fullfile(fileparts(mfilename('fullpath')),this.DUMMY_FILENAME);
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
    function val = get.appDataPath(this)
      val = fullfile(fileparts(mfilename('fullfile')),'appdata');
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
      save(fullfile(this.appDataPath,'cal'),'calib','calibPointsData');
      
      for ii=1:length(calibPointsData)
        calibPointsData(ii)
      end
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
        % initialize graphics
        % TODO draw the task environment
        % this.drawSTL(hxTgfx,'TASK_SPACE.stl',0.5*[1,1,1],0.5);
        this.drawSTL(hx.Ugfx,'LEFT_UPPER.stl','r',0.5);
        this.drawSTL(hx.Lgfx,'LEFT_LOWER.stl','g',0.5);
        this.drawSTL(hx.Hgfx,'LEFT_HAND.stl','b',0.5);
        this.drawTriad(hx.U,100,4);
        this.drawTriad(hx.LU,100,4);
        this.drawTriad(hx.HL,100,4);
        this.drawTriad(hx.F,400,4);
        
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
      
      drawnow;
      
      function val = scaleX(sx)
        val = eye(4);
        val(1,1) = sx;
      end
    end
    
    function animatePlotUpperLimb(this,nameStr,calibStruct,dataStruct)
      % animatePlotUpperLimb(this,nameStr,dataStruct)
      %   Animate a data sequence
      % dispatch timer
      tmr = timer(...
        'executionmode','fixedrate',...
        'period',0.05,...
        'busymode','drop',...
        'timerfcn',@(src,evt)this.animatePlotUpperLimbCallback(src,evt,nameStr,calibStruct,dataStruct),...
        'stopfcn',@(src,evt)delete(src));
      start(tmr);
    end
    function animatePlotUpperLimbCallback(this,src,evt,nameStr,calibStruct,dataStruct)
      %idx = src.TasksExecuted;
      if isempty(src.UserData)
        src.UserData = datenum(evt.Data.time);
      end
      currTime = (datenum(evt.Data.time)-src.UserData)*60*60*24;
      idx = round(currTime*this.SAMPLE_RATE);
      if idx>0 && idx<=dataStruct.numSamples
        dataSample = this.makeDataStruct(...
          dataStruct.RU(:,:,idx),...
          dataStruct.RL(:,:,idx),...
          dataStruct.RH(:,:,idx));
        this.drawPlotUpperLimb(nameStr,calibStruct,dataSample);
      else
        stop(src);
      end
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
  end
end