%Calculate initial slopes of dF/F spikes


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

end
