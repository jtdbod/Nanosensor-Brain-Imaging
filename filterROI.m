function S = filterROI(sf,currentDataset)
%this function takes a stimulus frame (sf) and calls sigResp to
%determine if a significant response occurs around the stimulus frame, and
%linBases to determine if the initial and terminal baselines are flat
%enough relative to the response to be considered valid. A new struct is
%returned

n=size(currentDataset.measuredValues,2);%number of ROIs defined

%load each dF/Fo plot into a matrix size i x 600 (600 frames) 

B=[];%declare a matrix, might be able to do preallocation for speed?
for i=1:n
    B=[B;currentDataset.measuredValues(i).dF];
end
%each row of B corresponds to an ROI, each column corresponds to the dF/Fo

%each dataset may have a different number of frames, depending on when
%recording stopped. All ROIs will have the same number of frames, because
%all are in the same dataset, so we determine the number of frames present
%in the first ROI 

frameCount=size(currentDataset.measuredValues(1).dF,2);

frame=1:frameCount; 

%call sigResp function and store the values into hasResp vector
%(true/false)
hasResp=sigResp(B,sf);
linearBaselines=linBases(B,sf);

roiCount=size(B,1);
ROI=1:roiCount;

%validROI is a vector of the ROI indices that have linear baselines and responses
%around the response time
validROI=ROI(hasResp&linearBaselines);

%store the valid dF plots (rows) into a new matrix to save them into a struct
validROIdF = B([validROI],:);

%we care about the ROInum and dF plot for the valid ROI's, we need to
%extract them. The matrix validROIdF has the dF plots, now I need to get
%the ROInum corresponding to each

%declare a matrix C to store the ROInum (constant identifier for each ROI)
C=[];
for i=1:n
    C=[C;currentDataset.measuredValues(i).ROInum];
end

validROInum=C([validROI],:);

%now create validMeasuredValues.dF and .ROInum
validMeasuredValues.dF=validROIdF;
validMeasuredValues.ROInum=validROInum;

%now we need to remove the non-valid ROIs from the mask and LMatrix
nonValidROI=ROI(~hasResp|~linearBaselines);
%store the ROInum constant identifier of the nonValid ROI's
D=[];
for i=1:n
    D=[D;currentDataset.measuredValues(i).ROInum];
end
nonValidROInum=D([nonValidROI],:);

Lmat=currentDataset.Lmatrix;
Mask=currentDataset.mask;
%imshow(Mask)
%imshow(Lmat)

% matrix C contains the ROInum constant identifier of the ROIs with good dF

%iterate through each element in nonValidROInum, change the Mask and Lmat
%(Lmatrix) pixels that have been assigned that invalid ROInum
for i= 1:size(nonValidROInum,1)
    %change the value of nonValidROI pixels in both Lmat and Mask to 0
    %find returns an array of the linear indices of pixels that were invalid
    for j = find(Lmat==nonValidROInum(i))
        Mask(j)=0;
        Lmat(j)=0;
    end
end

%store the validMeasuredValues, validMask, validLmatrix into currentDataset
validMask=Mask;
validLmatrix=Lmat;

currentDataset.validMeasuredValues=validMeasuredValues;
currentDataset.validMask=Mask;
currentDataset.validLmatrix=Lmat;

S=currentDataset;

%plot the Lmatrix to visualize the removed ROIs that were deemed invalid. 
% figure
% subplot(2,2,1)
% image(currentDataset.Lmatrix)
% title('Lmatrix before Linear Baseline and Significant Reponse Filter')
% 
% subplot(2,2,2)
% image(currentDataset.validLmatrix)
% title('After filter')
% 
% subplot(2,2,3)
% imshow(currentDataset.mask)
% title('Mask before Linear Baseline and Significant Reponse Filter')
% 
% subplot(2,2,4)
% imshow(currentDataset.validMask)
% title('After filter')
% end

