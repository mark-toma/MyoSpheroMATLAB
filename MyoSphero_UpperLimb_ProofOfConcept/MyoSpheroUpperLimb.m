classdef MyoSpheroUpperLimb < handle
  properties
    % handles to the devices
    myoMex
    sphero
    idxHead
    timeOffset = 0
    myoOneIsUpper = true
    lengthUpper
    lengthLower
    lengthHand
    plotTable = {}
  end
  properties (Dependent)
    qU_log
    qL_log
    qH_log
    logLengthsULH
  end
  properties (Constant)
    SPHERO_REMOTE_NAME = 'Sphero-WPP'
    SPHERO_FRAME_RATE  = 50
    SPHERO_FRAME_COUNT = 2
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
      delete(this.myoMex);
    end
    function val = get.qU_log(this)
      if this.myoOneIsUpper
        val = this.myoMex.myoData(1).quat_log;
      else
        val = this.myoMex.myoData(2).quat_log;
      end
    end
    function val = get.qL_log(this)
      if this.myoOneIsUpper
        val = this.myoMex.myoData(2).quat_log;
      else
        val = this.myoMex.myoData(1).quat_log;
      end
    end
    function val = get.qH_log(this)
      val = this.sphero.quat_log;
    end
    function val = get.logLengthsULH(this)
      val = [size(this.qU_log,1),size(this.qL_log,1),size(this.qH_log,1)];
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
      this.sphero.ClearLogs();
      this.myoMex.myoData.clearLogs();
      pause(1);
      
      % Store the time offset in case it's needed later...
      ts = this.sphero.time_log(1);
      tm1 = this.myoMex.myoData(1).timeIMU_log(1);
      tm2 = this.myoMex.myoData(2).timeIMU_log(2);
      % Calculate the minimum time to subtract from sphero.time
      this.timeOffset = ts - max([tm1,tm2]);
      
    end
    
    %% --- Data
    function data = popQuatData(this)
      idxTail = min(this.logLengthsULH);
      % read nn samples starting at idxHead
      idxHead = this.idxHead;
      qU = this.qU_log(idxHead:idxTail,:);
      qL = this.qL_log(idxHead:idxTail,:);
      qH = this.qH_log(idxHead:idxTail,:);
      time = this.sphero.time_log(idxHead:idxTail)-this.timeOffset;
      % update idxHead
      this.idxHead = idxTail + 1;
      % pack data into struct
      data = this.makeDataStruct(time,qU,qL,qH);
    end
    
    
    function drawPlotUpperLimb(this,nameStr)
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
      
      
      % enforce axes properties
      
      % find name in table
      if ~isempty(this.plotTable)
        idx = find(strcmp(nameStr,this.plotTable{:,1}));
        assert(~isempty(idx),'Plot name not found in plotTable.');
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
        % store in plotTable
        this.plotTable{end+1,1} = nameStr; % push name
        this.plotTable{end,2} = hx;        % place handles
      else
        % find transforms
        hx = this.plotTable{idx,2};
      end
      
      % draw current pose
      idxTail = min(this.logLengthsULH);
      qU = this.qU_log(idxTail,:);
      qL = this.qL_log(idxTail,:);
      qH = this.qH_log(idxTail,:);
      if isempty(qU) || isempty(qL) || isempty(qH)
        RU = eye(3);
        RL = eye(3);
        RH = eye(3);
      else
        RU = MyoData.q2r(qU);
        RL = MyoData.q2r(qL);
        RH = MyoData.q2r(qH);
      end
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
    
  end
  methods (Static)
    function data = makeDataStruct(time,qU,qL,qH)
      data.numSamples = length(time);
      data.time = time;
      data.qU = qU;
      data.qL = qL;
      data.qH = qH;
    end
    function drawSTL(h,fname,FC,FA)
      % [v,f,n,c]
      [v,f,~,c] = stlread(fname);
      patch('Faces',f,'Vertices',v,'FaceVertexCData',c,...
        'parent',h,'edgecolor','none',...
        'facecolor',FC,'facealpha',FA);
    end
  end
end
