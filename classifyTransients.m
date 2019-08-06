function [handles,transientIndex]=classifyTransients(handles,dFF)
%Trying degative transient noise estimation

frameRate = handles.DataSet.frameRate;

x = 1:length(dFF);
x = x./frameRate;
filterWidth = floor(2*frameRate); %In seconds
baselineFilt = movmean(dFF,filterWidth);
%Find negative values of (dF/F0 - baselineFilt). Signal that drops below
%baseline is not associated with a transient fluorescnece intensity spike
%and is used to estimate the fluorescence fluctuation, sigma.

noiseDataIndex = find(dFF<baselineFilt);
noiseData = dFF(noiseDataIndex)-baselineFilt(noiseDataIndex);
%Mirror image the negative noise to create a normal distribution
noiseDataNormal = [noiseData, -noiseData];
%hist(noiseDataNormal);
%Fit a Gaussian to noise histogram
noiseFit = fitdist(noiseDataNormal','normal');
xfit = linspace(min(noiseDataNormal),max(noiseDataNormal),100);
yfit = pdf(noiseFit,xfit);
%{
hist(noiseDataNormal,20);
hold on
plot(xfit,yfit)
%}
sigma = noiseFit.sigma; %STD of the symmetric fluorescence fluctuations around baseline.

%Go through positive values of (dF/F0)-baselineFilt to see which are larger
%than 3*sigma to determine a statistically significant positive transient.
filterWidth = floor(10*frameRate); %In seconds
baselineFilt = movmean(dFF,filterWidth);
baseCorrTrace = dFF - baselineFilt; %Baseline corrected trace
%Create logic vector that indicates whether a frame contains a datapoint
%that is part of a statistically significant positive transient from
%baseline.
transientIndex = zeros(1,length(baseCorrTrace));
%{
figure()
subplot(121)
hold on
%}
for i = 1:length(baseCorrTrace);
    if baseCorrTrace(i) > 3*sigma
        transientIndex(i)=1;
        %plot(x(i),baseCorrTrace(i),'or')
    else
        %plot(x(i),baseCorrTrace(i),'ok')
    end
end
%{
plot(x,baseCorrTrace,'k-');
title('Transient Signal from Baseline')

subplot(122)
plot(x,dFF)
hold on
plot(x,baselineFilt)
title('dF/F0 and smooth baseline')
%}
%Morphologically open the logic array to remove spurious frames classified
%as transient (i.e. single frame outlier). Then close to fill in gaps
%within tracts of frames classified as transients. E.g.
%(000010000)->(000000000) and (011101110)->(011111110).
%{
plot(transientIndex,'k-')
hold on
%}
se = strel('line',1,0);
dilateTransientIndex = imdilate(transientIndex,se);
se = strel('line',4,0);
closeTransientIndex = imclose(dilateTransientIndex,se);
transientIndex = closeTransientIndex;
transientIndex;
%{
plot(dilateTransientIndex,'b--')
hold on
plot(closeTransientIndex,'r:')
fixfig
ylim([0,2])
%}