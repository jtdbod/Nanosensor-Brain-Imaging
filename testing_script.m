%% Test script

%Test for negative pixel values and correct.
if any(imagestack(:)<0)
    imagestack = imagestack-min(imagestack(:));
end

%Subtract time mean image from every frame

imagestackmean = mean(imagestack,3);
imagestackmeansub = imagestack-imagestackmean;


%%

strelsize=4;

figure()
subplot(251)
imagestdsmooth=medfilt2(imagestd);
imagesc(imagestdsmooth./max(imagestdsmooth(:)))
subplot(252)
imagestackmeansmooth=medfilt2(imagestackmean);
imagesc(imagestackmeansmooth);

imagestdsmoothnorm=imagestdsmooth./imagestackmeansmooth;

subplot(253)
imagesc(imagestdsmoothnorm);
imagestdsmoothnorm(isnan(imagestdsmoothnorm))=0; %Remove NaN


subplot(254)
imagestdsmoothnormed=imagestdsmooth./max(imagestdsmooth(:));
imagesc(imagestdsmoothnormed);
subplot(255)
mask1 = imbinarize(imagestdsmoothnormed,'adaptive','ForegroundPolarity','bright','Sensitivity',0.3);
mask1 = bwareaopen(mask1,10); %Remove ROIs with fewer than 10 pixels
imagesc(mask1)

subplot(256)
se = strel('disk',strelsize);
mask2=imdilate(mask1,se);
imagesc(mask2);

subplot(257)
%mask2=imopen(mask2,se);
imagesc(mask2)

%%
figure()
imagesc(mask2);