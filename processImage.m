function [Lmatrix,mask,imagemed]=processImage(imagestack,strelsize,numopens)
    imagestd=std(imagestack,0,3); %Standard deviation of video stack for each pixel
    imagemed=medfilt2(imagestd); %Smoothing filter to eliminate noise.
    
    %Testing: normalize the SD to the mean pixel intensity.
    imageavg=mean(imagestack,3);
    
    image = imagemed./max(imagemed(:));
    image2 = imadjust(image);
    image2 = medfilt2(image2);
    mask1 = imbinarize(image2,(mean2(image2)+3*std2(image2)));%, 'adaptive','ForegroundPolarity','bright','Sensitivity',0.5);
    mask1 = bwareaopen(mask1,10); %Remove ROIs with fewer than 10 pixels
    %The above threshold is too high for the Ninox data
    %thresh=multithresh(image2);
    se = strel('disk',strelsize);
    mask2=mask1;
    %{
    for opens=1:numopens
        mask2=imopen(mask2,se);
    end
    %}
    mask=mask2;
    CC = bwconncomp(mask);
    Lmatrix = labelmatrix(CC);
end