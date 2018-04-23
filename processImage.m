function [Lmatrix,mask,imagestdsmooth]=processImage(imagestack,strelsize,numopens)
    %Test for negative pixel values and correct.
    if any(imagestack(:)<0)
        imagestack = imagestack-min(imagestack(:));
    end
    
    imagestd = std(imagestack,[],3); %Calculate standard deviation image
    imagemean = mean(imagestack,3); %Calculate average image
    
    imagestdsmooth = medfilt2(imagestd); %Remove noise
    imagemeansmooth=medfilt2(imagemean); %Remove noise
    
    imagestdsmoothnormed = imagestdsmooth./imagemeansmooth; %Normalize STD stack to mean stack
    imagestdsmoothnormed = imagestdsmoothnormed./max(imagestdsmoothnormed(:)); %Norm to 1.
    %imagestdsmoothnormed = imagestdsmooth./max(imagestdsmooth(:)); %Normalize the STD stack so range [0 1]
    imagestdsmoothnormed(isnan(imagestdsmoothnormed)) = 0; %Remove NaN
    
    %Create mask
    mask1 = imbinarize(imagestdsmoothnormed,'adaptive',...
        'ForegroundPolarity','bright','Sensitivity',0.4); %Threshold image
    mask1 = bwareaopen(mask1,10); %Remove ROIs with fewer than 10 pixels
    
    se = strel('disk',strelsize);
    mask2 = imdilate(mask1,se); %Expands ROIs by "strelsize" provided by user
    mask = mask2;
 
    CC = bwconncomp(mask);
    Lmatrix = labelmatrix(CC);
end