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
        barhandle = waitbar(0,'Loading Frame: x of x','Name',sprintf('Processing File %s of %s',num2str(i),num2str(size(files,1))),...
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