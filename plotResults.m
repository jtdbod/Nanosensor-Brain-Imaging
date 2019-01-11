function []=plotResults(handles)

%DETERMINE WHETHER "FILTER ROIS" HAS BEEN RUN AND SELECT VALID ROIS
if isfield(handles.DataSet, 'validMeasuredValues')
    measuredValues = handles.DataSet.validMeasuredValues;
    Lmatrix = handles.DataSet.validLmatrix;
else
    measuredValues = handles.DataSet.measuredValues;
    roiMask=handles.DataSet.roiMask;
end
frameRate = handles.DataSet.frameRate;

imageFrame1 = handles.DataSet.projectionImages.f0;
%Return a blank figure if there are no ROIs detected in file
if not(isfield(measuredValues,'ROInum'))
    currFig = gcf;
    axes(handles.axes1);
    cla(handles.axes1);
    imagesc(imageFrame1);
    xlabel('NO ROIS FOUND')
else
    %Plot the ROI overlay figure
    currFig = gcf;
    axes(handles.axes1);
    cla(handles.axes1);
    cidx = 0;
    roi_list = nonzeros(unique(roiMask));
    mask = roiMask;
    imagesc(imageFrame1); hold on;
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


    %Plot all dF/F traces
    axes(handles.axes2);
    title('');
    cla(handles.axes2);
    set(handles.axes2,'Ydir','normal')
    hold on

    %DETERMINE WHETHER PLOTTING ORIGINAL OR FILTERED ROIS. THIS HAD TO
    %BE DONE BECAUSE THE TWO STRUCTURES WERE MADE DIFFERENTLY
    if isfield(handles.DataSet, 'validMeasuredValues')
        for tracenum=1:size(measuredValues.dF,1)
            signal = measuredValues.dF(tracenum,:);
            traces(tracenum,:)=signal;
        end
    else
        for tracenum=1:size(measuredValues,2)
            signal = measuredValues(tracenum).dF;
            traces(tracenum,:)=signal;
        end
    end

    x = 1:size(traces,2);
    x=x./frameRate;
    for trace=1:size(traces,1)
        if trace==1
            plot(x,traces(trace,:));
            plottedTrace=traces(trace,:); %To stack traces on top of each other
        else
            plottedTrace = traces(trace,:)+max(plottedTrace);
            plot(x,plottedTrace);
        end
        %CORRECT FOR DIFFERENCES BETWEEN VALID ROI STRUCTURES
        if isfield(handles.DataSet, 'validMeasuredValues')
            text(0,plottedTrace(1),num2str(measuredValues.ROInum(trace)))
        else
            text(0,plottedTrace(1),num2str(measuredValues(trace).ROInum));
        end
        hold on
    end
    
    %Plot an indicator of the stimulation point (if any).
    stimFrameNumber = str2double(get(handles.stimFrameNumber,'String'));
    stimTime = stimFrameNumber./frameRate;
    plot(stimTime*ones(100,1),linspace(0,max(plottedTrace)),'r-')
    
    xlabel('Time (s)')
    ylabel('dF/F')
    axis tight

    %Plot heat map of all ROI activity using imagesc
    axes(handles.axes3);
    cla(handles.axes3);

    y=1:size(traces,1);
    imagesc(x,y,traces)
    set(handles.axes3,'Ydir','normal')
    ylabel('ROI#');
    xlabel('Time (s)');
    caxis([min(traces(:)),max(traces(:))])
    xlim([0,max(x)])
    ylim([.5,max(y)+.5])
end
