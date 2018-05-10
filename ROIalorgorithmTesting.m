%% Testing Laplacian of Gaussian filter for image processing.
%{
%%
baselineFrames = 0.05*size(imagestack,3);
f0 = mean(imagestack(:,:,1:baselineFrames),3);
dFstack = (imagestack-f0);
dfStackMax = max(dFstack,[],3);
dfStackMaxSmooth = medfilt2(dfStackMax);
dfStackMaxSmoothNorm = dfStackMaxSmooth./max(dfStackMaxSmooth(:));
I=dfStackMaxSmoothNorm./f0;
I=imadjust(I);
%%

h = fspecial('log',3,20*3.7); %Laplacian of Gaussian filter (sigma = bouton size = 20microns*3.7pix/micron

Ifilt = imfilter(I,h,'replicate');

BW = imbinarize(Ifilt);
[regions cc] = detectMSERFeatures(I);
  
figure(),
subplot(131)
imagesc(I);
subplot(132)
imagesc(Ifilt);
subplot(133)
hold on
imagesc(I);
plot(regions,'showPixelList',true);

%}
%% Non-maximum suppression module

%Cycle through all region center locations

% 1) Calculate distance between each locations (maybe pdist?)
% 2) For each lcoation, find all other locations within ~1 bouton size (4
% microns)
% 3) Find location that has maximum intensity and set location of other to
% that location
% 4) Remove redundant locations

[filename pathname] = uigetfile('*.tif');

fileinfo=imfinfo(strcat(pathname,filename));
height=fileinfo(1).Height;
width=fileinfo(1).Width;
frames=size(fileinfo,1);

imagestack=zeros(height,width,frames);

for j=1:frames
    imagestack(:,:,j)=imread(strcat(pathname,filename),j);   
            % Check for Cancel button press
    disp(j);

end
%%

%background subtract
background = imopen(imagestack(:,:,1),strel('disk',15));

imagestackBacksub = imagestack -background;
baselineFrames = 0.05*size(imagestackBacksub,3);

f0 = mean(imagestackBacksub(:,:,1:baselineFrames),3);
dFstack = (imagestackBacksub-f0);
dfStackMax = max(dFstack,[],3);
dfStackMaxSmooth = medfilt2(dfStackMax);
dfStackMaxSmoothNorm = dfStackMaxSmooth./max(dfStackMaxSmooth(:));
I=dfStackMaxSmoothNorm./f0;
I=dfStackMaxSmoothNorm;
I=imadjust(I);

I2=imtophat(I,strel('disk',round(boutonSize/2)));
level = graythresh(I2);
BW = im2bw(I2,level);
mask = imopen(BW,strel('disk',round(boutonSize/5)));
D = -bwdist(~mask);
D(~mask) = -Inf;
L = watershed(D);

figure()
subplot(131)
imagesc(I2)
subplot(132)
imagesc(mask)
subplot(133)
imagesc(L)


h = fspecial('log',5,boutonSize); %Laplacian of Gaussian filter (sigma = bouton size = 20microns*3.7pix/micron

Ifilt = imfilter(I2,h,'replicate');
regions= detectMSERFeatures(I2);



figure()
hold on
imshow(I2)
hold on
regions.plot


%%
distances = pdist(regions.Location);
distances = squareform(distances);

boutonSize = 4*3.7; %4 microns in pixels

nonMaxSuppressedIndex = ones(1,size(distances,1)); %Logical index for which locations to keep

%Remove stuff bigger than 3 boutons

nonMaxSuppressedIndex(find(regions.Axes(:,1)>3*boutonSize))=0;

for i=1:size(distances,1)
    if nonMaxSuppressedIndex(i) == 1
        neighbors = find(distances(i,:)<boutonSize);
        locs = round(regions.Location(neighbors,:));
        intensityValues = zeros(1,length(locs));
        for j = 1:size(locs,1)
            intensityValues(j) = I(locs(j,2),locs(j,1));
        end
        if (I(round([regions.Location(i,1),regions.Location(i,2)])) < max(intensityValues)) %| (I(round([regions.Location(i,1),regions.Location(i,2)]))<mean(I(:)))
            nonMaxSuppressedIndex(i) = 0;
        end
    end
end

rois = regions.Location(find(nonMaxSuppressedIndex),:);

figure(),scatter(rois(:,1),rois(:,2));

