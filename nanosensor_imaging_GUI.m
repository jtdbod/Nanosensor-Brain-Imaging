
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

% Last Modified by GUIDE v2.5 14-Oct-2019 13:29:51

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
    
    data = load(strcat(PathName,'/',FileName)); %LOAD ANALYZED DATA
    %CLEAR CURRENT DATASET IN MEMORY
    DataSet = struct('fileName',{data.DataSet.fileName}); %Initialize new DataSet structure
    %UPDATE DATASET TO CURRENT GUI HANDLES
    for fn = fieldnames(data.DataSet)' %NOTE THAT THIS ONLY WORKS AS A ROW OF CELLS
        DataSet.(fn{1})=data.DataSet.(fn{1});
    end
    handles.DataSet = DataSet;
    
    %Plot file
    plotResults(handles);
   
    set(handles.CurrentFileLoaded,'String',strcat(PathName,'/',FileName));
    guidata(hObject,handles);%To save DataSet to handles
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
elseif FileName==0
    %User cancelled open command. Do nothing.
elseif strmatch(fileType,'tif') && any(FileName)
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
    set(handles.CurrentFileLoaded,'String',strcat(PathName,'/',FileName));
    handles.ImageStack = imageStack;
    handles.DataSet.projectionImages.f0 = mean(imageStack(:,:,1:5),3);
    fileinfo=imfinfo(strcat(PathName,'/',FileName));
    handles.DataSet.numFrames=size(fileinfo,1);
    %Generate Mean Projection and dF Max Projecitons and store in handles
    if ~isfield(handles.DataSet.projectionImages,'meanProj')
        currFig = gcf;
        axes(handles.axes1);
        cla(handles.axes1);
        title('Calculating Mean Projection')
        xlabel('')
        imageStack = handles.ImageStack;
        imstack = imageStack;
        if any(imageStack(:)<0)
            imstack = imageStack-min(imageStack(:));
        end

        meanProjImage = mean(imstack,3);
        meanProjImageFilt = medfilt2(meanProjImage,[3 3]);
        handles.DataSet.projectionImages.meanProj = meanProjImageFilt;
        guidata(hObject,handles);
    end

    if ~isfield(handles.DataSet.projectionImages,'dFMaxProj')
    currFig = gcf;
    axes(handles.axes1);
    cla(handles.axes1);
    title('Calculating dF Projection')
    xlabel('')
    imstack = handles.ImageStack;
    dFImage = imstack-handles.DataSet.projectionImages.meanProj;
    maxdFProjImage = max(dFImage,[],3);
    maxdFProjImageFilt = medfilt2(maxdFProjImage,[4 4]);
    handles.DataSet.projectionImages.dFMaxProj = maxdFProjImageFilt;
    guidata(hObject,handles);
    end
    clear imstack dFImage
    guidata(hObject,handles);%To save DataSet to handles

    %Display first frame after file loads.
    axes(handles.axes1);
    cla(handles.axes1);
    colormap(defineGemColormap);
    imagesc(imageStack(:,:,1));
    title('Frame 1')
    cla(handles.axes2);
    cla(handles.axes3);
    
    delete(barhandle);
    guidata(hObject,handles);%To save DataSet to handles
else
    error('Error. Filetype must be "tif" or "spe"');
end

% --- Executes on button press in processfilebutton.
function processfilebutton_Callback(hObject, eventdata, handles)
% hObject    handle to processfilebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles = processTifFile(handles);
handles = calculateDecayConstant(handles);
guidata(hObject,handles);
guidata(hObject,handles);


% --- Executes on button press in batchprocessbutton.
function batchprocessbutton_Callback(hObject, eventdata, handles)
% hObject    handle to batchprocessbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

selpath = uigetdir;
tifFiles = dir(strcat(selpath,'/*.tif'));

for file = 1:size(tifFiles,1)

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

    %[FileName,PathName,~] = uigetfile(strcat('*.',fileType));
    FileName = tifFiles(file).name;
    PathName = selpath;

    if strmatch(fileType,'spe')
        error('SPE is not supported in this version. Bug Travis and he will fix it in a few minutes');
    elseif FileName==0
        %User cancelled open command. Do nothing.
    elseif strmatch(fileType,'tif') && any(FileName)
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
        handles.DataSet.projectionImages.f0 = mean(imageStack(:,:,1:5),3);
        fileinfo=imfinfo(strcat(PathName,'/',FileName));
        handles.DataSet.numFrames=size(fileinfo,1);
        %Generate Mean Projection and dF Max Projecitons and store in handles
        if ~isfield(handles.DataSet.projectionImages,'meanProj')
        currFig = gcf;
        axes(handles.axes1);
        cla(handles.axes1);
        title('Calculating Mean Projection')
        xlabel('')
        imageStack = handles.ImageStack;
        imstack = imageStack;
        if any(imageStack(:)<0)
            imstack = imageStack-min(imageStack(:));
        end

        meanProjImage = mean(imstack,3);
        meanProjImageFilt = medfilt2(meanProjImage,[3 3]);
        handles.DataSet.projectionImages.meanProj = meanProjImageFilt;
        guidata(hObject,handles);
        end

        if ~isfield(handles.DataSet.projectionImages,'dFMaxProj')
        currFig = gcf;
        axes(handles.axes1);
        cla(handles.axes1);
        title('Calculating dF Projection')
        xlabel('')
        imstack = handles.ImageStack;
        dFImage = imstack-handles.DataSet.projectionImages.meanProj;
        maxdFProjImage = max(dFImage,[],3);
        maxdFProjImageFilt = medfilt2(maxdFProjImage,[4 4]);
        handles.DataSet.projectionImages.dFMaxProj = maxdFProjImageFilt;
        guidata(hObject,handles);
        end
        clear imstack dFImage
        guidata(hObject,handles);%To save DataSet to handles

        %Display first frame after file loads.
        axes(handles.axes1);
        cla(handles.axes1);
        colormap(defineGemColormap);
        imagesc(imageStack(:,:,1));
        title('Frame 1')
        cla(handles.axes2);
        cla(handles.axes3);

        delete(barhandle);
        guidata(hObject,handles);%To save DataSet to handles
    else
        error('Error. Filetype must be "tif" or "spe"');
    end


    %handles = generateRois(handles);
    handles = generateGrid(handles);
    guidata(hObject,handles);
    handles = processTifFile(handles);
    guidata(hObject,handles);
    handles = calculateDecayConstant(handles);
    guidata(hObject,handles);
end

%{
%Need to rewrite to do the following
1> Select directory and get all filenames of tif files
2> Load each tif file into memory
3> For each, apply either "ROI gen" or "Grid ROI gen"
4> Process all ROIs and save the data
%}


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
    
    t = [1:size(measuredValues(i).dF,2)]./handles.DataSet.frameRate;
    plot(t,measuredValues(i).dF)
    hold on

end
%Plot an indicator of the stimulation point (if any).
stimFrameNumber = str2double(get(handles.stimFrameNumber,'String'));
stimTime = stimFrameNumber./handles.DataSet.frameRate;
yl = ylim; %Get limits of the yaxis
plot(stimTime*ones(100,1),linspace(yl(1),yl(2)),'r-')
xlabel('Time (s)')
ylabel('dF/F')


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
title('Hierarchical Clustering')

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
title('Hierarchical Clustering')
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
roi_index=find([handles.DataSet.measuredValues.roiNUM]==roi_selected);
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

    %Plot the ROI overlay figure
    currFig = gcf;
    axes(handles.axes1);
    cla(handles.axes1);
    
    imagesc(handles.DataSet.projectionImages.f0); hold on;
    roi_list = nonzeros(unique(handles.DataSet.roiMask));
    mask = handles.DataSet.roiMask;
    
    %Highlight the selected ROI.

    
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

%Reload updated DataSet
loadedData = load(strcat(handles.DataSet.fileName(1:end-4),'.mat'));
handles.DataSet = loadedData.DataSet;

%Plot updated DataSet
frameRate=str2double(get(handles.enterframerate,'String'));
plotResults(handles);

%Update listbox containing list of each ROI for selection
roiMask = handles.DataSet.roiMask;
%For when ROI mask is generated from the file being analyzed.
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
        imagesc(handles.DataSet.projectionImages.dFMaxProj); hold on;
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

[roiMask,~,dfofMaxProjection]=calculateMask(handles);
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
    set(handles.axes2,'Ydir','reverse')
    %Define colormap (Gem adapted from ImageJ, Abraham's favorite)
    colormap(defineGemColormap);
    cidx = 0;

    roi_list = nonzeros(unique(roiMask));
    mask = roiMask;
    dfofImage = medfilt2(dfofMaxProjection);
    imagesc(dfofImage); hold on;
    title('Maximum dF/F Projection @ Stimulation')
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
    handles.DataSet.projectionImages.dfofMaxProjection = dfofMaxProjection;
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
handles.DataSet.stimFrame = sf;
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



function roiBoxSize_Callback(hObject, eventdata, handles)
% hObject    handle to roiBoxSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of roiBoxSize as text
%        str2double(get(hObject,'String')) returns contents of roiBoxSize as a double


% --- Executes during object creation, after setting all properties.
function roiBoxSize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to roiBoxSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in GenerateRoiGrid.
function GenerateRoiGrid_Callback(hObject, eventdata, handles)
% hObject    handle to GenerateRoiGrid (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles = generateGrid(handles);
guidata(hObject,handles);


% --- Executes on button press in ShowAllRois.
function ShowAllRois_Callback(hObject, eventdata, handles)
% hObject    handle to ShowAllRois (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

plotResults(handles);

% --- Executes on button press in PlotPeakdF.
function PlotPeakdF_Callback(hObject, eventdata, handles)
% hObject    handle to PlotPeakdF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Plot an overlay of the ROIs that is color-coded by each ROI's peak dF/F
currFig = gcf;
axes(handles.axes3);
cla(handles.axes3);
roi_list = nonzeros(unique(handles.DataSet.roiMask));
mask = handles.DataSet.roiMask;
dFmask = zeros(size(mask,1),size(mask,2));

for roi_index=1:length(roi_list)
    roi = roi_list(roi_index);
    %index=find([handles.DataSet.measuredValues.ROInum]==roi);
    %roi_maxdF = max(handles.DataSet.measuredValues(index).dF);
    %roi_maxdF = handles.DataSet.measuredValues(index).dFoFPeak;
    roi_maxdF = handles.DataSet.measuredValues(roi).dFoFPeak;
    %NOTE: This is generated by the decay constant curve fitting code. This
    %calcluates dF/F as the maximum in a fixed time interval after
    %stimulation.
    dFmask(mask==roi)=roi_maxdF;
end

imagesc(dFmask);
colorbar();
colormap(handles.axes3,'jet')
title('\Delta F/F_{0}')
set(handles.axes3,'Ydir','reverse')
xlim([0,size(dFmask,2)])
ylim([0,size(dFmask,1)])
installVersion = version;
currentMatlabInstall = str2num(installVersion(1:3));
if currentMatlabInstall > 9.4;
set(gca,'colorscale','linear')
end
caxis([0,median(nonzeros(dFmask(:)))+std(nonzeros(dFmask(:)))])


% --- Executes on button press in PlotAvgdFTrace.
function PlotAvgdFTrace_Callback(hObject, eventdata, handles)
% hObject    handle to PlotAvgdFTrace (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

traces = zeros(size(handles.DataSet.measuredValues,2),handles.DataSet.numFrames);
for roiNum = 1:size(handles.DataSet.measuredValues,2)
    traces(roiNum,:)=handles.DataSet.measuredValues(roiNum).dF;
end

meanTrace = mean(traces);
%Flag = 0 -> No smoothing or baseline correction
flag=0;
%Calculate decay constants
data = zeros(size(traces,2),2);
data(:,1)=(1:size(traces,2))./handles.DataSet.frameRate; %Make first column = frame number for compatibility with 'first_order_curvefit()'
data(:,2)=meanTrace;
frameRate = handles.DataSet.frameRate;
stimFrameNum = str2double(get(handles.stimFrameNumber,'String'));
[first_order_constants, first_order_fit] = first_order_curvefit(data, flag, stimFrameNum, frameRate);
decayConstant = first_order_constants(2);


currFig = gcf;
axes(handles.axes2);
cla(handles.axes2);
t = [1:size(meanTrace,2)]./handles.DataSet.frameRate;
plot(t,meanTrace);
%Plot an indicator of the stimulation point (if any).
stimFrameNumber = str2double(get(handles.stimFrameNumber,'String'));
stimTime = stimFrameNumber./handles.DataSet.frameRate;
yl = ylim; %Get limits of the yaxis
plot(stimTime*ones(100,1),linspace(yl(1),yl(2)),'k--')
hold on
plot(t,first_order_fit);
title('Average dF/F Trace')
xlabel('Time (s)')
ylabel('dF/F')
maxY=max(nonzeros(first_order_fit));
minY=min(nonzeros(first_order_fit));
ypos = (maxY-minY)./2+minY;
xpos = mean(find(first_order_fit))./handles.DataSet.frameRate;
text(xpos,ypos,['tau = ' num2str(round(1/decayConstant,1)) ' s'])


% --- Executes on button press in ExportToWorkspace.
function ExportToWorkspace_Callback(hObject, eventdata, handles)
% hObject    handle to ExportToWorkspace (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
clear currentDataset
assignin('base','currentDataset', handles.DataSet) %Adds measuredValues for the loaded file to the current MATLAB workspace


% --- Executes on button press in calculateTau.
function calculateTau_Callback(hObject, eventdata, handles)
% hObject    handle to calculateTau (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Fit first order decay constants to each ROI trace. Give option to correct
%drift as well as filter out motion artifact traces if they exhibit an
%instantaneous rise time following stimulation. Adapted from code developed
%by Abraham and Andrew.
handles = calculateDecayConstant(handles);
guidata(hObject,handles);


% --- Executes on button press in ColorByTau.
function ColorByTau_Callback(hObject, eventdata, handles)
% hObject    handle to ColorByTau (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Plot an overlay of the ROIs that is color-coded by each ROI's peak dF/F
currFig = gcf;
axes(handles.axes3);
cla(handles.axes3);
roi_list = nonzeros(unique(handles.DataSet.roiMask));
mask = handles.DataSet.roiMask;
decayMask = zeros(size(mask,1),size(mask,2));
tauMask = zeros(size(mask,1),size(mask,2));

for roi_index=1:length(roi_list)
    roi = roi_list(roi_index);
    index=find([handles.DataSet.measuredValues.ROInum]==roi);
    %roi_decayConstant = handles.DataSet.measuredValues(index).decayConstant;
    roi_decayConstant = handles.DataSet.measuredValues(roi).decayConstant;
    decayMask(mask==roi)=roi_decayConstant;
    %roi_tauConstant = 1./handles.DataSet.measuredValues(index).decayConstant;
    roi_tauConstant = 1./handles.DataSet.measuredValues(roi).decayConstant;
    tauMask(mask==roi)=roi_tauConstant;
end

imagesc(tauMask);
colorbar();
colormap(handles.axes3,'jet')
set(handles.axes3,'Ydir','reverse')
xlim([0,size(decayMask,2)])
ylim([0,size(decayMask,1)])
xlabel('')
ylabel('')
title('\tau (s)')
installVersion = version;
currentMatlabInstall = str2num(installVersion(1:3));
if currentMatlabInstall > 9.4;
set(gca,'colorscale','linear')
end
%set(gca,'colorscale','linear')
%caxis([0,median(nonzeros(decayMask(:)))+std(nonzeros(decayMask(:)))])
caxis('auto')
caxis([0,10])


% --- Executes on button press in classifyTraces.
function classifyTraces_Callback(hObject, eventdata, handles)
% hObject    handle to classifyTraces (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

transientIndices = zeros(size(handles.DataSet.measuredValues,2),size(handles.DataSet.measuredValues(1).dF,2));
numROIs = size(handles.DataSet.measuredValues,2);
for roiNum = 1:numROIs
    dFF = handles.DataSet.measuredValues(roiNum).dF;
    [handles transientIndex] = classifyTransients(handles, dFF);
    transientIndices(roiNum,:) = transientIndex;
end

% Check if trace contains significant transient after stimulation
stimFrame = str2double(get(handles.stimFrameNumber,'String'));
frameNumbers = stimFrame-10:stimFrame+50;
isSignificant = zeros(size(transientIndices,1),1);
%Set condition for "significance": Are more than 10% of points after
%stimulation signficiant?
for i = 1:size(transientIndices,1)
    if sum(transientIndices(i,frameNumbers))/length(transientIndices(i,frameNumbers))>0.1
        handles.DataSet.measuredValues(i).isSignificant = 1;
    else
        handles.DataSet.measuredValues(i).isSignificant = 0;
    end
end

%Plot traces color coded according to transientIndex
%Plot all dF/F traces
    axes(handles.axes2);
    title('');
    cla(handles.axes2);
    set(handles.axes2,'Ydir','normal')
    hold on
    measuredValues = handles.DataSet.measuredValues;
    for tracenum=1:size(measuredValues,2)
        signal = measuredValues(tracenum).dF;
        if measuredValues(tracenum).isSignificant
            traces(tracenum,:)=signal;
        else
        end
    end
    x = 1:size(traces,2);
    x=x./handles.DataSet.frameRate;

    for trace=1:size(traces,1)
        
        %Calculate a moving baseline
        filterWidth = 10*handles.DataSet.frameRate; %In frames
        baseline = movmean(traces(trace,:),filterWidth);
        if trace==1
            y = traces(trace,:)-baseline;
            plot(x,y,'k');
            CC = bwconncomp(transientIndices(trace,:));
            L = labelmatrix(CC);
            hold on
            if max(L)>0
                for i = 1:max(L)
                    transientY = y(find(L==i));
                    transientX = x(find(L==i));
                    plot(transientX,transientY,'r-')
                end
            end
            %plot(transientX,transientY,'r-');
            plottedTrace=y-baseline; %To stack traces on top of each other
            
        else
            
            y=traces(trace,:)-baseline;
            y = y+max(plottedTrace);
            plot(x,y,'k');
            hold on
            CC = bwconncomp(transientIndices(trace,:));
            L = labelmatrix(CC);
            if max(L)>0
                for i = 1:max(L)
                    transientY = y(find(L==i));
                    transientX = x(find(L==i));
                    plot(transientX,transientY,'r-')
                end
            end
            %plot(transientX,transientY,'r-');
            plottedTrace=y; %To stack traces on top of each other
            
            
        end
        hold on
    end
    %Plot an indicator of the stimulation point (if any).
    stimFrameNumber = str2double(get(handles.stimFrameNumber,'String'));
    stimTime = stimFrameNumber./handles.DataSet.frameRate;
    plot(stimTime*ones(100,1),linspace(0,max(plottedTrace)),'r-')
    
    xlabel('Time (s)')
    ylabel('dF/F')
    axis tight
    %Plot heat map of all classified transients
    axes(handles.axes3);
    cla(handles.axes3);

    y=1:size(traces,1);
    imagesc(x,y,transientIndices)
    set(handles.axes3,'Ydir','normal')
    ylabel('ROI#');
    xlabel('Time (s)');
    caxis([min(traces(:)),max(traces(:))])
    xlim([0,max(x)])
    ylim([.5,max(y)+.5])
    map = [1 1 1
        1 0 0];
    colormap(handles.axes3,map);
    caxis([0,1]);
    title('')
    
handles.DataSet.transients = transientIndices;
guidata(hObject,handles);%To save roiMaskFIXED to handles


% --- Executes on button press in colorByTimeToPeak.
function colorByTimeToPeak_Callback(hObject, eventdata, handles)
% hObject    handle to colorByTimeToPeak (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
currFig = gcf;
axes(handles.axes3);
cla(handles.axes3);
roi_list = nonzeros(unique(handles.DataSet.roiMask));
mask = handles.DataSet.roiMask;
timetoPeakMask = zeros(size(mask,1),size(mask,2));


for roi_index=1:length(roi_list)
    roi = roi_list(roi_index);
    index=find([handles.DataSet.measuredValues.ROInum]==roi);
    roi_timetopeak = handles.DataSet.measuredValues(index).timeToPeak;
    timetoPeakMask(mask==roi)=roi_timetopeak;
end

imagesc(timetoPeakMask);
colorbar();
colormap(handles.axes3,'jet')
set(handles.axes3,'Ydir','reverse')
xlim([0,size(timetoPeakMask,2)])
ylim([0,size(timetoPeakMask,1)])
xlabel('')
ylabel('')
title('Time to Peak (s)')
installVersion = version;
currentMatlabInstall = str2num(installVersion(1:3));
if currentMatlabInstall > 9.4;
set(gca,'colorscale','linear')
end
%set(gca,'colorscale','linear')
%caxis([0,median(nonzeros(decayMask(:)))+std(nonzeros(decayMask(:)))])
%caxis('auto')
caxis([0,5])


% --- Executes on button press in specifyFilenameFlag.
function specifyFilenameFlag_Callback(hObject, eventdata, handles)
% hObject    handle to specifyFilenameFlag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of specifyFilenameFlag


% --- Executes on button press in AltBatchProcess.
function AltBatchProcess_Callback(hObject, eventdata, handles)
% hObject    handle to AltBatchProcess (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
selpath = uigetdir;
tifFiles = dir(strcat(selpath,'/*.tif'));

for file = 1:size(tifFiles,1)

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

    %[FileName,PathName,~] = uigetfile(strcat('*.',fileType));
    FileName = tifFiles(file).name;
    PathName = selpath;

    if strmatch(fileType,'spe')
        error('SPE is not supported in this version. Bug Travis and he will fix it in a few minutes');
    elseif FileName==0
        %User cancelled open command. Do nothing.
    elseif strmatch(fileType,'tif') && any(FileName)
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
        handles.DataSet.projectionImages.f0 = mean(imageStack(:,:,1:5),3);
        fileinfo=imfinfo(strcat(PathName,'/',FileName));
        handles.DataSet.numFrames=size(fileinfo,1);
        %Generate Mean Projection and dF Max Projecitons and store in handles
        if ~isfield(handles.DataSet.projectionImages,'meanProj')
        currFig = gcf;
        axes(handles.axes1);
        cla(handles.axes1);
        title('Calculating Mean Projection')
        xlabel('')
        imageStack = handles.ImageStack;
        imstack = imageStack;
        if any(imageStack(:)<0)
            imstack = imageStack-min(imageStack(:));
        end

        meanProjImage = mean(imstack,3);
        meanProjImageFilt = medfilt2(meanProjImage,[3 3]);
        handles.DataSet.projectionImages.meanProj = meanProjImageFilt;
        guidata(hObject,handles);
        end

        if ~isfield(handles.DataSet.projectionImages,'dFMaxProj')
        currFig = gcf;
        axes(handles.axes1);
        cla(handles.axes1);
        title('Calculating dF Projection')
        xlabel('')
        imstack = handles.ImageStack;
        dFImage = imstack-handles.DataSet.projectionImages.meanProj;
        maxdFProjImage = max(dFImage,[],3);
        maxdFProjImageFilt = medfilt2(maxdFProjImage,[4 4]);
        handles.DataSet.projectionImages.dFMaxProj = maxdFProjImageFilt;
        guidata(hObject,handles);
        end
        clear imstack dFImage
        guidata(hObject,handles);%To save DataSet to handles

        %Display first frame after file loads.
        axes(handles.axes1);
        cla(handles.axes1);
        colormap(defineGemColormap);
        imagesc(imageStack(:,:,1));
        title('Frame 1')
        cla(handles.axes2);
        cla(handles.axes3);

        delete(barhandle);
        guidata(hObject,handles);%To save DataSet to handles
    else
        error('Error. Filetype must be "tif" or "spe"');
    end
    %handles = generateRois(handles);
    handles = generateGrid(handles);
    guidata(hObject,handles);
    handles = processTifFileMOD(handles);
    guidata(hObject,handles);
    handles = calculateDecayConstant(handles);
    guidata(hObject,handles);
end

% AVERAGE ROIS OVER ALL FILES IN FOLDER AND PLOT SCATTER PLOT
matFiles = dir(strcat(selpath,'/*.mat'));

processedData=struct('data',[]);
numFiles = size(matFiles,1);
for file = 1:numFiles
    FileName = matFiles(file).name;
    PathName = selpath;
    load(strcat(PathName,'/',FileName));
    processedData(file).data = DataSet;
end
numROIs = size(processedData(2).data.measuredValues,2);
peakdF = zeros(numFiles,numROIs);
%isSignificant = zeros(numFiles,numROIs);

for file = 1:numFiles
    peakdF(file,:) = [processedData(file).data.measuredValues.dFoFPeak];
    %isSignificant(file,:) = [processedData(file).data.measuredValues.isSignificant];
end

meanPeakdF = mean(peakdF,1);
semPeakdF = std(peakdF,[],1)./numFiles;

axes(handles.axes2);
cla(handles.axes2);
plotSpread({meanPeakdF},'distributionMarkers','o')
ylabel('Mean Peak dF/F for Each ROI')
axes(handles.axes3);
cla(handles.axes3);
scatter(meanPeakdF,semPeakdF)
xlabel('Mean Peak dF/F for Each ROI')
ylabel('SEM of Peak dF/F')

save(strcat(PathName,'/','meanPeakdF.mat'),'meanPeakdF','semPeakdF')

% --- Executes on button press in classifyAndFilter.
function classifyAndFilter_Callback(hObject, eventdata, handles)
% hObject    handle to classifyAndFilter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of classifyAndFilter
