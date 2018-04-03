function batchProcessVideos(filetype,frameRate,strelsize,numopens,handles)
clearvars -except filetype frameRate strelsize numopens

if strmatch(filetype,'spe')
    folder = uigetdir();
    files=dir(strcat(folder,'/','*.spe'));
elseif strmatch(filetype,'tif')
    folder = uigetdir();
    files=dir(strcat(folder,'/','*.tif'));
else 
    error('Error. Filetype must be "tif" or "spe"');
end

for i=1:size(files,1)

    if strmatch(filetype,'spe')
        %Make progress bar
        barhandle = waitbar(0,'Loading Frame: x of x','Name',sprintf('Processing File %s of %s',num2str(i),num2str(size(files,1))),...
                'CreateCancelBtn',...
                'setappdata(gcbf,''canceling'',1)');
        setappdata(barhandle,'canceling',0)
        [imagestack,filename]=loadIMstackSPE(folder,files,i,barhandle);
    elseif strmatch(filetype,'tif')
        %Make progress bar
        barhandle = waitbar(0,'1','Name',sprintf('Processing File %s of %s',num2str(i),num2str(size(files,1))),...
                'CreateCancelBtn',...
                'setappdata(gcbf,''canceling'',1)');
        setappdata(barhandle,'canceling',0)
        [imagestack,filename]=loadIMstackTIF(folder,files,i,barhandle);
    else
        error('Error. Filetype must be "tif" or "spe"');
    end

    [Lmatrix,mask,imagemed]=processImage(imagestack,strelsize,numopens);
    [measuredValues]=processROI(imagestack,Lmatrix,barhandle,frameRate);
    if isempty(measuredValues)
        %do nothing
    else
        plotResults(mask,imagemed,measuredValues,frameRate,handles);
        %csvwrite(strcat(folder,'/',filename(1:end-4),'.csv'),measuredValues);
        %savefig(strcat(folder,'/',filename(1:end-4)));
        save(strcat(files(i).folder,'/',files(i).name(1:end-4),'.mat'),'Lmatrix','mask','imagemed','measuredValues');
        clear imagestack Lmatrix mask imagemed measuredValues 
        close all
    end
end

delete(findall(0,'Type','Figure'))

end
