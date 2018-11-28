function [Lmatrix, mask]=calculateMask(handles)
% GENERATES A BINARY MASK THAT HIGHLIGHTS REGIONS OF INTEREST (ROIS) BASED
% ON AN INTENSITY THRESHOLD CUTOFF AND THE THE MAXIMUM PROJECTION OF (F-F0)
% OR THE VIDEO STACK. REGIONS (PIXELS) THAT UNDERGO A LARGE, POSITIVE
% CHANGE IN INTENSITY OVER TIME WILL BECOME ROIS. PIXEL VALUES WITHIN ROIS
% WILL BE SET TO 1, AND ALL OTHER PIXELS TO 0 ('mask'). THEN, THE ROIS WILL BE
% NUMBERED AND THEIR PIXEL VALUES CHANGED TO REFLECT THE NUMBER OF THE ROI
% ('Lmatrix'). THE CUTOFF THRESHOLD CAN BE SET EITHER ALGORITHMICALLY
% ('graythresh') OR SET AS A FIXED PERCENTAGE USING INPUT FROM THE USER.

userThreshold = str2double(get(handles.thresholdLevel,'String'));
dfStackMaxSmoothNorm = handles.dataset.dfStackMaxSmoothNorm;
%ALGORITHMIC THRESHOLDING:
%T=graythresh(dfStackMaxSmoothNorm)*(userThreshold./100);

%ADAPTICE ALGORIITHMIC THRESHOLDING:
%T=adaptthresh(dfStackMaxSmoothNorm,0.1,...
    %'ForegroundPolarity','bright','neigh',51);
    
%USER SET THRESHOLD:
T=userThreshold./100; %In percent

mask1 = imbinarize(dfStackMaxSmoothNorm, T); %Threshold image
strelsize=get(handles.strelSlider,'Value');
se = strel('disk',strelsize);
mask2 = imdilate(mask1,se); %Expands ROIs by "strelsize" provided by user
mask = mask2;

CC = bwconncomp(mask);
Lmatrix = labelmatrix(CC);

end
