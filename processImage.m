function [Lmatrix,mask,imagemed]=processImage(imagestack,strelsize,numopens)
    imagestd=std(imagestack,0,3);
    imagemed=medfilt2(imagestd);

    
    image = imagemed./max(imagemed(:));
    mask1 = imbinarize(image,(mean2(image)+3*std2(image)));%, 'adaptive','ForegroundPolarity','bright','Sensitivity',0.5);
    %The above threshold is too high for the Ninox data
    se = strel('disk',strelsize);
    
    for opens=1:numopens
        mask1=imopen(mask1,se);
    end
    mask=mask1;
    CC = bwconncomp(mask);
    Lmatrix = labelmatrix(CC);
end