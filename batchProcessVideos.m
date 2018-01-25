function batchProcessVideos(filetype,frameRate)
clearvars -except filetype frameRate
if strmatch(filetype,'spe');
    files=dir('*.spe');
elseif strmatch(filetype,'tif');
    files=dir('*.tif');
else 
    error('Error. Filetype must be "tif" or "spe"');
end

for i=1:size(files,1)
    fprintf(1,'Processing file %d of %d',[i size(files,1)])
    if strmatch(filetype,'spe')
        %Make progress bar
        barhandle = waitbar(0,'1','Name',sprintf('Processing File %s of %s',num2str(i),num2str(size(files,1))),...
                'CreateCancelBtn',...
                'setappdata(gcbf,''canceling'',1)');
        setappdata(barhandle,'canceling',0)
        [imagestack,filename]=loadIMstackSPE(files,i,barhandle);
    elseif strmatch(filetype,'tif')
        %Make progress bar
        barhandle = waitbar(0,'1','Name',sprintf('Processing File %s of %s',num2str(i),num2str(size(files,1))),...
                'CreateCancelBtn',...
                'setappdata(gcbf,''canceling'',1)');
        setappdata(barhandle,'canceling',0)
        [imagestack,filename]=loadIMstackTIF(files,i,barhandle);
    else
        error('Error. Filetype must be "tif" or "spe"');
    end

        [Lmatrix,mask,imagemed]=processImage(imagestack);
        [measuredValues]=processROI(imagestack,Lmatrix,barhandle);
        if isempty(measuredValues)
            %do nothing
        else
            plotResults(mask,imagemed,measuredValues,frameRate);
            csvwrite(strcat(pwd,'/',filename(1:end-4),'.csv'),measuredValues);
            savefig(strcat(pwd,'/',filename(1:end-4)));
            save(strcat(pwd,'/',filename(1:end-4),'.mat'),'mask','imagemed','measuredValues');
            clear imagestack Lmatrix mask imagemed measuredValues 
            close all
    end
end

delete(findall(0,'Type','Figure'))

end

%Functions defined below

function [imagestack,filename]=loadIMstackSPE(files,i,h) %Load image stacks into variable "imagestack"
    
    fprintf(1,'\n\tLoading frame:\t');
    filename=files(i).name;
    readerobj=SpeReader(files(i).name);
    vidFrames=read(readerobj);
    height=size(vidFrames,1);
    width=size(vidFrames,2);   
    frames=size(vidFrames,4);
     
    imagestack=zeros(height,width,frames);


    
    for j=1:frames

        imagestack(:,:,j)=vidFrames(:,:,1,j);
        fprintf(1,'%d',j)
        fprintf(1,repmat('\b',1,length(num2str(j))))

        % Check for Cancel button press
        if getappdata(h,'canceling')
            delete(h)
            error('Operation terminated by user');
        end
        
        %Update progress bar
        waitbar(j/frames,h,sprintf('Loading frame %i of %i',[j,frames]));
        
    end
        
    fprintf(1,'%d',j)
    fprintf('\n')
end

function [imagestack,filename]=loadIMstackTIF(files,i,h) %Load image stacks into variable "imagestack"
    
    fprintf(1,'\n\tLoading frame:\t');
    filename=files(i).name;
    fileinfo=imfinfo(filename);
    height=fileinfo(1).Height;
    width=fileinfo(1).Width;
    frames=size(fileinfo,1);

    imagestack=zeros(height,width,frames);

    for j=1:frames
        imagestack(:,:,j)=imread(filename,j);   
        fprintf(1,'%d',j)
        fprintf(1,repmat('\b',1,length(num2str(j))))
                % Check for Cancel button press
        if getappdata(h,'canceling')
            delete(h)
            error('Operation terminated by user');
        end
        
        %Update progress bar
        waitbar(j/frames,h,sprintf('Loading frame %i of %i',[j,frames]));
        
    end
    fprintf(1,'%d',j)
    fprintf('\n')
end

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

function [measuredValues]=processROI(imagestack,Lmatrix,h)   
    frames=size(imagestack,3);
    measuredValues = zeros(max(Lmatrix(:)),frames);
    measuredAreas = zeros(max(Lmatrix(:)),frames);
    fprintf(1,'\tCalculating traces (frame):\t')
    for frame = 1:frames
        % Check for Cancel button press
        if getappdata(h,'canceling')
            delete(h)
            error('Operation terminated by user');
        end
        
        %Update progress bar
        waitbar(frame/frames,h,sprintf('ROI processing. Frame %i of %i',[frame,frames]));
        
        %background = mean2(imagestack(:,:,frame));
        %background = mean(background);
        %background = mean(imagestack(:)); %this is a test
        %image=imagestack(:,:,frame)-background;
        image=imagestack(:,:,frame);
        stats=regionprops(Lmatrix,image,'MeanIntensity','Centroid','Area');
        measuredValues(:,frame)=[stats.MeanIntensity];
        measuredAreas(:,frame)=[stats.Area];
        fprintf(1,'%d',frame)
        fprintf(1,repmat('\b',1,length(num2str(frame))))
        
    end
    fprintf(1,'%d',frame)
    fprintf('\n')
end

function []=plotResults(mask,imagemed,measuredValues,frameRate)
    subplot(131)
    [B,L,N,A] = bwboundaries(mask,'noholes');
    imagesc(imagemed); hold on;
    colors=['b' 'g' 'r' 'c' 'm' 'y'];
    for k=1:length(B),
      boundary = B{k};
      cidx = mod(k,length(colors))+1;
      plot(boundary(:,2), boundary(:,1),...
           colors(cidx),'LineWidth',1);

      %randomize text position for better visibility
      rndRow = ceil(length(boundary)/(mod(rand*k,7)+1));
      col = boundary(rndRow,2); row = boundary(rndRow,1);
      h = text(col+1, row-1, num2str(L(row,col)));
      set(h,'Color',colors(cidx),'FontSize',14);
    end
    subplot(132)
    for tracenum=1:size(measuredValues,1)
        %%%%NEED TO WORK ON THIS BASELINE CORRECTION AND NORMALIZATION
        signal = measuredValues(tracenum,:)+abs(min(measuredValues(tracenum,:)));
        signal = signal./max(signal);
        traces(tracenum,:)=signal;
    end
        
    x = 1:size(traces,2);
    x=x./frameRate;
    for trace=1:size(traces,1)
        %smoothed=smooth(traces(trace,:),'rloess');
        plot(x,traces(trace,:)+trace-1);
        %plot(x,smoothed+trace-1)
        text(0,trace,num2str(trace));
        hold on
    end
    xlabel('Time (s)')
    ylabel('Normalized Intensity (a.u.)')
    
    subplot(133)
    imagesc(traces)
    ylabel('ROI#');
    xlabel('Time (s)');
end


function []=correctMotion(imagestack)
    stablestack=zeros(size(imagestack)+1);
    for frame=1:size(imagestack,3)
        
        %{
        [optimizer,metric]=imregconfig('monomodal');
        fixed=mean(imagestack(:,:,1:10),3);
        moving=imagestack(:,:,frame);
        tmatrix = imregtform(moving,fixed,'rigid',optimizer,metric);
        stablestack(:,:,frame) = imwarp(moving,tmatrix);
        frame
        
        
        subplot(121)
        imagesc(imagestack(:,:,frame))
        colorbar
        subplot(122)
        imagesc(stablestack)
        colorbar
        pause(.1)
        %}
        
        
        meanbackground=imopen(mean(imagestack(:,:,1:10),3),se);
        
        subplot(121)
        imagesc(imagestack(:,:,frame))
        colorbar
        subplot(122)
        meanframe = mean(imagestack(:,:,frame));
        meanframe = mean(meanframe);
        meansubimage=imagestack(:,:,frame)-meanframe;
        imagesc(meansubimage)
        colorbar
        pause(.1)
        
    end
    
end


function [baseCorrectedSignal]=correctBaseline(signal)

signal = samplevideo(8,:)
smoothedSignal = smooth(signal);
smoothedSignal = smoothedSignal';
x=1:length(smoothedSignal);
p = polyfit(x,smoothedSignal,3);
y1 = polyval(p,x);
subplot(121)
plot(x,signal), hold on
plot(x,smoothedSignal);
plot(x,y1);
subplot(122)
plot(x,signal./y1);


end

