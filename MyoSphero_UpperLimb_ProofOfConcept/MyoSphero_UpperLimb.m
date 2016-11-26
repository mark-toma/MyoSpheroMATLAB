function varargout = MyoSphero_UpperLimb(varargin)
% MYOSPHERO_UPPERLIMB MATLAB code for MyoSphero_UpperLimb.fig
%      MYOSPHERO_UPPERLIMB, by itself, creates a new MYOSPHERO_UPPERLIMB or raises the existing
%      singleton*.
%
%      H = MYOSPHERO_UPPERLIMB returns the handle to a new MYOSPHERO_UPPERLIMB or the handle to
%      the existing singleton*.
%
%      MYOSPHERO_UPPERLIMB('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MYOSPHERO_UPPERLIMB.M with the given input arguments.
%
%      MYOSPHERO_UPPERLIMB('Property','Value',...) creates a new MYOSPHERO_UPPERLIMB or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before MyoSphero_UpperLimb_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to MyoSphero_UpperLimb_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help MyoSphero_UpperLimb

% Last Modified by GUIDE v2.5 09-Jun-2016 05:24:07

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @MyoSphero_UpperLimb_OpeningFcn, ...
                   'gui_OutputFcn',  @MyoSphero_UpperLimb_OutputFcn, ...
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


% --- Executes just before MyoSphero_UpperLimb is made visible.
function MyoSphero_UpperLimb_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to MyoSphero_UpperLimb (see VARARGIN)

% constants
handles.const.COUNT_MYOS = 2;
handles.const.UPDATE_RATE = 25;
handles.const.START_DELAY = 2;
handles.const.LENGTH_UPPER = 280;
handles.const.RADIUS_UPPER = 60;
handles.const.LENGTH_LOWER = 290.03;
handles.const.RADIUS_LOWER = 35;
handles.const.RADIUS_HAND = 110;
handles.const.THICK_HAND = 30;
total_length = handles.const.LENGTH_UPPER + handles.const.LENGTH_LOWER + 2*handles.const.RADIUS_HAND;
handles.const.XLIM = total_length*[-1,1];
handles.const.YLIM = total_length*[-1,1];
handles.const.ZLIM = total_length*[-1,1];
handles.const.SPHERO_REMOTE_NAME_DEFAULT = 'Sphero-WPP';
handles.const.SPHERO_FRAME_RATE = 50;
handles.const.SPHERO_FRAME_COUNT = 2;

% variables
handles.R0Upper = eye(3);
handles.R0Lower = eye(3);
handles.R0Hand = eye(3);

handles.myoMex = [];
handles.sphero = [];
handles.updateTimer = timer(...
  'executionmode','fixedrate',...
  'period',1/handles.const.UPDATE_RATE,...
  'startdelay',handles.const.START_DELAY,...
  'timerfcn',@(src,evt)update_ax_main(src,evt,hObject));

set(handles.et_sphero_remote_name,...
  'string',handles.const.SPHERO_REMOTE_NAME_DEFAULT);

% set up axes
colorFig = get(hObject,'color');
set(handles.ax_main,...
  'nextplot','add',...
  'xlim',handles.const.XLIM,...
  'ylim',handles.const.YLIM,...
  'zlim',handles.const.ZLIM,...
  'dataaspectratio',[1,1,1],...
  'xtick',[],'ytick',[],'ztick',[],...
  'xcolor',colorFig,'ycolor',colorFig,'zcolor',colorFig);%,...
  %'color',colorFig);
view(handles.ax_main,-180,5);

% plot transform tree
handles.hxWorld = hgtransform('parent',handles.ax_main);

handles.hxUpper = hgtransform('parent',handles.hxWorld);
handles.hxUpperMesh = hgtransform('parent',handles.hxUpper);

handles.hxLower = hgtransform('parent',handles.hxUpper,...
  'matrix',makehgtform('translate',handles.const.LENGTH_UPPER,0,0));
handles.hxLowerMesh = hgtransform('parent',handles.hxLower);

handles.hxHand  = hgtransform('parent',handles.hxLower,...
  'matrix',makehgtform('translate',handles.const.LENGTH_LOWER,0,0));
handles.hxHandMesh = hgtransform('parent',handles.hxHand);

% plot stuff
drawTriad(handles.hxWorld,200,1);

FA = 0.8;

drawTriad(handles.hxUpper,100,2);
% drawArm(handles.hxUpper,...
%   handles.const.RADIUS_UPPER,handles.const.LENGTH_UPPER,...
%   'r',0.2);
drawSTL(handles.hxUpperMesh,'LEFT_UPPER.stl',...
  'r',FA);

drawTriad(handles.hxLower,100,2);
% drawArm(handles.hxLower,...
%   handles.const.RADIUS_LOWER,handles.const.LENGTH_LOWER,...
%   'g',0.2);
drawSTL(handles.hxLowerMesh,'LEFT_LOWER.stl',...
  'g',FA);

drawTriad(handles.hxHand,100,2);
% drawHand(handles.hxHand,...
%   handles.const.RADIUS_HAND,handles.const.THICK_HAND,...
%   'b',0.2);
drawSTL(handles.hxHandMesh,'LEFT_HAND.stl',...
  'b',FA);

lighting('phong')


% Choose default command line output for MyoSphero_UpperLimb
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes MyoSphero_UpperLimb wait for user response (see UIRESUME)
% uiwait(handles.figure1);

start(handles.updateTimer);

% --- Outputs from this function are returned to the command line.
function varargout = MyoSphero_UpperLimb_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Draw coordinate frame
function drawTriad(h,S,LW)

e = [0,1]; z = [0,0];
plot3(h,S*e,z,z,'r','linewidth',LW);
plot3(h,z,S*e,z,'g','linewidth',LW);
plot3(h,z,z,S*e,'b','linewidth',LW);


% --- Draw cylinder along x axis
function drawArm(h,R,L,FC,FA)
[y,z,x] = cylinder();
surf(L*x,R*y,R*z,...
  'parent',h,...
  'facecolor',FC,...
  'facealpha',FA);


% --- Draw cylinder along x axis
function drawHand(h,R,L,FC,FA)
[x,y,z] = cylinder();
surf(R*x+R,R*y,L*z-L/2,...
  'parent',h,...
  'facecolor',FC,...
  'facealpha',FA);


% --- Draw STL
function drawSTL(h,fname,FC,FA)

[v,f,n,c] = stlread(fname);
patch('Faces',f,'Vertices',v,'FaceVertexCData',c,...
  'parent',h,'edgecolor','none',...
  'facecolor',FC,'facealpha',FA);


% --- Sets rotation part of transform
function setTransformRotation(hx,rot)
M = get(hx,'matrix');
M(1:3,1:3) = rot;
set(hx,'matrix',M);


% --- Lookup index for Myo
function val = lookupMyoIndex(handles,spec)

assert( any(strcmp(spec,{'upper','lower'})),...
  'Input ''spec'' must be ''upper'' or ''lower''.');

vals = [1,2];
if get(handles.cb_toggle_myos,'value')
  vals = fliplr(vals);
end

switch spec
  case 'upper'
    val = vals(1);
  case 'lower'
    val = vals(2);
end


% --- Updates main axes
function update_ax_main(src,evt,hFig)

% fprintf('updateTimer\n');

% get handles structure
handles = guidata(hFig);

% bail if data sources aren't initialized
if isempty(handles.myoMex) %|| isempty(handles.sphero)
  return;
end
if isempty(handles.myoMex.myoData(lookupMyoIndex(handles,'upper')).rot)
  return
end
if isempty(handles.myoMex.myoData(lookupMyoIndex(handles,'lower')).rot)
  return
end

RU = handles.myoMex.myoData(lookupMyoIndex(handles,'upper')).rot;
RU = handles.R0Upper'*RU;

RL = handles.myoMex.myoData(lookupMyoIndex(handles,'lower')).rot;
RL = handles.R0Lower'*RL;
RLU = RU'*RL;

RH = handles.sphero.rot;
RH = handles.R0Hand'*RH;
RHL = RL'*RH;

setTransformRotation(handles.hxUpper,RU);
setTransformRotation(handles.hxLower,RLU);
setTransformRotation(handles.hxHand,RHL);


% --- Executes on button press in pb_myo_init.
function pb_myo_init_Callback(hObject, eventdata, handles)
% hObject    handle to pb_myo_init (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% disable button
set(hObject,'enable','off');

% attempt instantiation
try
  handles.myoMex = MyoMex(handles.const.COUNT_MYOS);
catch err
  warning(err.message);
  handles.myoMex = [];
  set(hObject,'enable','on');
  return;
end

if ~isempty(handles.myoMex)
  guidata(hObject,handles);
end

if ~isempty(handles.myoMex) && ~isempty(handles.sphero)
  set(handles.pb_set_identity_pose,'enable','on');
end


% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% delete Timer
stop(handles.updateTimer);
delete(handles.updateTimer);

% delete MyoMex
if ~isempty(handles.myoMex)
  delete(handles.myoMex);
end

% delete Sphero
if ~isempty(handles.sphero)
  handles.sphero.SetDataStreaming(400,1,1,{});
  handles.sphero.SetStabilization(true);
  handles.sphero.SetBackLEDOutput(0);
  delete(handles.sphero);
end


% --- Executes on button press in pb_sphero_init.
function pb_sphero_init_Callback(hObject, eventdata, handles)
% hObject    handle to pb_sphero_init (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% disable button

set(hObject,'enable','off');
remote_name = get(handles.et_sphero_remote_name,'string');

% attempt instantiation
try
  handles.sphero = Sphero(remote_name);
  assert( ~handles.sphero.Ping(),'Sphero failed Ping().');
  handles.sphero.SetStabilization(false);
  handles.sphero.SetBackLEDOutput(1);
  handles.sphero.SetDataStreaming(...
        handles.const.SPHERO_FRAME_RATE,...
        handles.const.SPHERO_FRAME_COUNT,...
        0,...
        {'quat'});
catch err
  warning(err.message);
  handles.sphero = [];
  set(hObject,'enable','on');
  return;
end

if ~isempty(handles.sphero)
  guidata(hObject,handles);
end

if ~isempty(handles.myoMex) && ~isempty(handles.sphero)
  set(handles.pb_set_identity_pose,'enable','on');
end


% --- Executes on button press in pb_set_identity_pose.
function pb_set_identity_pose_Callback(hObject, eventdata, handles)
% hObject    handle to pb_set_identity_pose (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.R0Upper = handles.myoMex.myoData(lookupMyoIndex(handles,'upper')).rot;
handles.R0Lower = handles.myoMex.myoData(lookupMyoIndex(handles,'lower')).rot;
handles.R0Hand =  handles.sphero.rot;

guidata(hObject,handles);


% --- Executes on button press in cb_toggle_myos.
function cb_toggle_myos_Callback(hObject, eventdata, handles)
% hObject    handle to cb_toggle_myos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_toggle_myos



function et_sphero_remote_name_Callback(hObject, eventdata, handles)
% hObject    handle to et_sphero_remote_name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_sphero_remote_name as text
%        str2double(get(hObject,'String')) returns contents of et_sphero_remote_name as a double
str = get(hObject,'string');
flag = strfind(str,'Sphero-');
if isempty(flag) || ~flag
  warning('Remote name must begin with ''Sphero-''.');
  set(hObject,'string',handles.const.SPHERO_REMOTE_NAME_DEFAULT);
end

  
% --- Executes during object creation, after setting all properties.
function et_sphero_remote_name_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_sphero_remote_name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pb_switch_arm.
function pb_switch_arm_Callback(hObject, eventdata, handles)
% hObject    handle to pb_switch_arm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% transform that reflects about z-x plane
T = diag([1,-1,1,1]);
set(handles.hxUpperMesh,'matrix',T*get(handles.hxUpperMesh,'matrix'));
set(handles.hxLowerMesh,'matrix',T*get(handles.hxLowerMesh,'matrix'));
set(handles.hxHandMesh,'matrix',T*get(handles.hxHandMesh,'matrix'));
switch get(handles.st_which_arm,'string')
  case 'Left'
    armStr = 'Right';
  case 'Right'
    armStr = 'Left';
end
set(handles.st_which_arm,'string',armStr);
