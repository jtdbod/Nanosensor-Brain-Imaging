function [handles]=calculateDecayConstant(handles)%Generate grid of ROIs
%Generate structure containing the dF/F traces, the number of the ROI, and 
numberOfRois = size(handles.DataSet.measuredValues,2);
numberOfFrames = size(handles.DataSet.measuredValues(1).dF,2);

traces = struct('RoiNumber',{zeros(numberOfRois,1)},'dF',{zeros(numberOfFrames,1)});

%Using the detrend dF traces that have drift removed
%(handles.DataSet.measuredValues().dFdetrend).
for roinum = 1:numberOfRois
    traces(roinum).RoiNumber=handles.DataSet.measuredValues(roinum).ROInum;
    %traces(roinum).dF=handles.DataSet.measuredValues(roinum).dF';
    traces(roinum).dF=handles.DataSet.measuredValues(roinum).dFdetrend';
end

%Make data compatible with Abraham/Andrew's first_order_curvefit.m analysis

data = zeros(numberOfFrames,numberOfRois+1); %Add 1 for time dimension
data(:,1) = (1:numberOfFrames)./handles.DataSet.frameRate; %This column is the time dimension (seconds)

%Fill in dF/F values for each ROI (column)
for roinum = 1:numberOfRois
    data(:,roinum+1) = traces(roinum).dF;
end

flag = 0; %This indicates whether traces that look like motion artifacts are filtered out. Will implement a user defined checkbox for this later.

%Check if decay constants have been calculated already
if ~isfield(handles.DataSet.measuredValues,'decayFit')
    %Calculate first order decay constants and linear fits
    frameRate = handles.DataSet.frameRate;
    stimFrameNum = str2double(get(handles.stimFrameNumber,'String'));
    [first_order_constants, first_order_fit] = first_order_curvefit(data, flag, stimFrameNum, frameRate);
    decayConstants = first_order_constants(2,:);
    timeToPeak = first_order_constants(4,:);
    %Add tau and peak dF/F for each ROI to gui handles
    for roinum = 1:numberOfRois
        handles.DataSet.measuredValues(roinum).dFoFPeak = max(first_order_fit(:,roinum));
        handles.DataSet.measuredValues(roinum).decayConstant = decayConstants(roinum);
        handles.DataSet.measuredValues(roinum).decayFit = first_order_fit(:,roinum);
        handles.DataSet.measuredValues(roinum).timeToPeak = timeToPeak(:,roinum);
    end

    %Update saved DataSet file
    DataSet = handles.DataSet;
    save(strcat(handles.DataSet.pathName,'/',handles.DataSet.fileName(1:end-4),'.mat'),'DataSet');
    clear DataSet
else
        decayConstants=[];
        first_order_fit=[];
    for i=1:size(handles.DataSet.measuredValues,2)
        first_order_fit(:,i) = handles.DataSet.measuredValues(i).decayFit;
        decayConstants(i) = handles.DataSet.measuredValues(i).decayConstant;
    end
end

%Plot a stack of the fits over the original traces

axes(handles.axes2);
title('');
cla(handles.axes2);
set(handles.axes2,'Ydir','normal')
hold on

traceData = data(:,2:end)';
x = 1:size(traceData,2);
x=x./handles.DataSet.frameRate;
for trace=1:size(traceData,1)
    if trace==1
        plot(x,traceData(trace,:));
        plottedTrace=traceData(trace,:); %To stack traces on top of each other
        plot(x,first_order_fit(:,trace));
    else
        offSet = max(plottedTrace);
        plottedTrace = traceData(trace,:)+offSet;
        plot(x,plottedTrace);
        plot(x,first_order_fit(:,trace)+offSet);
    end

    %Label each trace by ROI num
    text(0,plottedTrace(1),num2str(traces(trace).RoiNumber));

    hold on
end
axis tight

%Plot histogram of tau values
axes(handles.axes3);
title('');
cla(handles.axes3);
set(handles.axes3,'Ydir','normal')
hold on
xlabel('\tau (s)')
ylabel('Counts')
%hist(decayConstants(find(and(decayConstants<1,decayConstants>0))),20);
%Filter out strong outliers for tau, i.e. anything that is impossible
tauRange = (1./decayConstants)<60; %Filter out anything over 60 seconds, which would be unreasonable
hist(1./decayConstants(tauRange),20);

xlim auto
ylim auto
end