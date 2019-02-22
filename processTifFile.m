function [handles] = processTifFile(handles)
if isfield(handles,'ImageStack')
    %Define colormap (Gem adapted from ImageJ, Abraham's favorite)
    colormap(defineGemColormap);
    %Make progress bar
    barhandle = waitbar(0,'ROI processing. Frame %i of %i','Name',sprintf('Processing File 1 of 1'),...
            'CreateCancelBtn',...
            'setappdata(gcbf,''canceling'',1)');
    setappdata(barhandle,'canceling',0)

    %CALCULATE SIZE, VALUES ETC. FOR EACH ROI (stored in roiMask) GENERATED
    %BY BUTTON PRESS OR LOADED FROM PREVIOUS FILE
    handles.DataSet.frameRate = str2double(get(handles.enterframerate,'String'));
    handles.DataSet.thresholdValue = str2double(get(handles.thresholdLevel,'String'));
    [measuredValues]=processROI(handles,barhandle);

    handles.DataSet.measuredValues = measuredValues;

    if ~isempty(measuredValues)
        DataSet = handles.DataSet;
        specifyFilename = get(handles.specifyFilenameFlag,'Value');
        if specifyFilename
            [file path] = uiputfile('*.mat');
            save(strcat(path,file));
        else
            save(strcat(handles.DataSet.pathName,'/',handles.DataSet.fileName(1:end-4),'.mat'),'DataSet');      
        end
        %PLOT THE RESULTS
        plotResults(handles);
        set(handles.CurrentFileLoaded,'String',handles.DataSet.fileName);
        delete(barhandle);
    end
else
    error('Please load imagestack first.')
end



%Generate listbox containing list of each ROI for selection
roiNames = nonzeros(unique(handles.DataSet.roiMask));
roiNamesStr = num2str(roiNames);
set(handles.roi_listbox,'Value',1); %Set "selected" listbox value to 1 to prevent error
set(handles.roi_listbox,'string',roiNamesStr);

end
