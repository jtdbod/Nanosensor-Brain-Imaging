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

% Last Modified by GUIDE v2.5 28-Nov-2018 15:12:45

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
%Define colormap (Gem adapted from ImageJ, Abraham's favorite)
colormap(defineGemColormap);
% Update handles structure
guidata(hObject, handles);
isLoaded=0;
assignin('base','isLoaded',isLoaded);

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

%LOAD A MAT FILE CONTAINING PROCESSED VIDEO DATA

%Define colormap (Gem adapted from ImageJ, Abraham's favorite)
colormap(defineGemColormap);

%Load file
[FileName,PathName,FilterIndex] = uigetfile('*.mat');

if ~isequal(FileName,0)
    
    load(strcat(PathName,'/',FileName)); %LOAD ANALYZED DATA
    %CLEAR CURRENT DATASET IN MEMORY
    handles.DataSet = [];
    %UPDATE DATA TO CURRENT GUI HANDLES
    for fn = fieldnames(DataSet)' %NOTE THAT THIS ONLY WORKS AS A ROW OF CELLS
        handles.DataSet.(fn{1})=DataSet.(fn{1});
    end
    guidata(hObject,handles);%To save DataSet to handles
    %Plot file
    plotResults(handles);
   
    set(handles.CurrentFileLoaded,'String',FileName);
    assignin('base', 'currentDataset', handles.DataSet) %Adds measuredValues for the loaded file to the current MATLAB workspace
    isLoaded=1;
    assignin('base','isLoaded',isLoaded);
    %Update listbox containing list of each ROI for selection
    roiNames = nonzeros(unique(handles.DataSet.roiMask));
    roiNamesStr = num2str(roiNames);
    set(handles.roi_listbox,'Value',1); %Set "selected" listbox value to 1 to prevent error
    set(handles.roi_listbox,'string',roiNamesStr);
    
end

% --- Executes during object creation, after setting all properties.
function LoadStack_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LoadStack (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% --- Executes on button press in LoadStack.
function LoadStack_Callback(hObject, eventdata, handles)
% hObject    handle to LoadStack (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%CREATE DATASTRUCTURE FOR USER DATA AND STORE IN GUI HANDLES
handles.DataSet = struct('frameRate',{},'fileName',{},'pathName',{'PathName'},'roiMask',{},'measuredValues',{},...
    'projectionImages',{},'thresholdValue',{},'numFrames',{},'stimFrames',{});
handles.ImageStack = [];

%LOAD A VIDEO STACK INTO APPDATA MEMORY (EITHER TIF OR SPE)
if true(get(handles.radiobuttonSPE,'Value'))
    fileType = 'spe';
elseif true(get(handles.radiobuttonTIF,'Value'))
    fileType = 'tif';
end

[FileName,PathName,~] = uigetfile(strcat('*.',fileType));

if strmatch(fileType,'spe')
    error('SPE is not supported in this version. Bug Travis and he will fix it in a few minutes');
elseif strmatch(fileType,'tif')
    %Make progress bar
    barhandle = waitbar(0,'1','Name',sprintf('Processing File 1 of 1'),...
            'CreateCancelBtn',...
            'setappdata(gcbf,''canceling'',1)');
    setappdata(barhandle,'canceling',0)

    %Load stack
    [imageStack]=loadIMstackTIF(PathName,FileName,1,barhandle);
    %ADD FILENAME AND IMAGESTACK DATA TO APPDATA
    handles.DataSet(1).fileName = FileName;
    handles.DataSet.pathName = PathName;
    handles.ImageStack = imageStack;
    fileinfo=imfinfo(strcat(PathName,'/',FileName));
    handles.DataSet.numFrames=size(fileinfo,1);
    %Generate maximum dF projection to use for further processing
    dfStackMaxSmoothNorm = processImage(imageStack,handles);
    %Assign max dF projection into the guidata handles
    handles.DataSet.projectionImages.maxdFoverFProj = dfStackMaxSmoothNorm;
    guidata(hObject,handles);%To save DataSet to handles

    %Display first frame after file loads.
    axes(handles.axes1);
    cla(handles.axes1);
    colormap(defineGemColormap);
    imagesc(imageStack(:,:,1));
    title('Frame 1')
else
    error('Error. Filetype must be "tif" or "spe"');
end

delete(barhandle);
guidata(hObject,handles);%To save DataSet to handles



% --- Executes on button press in processfilebutton.
function processfilebutton_Callback(hObject, eventdata, handles)
% hObject    handle to processfilebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isfield(handles,'ImageStack')
    %Define colormap (Gem adapted from ImageJ, Abraham's favorite)
    colormap(defineGemColormap);
    %Make progress bar
    barhandle = waitbar(0,'ROI processing. Frame %i of %i','Name',sprintf('Processing File 1 of 1'),...
            'CreateCancelBtn',...
            'setappdata(gcbf,''canceling'',1)');
    setappdata(barhandle,'canceling',0)

    %CALCULATE SIZE, VALUES ETC. FOR EACH ROI (stored in roiMask) GENERATED
    %BY BUTTON PRESS OR LOADED FROM PREVIOUS FILE
    handles.DataSet.frameRate = str2double(get(handles.enterframerate,'String'));
    [measuredValues]=processROI(handles,barhandle);

    handles.DataSet.measuredValues = measuredValues;
    
    guidata(hObject,handles);%To save DataSet to handles

    if ~isempty(measuredValues)
        DataSet = handles.DataSet;
        save(strcat(handles.DataSet.pathName,'/',handles.DataSet.fileName(1:end-4),'.mat'),'DataSet');
        %assignin('base', 'currentDataset', handles.DataSet) %Adds all data for the loaded file to the current MATLAB workspace        
        %PLOT THE RESULTS
        plotResults(handles);
        set(handles.CurrentFileLoaded,'String',handles.DataSet.fileName);
        delete(barhandle);
    end
else
    error('Please load imagestack first.')
end



%Generate listbox containing list of each ROI for selection
roiNames = nonzeros(unique(handles.DataSet.roiMask));
roiNamesStr = num2str(roiNames);
set(handles.roi_listbox,'Value',1); %Set "selected" listbox value to 1 to prevent error
set(handles.roi_listbox,'string',roiNamesStr);


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
handles = batchProcessVideos(fileType,frameRate,strelsize,numopens,handles);
guidata(hObject,handles);%To save DataSet to handles


function [frameRate]=enterframerate_Callback(hObject, eventdata, handles)
% hObject    handle to enterframerate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of enterframerate as text
%        str2double(get(hObject,'String')) returns contents of enterframerate as a double

%Look to see if metadata exists

%exist(strcat(handles.DataSet.filename,'.txt');

handles.DataSet.frameRate = str2double(get(hObject,'String'));


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
set(hObject,'String','8.33');
input = str2double(get(hObject,'String'));
if isnan(input)
  errordlg('You must enter a numeric value','Invalid Input','modal')
  uicontrol(hObject)
  return

end


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

delete(findall(0,'Type','Figure','Tag','TMWWaitbar')) %Closes hanging waitbars.


% --- Executes on button press in plotHistogram.
function plotHistogram_Callback(hObject, eventdata, handles)
% hObject    handle to plotHistogram (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
for i=1:size(handles.DataSet.measuredValues,2);
    ROIsize(i) = handles.DataSet.measuredValues(i).Area(1);
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
measuredValues=handles.DataSet.measuredValues;
axes(handles.axes2);
hold off
for i=1:size(measuredValues,2)
    
    plot(measuredValues(i).dF)
    hold on
    xlabel('Time (s)')
    ylabel('dF/F')
end


% --- Executes on button press in CorrelationMatrix.
function CorrelationMatrix_Callback(~, eventdata, handles)
% hObject    handle to CorrelationMatrix (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

axes(handles.axes3);

hold off
data=handles.DataSet.measuredValues;
for rois=1:size(data,2)
    allTraces(rois,:)=data(rois).dF;
    roi_labels(rois) = data(rois).ROInum;
end
%Simple correlation calculation
%{ 
R=corrcoef(allTraces');
imagesc(R);

R(isnan(R))=0;

eva = evalclusters(R,'kmeans','DaviesBouldin','KList',[1:10]);
clusterIdx = kmeans(R,eva.OptimalK,'Replicates',5);
%}

%Calculate hierarchical clustering linkage of ROIs
Z = linkage(allTraces,'average','euclidean');
clusterIdx = cluster(Z,5);
dendrogram(Z,'ColorThreshold',3)

axes(handles.axes2);
cla(handles.axes2);

%Plot ROIs color coded by cluster ID
mask = handles.DataSet.roiMask;

for roiIdx = 1:size(clusterIdx,1)
    roi = roi_labels(roiIdx);
    mask(find(mask==roi))=clusterIdx(roiIdx); %Replace label with cluster number
    hold all
end

set(handles.axes2,'Ydir','reverse')
colormap('jet')
imagesc(mask)
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

measuredValues=handles.DataSet.measuredValues;
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
roi_index=find([handles.DataSet.measuredValues.ROInum]==roi_selected);
if ~isempty(roi_index)
    axes(handles.axes2)
    cla(handles.axes2)
    set(handles.axes2,'Ydir','normal')
    frameRate=str2double(get(handles.enterframerate,'String'));
    x=1:length(handles.DataSet.measuredValues(roi_index).dF);
    x=x./frameRate;
    if get(handles.medianBaselineFilter,'Value') %Subtract median filter for baseline correction (optional)
        traceFilt = medfilt1(handles.DataSet.measuredValues(roi_index).dF,50);
        y=smooth(handles.DataSet.measuredValues(roi_index).dF,5)-traceFilt';
    else
        y=handles.DataSet.measuredValues(roi_index).dF;
    end
    plot(x,y)
    axis tight

    %Highlight the selected ROI.

    %Plot the ROI overlay figure
    currFig = gcf;
    axes(handles.axes1);
    cla(handles.axes1);
    roi_list = nonzeros(unique(handles.DataSet.roiMask));
    mask = handles.DataSet.roiMask;

    imagesc(handles.ImageStack(:,:,1)); hold on;
    for roi_index=1:length(roi_list)
        roi = roi_list(roi_index);
        if roi == roi_selected
            color = 'r';
        else
            color = 'g';
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
          %h = text(col+1, row-1, num2str(roi));
          %set(h,'Color',color,'FontSize',14);
        end
    end
else 
    axes(handles.axes2)
    cla(handles.axes2)
    set(handles.axes2,'Ydir','normal')
    xlimits = get(handles.axes2,'XLim');
    ylimits = get(handles.axes2,'YLim');
    xpos = (xlimits(2)-xlimits(1))/2;
    ypos = (ylimits(2)-ylimits(1))/2;
    text(xpos,ypos,'ROI Previously Deleted. Reload DataSet','HorizontalAlignment','Center');
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
roi_index=find([handles.DataSet.measuredValues.ROInum]==roi_selected);

%NOTE: careful use of 'roi_index' for deleting correct field of the
%measuredValues structure while 'roi_selected' is used for deleting ROIs in
%the 'roiMask' and 'mask' variables.

handles.DataSet.measuredValues(roi_index)=[];
handles.DataSet.roiMask(handles.DataSet.roiMask==roi_selected)=0;

guidata(hObject,handles);%Update DataSet to handles

%Save updated DataSet to MAT file (this will be removed once a SAVE button
%is added
DataSet = handles.DataSet;
file = strcat(handles.DataSet.pathName,'/',handles.DataSet.fileName(1:end-4));
save(file,'DataSet');

%
%Plot file
handles.DataSet = load(strcat(handles.DataSet.fileName,'.mat'));
frameRate=str2double(get(handles.enterframerate,'String'));
plotResults(handles.DataSet.roiMask,handles.DataSet.avgStack,handles.DataSet.measuredValues,frameRate,handles);
assignin('base', 'currentDataset', handles.DataSet) %Adds measuredValues for the loaded file to the current MATLAB workspace

%Update listbox containing list of each ROI for selection
if true(get(handles.useCurrentROIs,'Value'))
    roiMask = handles.roiMaskFIXED;
    %For when processing is done with a loaded ROI mask instead of generated
    %ROIs
else
    roiMask = handles.DataSet.roiMask;
    %For when ROI mask is generated from the file being analyzed.
end
roiNames = nonzeros(unique(roiMask));
roiNamesStr = num2str(roiNames);
set(handles.roi_listbox,'Value',1); %Set "selected" listbox value to 1 to prevent error
set(handles.roi_listbox,'string',roiNamesStr);


% --- Executes on button press in subPixelCorrButton.
function subPixelCorrButton_Callback(hObject, eventdata, handles)
% hObject    handle to subPixelCorrButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

subRoiCalculationsCorr(handles)


% --- Executes on button press in plotVideoProjections.
function plotVideoProjections_Callback(hObject, eventdata, handles)
% hObject    handle to plotVideoProjections (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

axes(handles.axes1)
cla(handles.axes1)
set(handles.axes1,'Ydir','reverse')

imagesc(handles.DataSet.dfStackMaxSmoothNorm);
ylabel('');
xlabel('Max dF Projection');

axes(handles.axes2)
cla(handles.axes2)
set(handles.axes2,'Ydir','reverse')

imagesc(handles.DataSet.stdStack);
ylabel('');
xlabel('Mean Normalized STD Projection');

axes(handles.axes3)
cla(handles.axes3)
set(handles.axes3,'Ydir','reverse')

imagesc(handles.DataSet.avgStack);
ylabel('');
xlabel('Mean Projection');


% --- Executes on button press in loadMaskButton.
function loadMaskButton_Callback(hObject, eventdata, handles)
% hObject    handle to loadMaskButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% LOAD A PRE-EXISTING ROI MASK GENERATED FROM A PREVIOUS VIDEO FILE. THIS
% CAN BE USED TO OVERLAY THE SAME ROIS ON A SUBSEQUENT VIDEO OF THE SAME
% FOV.

[FileName,PathName,FilterIndex] = uigetfile('*.mat');

if FileName~=0,
    %LOAD MASK FILE INTO MEMORY AND ASSIGN TO HANDLES
    loadedData = load(strcat(PathName,'/',FileName),'roiMask');
    roiMask = loadedData.roiMask;
    handles.DataSet.roiMask = roiMask;
    guidata(hObject,handles);%To save roiMaskFIXED to handles

    %PLOT ROIS ON CURRENT MAX PROJECTION
    if max(roiMask)==0
        currFig = gcf;
        axes(handles.axes2);
        cla(handles.axes2);
        title('Maximum dF Projection')
        xlabel('NO ROIS FOUND')
    else
        %PLOT ROI OVERLAY
        currFig = gcf;
        axes(handles.axes2);
        cla(handles.axes2);
        %Define colormap (Gem adapted from ImageJ, Abraham's favorite)
        colormap(defineGemColormap);
        cidx = 0;
        roi_list = nonzeros(unique(roiMask));
        mask = roiMask;
        %PLOT MAX dF PROJECTION
        imagesc(handles.DataSet.projectionImages.maxdFoverFProj); hold on;
        title('Maximum F-F_{0} Projection')
        for roi_index=1:length(roi_list)
            roi = roi_list(roi_index);
            roi_mask = mask;
            roi_mask(find(roi_mask~=roi))=0;
            [B,L,N,A] = bwboundaries(roi_mask,'noholes');
            colors=['b' 'g' 'r' 'c' 'm' 'y'];
            cidx = mod(cidx,length(colors))+1; %Cycle through colors for drawing borders
            for k=1:length(B),
              boundary = B{k};
              %cidx = mod(k,length(colors))+1;
              plot(boundary(:,2), boundary(:,1),...
                   colors(cidx),'LineWidth',1);
              %randomize text position for better visibility
              rndRow = ceil(length(boundary)/(mod(rand*k,7)+1));
              col = boundary(rndRow,2); row = boundary(rndRow,1);
              %h = text(col+1, row-1, num2str(L(row,col)));
              h = text(col+1, row-1, num2str(roi));
              set(h,'Color',colors(cidx),'FontSize',14);
            end
        end
    end
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


% --- Executes on button press in medianBaselineFilter.
function medianBaselineFilter_Callback(hObject, eventdata, handles)
% hObject    handle to medianBaselineFilter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of medianBaselineFilter



function thresholdLevel_Callback(hObject, eventdata, handles)
% hObject    handle to thresholdLevel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of thresholdLevel as text
%        str2double(get(hObject,'String')) returns contents of thresholdLevel as a double




% --- Executes during object creation, after setting all properties.
function thresholdLevel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to thresholdLevel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in CalculateROIs.
function CalculateROIs_Callback(hObject, eventdata, handles)
% hObject    handle to CalculateROIs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

strelsize=get(handles.strelSlider,'Value');
numopens=get(handles.numopens_slider,'Value');

[roiMask,~]=calculateMask(handles);
if max(roiMask)==0
    currFig = gcf;
    axes(handles.axes2);
    cla(handles.axes2);
    title('Maximum dF Projection')
    xlabel('NO ROIS FOUND')
else
    %Plot the ROI overlay figure
    currFig = gcf;
    axes(handles.axes2);
    cla(handles.axes2);
    %Define colormap (Gem adapted from ImageJ, Abraham's favorite)
    colormap(defineGemColormap);
    cidx = 0;

    roi_list = nonzeros(unique(roiMask));
    mask = roiMask;
    maxdFProjImage = handles.DataSet.projectionImages.maxdFoverFProj;
    imagesc(maxdFProjImage); hold on;
    title('Maximum F-F_{0} Projection')
    for roi_index=1:length(roi_list)
        roi = roi_list(roi_index);
        roi_mask = mask;
        roi_mask(find(roi_mask~=roi))=0;
        [B,L,N,A] = bwboundaries(roi_mask,'noholes');
        colors=['b' 'g' 'r' 'c' 'm' 'y'];
        cidx = mod(cidx,length(colors))+1; %Cycle through colors for drawing borders
        for k=1:length(B),
          boundary = B{k};
          %cidx = mod(k,length(colors))+1;
          plot(boundary(:,2), boundary(:,1),...
               colors(cidx),'LineWidth',1);
          %randomize text position for better visibility
          rndRow = ceil(length(boundary)/(mod(rand*k,7)+1));
          col = boundary(rndRow,2); row = boundary(rndRow,1);
          %h = text(col+1, row-1, num2str(L(row,col)));
          h = text(col+1, row-1, num2str(roi));
          set(h,'Color',colors(cidx),'FontSize',14);
        end

    end
    %Store the ROI mask (roiMask) into the figure handles structure
    handles.DataSet.roiMask = roiMask;
    guidata(hObject,handles);%To save DataSet to handles
end


% --- Executes on button press in filterROIs.
function filterROIs_Callback(hObject, eventdata, handles)
% hObject    handle to filterROIs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

isLoaded=evalin('base','isLoaded');
if(isLoaded)
    currentDataset = evalin('base','currentDataset');%grab currentDataset struct from workspace
    if(get(handles.stimFrameNumber,'String')~="")
        sf=str2double(get(handles.stimFrameNumber,'String'));%store the stimulus frame provided
        %call the appropriate function with that stimulus frame
        %                  disp(sf)
        %https://www.mathworks.com/matlabcentral/answers/42467-gui-and-work-space-data-sharing
 
        %         disp(currentDataset.measuredValues(1).dF)
        currentDataset = filterROI(sf,currentDataset);
        %export the filtered currentDataset to base workspace
        assignin('base','currentDataset',currentDataset);
        %update the GUI with the valid ROIs
        %currentDataset.validMeasuredValues.ROInum contains the updated ROIs
        %update the listbox with the valid ROIs
        validROInum = currentDataset.validMeasuredValues.ROInum;
        %     disp(ROInum)
        roiNamesStr = num2str(validROInum);
        set(handles.roi_listbox,'Value',1); %Set "selected" listbox value to 1 to prevent error
        set(handles.roi_listbox,'string',roiNamesStr);
        %PLOT VALID ROI RESULTS
        handles.DataSet.validMeasuredValues = currentDataset.validMeasuredValues;
        handles.DataSet.validroiMask = currentDataset.validroiMask;
        guidata(hObject,handles);%To save roiMaskFIXED to handles
        plotResults(handles);
        disp('The filter has been applied; the ROI list has been updated.');
        
        
    else
        disp('A stimulus frame must be specified.');
    end
else
    disp('The data must first be loaded.');
end


function stimFrameNumber_Callback(hObject, eventdata, handles)
% hObject    handle to stimFrameNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of stimFrameNumber as text
%        str2double(get(hObject,'String')) returns contents of stimFrameNumber as a double
sf=str2double(get(hObject,'String'));
%set(handles.stimFrameNumber,'string','Click Filter after loading data.');
%sf is the stimulus frame, which will be passed to filter function

% --- Executes during object creation, after setting all properties.
function stimFrameNumber_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stimFrameNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function processfilebutton_CreateFcn(hObject, eventdata, handles)
% hObject    handle to processfilebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in Save_ROI_Mask.
function Save_ROI_Mask_Callback(hObject, eventdata, handles)
% hObject    handle to Save_ROI_Mask (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%SAVE THE MASK TO AN M-FILE FOR LATER USE.

roiMask = handles.DataSet.roiMask;
uisave('roiMask');
