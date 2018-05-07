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

% Last Modified by GUIDE v2.5 04-May-2018 15:13:51

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
[FileName,PathName,FilterIndex] = uigetfile('*.mat');

if isequal(FileName,0)
    %Do nothing
else
    handles.dataset = load(strcat(PathName,'/',FileName));
    handles.dataset.filename = strcat(strcat(PathName,'/',FileName));
    guidata(hObject,handles);%To save dataset to handles
    frameRate=str2double(get(handles.enterframerate,'String'));
    %CurrentFileLoaded();
    %set(handles.CurrentFileLoaded, 'String', FileName);

    %Plot file
    plotResults(handles.dataset.mask,handles.dataset.avgStack,handles.dataset.measuredValues,frameRate,handles);
   
    set(handles.CurrentFileLoaded,'String',FileName);
    assignin('base', 'currentDataset', handles.dataset) %Adds measuredValues for the loaded file to the current MATLAB workspace

    %Update listbox containing list of each ROI for selection
    roiNames = nonzeros(unique(handles.dataset.Lmatrix));
    roiNamesStr = num2str(roiNames);
    set(handles.roi_listbox,'Value',1); %Set "selected" listbox value to 1 to prevent error
    set(handles.roi_listbox,'string',roiNamesStr);
    
end
% --- Executes on button press in processfilebutton.
function processfilebutton_Callback(hObject, eventdata, handles)
% hObject    handle to processfilebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

clear currentDataset handles.dataset %Hopefully fixes slowdown?

frameRate=str2double(get(handles.enterframerate,'String'));
if true(get(handles.radiobuttonSPE,'Value'))
    fileType = 'spe';
elseif true(get(handles.radiobuttonTIF,'Value'))
    fileType = 'tif';
end
[FileName,PathName,FilterIndex] = uigetfile(strcat('*.',fileType));
file = struct('name',FileName); %Convert to structure for consistency with batch processing code
handles.dataset.filename = strcat(PathName,'/',FileName);
if true(FilterIndex)
    
        if strmatch(fileType,'spe')
            %Make progress bar
            barhandle = waitbar(0,'Loading Frame: x of x','Name',sprintf('Processing File 1 of 1'),...
                    'CreateCancelBtn',...
                    'setappdata(gcbf,''canceling'',1)');
            setappdata(barhandle,'canceling',0)

            [imagestack,filename]=loadIMstackSPE(PathName,file,1,barhandle);
        elseif strmatch(fileType,'tif')
            %Make progress bar
            barhandle = waitbar(0,'1','Name',sprintf('Processing File 1 of 1'),...
                    'CreateCancelBtn',...
                    'setappdata(gcbf,''canceling'',1)');
            setappdata(barhandle,'canceling',0)

            [imagestack,filename]=loadIMstackTIF(PathName,file,1,barhandle);
        else
            error('Error. Filetype must be "tif" or "spe"');
        end
        strelsize=get(handles.strelSlider,'Value');
        numopens=get(handles.numopens_slider,'Value');
        
        [Lmatrix,mask,stdStack,avgStack]=processImage(imagestack,strelsize,numopens);
        if true(get(handles.useCurrentROIs,'Value'))
            [measuredValues]=processROI(imagestack,handles.LmatrixFIXED,barhandle,frameRate);
            mask = handles.LmatrixFIXED; %Update mask displayed to represent the "saved" ROIs used for this analysis.
            mask(find(mask))=1; %Need to udpate this eventually so ROIs are not calculated for new video and then thrown away.
        else
            [measuredValues]=processROI(imagestack,Lmatrix,barhandle,frameRate);
        end
        if isempty(measuredValues)
            %do nothing
            delete(barhandle);

        else
            filename=strcat(PathName,'/',FileName(1:end-4));
            save(strcat(filename,'.mat'),'Lmatrix','mask','stdStack','avgStack','measuredValues','filename');
            handles.dataset = load(strcat(filename,'.mat'));
            
            guidata(hObject,handles);%To save dataset to handles
            assignin('base', 'currentDataset', handles.dataset) %Adds all data for the loaded file to the current MATLAB workspace
            plotResults(mask,avgStack,measuredValues,frameRate,handles);
            delete(barhandle);
        end
        

        %Generate listbox containing list of each ROI for selection
        roiNames = nonzeros(unique(handles.dataset.Lmatrix));
        roiNamesStr = num2str(roiNames);
        set(handles.roi_listbox,'Value',1); %Set "selected" listbox value to 1 to prevent error
        set(handles.roi_listbox,'string',roiNamesStr);
end



% --- Executes on button press in batchprocessbutton.
function batchprocessbutton_Callback(hObject, eventdata, handles)
% hObject    handle to batchprocessbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
frameRate=str2double(get(handles.enterframerate,'String'));
if true(get(handles.radiobuttonSPE,'Value'))
    fileType = 'spe';
elseif true(get(handles.radiobuttonTIF,'Value'))
    fileType = 'tif';
end
strelsize=get(handles.strelSlider,'Value');
numopens=get(handles.numopens_slider,'Value');
batchProcessVideos(fileType,frameRate,strelsize,numopens,handles);

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

function [frameRate]=enterframerate_Callback(hObject, eventdata, handles)
% hObject    handle to enterframerate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of enterframerate as text
%        str2double(get(hObject,'String')) returns contents of enterframerate as a double

%Look to see if metadata exists

%exist(strcat(handles.dataset.filename,'.txt');

frameRate = get(hObject,'String');
frameRate = str2double(frameRate);

%Future code for mining metadata
%{
fileID = fopen(filename,'r');

metadataText = textscan(fileID,'%s  %f','delimiter',',');

expression = '"ElapsedTime-ms": [0-9]+';
matches = regexp(metadataText{1},expression,'match');
matches = matches(~cellfun('isempty',matches));

expression = '[0-9]+';
timePoints = regexp(string(matches),expression,'match');

timePointsStr = string(timePoints);

x = str2double(timePointsStr);

fclose(fileID)
%}

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
set(hObject,'String','6.92');
input = str2double(get(hObject,'String'));
if isnan(input)
  errordlg('You must enter a numeric value','Invalid Input','modal')
  uicontrol(hObject)
  return

end

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


% --- Executes on slider movement.
function strelSlider_Callback(hObject, eventdata, handles)
% hObject    handle to strelSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function strelSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to strelSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function numopens_slider_Callback(hObject, eventdata, handles)
% hObject    handle to numopens_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function numopens_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numopens_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in radiobuttonSPE.
function radiobuttonSPE_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonSPE (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobuttonSPE


% --- Executes on button press in radiobuttonTIF.
function radiobuttonTIF_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonTIF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobuttonTIF


% --- Executes on button press in CloseAll.
function CloseAll_Callback(hObject, eventdata, handles)
% hObject    handle to CloseAll (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

delete(findall(0,'Type','Figure')) %Closes all open windows, including pesky waitbars


% --- Executes on button press in plotHistogram.
function plotHistogram_Callback(hObject, eventdata, handles)
% hObject    handle to plotHistogram (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
for i=1:size(handles.dataset.measuredValues,2);
    ROIsize(i) = handles.dataset.measuredValues(i).Area(1);
end
axes(handles.axes2)
cla(handles.axes2)
hist(sqrt(ROIsize));
xlabel('sqrt(ROI size) (pixels)')
ylabel('Count')


% --- Executes on button press in plotAlldF.
function plotAlldF_Callback(hObject, eventdata, handles)
% hObject    handle to plotAlldF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
measuredValues=handles.dataset.measuredValues;
axes(handles.axes2);
hold off
for i=1:size(measuredValues,2)
    
    plot(measuredValues(i).dF)
    hold on
    xlabel('Time (s)')
    ylabel('dF/F')
end


% --- Executes on button press in CorrelationMatrix.
function CorrelationMatrix_Callback(hObject, eventdata, handles)
% hObject    handle to CorrelationMatrix (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

axes(handles.axes3);

hold off
data=handles.dataset.measuredValues;
for rois=1:size(data,2)
    allTraces(rois,:)=data(rois).dF;
    roi_labels(rois) = data(rois).ROInum;
end
R=corrcoef(allTraces');
imagesc(R);

R(isnan(R))=0;

eva = evalclusters(R,'kmeans','DaviesBouldin','KList',[1:10]);
clusterIdx = kmeans(R,eva.OptimalK,'Replicates',5);

axes(handles.axes2);
cla(handles.axes2);

%Plot ROIs color coded by cluster ID
mask = handles.dataset.Lmatrix;

for roiIdx = 1:size(clusterIdx,1)
    roi = roi_labels(roiIdx);
    mask(find(mask==roi))=clusterIdx(roiIdx); %Replace label with cluster number
    hold all
end
imagesc(mask)
set(handles.axes2,'Ydir','reverse')
xlim([0 size(mask,2)])
ylim([0 size(mask,1)])
xlabel('');
ylabel('');
    
% --------------------------------------------------------------------
function edit_Callback(hObject, eventdata, handles)
% hObject    handle to edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function copy_figure_Callback(hObject, eventdata, handles)
% hObject    handle to copy_figure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ax=gca;
newFig=figure('visible','off');
newHandle = copyobj(ax,newFig);
%print(newFig,'-noui','-clipboard','-dpdf');
editmenufcn(newFig,'EditCopyFigure')
delete(newFig);



% --- Executes on button press in calc_spike_slope.
function calc_spike_slope_Callback(hObject, eventdata, handles)
% hObject    handle to calc_spike_slope (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

measuredValues=handles.dataset.measuredValues;
frameRate=str2double(get(handles.enterframerate,'String'));
spikeSlopes=[]; %Store slopes in this array
%fileNumbers = []; %Stores file number for each slope measurements
roiNumbers = []; %Stores roiNumber for each slope measurement

[spikeSlopes,roiNumbers, pks, locs]=computespikeslope(measuredValues,frameRate,spikeSlopes,roiNumbers);
axes(handles.axes2);
cla(handles.axes2);
notBoxPlot(spikeSlopes);
xlabel('All Spike Events')
ylabel('Slope ([dF/F]/s)')
axes(handles.axes3);
cla(handles.axes3);
elapsedTime=(1:size(measuredValues(1).dF,2))./frameRate;
for itrace=1:size(measuredValues,2)
    plot(elapsedTime,measuredValues(itrace).dF)
    hold on
end

scatter(locs./frameRate,pks,72,'vk','filled');

%{
hist(spikeSlopes)
xlabel('Slope ([dF/F]/s)')
ylabel('Counts')
%}



% --- Executes on button press in batch_calc_spike_slope.
function batch_calc_spike_slope_Callback(hObject, eventdata, handles)
% hObject    handle to batch_calc_spike_slope (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

frameRate=str2double(get(handles.enterframerate,'String'));

folder = uigetdir();
files=dir(strcat(folder,'/','*.mat'));

spikeSlopes=[]; %Store slopes in this array
%fileNumbers = []; %Stores file number for each slope measurements
roiNumbers = []; %Stores roiNumber for each slope measurement
for ifile = 1:length(files)

    load(strcat(folder,'/',files(ifile).name),'measuredValues');
    [spikeSlopes,roiNumbers]=computespikeslope(measuredValues,frameRate,spikeSlopes,roiNumbers);
end

axes(handles.axes2);
hold off
notBoxPlot(spikeSlopes);
xlabel('All Spike Events')
ylabel('Slope ([dF/F]/s)')
axes(handles.axes3);
hold off
hist(spikeSlopes)
xlabel('Slope ([dF/F]/s)')
ylabel('Counts')


% --- Executes on selection change in roi_listbox.
function roi_listbox_Callback(hObject, eventdata, handles)
% hObject    handle to roi_listbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns roi_listbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from roi_listbox
roi_selected_value = get(handles.roi_listbox,'Value'); %Number of selected element
roi_names = get(handles.roi_listbox,'string'); %Name of ROI selected (using roi_selected_value as index)
roi_selected=str2num(roi_names(roi_selected_value,:));

%Find ROI name that matches selected value
roi_index=find([handles.dataset.measuredValues.ROInum]==roi_selected);
axes(handles.axes2)
cla(handles.axes2)
set(handles.axes2,'Ydir','normal')
frameRate=str2double(get(handles.enterframerate,'String'));
x=1:length(handles.dataset.measuredValues(roi_index).dF);
x=x./frameRate;
y=handles.dataset.measuredValues(roi_index).dF;
plot(x,y)
axis tight

%Highlight the selected ROI.

%Plot the ROI overlay figure
currFig = gcf;
axes(handles.axes1);
cla(handles.axes1);

%Decide whether to use mask generated from file or Lmatrix mask from
%previously loaded video.
if true(get(handles.useCurrentROIs,'Value'))
    roi_list = nonzeros(unique(handles.LmatrixFIXED));
    mask = handles.LmatrixFIXED;
else
    roi_list = nonzeros(unique(handles.dataset.Lmatrix));
    mask = handles.dataset.Lmatrix;
end
imagesc(handles.dataset.avgStack); hold on;
for roi_index=1:length(roi_list)
    roi = roi_list(roi_index);
    if roi == roi_selected
        color = 'r';
    else
        color = 'k';
    end
    roi_mask = mask;
    roi_mask(find(roi_mask~=roi))=0;
    [B,L,N,A] = bwboundaries(roi_mask,'noholes');
    for k=1:length(B),
      boundary = B{k};
      %cidx = mod(k,length(colors))+1;
      plot(boundary(:,2), boundary(:,1),...
           color,'LineWidth',1);
      %randomize text position for better visibility
      rndRow = ceil(length(boundary)/(mod(rand*k,7)+1));
      col = boundary(rndRow,2); row = boundary(rndRow,1);
      %h = text(col+1, row-1, num2str(L(row,col)));
      h = text(col+1, row-1, num2str(roi));
      set(h,'Color',color,'FontSize',14);
    end

end

% --- Executes during object creation, after setting all properties.
function roi_listbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to roi_listbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in delete_roi_button.
function delete_roi_button_Callback(hObject, eventdata, handles)
% hObject    handle to delete_roi_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Make "PLEASE WAIT" indicator

axes(handles.axes2);
cla(handles.axes2);
xlimits = get(handles.axes2,'XLim');
ylimits = get(handles.axes2,'YLim');
xpos = (xlimits(2)-xlimits(1))/2;
ypos = (ylimits(2)-ylimits(1))/2;
text(xpos,ypos,'PLEASE WAIT','HorizontalAlignment','Center');

roi_selected_value = get(handles.roi_listbox,'Value'); %Number of selected element
roi_names = get(handles.roi_listbox,'string'); %Name of ROI selected (using roi_selected_value as index)
roi_selected=str2num(roi_names(roi_selected_value,:));
%Delete measuredValues for selected ROI

%Find ROI name that matches selected value
roi_index=find([handles.dataset.measuredValues.ROInum]==roi_selected);

%NOTE: careful use of 'roi_index' for deleting correct field of the
%measuredValues structure while 'roi_selected' is used for deleting ROIs in
%the 'Lmatrix' and 'mask' variables.

handles.dataset.measuredValues(roi_index)=[];
handles.dataset.Lmatrix(handles.dataset.Lmatrix==roi_selected)=0;
if true(get(handles.useCurrentROIs,'Value'))
    handles.LmatrixFIXED(handles.LmatrixFIXED==roi_selected)=0;
    %For when processing is done with a loaded ROI mask instead of generated
    %ROIs
else
    handles.dataset.mask(handles.dataset.Lmatrix==roi_selected)=0;
    %For when ROI mask is generated from the file being analyzed.
end
guidata(hObject,handles);%Update dataset to handles
%Resave updated dataset
Lmatrix=handles.dataset.Lmatrix;
mask=handles.dataset.mask;
stdStack=handles.dataset.stdStack;
measuredValues=handles.dataset.measuredValues;
filename = handles.dataset.filename;
avgStack = handles.dataset.avgStack;

save(strcat(handles.dataset.filename,'.mat'),'Lmatrix','mask','stdStack','avgStack','measuredValues','filename');

%
%Plot file
handles.dataset = load(strcat(handles.dataset.filename,'.mat'));
frameRate=str2double(get(handles.enterframerate,'String'));
plotResults(handles.dataset.mask,handles.dataset.avgStack,handles.dataset.measuredValues,frameRate,handles);
assignin('base', 'currentDataset', handles.dataset) %Adds measuredValues for the loaded file to the current MATLAB workspace

%Update listbox containing list of each ROI for selection
if true(get(handles.useCurrentROIs,'Value'))
    Lmatrix = handles.LmatrixFIXED;
    %For when processing is done with a loaded ROI mask instead of generated
    %ROIs
else
    Lmatrix = handles.dataset.Lmatrix;
    %For when ROI mask is generated from the file being analyzed.
end
roiNames = nonzeros(unique(Lmatrix));
roiNamesStr = num2str(roiNames);
set(handles.roi_listbox,'Value',1); %Set "selected" listbox value to 1 to prevent error
set(handles.roi_listbox,'string',roiNamesStr);


% --- Executes on button press in subPixelCorrButton.
function subPixelCorrButton_Callback(hObject, eventdata, handles)
% hObject    handle to subPixelCorrButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

subRoiCalculationsCorr(handles)


% --- Executes on button press in plotImageStacks.
function plotImageStacks_Callback(hObject, eventdata, handles)
% hObject    handle to plotImageStacks (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

axes(handles.axes2)
cla(handles.axes2)
set(handles.axes2,'Ydir','reverse')

imagesc(handles.dataset.stdStack);
ylabel('');
xlabel('Avg. Normalized STD Stack');

axes(handles.axes3)
cla(handles.axes3)
set(handles.axes3,'Ydir','reverse')

imagesc(handles.dataset.avgStack);
ylabel('');
xlabel('Avg. Stack');


% --- Executes on button press in useCurrentROIs.
function useCurrentROIs_Callback(hObject, eventdata, handles)
% hObject    handle to useCurrentROIs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of useCurrentROIs

isSelected = get(handles.useCurrentROIs,'Value');

if isempty(get(handles.CurrentFileLoaded,'String'));
    disp('No ROI mask loaded')
else

end


% --- Executes on button press in loadMaskButton.
function loadMaskButton_Callback(hObject, eventdata, handles)
% hObject    handle to loadMaskButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


%Sets a Lmatrix, aka ROI mask, that stays constant until changed and can be
%used to analyze other videos and overrides the ROI generation for that
%video.
[FileName,PathName,FilterIndex] = uigetfile('*.mat');

if isequal(FileName,0)
    %Do nothing
else
    dataset = load(strcat(PathName,'/',FileName));
    handles.LmatrixFIXED = dataset.Lmatrix;
    guidata(hObject,handles);%To save LmatrixFIXED to handles
end


% --- Executes on button press in subRoiMaxDfnorm.
function subRoiMaxDfnorm_Callback(hObject, eventdata, handles)
% hObject    handle to subRoiMaxDfnorm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

subRoiCalculationsMaxdF(handles);


% --- Executes on button press in subROITime2Peak.
function subROITime2Peak_Callback(hObject, eventdata, handles)
% hObject    handle to subROITime2Peak (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

subRoiCalculationsTime2Peak(handles);