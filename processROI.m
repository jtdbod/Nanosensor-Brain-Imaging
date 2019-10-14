function [measuredValues]=processROI(handles,barhandle)   
    
    imagestack = handles.ImageStack;
    roiMask = handles.DataSet.roiMask;
    frameRate = handles.DataSet.frameRate;

    frames=size(imagestack,3);
    %measuredValues = zeros(max(roiMask(:)),frames);
    measuredValues = struct('MeanIntensity',zeros(1,size(imagestack,3)),...
        'Area',zeros(1,size(imagestack,3)),...
        'CenterX',zeros(1,size(imagestack,3)),...
        'CenterY',zeros(1,size(imagestack,3)),...
        'dF',zeros(1,size(imagestack,3)),...
        'dFdetrend',zeros(1,size(imagestack,3)));
    measuredAreas = zeros(max(roiMask(:)),frames);

    dataResults=struct('MeanItensity',[zeros(length(frames))],'RoiArea',[],'dF',[zeros(length(frames))]);
    for frame = 1:frames
        % Check for Cancel button press
        if getappdata(barhandle,'canceling')
            delete(barhandle)
            error('Operation terminated by user');
        end
        
        %Update progress bar
        waitbar(frame/frames,barhandle,sprintf('ROI processing. Frame %i of %i',[frame,frames]));
        
        %background = mean2(imagestack(:,:,frame));
        %background = mean(background);
        %background = mean(imagestack(:)); %this is a test
        %image=imagestack(:,:,frame)-background;
        image=imagestack(:,:,frame);
        
        stats=regionprops(roiMask,image,'MeanIntensity','WeightedCentroid','Area');
        numROIs=length(stats);
        
        for j=1:numROIs
            
            measuredValues(j).MeanIntensity(frame)=stats(j).MeanIntensity;
            measuredValues(j).Area(frame)=stats(j).Area;
            measuredValues(j).CenterX(frame)=stats(j).WeightedCentroid(1);
            measuredValues(j).CenterY(frame)=stats(j).WeightedCentroid(2);
            measuredValues(j).ROInum=j; 

        end

    end

    %Calculate dF/F using average of 50 previous frames
    for roi=1:numROIs
        stimFrameNumber = str2double(get(handles.stimFrameNumber,'String'));
        if stimFrameNumber < 55
            f0=mean(measuredValues(roi).MeanIntensity(stimFrameNumber-10:stimFrameNumber));
        else
            f0=mean(measuredValues(roi).MeanIntensity(stimFrameNumber-50:stimFrameNumber));
        end
        f=measuredValues(roi).MeanIntensity;
        df=(f-f0)./f0;
        dfdetrend = detrend(df);
        measuredValues(roi).dF=df;
        measuredValues(roi).dFdetrend=dfdetrend;
<<<<<<< HEAD
        measuredValues(roi).zScore=processTrace(f,frameRate,stimFrameNumber);
=======
        stimFrame = handles.DataSet.stimFrames;
        measuredValues(roi).zScore=processTrace(f,frameRate,stimFrame);
>>>>>>> dev
        measuredValues(roi).Time=(1:length(df))./frameRate;
    end
    
    delete(barhandle);

    
end