function [measuredValues]=processROI(imagestack,Lmatrix,h)   
    frames=size(imagestack,3);
    measuredValues = zeros(max(Lmatrix(:)),frames);
    measuredAreas = zeros(max(Lmatrix(:)),frames);
    fprintf(1,'\tCalculating traces (frame):\t')
    dataResults=struct('MeanItensity',[zeros(length(frames))],'RoiArea',[],'dF',[zeros(length(frames))]);
    for frame = 1:frames
        % Check for Cancel button press
        if getappdata(h,'canceling')
            delete(h)
            error('Operation terminated by user');
        end
        
        %Update progress bar
        waitbar(frame/frames,h,sprintf('ROI processing. Frame %i of %i',[frame,frames]));
        
        %background = mean2(imagestack(:,:,frame));
        %background = mean(background);
        %background = mean(imagestack(:)); %this is a test
        %image=imagestack(:,:,frame)-background;
        image=imagestack(:,:,frame);
        stats=regionprops(Lmatrix,image,'MeanIntensity','Centroid','Area');
        measuredValues(:,frame)=[stats.MeanIntensity];
        %measuredValues.dF
        measuredAreas(:,frame)=[stats.Area];
        %fprintf(1,'%d',frame)
        %fprintf(1,repmat('\b',1,length(num2str(frame))))
        
        %create data structure with ROI data including intensity, df/f,
        %area etc.

        %dataResults(totalROIs).MeanIntensity = [stats.MeanIntensity];
        %dataResults(totalROIs).RoiArea = [stats.Area];
        dataResults(totalROIs).
    end
    fprintf(1,'%d',frame)
    fprintf('\n')
    delete(h);
end