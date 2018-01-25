function [Lmatrix,mask,imagemed]=processImage(imagestack)
    imagestd=std(imagestack,0,3);
    imagemed=medfilt2(imagestd);

    
    image = imagemed./max(imagemed(:));
    mask1 = imbinarize(image,(mean2(image)+3*std2(image)));%, 'adaptive','ForegroundPolarity','bright','Sensitivity',0.5);
    se = strel('disk',2);
    mask2=imopen(mask1,se);
    mask=mask2;
    CC = bwconncomp(mask);
    Lmatrix = labelmatrix(CC);
end