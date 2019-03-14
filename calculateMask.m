function [Lmatrix, mask, dfofMaxProjection]=calculateMask(handles)
% GENERATES A BINARY MASK THAT HIGHLIGHTS REGIONS OF INTEREST (ROIS) BASED
% ON AN INTENSITY THRESHOLD CUTOFF AND THE THE MAXIMUM PROJECTION OF (F-F0)
% OR THE VIDEO STACK. REGIONS (PIXELS) THAT UNDERGO A LARGE, POSITIVE
% CHANGE IN INTENSITY OVER TIME WILL BECOME ROIS. PIXEL VALUES WITHIN ROIS
% WILL BE SET TO 1, AND ALL OTHER PIXELS TO 0 ('mask'). THEN, THE ROIS WILL BE
% NUMBERED AND THEIR PIXEL VALUES CHANGED TO REFLECT THE NUMBER OF THE ROI
% ('Lmatrix'). THE CUTOFF THRESHOLD CAN BE SET EITHER ALGORITHMICALLY
% ('graythresh') OR SET AS A FIXED PERCENTAGE USING INPUT FROM THE USER.
%{
userThreshold = str2double(get(handles.thresholdLevel,'String'));
dFMaxProj = handles.DataSet.projectionImages.dFMaxProj;
dFMaxProjNorm = dFMaxProj./max(dFMaxProj(:));
%ALGORITHMIC THRESHOLDING:
%T=graythresh(dfStackMaxSmoothNorm)*(userThreshold./100);

%ADAPTICE ALGORIITHMIC THRESHOLDING:
%T=adaptthresh(dfStackMaxSmoothNorm,0.1,...
    %'ForegroundPolarity','bright','neigh',51);
    
%USER SET THRESHOLD:
T=userThreshold./100; %In percent

mask1 = imbinarize(dFMaxProjNorm, T); %Threshold image
strelsize=get(handles.strelSlider,'Value');
se = strel('disk',strelsize);
mask2 = imdilate(mask1,se); %Expands ROIs by "strelsize" provided by user
mask = mask2;

CC = bwconncomp(mask);
Lmatrix = labelmatrix(CC);
%}

% START TEST OF NEW APPROACH FOR ROI GENERATION

%Estimate background pixels
I = mean(handles.ImageStack,3);
I = imgaussfilt(I,2);
thresh = prctile(I(:),30);
I(I<thresh) = 0;
backgroundMask = imbinarize(I);

% Look in the region around the stimulation (-2 seconds : 3 seconds)
frameRate=str2double(get(handles.enterframerate,'String'));
stimFrame = str2num(get(handles.stimFrameNumber,'String'));
stimRegion = (stimFrame - floor(2*frameRate)):(stimFrame + floor(3*frameRate));
stimStack = handles.ImageStack(:,:,stimRegion);

f0 = mean(stimStack(:,:,1:20),3);
dfof = zeros(size(stimStack));
for i = 1:size(stimStack,3)
    frame = stimStack(:,:,i);
    dfof(:,:,i) = (frame-f0)./f0;
end

dfofMaxProjection = max(dfof,[],3);
dfofMaxProjection(~backgroundMask)=NaN;


I = dfofMaxProjection;
I = medfilt2(I,[3 3]);
%T=graythresh(dfofMaxProjection);
userThreshold = str2double(get(handles.thresholdLevel,'String'));
T = prctile(dfofMaxProjection(~isnan(dfofMaxProjection)),userThreshold);

%USER SET THRESHOLD:
%T=userThreshold./100; %In percent

mask1 = imbinarize(I, T); %Threshold image

%strelsize=get(handles.strelSlider,'Value');
strelsize = 2;
se = strel('disk',strelsize);
mask2 = imerode(mask1,se);
mask3 = imdilate(mask2,se);

mask = mask3;

CC = bwconncomp(mask);
Lmatrix = labelmatrix(CC);
Lmatrix = imdilate(Lmatrix,se);
end
