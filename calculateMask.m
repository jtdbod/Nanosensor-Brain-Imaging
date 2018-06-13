function [Lmatrix mask]=calculateMask(dfStackMaxSmoothNorm,strelsize,handles)

userThreshold = str2double(get(handles.thresholdLevel,'String'));

T=graythresh(dfStackMaxSmoothNorm)*(userThreshold./100);
%T=adaptthresh(dfStackMaxSmoothNorm,0.1,...
    %'ForegroundPolarity','bright','neigh',51);
%T=graythresh(dfStackMaxSmoothNorm)*1.25;

mask1 = imbinarize(dfStackMaxSmoothNorm, T); %Threshold image
se = strel('disk',strelsize);
mask2 = imdilate(mask1,se); %Expands ROIs by "strelsize" provided by user
mask = mask2;

CC = bwconncomp(mask);
Lmatrix = labelmatrix(CC);

end
