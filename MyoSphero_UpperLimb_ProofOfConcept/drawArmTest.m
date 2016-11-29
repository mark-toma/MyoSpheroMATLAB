function drawArmTest(cmd,myoSphero,updateRate)
% drawArmTest(cmd,myoSphero,updateRate)
TAG = 'drawArmTest';
tmr = timerfind('tag',TAG);

switch cmd
  case 'start'
    assert( isempty(tmr), 'Cannot run more than one test simultaneously.');
    tmr = timer(...
      'tag','drawArmTest',...
      'executionmode','fixedrate',...
      'period',1/updateRate,...
      'busymode','drop',...
      'timerfcn',@(src,evt)timerFcnDrawArmTest(src,evt,myoSphero,'drawArmTest'));
    start(tmr);
  case 'stop'
    assert( ~isempty(tmr), 'Cannot find running timer.');
    stop(tmr);
    delete(tmr);
  otherwise
    error('Bad command.');
end  
end

function timerFcnDrawArmTest(~,~,myoSphero,name)
% timerFcnDrawArmTest(src,evt,myoSphero)
myoSphero.drawPlotUpperLimb(name);
end