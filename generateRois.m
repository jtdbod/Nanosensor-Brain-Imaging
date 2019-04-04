function [handles] = generateRois(handles)
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
    
end