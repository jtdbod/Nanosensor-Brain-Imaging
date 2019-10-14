<<<<<<< HEAD
function [zscoreTrace] = processTrace(trace,frameRate,stimFrameNumber)
=======
function [zscoreTrace] = processTrace(trace,frameRate,stimFrame)
>>>>>>> dev
%trace = currentDataset.measuredValues(1).MeanIntensity;
x=1:length(trace);
window = 20; %seconds
frameWindow = window*frameRate;

<<<<<<< HEAD
xbase = [x(1:stimFrameNumber-10),x(stimFrameNumber+50:end)];
baseline = interp1(xbase,trace(xbase),1:length(x),'loess');
=======
xbase = [x(1:stimFrame-10),x(end-50:end)];
baseline = interp1(xbase,trace(xbase),1:length(trace),'loess');
>>>>>>> dev
smoothTrace = smooth(baseline,frameWindow);

centeredTrace = trace-smoothTrace';
%negIndex = find(centeredTrace<0);
%negIndex = centeredTrace<0;
%noiseDistribution = [centeredTrace(negIndex),-centeredTrace(negIndex)];
noiseDistribution = centeredTrace(xbase);
standardDev = std(noiseDistribution);
%eventIndex = find(centeredTrace>2*standardDev);

zscoreTrace = centeredTrace./standardDev;
end
