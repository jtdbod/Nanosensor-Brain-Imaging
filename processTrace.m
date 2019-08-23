function [zscoreTrace] = processTrace(trace,frameRate)
%trace = currentDataset.measuredValues(1).MeanIntensity;
x=1:length(trace);
window = 20; %seconds
frameWindow = window*frameRate;

xbase = [x(1:190),x(end-50:end)];
baseline = interp1(xbase,trace(xbase),1:600,'loess');
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
