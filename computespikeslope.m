%Calculate initial slopes of dF/F spikes

%TO DO: need to integrate this into the GUI
batchcomputespikeslope(frameRate)
function [spikeSlopes,roiNumbers]=computespikeslope(measuredValues,frameRate,spikeSlopes,roiNumbers)

numTraces=size(measuredValues,2);
tableLabels = {'File','ROI-#','Calculated Slope'};

%spikeSlopes=[]; %Store slopes in this array
%fileNumbers = []; %Stores file number for each slope measurements
%roiNumbers = []; %Stores roiNumber for each slope measurement

for itrace=1:numTraces
    dfTrace = measuredValues(itrace).dF;
    smoothTrace=smooth(dfTrace,50,'sgolay');
    traceDiff=diff(smoothTrace).*frameRate;
    spikeSlope=max(traceDiff);
    spikeSlopes = [spikeSlopes spikeSlope]; %append new value
    %fileNumbers = [fileNumbers ifileNumber];
    roiNumbers = [roiNumbers itrace];
    
    
    %{
    subplot(131)
    plot(dfTrace);
    subplot(132)
    plot(smoothTrace)
    subplot(133)
    plot(traceDiff)
    pause
    %}
    
end

%table(roiNumbers,spikeSlopes);
%{
subplot(121)
notBoxPlot(spikeSlopes);
xlabel('File Num')
ylabel('Slope ([dF/F]/s)')
fixfig
subplot(122)
hist(spikeSlopes)
xlabel('Slope ([dF/F]/s)')
ylabel('Counts')
fixfig
%}
end

function [spikeSlopes,roiNumbers]=batchcomputespikeslope(frameRate)

    folder = uigetdir();
    files=dir(strcat(folder,'/','*.mat'));
    
    spikeSlopes=[]; %Store slopes in this array
    %fileNumbers = []; %Stores file number for each slope measurements
    roiNumbers = []; %Stores roiNumber for each slope measurement
    for ifile = 1:length(files)
        
        load(strcat(folder,'/',files(ifile).name),'measuredValues');
        [spikeSlopes,roiNumbers]=computespikeslope(measuredValues,frameRate,spikeSlopes,roiNumbers)
    end
    
subplot(121)
notBoxPlot(spikeSlopes);
xlabel('File Num')
ylabel('Slope ([dF/F]/s)')
fixfig
subplot(122)
hist(spikeSlopes)
xlabel('Slope ([dF/F]/s)')
ylabel('Counts')
fixfig
    
end


