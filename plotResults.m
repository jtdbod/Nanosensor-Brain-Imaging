function []=plotResults(mask,imagemed,measuredValues,frameRate, handles)

    %Plot the ROI overlay figure
    currFig = gcf;
    axes(handles.axes1);
    cla(handles.axes1);
    
    cidx = 0;
    roi_list = nonzeros(unique(handles.dataset.Lmatrix));
    imagesc(imagemed); hold on;
    for roi_index=1:length(roi_list)
        roi = roi_list(roi_index);
        roi_mask = handles.dataset.Lmatrix;
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
    cla(handles.axes2);
    hold on
    for tracenum=1:size(measuredValues,2)
        signal = measuredValues(tracenum).dF;
        traces(tracenum,:)=signal;
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
        text(0,plottedTrace(1),num2str(measuredValues(trace).ROInum));
        hold on
    end
    xlabel('Time (s)')
    ylabel('dF/F')
    axis tight
    
    %Plot heat map of all ROI activity using imagesc
    axes(handles.axes3);
    cla(handles.axes3);
    x=x;
    y=1:size(traces,1);
    imagesc(x,y,traces)
    ylabel('ROI#');
    xlabel('Time (s)');
    end
