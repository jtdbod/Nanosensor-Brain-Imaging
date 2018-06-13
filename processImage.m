function [Lmatrix,mask,stdStack,meanStack,dfStackMaxSmoothNorm]=processImage(imagestack,strelsize,numopens,handles)
    %Test for negative pixel values and correct.
    if any(imagestack(:)<0)
        imagestack = imagestack-min(imagestack(:));
    end
    
    baselineFrames = floor(0.05*size(imagestack,3));
    f0 = mean(imagestack(:,:,1:baselineFrames),3);
    dFstack = (imagestack-f0);
    dfStackMax = max(dFstack,[],3);
    dfStackMaxSmooth = medfilt2(dfStackMax);
    dfStackMaxSmoothNorm = dfStackMaxSmooth./max(dfStackMaxSmooth(:));
    
    

    [Lmatrix,mask]=calculateMask(dfStackMaxSmoothNorm,strelsize,handles);

    
    imagestd = std(imagestack,[],3); %Calculate standard deviation image
    imagemean = mean(imagestack,3); %Calculate average image
    
    imagestdsmooth = medfilt2(imagestd); %Remove noise
    imagemeansmooth=medfilt2(imagemean); %Remove noise

    
    stdStack = imagestdsmooth;
    meanStack = imagemeansmooth;
    
    
    %ORIGINAL CODE
    %{
    imagestd = std(imagestack,[],3); %Calculate standard deviation image
    imagemean = mean(imagestack,3); %Calculate average image
    
    imagestdsmooth = medfilt2(imagestd); %Remove noise
    imagemeansmooth=medfilt2(imagemean); %Remove noise
    meanStack = imagemeansmooth;


    imagestdsmoothnormed = imagestdsmooth./imagemeansmooth; %Normalize STD stack to mean stack
    imagestdsmoothnormed(isnan(imagestdsmoothnormed)) = 0; %Remove NaN
    imagestdsmoothnormed = medfilt2(imagestdsmoothnormed);
    
    
    stdStack = imagestdsmoothnormed;
    imagestdsmoothnormed = imagestdsmoothnormed./max(imagestdsmoothnormed(:)); %Norm to 1.
    %imagestdsmoothnormed = imagestdsmooth./max(imagestdsmooth(:)); %Normalize the STD stack so range [0 1]
    imagestdsmoothnormed=medfilt2(imagestdsmoothnormed);
    imagestdsmoothnormed = imadjust(imagestdsmoothnormed);

    %Create mask
    mask1 = imbinarize(imagestdsmoothnormed,'adaptive',...
        'ForegroundPolarity','bright','Sensitivity',0.2); %Threshold image
    
    mask1 = bwareaopen(mask1,10); %Remove ROIs with fewer than 10 pixels
        
    se = strel('disk',strelsize);
    mask2 = imdilate(mask1,se); %Expands ROIs by "strelsize" provided by user
    mask = mask2;

    CC = bwconncomp(mask);
    Lmatrix = labelmatrix(CC);
    %}
end