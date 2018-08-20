function A = linBases(B,sf)
%This function will determine if the initial and terminal baselines are
%relatively linear (have slopes significantly less than maximum slope around
%stimulus frame).
%Nonlinear baselines are defined to be those that have a slope exceeding
%70% of the maximum slope 
roiCount=size(B,1);
frameCount=size(B,2);

initialBaselineRange=round(sf*0.8);
%initial baseline is the first 80% of frames until the stimulus frame
terminalBaselineRange=round(frameCount*0.3);
%terminal baseline is the last 30% of frames 
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
    maxSlope=max(M);%find and store the max slope and index it occurs at
    %if there exist trends in the data around the baselines that exceed a
    %maximum (slopeLim = 50% of maximum slope), then consider the ROI
    %invalid
    slopeLim=0.7*maxSlope;
    %slopeExceeds contains the indices (frames) where the slope exceeded
    %the limit
    %we also want the absolute value of the slopes, in case there are
    %sharply negative trends where the baselines should be, so we change M
    M=abs(M);
    slopeLimIndex=find(M>slopeLim);
    %if the slope of the smoothedcurve exceeds the limits within the first
    %or last 12% of frames, consider the baselines to be nonlinear 
    if min(slopeLimIndex)<initialBaselineRange || max(slopeLimIndex)> frameCount-terminalBaselineRange
        A(i)=0;
    else%else consider the baselines to be linear
        A(i)=1;
    end
end

end
