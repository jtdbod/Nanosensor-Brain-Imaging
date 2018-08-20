function A = sigResp(B,st)
%this function takes a matrix where each row is an ROI's dF/Fo value, and
%each column is a frame. It checks if there is a significant response
%around the stimulation time (st) based on the slope of a smoothed curve.
%It returns true or false
roiCount=size(B,1);
%if there is a significant response around the stimulus time +/- 12% of the
%frame count (12% is a figure I found agrees with my ROI selection), then
%that ROI is considered true
frameCount=size(B,2);
range=round(frameCount*0.12);
for i=1:roiCount
    roi=i;%ROI number
    dF=B(roi,:);
    SF=0.2;%smoothing factor, how aggressively to smooth the data
    C=smoothdata(dF,'smoothingfactor',SF);
    %determine slope of the smooth data to look for response around frame 200
    M=diff(C);%if we determine the slope of the raw data, it is too noisy
    avgM=mean(M);
    M=[M avgM];%append one element to M to make it same size to put on same plot
    %we want to make sure there was a significant response of dF/Fo around the
    %stimulus time, at frame 200. Check if slope reaches it's maximum value
    %around the correct interval
    [maxSlope,index]=max(M);%find and store the max slope and index it occurs at
    if maxSlope>0
        if index<st+range && index>st-range
            %disp(['ROI ',num2str(roi),' has a significant response around frame: ',num2str(st)])
            A(i)=1;
        else
            %disp(['ROI ',num2str(roi),' does NOT have a significant response around frame: ',num2str(st)])
            A(i)=0;
        end
    end
end
end
