function [measuredValues]=processROI(imagestack,Lmatrix,h)   
    frames=size(imagestack,3);
    %measuredValues = zeros(max(Lmatrix(:)),frames);
    measuredValues = struct('MeanIntensity',zeros(1,size(imagestack,3)),'Area',zeros(1,size(imagestack,3)),'CenterX',zeros(1,size(imagestack,3)),'CenterY',zeros(1,size(imagestack,3)));
    measuredAreas = zeros(max(Lmatrix(:)),frames);
    fprintf(1,'\tCalculating traces (frame):\t')
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
        stats=regionprops(Lmatrix,image,'MeanIntensity','WeightedCentroid','Area');
        numROIs=length(stats);
        for j=1:numROIs
            measuredValues(j).MeanIntensity(frame)=stats(j).MeanIntensity;
            measuredValues(j).Area(frame)=stats(j).Area;
            measuredValues(j).CenterX(frame)=stats(j).WeightedCentroid(1);
            measuredValues(j).CenterY(frame)=stats(j).WeightedCentroid(2);
        end
        %fprintf(1,'%d',frame)
        %fprintf(1,repmat('\b',1,length(num2str(frame))))
        
    end
    %fprintf(1,'%d',frame)
    %fprintf('\n')
    
    %Calculate dF/F using first 50 frames as F0
    for roi=1:numROIs
        f0=mean(measuredValues(roi).MeanIntensity(1:50));
        f=measuredValues(roi).MeanIntensity;
        df=(f-f0)./f0;
        measuredValues(roi).dF=df;
    end

    delete(h);
end