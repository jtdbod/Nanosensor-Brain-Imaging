I = mean(imageStack,3);
I = imgaussfilt(I,2);
thresh = prctile(I(:),30);

I(I<thresh) = 0;


mask = imbinarize(I);
figure(),imagesc(mask);

%%
% Look in the region around the stimulation (-2 seconds : 3 seconds)
frameRate=str2double(get(handles.enterframerate,'String'));
stimFrame = str2num(get(handles.stimFrameNumber,'String'));
stimRegion = (stimFrame - floor(2./frameRate)):(stimFrame + floor(3./frameRate));
stimStack = handles.DataSet.imageStack(:,:,stimRegion);

f0 = mean(stimStack(:,:,1:20),3);
dfof = zeros(size(stimStack));
for i = 1:size(stimStack,3)
    frame = stimStack(:,:,i);
    dfof(:,:,i) = (frame-f0)./f0;
end

dfofMaxProjection = max(dfof,[],3);
dfofMaxProjection(~mask)=NaN;


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






    



