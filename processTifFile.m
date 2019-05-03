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
    
    
    %Calculate whether transients are significant
    transientIndices = zeros(size(measuredValues,2),size(measuredValues(1).dF,2));
    numROIs = size(measuredValues,2);
    for roiNum = 1:numROIs
        dFF = measuredValues(roiNum).dF;
        [handles transientIndex] = classifyTransients(handles, dFF);
        transientIndices(roiNum,:) = transientIndex;
    end

    % Check if trace contains significant transient after stimulation
    stimFrame = str2double(get(handles.stimFrameNumber,'String'));
    frameNumbers = stimFrame-10:stimFrame+50;
    isSignificant = zeros(size(transientIndices,1),1);
    %Set condition for "significance": Are more than 10% of points after
    %stimulation signficiant?
    isSignificant = zeros(1,size(transientIndices,1));
    for i = 1:size(transientIndices,1)
        if sum(transientIndices(i,frameNumbers))/length(transientIndices(i,frameNumbers))>0.1
            measuredValues(i).isSignificant = 1;
            isSignificant(i) = 1;
        else
            measuredValues(i).isSignificant = 0;
        end
    end
    
    filteredMeasuredData = measuredValues(find(isSignificant));
    %Renumber ROIs in roiMask
    roiMask = handles.DataSet.roiMask;
    newROInum = 1;
    for i = 1:size(transientIndices,1)
        if isSignificant(i)
            logInd = roiMask==i;
            roiMask(logInd)=newROInum;
            filteredMeasuredData(newROInum).roiNUM = newROInum;
            newROInum = newROInum+1;

        else
            logInd = roiMask==i;
            roiMask(logInd)=0;
        end
    end

    handles.DataSet.measuredValues = filteredMeasuredData;
    handles.DataSet.roiMask = roiMask;

    %Save dataset to file
    if ~isempty(filteredMeasuredData)
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
