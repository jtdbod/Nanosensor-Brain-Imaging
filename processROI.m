function [measuredValues]=processROI(imagestack,Lmatrix,h,frameRate)   
    frames=size(imagestack,3);
    %measuredValues = zeros(max(Lmatrix(:)),frames);
    measuredValues = struct('MeanIntensity',zeros(1,size(imagestack,3)),'Area',zeros(1,size(imagestack,3)),'CenterX',zeros(1,size(imagestack,3)),'CenterY',zeros(1,size(imagestack,3)),'dF',zeros(1,size(imagestack,3)));
    measuredAreas = zeros(max(Lmatrix(:)),frames);

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
        
        %create data structure with ROI data including intensity, df/f,
        %area etc.

        %dataResults(totalROIs).MeanIntensity = [stats.MeanIntensity];
        %dataResults(totalROIs).RoiArea = [stats.Area];
        %dataResults(totalROIs).
    end
    %fprintf(1,'%d',frame)
    %fprintf('\n')

    %Calculate dF/F using first 5% of frames frames as F0
    F0 = floor(frames*0.05); %Make F0 the average of the first 5% of frames).
    for roi=1:numROIs
        f0=mean(measuredValues(roi).MeanIntensity(1:F0));
        f=measuredValues(roi).MeanIntensity;
        df=(f-f0)./f0;
        measuredValues(roi).dF=df;
        measuredValues(roi).Time=(1:length(df))./frameRate;
    end
    
    
    
    delete(h);
end