function varargout = MyoSpheroUpperLimbGUI_ControlPanel(varargin)
% MYOSPHEROUPPERLIMBGUI_CONTROLPANEL MATLAB code for MyoSpheroUpperLimbGUI_ControlPanel.fig
%      MYOSPHEROUPPERLIMBGUI_CONTROLPANEL, by itself, creates a new MYOSPHEROUPPERLIMBGUI_CONTROLPANEL or raises the existing
%      singleton*.
%
%      H = MYOSPHEROUPPERLIMBGUI_CONTROLPANEL returns the handle to a new MYOSPHEROUPPERLIMBGUI_CONTROLPANEL or the handle to
%      the existing singleton*.
%
%      MYOSPHEROUPPERLIMBGUI_CONTROLPANEL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MYOSPHEROUPPERLIMBGUI_CONTROLPANEL.M with the given input arguments.
%
%      MYOSPHEROUPPERLIMBGUI_CONTROLPANEL('Property','Value',...) creates a new MYOSPHEROUPPERLIMBGUI_CONTROLPANEL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before MyoSpheroUpperLimbGUI_ControlPanel_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to MyoSpheroUpperLimbGUI_ControlPanel_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help MyoSpheroUpperLimbGUI_ControlPanel

% Last Modified by GUIDE v2.5 03-Dec-2016 20:05:26

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @MyoSpheroUpperLimbGUI_ControlPanel_OpeningFcn, ...
                   'gui_OutputFcn',  @MyoSpheroUpperLimbGUI_ControlPanel_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before MyoSpheroUpperLimbGUI_ControlPanel is made visible.
function MyoSpheroUpperLimbGUI_ControlPanel_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to MyoSpheroUpperLimbGUI_ControlPanel (see VARARGIN)

handles.ms = MyoSpheroUpperLimb();

handles.updateTimer = timer(...
  'tag','myoSpheroUpperLimbGUI_VisualMonitor',...
  'executionmode','fixedrate',...
  'period',0.08,...
  'busymode','drop',...
  'timerfcn',@(src,evt)updateTimerCallback(src,evt,handles.ms,'myoSpheroUpperLimbGUI_VisualMonitor'));

% Choose default command line output for MyoSpheroUpperLimbGUI_ControlPanel
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes MyoSpheroUpperLimbGUI_ControlPanel wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = MyoSpheroUpperLimbGUI_ControlPanel_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
varargout{2} = handles.ms;


function cal_pnt_Dispatch(pb,duration,handles)
%{
handles.ms.popRotData();
tmr = timer(...
  'tag','myoSpheroUpperLimbGUI_cal_pnt',...
  'startdelay',duration,...
  'timerfcn',@(src,evt)cal_pnt_Callback(src,evt,pb,handles));
start(tmr);
wait(tmr);
delete(tmr);
%}

handles.ms.popRotData(); % toss data
fprintf('Beginning %3.1f second procedure...\n',duration);
tic;
t = toc;
fprintf('\tElapsed time = ');
fprintf('%3.1f[s]\n',t);  
while t < duration
  pause(0.1)
  fprintf('\b\b\b\b\b\b\b%3.1f[s]\n',t);
  t = toc;
end
data = handles.ms.popRotData();
set(pb,...
  'userdata',data,...
  'backgroundcolor',[0,1,0]);


function updateTimerCallback(src,evt,myoSphero,nameStr)
% myoSphero.sphero
myoSphero.drawPlotUpperLimb(nameStr);


% --- Executes on button press in pb_connectDevices.
function pb_connectDevices_Callback(hObject, eventdata, handles)
% hObject    handle to pb_connectDevices (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(hObject,'enable','off');
try handles.ms.connectDevices
catch e
  warndlg(...
    sprintf('There was an error in connectDevices: %s',e.message),...
    'Connection Error!','modal');
  set(hObject,'enable','on');
end


% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~isempty(handles.ms)
  delete(handles.ms);
end
if ~isempty(handles.updateTimer)
  delete(handles.updateTimer);
end


% --- Executes on slider movement.
function sl_RU_sourceBaseShift_Callback(hObject, eventdata, handles)
% hObject    handle to sl_RU_sourceBaseShift (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
val = round(get(hObject,'value'));
set(hObject,'value',val);
set(handles.st_RU_sourceBaseShift,'string',...
  sprintf('%s = %d','RU_sourceBaseShift',val));
handles.ms.RU_sourceBaseShift = val;


% --- Executes during object creation, after setting all properties.
function sl_RU_sourceBaseShift_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sl_RU_sourceBaseShift (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function sl_RL_sourceBaseShift_Callback(hObject, eventdata, handles)
% hObject    handle to sl_RL_sourceBaseShift (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
val = round(get(hObject,'value'));
set(hObject,'value',val);
set(handles.st_RL_sourceBaseShift,'string',...
  sprintf('%s = %d','RL_sourceBaseShift',val));
handles.ms.RL_sourceBaseShift = val;


% --- Executes during object creation, after setting all properties.
function sl_RL_sourceBaseShift_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sl_RL_sourceBaseShift (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function sl_RH_sourceBaseShift_Callback(hObject, eventdata, handles)
% hObject    handle to sl_RH_sourceBaseShift (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
val = round(get(hObject,'value'));
set(hObject,'value',val);
set(handles.st_RH_sourceBaseShift,'string',...
  sprintf('%s = %d','RH_sourceBaseShift',val));
handles.ms.RH_sourceBaseShift = val;


% --- Executes during object creation, after setting all properties.
function sl_RH_sourceBaseShift_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sl_RH_sourceBaseShift (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in pb_visual_monitor.
function pb_visual_monitor_Callback(hObject, eventdata, handles)
% hObject    handle to pb_visual_monitor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ud = get(hObject,'userdata');
if isempty(ud)
  hx = handles.ms.drawPlotUpperLimb('myoSpheroUpperLimbGUI_VisualMonitor');
  ud.hx = hx;
  
  start(handles.updateTimer);
  set(hObject,'userdata',ud);
else
  hx = ud.hx;
  stop(handles.updateTimer);
  pause(1);
  delete(hx.hFigure);
  handles.ms.removePlotUpperLimb('myoSpheroUpperLimbGUI_VisualMonitor');
  set(hObject,'userdata',[]);
end


% --- Executes on button press in cb_myoOneIsUpper.
function cb_myoOneIsUpper_Callback(hObject, eventdata, handles)
% hObject    handle to cb_myoOneIsUpper (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_myoOneIsUpper
handles.ms.myoOneIsUpper = get(hObject,'value')==1;


% --- Executes on button press in pb_setHomePose.
function pb_setHomePose_Callback(hObject, eventdata, handles)
% hObject    handle to pb_setHomePose (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.ms.setHomePose();


% --- Executes on button press in pb_cal_pnt_1.
function pb_cal_pnt_1_Callback(hObject, eventdata, handles)
% hObject    handle to pb_cal_pnt_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cal_pnt_Dispatch(hObject,5,handles);


% --- Executes on button press in pb_cal_pnt_2.
function pb_cal_pnt_2_Callback(hObject, eventdata, handles)
% hObject    handle to pb_cal_pnt_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cal_pnt_Dispatch(hObject,5,handles);


% --- Executes on button press in pb_cal_pnt_3.
function pb_cal_pnt_3_Callback(hObject, eventdata, handles)
% hObject    handle to pb_cal_pnt_3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cal_pnt_Dispatch(hObject,5,handles);


% --- Executes on button press in pb_calibrate.
function pb_calibrate_Callback(hObject, eventdata, handles)
% hObject    handle to pb_calibrate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

dataC1 = get(handles.pb_cal_pnt_1,'userdata');
dataC2 = get(handles.pb_cal_pnt_2,'userdata');
dataC3 = get(handles.pb_cal_pnt_3,'userdata');

if isempty(dataC1) || isempty(dataC2) || isempty(dataC3)
  warndlg('Must capture calibration data for all three points.',...
    'Calibration Data Incomplete!','modal');
  return;
end

% now we have three calibration data sets.
% send them to the calibration points function
handles.ms.calibrate([dataC1,dataC2,dataC3]);
