function []=plotResults(mask,imagemed,measuredValues,frameRate, handles)

    %Plot the ROI overlay figure
    currFig = gcf;
    axes(handles.axes1);
    [B,L,N,A] = bwboundaries(mask,'noholes');
    imagesc(imagemed); hold on;
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
    
    %Plot all dF/F traces
    axes(handles.axes2);
    for tracenum=1:size(measuredValues,1)
        %%%%NEED TO WORK ON THIS BASELINE CORRECTION AND NORMALIZATION
        signal = measuredValues.dF;
        traces(tracenum,:)=signal;
    end
    x = 1:size(traces,2);
    x=x./frameRate;
    for trace=1:size(traces,1)
        
        plot(x,traces(trace,:)+trace-1);

        text(0,trace,num2str(trace));
        hold on
    end
    xlabel('Time (s)')
    ylabel('Normalized Intensity (a.u.)')
    
    
    
    axes(handles.axes3);
    x=x;
    y=1:size(traces,1);
    imagesc(x,y,traces)
    ylabel('ROI#');
    xlabel('Time (s)');
    end
