function [params, data_fit] = first_order_curvefit(data, flag, handles)

% Function for fitting first order kinetics that
% Inputs: drift corrected (or raw) columns containing df/f traces 
% output: Parameters of first order decay equations and the function used
% to fit the data points 

stimFrameNumber = str2double(get(handles.stimFrameNumber,'String'));

data_max_find = data; 
data_max_find(1:stimFrameNumber-20,2:end) = 0;
data_max_find(stimFrameNumber+50:end,2:end) = 0; %imposes restriction to ensure only max value between frames 181 and 249 inclusive are considered for each ROI
params = zeros(4,(size(data,2)-1)); %creates column of 3 parameters (constant, tau, and peak height) per ROI 
data_fit = zeros(size(data,1),(size(data,2)-1)); %initialize matrix for the dF/F values with a column per ROI, not including the time column

for i = 2:size(data,2) %loops over columns (ROIs) of data, excluding the time column
    [a,b] = max(data_max_find(:,i)); %a,b = which value and which row the max value is found in, respectively
    %[~,c] = min(data(b:(b+83),i));
    d = mean(data(1:180,i)); 
    e = std(data(1:180,i));
    x0 = [0.01, 0.01]; %pick arbitrary initial values for the constant and tau 
    %endfit = find(data(b:end,i) > d-e & data(b:end,i) < d+e, 1); %ends fit where trace once again falls within one std of mean baseline
    endfit = 50; %End the fit 50 frames after stimulation
    xdata = data(b:(b+endfit-1),1);
    ydata = data(b:(b+endfit-1),i);


    risetime = (b - stimFrameNumber)/handles.DataSet.frameRate;
    
    if flag == 1
        if (a > d+3*e) && (risetime > 0) 
            F = @(x,xdata)x(1)*exp(-x(2)*xdata); %defines first order equation
            opts = optimset('Display','off','Algorithm','levenberg-marquardt');
            params(1:2,i-1) = transpose(lsqcurvefit(F,x0,xdata,ydata,[],[],opts)); %adds the curve fit parameters to the parameter matrix
            params(3,i-1) = a; %adds the max trace value to the parameter matrix
            params(4,i-1) = risetime; %adds the time to peak to the parameter matrix
            data_fit(b:(b+endfit-1),i-1) = F(transpose(params(:,i-1)),xdata); %fits function over the specified points 
        else
        end
    else 
        F = @(x,xdata)x(1)*exp(-x(2)*xdata);
        opts = optimset('Display','off');
        params(1:2,i-1) = transpose(lsqcurvefit(F,x0,xdata,ydata,[],[],opts)); %adds the curve fit parameters to the parameter matrix
        params(3,i-1) = a; %adds the max trace value to the parameter matrix
        params(4,i-1) = risetime; %adds the time to peak to the parameter matrix
        data_fit(b:(b+endfit-1),i-1) = F(transpose(params(:,i-1)),xdata); %fits function over the specified points 
    end
end

%{


% decay time constants, tau

tau=1./(x(:,2));

% stat plots of tau

boxplot(tau);
ylabel('\tau (s)')

histogram(Tau,50);
xlabel('\tau (s)')
ylabel('frequency')
xlim([0 10])

% plot tau vs. ?F/F max
scatter(tau,a');
xlim([0 5])

% Compute latency to peak
for i=1:size(ROI_Select,2)
    if b(i)<200
        b(i)=205;
    end 
end
 
lat_frame=b-200;
lat_time=lat_frame/8.3; % 8.3 is imaging frames per second. Replace appropriately.

%plot ?F/F max vs. latency
scatter(lat_time,a);
xlim([0 2])

%plot latency vs. tau
scatter(lat_time',tau)
xlim([0 2])

histogram(lat_time,500)
xlim([0 2])

%}





