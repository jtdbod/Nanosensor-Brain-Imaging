function varargout = nanosensor_imaging_GUI(varargin)
% NANOSENSOR_IMAGING_GUI MATLAB code for nanosensor_imaging_GUI.fig
%      NANOSENSOR_IMAGING_GUI, by itself, creates a new NANOSENSOR_IMAGING_GUI or raises the existing
%      singleton*.
%
%      H = NANOSENSOR_IMAGING_GUI returns the handle to a new NANOSENSOR_IMAGING_GUI or the handle to
%      the existing singleton*.
%
%      NANOSENSOR_IMAGING_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in NANOSENSOR_IMAGING_GUI.M with the given input arguments.
%
%      NANOSENSOR_IMAGING_GUI('Property','Value',...) creates a new NANOSENSOR_IMAGING_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before nanosensor_imaging_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to nanosensor_imaging_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help nanosensor_imaging_GUI

% Last Modified by GUIDE v2.5 19-Jan-2018 13:38:06

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @nanosensor_imaging_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @nanosensor_imaging_GUI_OutputFcn, ...
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


% --- Executes just before nanosensor_imaging_GUI is made visible.
function nanosensor_imaging_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to nanosensor_imaging_GUI (see VARARGIN)

% Choose default command line output for nanosensor_imaging_GUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes nanosensor_imaging_GUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = nanosensor_imaging_GUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in loadbutton.
function loadbutton_Callback(hObject, eventdata, handles)
% hObject    handle to loadbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB

%Load file
[FileName,PathName,FilterINdex] = uigetfile();
handles.dataset = load(strcat(PathName,'/',FileName));
set(handles.CurrentFileLoaded, 'String', FileName);

%Plot file

subplot(131)
    [B,L,N,A] = bwboundaries(handles.dataset.mask,'noholes');
    imagesc(handles.dataset.imagemed); hold on;
    colors=['b' 'g' 'r' 'c' 'm' 'y'];
    for k=1:length(B),
      boundary = B{k};
      cidx = mod(k,length(colors))+1;
      plot(boundary(:,2), boundary(:,1),...
           colors(cidx),'LineWidth',1);

      %randomize text position for better visibility
      rndRow = ceil(length(boundary)/(mod(rand*k,7)+1));
      col = boundary(rndRow,2); row = boundary(rndRow,1);
      h = text(col+1, row-1, num2str(L(row,col)));
      set(h,'Color',colors(cidx),'FontSize',14);
    end
    subplot(132)
    for tracenum=1:size(handles.dataset.measuredValues,1)
        %%%%NEED TO WORK ON THIS BASELINE CORRECTION AND NORMALIZATION
        signal = handles.dataset.measuredValues(tracenum,:)+abs(min(handles.dataset.measuredValues(tracenum,:)));
        signal = signal./max(signal);
        traces(tracenum,:)=signal;
    end
        
    x = 1:size(traces,2);
    x=x./handles.frameRate;
    for trace=1:size(traces,1)
        %smoothed=smooth(traces(trace,:),'rloess');
        plot(x,traces(trace,:)+trace-1);
        %plot(x,smoothed+trace-1)
        text(0,trace,num2str(trace));
        hold on
    end
    xlabel('Time (s)')
    ylabel('Normalized Intensity (a.u.)')
    
    subplot(133)
    imagesc(traces)
    ylabel('ROI#');
    xlabel('Time (s)');





% --- Executes on button press in processfilebutton.
function processfilebutton_Callback(hObject, eventdata, handles)
% hObject    handle to processfilebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in batchprocessbutton.
function batchprocessbutton_Callback(hObject, eventdata, handles)
% hObject    handle to batchprocessbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in driftcheck.
function driftcheck_Callback(hObject, eventdata, handles)
% hObject    handle to driftcheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of driftcheck


% --- Executes on button press in spikecheck.
function spikecheck_Callback(hObject, eventdata, handles)
% hObject    handle to spikecheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of spikecheck



function edit2_Callback(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit2 as text
%        str2double(get(hObject,'String')) returns contents of edit2 as a double


% --- Executes during object creation, after setting all properties.
function edit2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function enterframerate_Callback(hObject, eventdata, handles)
% hObject    handle to enterframerate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of enterframerate as text
%        str2double(get(hObject,'String')) returns contents of enterframerate as a double

frameRate = get(hObject,'String');
handles.frameRate = str2double(frameRate);

% --- Executes during object creation, after setting all properties.
function enterframerate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to enterframerate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

frameRate = get(hObject,'String');
handles.frameRate = str2double(frameRate);

function edit4_Callback(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit4 as text
%        str2double(get(hObject,'String')) returns contents of edit4 as a double


% --- Executes during object creation, after setting all properties.
function edit4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in savedatabutton.
function savedatabutton_Callback(hObject, eventdata, handles)
% hObject    handle to savedatabutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function CurrentFileLoaded_CreateFcn(hObject, eventdata, handles)
% hObject    handle to CurrentFileLoaded (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
