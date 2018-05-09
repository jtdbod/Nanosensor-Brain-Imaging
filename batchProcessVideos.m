function [handles]=batchProcessVideos(filetype,frameRate,strelsize,numopens,handles)
clearvars -except filetype frameRate strelsize numopens handles

if strmatch(filetype,'spe')
    folder = uigetdir('*.spe');
    files=dir(strcat(folder,'/','*.spe'));
elseif strmatch(filetype,'tif')
    folder = uigetdir('*.tif');
    files=dir(strcat(folder,'/','*.tif'));
else 
    error('Error. Filetype must be "tif" or "spe"');
end

PathName = folder;

for i=1:size(files,1)

    if strmatch(filetype,'spe')
        %Make progress bar
        barhandle = waitbar(0,'Loading Frame: x of x','Name',sprintf('Processing File 1 of 1'),...
                'CreateCancelBtn',...
                'setappdata(gcbf,''canceling'',1)');
        setappdata(barhandle,'canceling',0)

        [imagestack,filename]=loadIMstackSPE(PathName,files,i,barhandle);
    elseif strmatch(filetype,'tif')
        %Make progress bar
        barhandle = waitbar(0,'1','Name',sprintf('Processing File 1 of 1'),...
                'CreateCancelBtn',...
                'setappdata(gcbf,''canceling'',1)');
        setappdata(barhandle,'canceling',0)

        [imagestack,filename]=loadIMstackTIF(PathName,files,i,barhandle);
    else
        error('Error. Filetype must be "tif" or "spe"');
    end

    strelsize=get(handles.strelSlider,'Value');
    numopens=get(handles.numopens_slider,'Value');

    [Lmatrix,mask,stdStack,avgStack]=processImage(imagestack,strelsize,numopens);
    if true(get(handles.useCurrentROIs,'Value'))
        [measuredValues]=processROI(imagestack,handles.LmatrixFIXED,barhandle,frameRate);
        mask = handles.LmatrixFIXED; %Update mask displayed to represent the "saved" ROIs used for this analysis.
        mask(find(mask))=1; %Need to udpate this eventually so ROIs are not calculated for new video and then thrown away.
    else
        [measuredValues]=processROI(imagestack,Lmatrix,barhandle,frameRate);
    end
    if isempty(measuredValues)
        %do nothing
        delete(barhandle);

    else
        FileName = files(i).name;
        filename=strcat(PathName,'/',FileName(1:end-4));
        save(strcat(filename,'.mat'),'Lmatrix','mask','stdStack','avgStack','measuredValues','filename');
        handles.dataset = load(strcat(filename,'.mat'));

        assignin('base', 'currentDataset', handles.dataset) %Adds all data for the loaded file to the current MATLAB workspace
        plotResults(mask,avgStack,measuredValues,frameRate,handles);
        delete(barhandle);
    end
    
    %Generate listbox containing list of each ROI for selection
    roiNames = nonzeros(unique(handles.dataset.Lmatrix));
    roiNamesStr = num2str(roiNames);
    set(handles.roi_listbox,'Value',1); %Set "selected" listbox value to 1 to prevent error
    set(handles.roi_listbox,'string',roiNamesStr);
end

end
