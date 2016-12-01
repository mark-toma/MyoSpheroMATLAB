classdef MyoSpheroUpperLimb < handle
  properties
    % handles to the devices
    myoMex
    sphero
    idxHead = 1
    timeOffset = 0
    myoOneIsUpper = true
    myoSamplesAdvance = 0
    lengthUpper
    lengthLower
    lengthHand
    plotTable = {}
    RFNU = eye(3)
    RFNL = eye(3)
    RFNH = eye(3)
  end
  properties (Dependent)
    RU_log
    RL_log
    RH_log
    logLengthsULH
    calibStruct
  end
  properties (Constant)
    SPHERO_REMOTE_NAME = 'Sphero-WPP'
    SPHERO_FRAME_RATE  = 50 % 50
    SPHERO_FRAME_COUNT = 4 % 2
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
    end
    function delete(this)
      if ~isempty(this.sphero)
        this.sphero.SetDataStreaming(400,1,1,{});
        this.sphero.SetBackLEDOutput(0);
        this.sphero.SetStabilization(true);
        delete(this.sphero);
      end
      if ~isempty(this.myoMex)
        delete(this.myoMex);
      end
    end
    
    function val = get.RU_log(this)
      if this.myoOneIsUpper
        val = this.myoMex.myoData(1).rot_log;
      else
        val = this.myoMex.myoData(2).rot_log;
      end
    end
    function val = get.RL_log(this)
      if this.myoOneIsUpper
        val = this.myoMex.myoData(2).rot_log;
      else
        val = this.myoMex.myoData(1).rot_log;
      end
    end
    function val = get.RH_log(this)
      val = this.sphero.rot_log;
    end
    function val = get.logLengthsULH(this)
      val = [size(this.RU_log,3),size(this.RL_log,3),size(this.RH_log,3)];
    end
    function val = get.calibStruct(this)
      val.RFNU = this.RFNU;
      val.RFNL = this.RFNL;
      val.RFNH = this.RFNH;
      % ... and more
    end
    
    %% --- Device
    function connectDevices(this)
      % connectDevices  Connects to the Myos and Sphero
      
      % Connect Sphero
      this.sphero = Sphero(this.SPHERO_REMOTE_NAME);
      assert( ~this.sphero.Ping(),'Sphero failed Ping().');
      this.sphero.SetStabilization(false);
      this.sphero.SetBackLEDOutput(1);
      this.sphero.SetDataStreaming(...
        this.SPHERO_FRAME_RATE,...
        this.SPHERO_FRAME_COUNT,...
        0,...
        {'quat'});
      
      % Connect Myos
      this.myoMex = MyoMex(2);
      
      % Simply clear logs on both objects (assumed instantaneously) to sync
      this.clearLogs();
      pause(1);
      
      % Store the time offset in case it's needed later...
      ts = this.sphero.time_log(1);
      tm1 = this.myoMex.myoData(1).timeIMU_log(1);
      tm2 = this.myoMex.myoData(2).timeIMU_log(2);
      % Calculate the minimum time to subtract from sphero.time
      this.timeOffset = ts - max([tm1,tm2]);
      
    end
    
    %% --- Data
    function clearLogs(this)
      this.myoMex.myoData.clearLogs();
      this.sphero.ClearLogs();
      this.idxHead = 1;
    end
    function data = popRotData(this)
      idxTail = min(this.logLengthsULH)
      % read nn samples starting at idxHead
      idxHead = this.idxHead
      size(this.sphero.time_log)
      RU = this.RU_log(:,:,idxHead:idxTail);
      RL = this.RL_log(:,:,idxHead:idxTail);
      RH = this.RH_log(:,:,idxHead:idxTail);
      time = this.sphero.time_log(idxHead:idxTail)-this.timeOffset;
      % update idxHead
      this.idxHead = idxTail + 1;
      % pack data into struct
      data = this.makeDataStruct(time,RU,RL,RH);
    end
    
    function setHomePose(this)
      idxTail = min(this.logLengthsULH);
      this.RFNU = this.RU_log(:,:,idxTail);
      this.RFNL = this.RL_log(:,:,idxTail);
      this.RFNH = this.RH_log(:,:,idxTail);
    end
    
    function drawPlotUpperLimb(this,nameStr,calibStruct,dataSample)
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
        hx.hAxes = axes;
        colorFig = get(get(hx.hAxes,'parent'),'color');
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
        idxTail = min(this.logLengthsULH);
        %RU = this.RU_log(:,:,end);
        %RL = this.RL_log(:,:,end);
        %RH = this.RH_log(:,:,end);
        RU = this.RU_log(:,:,idxTail);
        RL = this.RL_log(:,:,idxTail);
        RH = this.RH_log(:,:,idxTail);
        if isempty(RU) || isempty(RL) || isempty(RH)
          RU = eye(3);
          RL = eye(3);
          RH = eye(3);
        end
        RFNU = this.RFNU;
        RFNL = this.RFNL;
        RFNH = this.RFNH;
      else
        % take provided pose
        RU = dataSample.RU;
        RL = dataSample.RL;
        RH = dataSample.RH;
        RFNU = calibStruct.RFNU;
        RFNL = calibStruct.RFNL;
        RFNH = calibStruct.RFNH;
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
        'stopfcn',@(src,~)delete(src));
      start(tmr);
    end
    function animatePlotUpperLimbCallback(this,src,evt,nameStr,calibStruct,dataStruct)
      %idx = src.TasksExecuted;
      if isempty(src.UserData)
        src.UserData = datenum(evt.Data.time);
      end
      currTime = (datenum(evt.Data.time)-src.UserData)*60*60*24;
      timeVec = dataStruct.time - dataStruct.time(1);
      idx = find(timeVec>=currTime,1,'first');
      if ~isempty(idx)
        dataSample = this.makeDataStruct(...
          dataStruct.time(idx),...
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
    function data = makeDataStruct(time,RU,RL,RH)
      data.numSamples = length(time);
      data.time = time;
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
