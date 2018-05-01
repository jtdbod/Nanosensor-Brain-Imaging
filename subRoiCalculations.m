function subRoiCalculations(handles)
axes(handles.axes2);
cla(handles.axes2);
image = zeros(512,512);
for roiIdx = 1:size(handles.dataset.measuredValues,2)   
    disp(roiIdx)
    disp('of')
    disp(size(handles.dataset.measuredValues,2));
    roi_num=roiIdx;
    
    %Calculate dF/F for each pixel
    pixelValues = handles.dataset.measuredValues(roi_num).PixelValues;
    F0=mean(pixelValues(1:floor((size(pixelValues,1)*.05)),:),1);
    pixelValuesNormed = (pixelValues-F0)./F0;

    R = corrcoef(pixelValuesNormed);
    R = gpuArray(R);
    % rows = observations (frame number); columns = variables (pixels).

    %Run k-means clustering on correlation coefficients to 
    eva = evalclusters(R,'kmeans','CalinskiHarabasz','KList',[1:10]);
    clusterIdx = kmeans(R,eva.OptimalK,'Replicates',5);

    %Plot ROIs with pixel intensity corresponding to cluster index
    frameNum = 1; %Using pixel coordinates from first frame. Assuming they are the same for each.

    %Reconstruct image using color of each pixel as cluster ID
    pixelLocsRow = handles.dataset.measuredValues(roi_num).PixelListRow;
    pixelLocsCol = handles.dataset.measuredValues(roi_num).PixelListCol;
    for pixidx=1:size(pixelValues,2)
        image(pixelLocsRow(frameNum,pixidx),pixelLocsCol(frameNum,pixidx))=clusterIdx(pixidx);
        imagesc(image');
    end
end
disp('test')
imagesc(image');
set(handles.axes2,'Ydir','reverse')
xlim([0 size(image,1)])
ylim([0 size(image,2)])
ylabel('')
xlabel('')

end