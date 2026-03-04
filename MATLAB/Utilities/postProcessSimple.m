function [data] =  postProcessSimple(station,start_date,end_date,averagingPeriod)
% Marine Wave Boundary Layer Analysis
% Script for plotting ensemble averaged variables collected from the data
% collection
%
% Written by Kayhan Ulgen
%
% Inputs:
%   station 		- structure variable from ATI or Gill sonic, or single DPL ATI (e.g., H1)
%   substation	    - averaging period (s)
%   start_date      - data collection start date in 'MM/dd/yyyy HH:mm:ss' in format
%   end_date        - data collection end date in 'MM/dd/yyyy HH:mm:ss' in format
%   averagingPeriod - ensemble averaging period in minutes.
%   12/15/2023      - data is collected via get_MWBL_data beased on the locations
%   12/15/2023      - sunrise and sundown times are calculated by suncycle function and recorded 
%   12/18/2023      - ensemble averaged variables are calculated based on variable list.
%   12/22/2023      - compare sampling frequency and averaging frequency. Ensemble average or interpolate based on the comparison
%   12/26/2023      - fixed the errors in the plots.
%   12/27/2023      - corrected paths for saving graphs.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% start_date = '12/01/2023 00:00:00';
% end_date = '12/02/2023 23:59:59';
averagingPeriod = seconds(minutes(averagingPeriod));
averagingFrequency =  1/averagingPeriod;
dt_format = 'MM/dd/yyyy HH:mm:ss';

start_date = datetime(start_date,'Format',dt_format);
end_date = datetime(end_date,'Format',dt_format);

outpath = '/usr2/MWBL/QA_QC_Analysis/';
savepath = ([outpath,station,'_Analysis_',datestr(start_date,'mmddyyyy'),'_',datestr(end_date,'mmddyyyy'),'/']);
mkdir(savepath);
%% Sunrise and Sunset Times
if strcmp(station,'SMAST')   
    data.(station).Location.Lat = 41.5941667;
    data.(station).Location.Lon = -70.9111111;
elseif strcmp(station,'NBCBC')
    data.(station).Location.Lat = 41.6083333;
    data.(station).Location.Lon = -70.9302778;
end
% Compute Sunrise and Sunset arrays
d1 = datenum(start_date - caldays(1)) ;
d2 = datenum(end_date + caldays(1));
d = d1:d2;
for k = 1:numel(d)
    [rs,~,~,~,~,~] = suncycle(data.(station).Location.Lat,data.(station).Location.Lon,d(k),2880);
    sunrise_times(k,1) = rs(1); sunset_times(k,1) = rs(2);
    data.(station).Location.sunrise.date_time(k,1) = datetime(datetime(d(k),'ConvertFrom','datenum') + hours(sunrise_times(k,1)),'Format',dt_format);
    data.(station).Location.sunset.date_time(k,1) = datetime(datetime(d(k),'ConvertFrom','datenum') + hours(sunset_times(k,1)),'Format',dt_format);
end
%% Load Data
if strcmp(station,'SMAST')
    data.(station).Gill = get_MWBL_data(start_date,end_date,'Lattice_SMAST_Station1','Gill');
    data.(station).ATI = get_MWBL_data(start_date,end_date,'Lattice_SMAST_Station1','ATI');
    data.(station).DataQ = get_MWBL_data(start_date,end_date,'Lattice_SMAST_Station1','DataQ');
    data.(station).DPL = get_MWBL_data(start_date,end_date,'DPL_SMAST',[]);
    data.(station).RainwisePortLog = get_MWBL_data(start_date,end_date,'RainwisePortLog','13449');
    data.(station).OnsetHOBO = get_MWBL_data(start_date,end_date,'OnsetHOBO','21265947');

elseif strcmp(station,'NBCBC')
    data.(station).ATI = get_MWBL_data(start_date,end_date,'Lattice_CBC_Station2','ATI');
    data.(station).DataQ = get_MWBL_data(start_date,end_date,'Lattice_CBC_Station2','DataQ');
    data.(station).DPL = get_MWBL_data(start_date,end_date,'DPL_CBC',[]);
    data.(station).RainwisePortLog = get_MWBL_data(start_date,end_date,'RainwisePortLog','13448');
    data.(station).OnsetHOBO = get_MWBL_data(start_date,end_date,'OnsetHOBO','21265946');
end

data.(station).KZScintillometer = get_MWBL_data(start_date,end_date,'KZScintillometer',[]);
data.(station).NBAirport = get_MWBL_data(start_date,end_date,'NBAirport',[]);

%% Find the missing timestamp and add NaN

%% Adjust the Heights to Mean Sea Level
MHW = 0.78;		                % (m NAVD88)		                        % per pier As-Built plans, dated 4/9/2007
MLW =-0.30;		                % (m NAVD88)		                        % per pier As-Built plans, dated 4/9/2007

if strcmp(station,'SMAST')
    data.(station).height = 2.86;  % (m NAVD88)		                        % SMAST pier, average of landward end, seaward end, tower
    data.(station).height_offset = data.(station).height-(MHW+MLW)/2;
    data.(station).Gill.zLevel = data.(station).Gill.elevation + data.(station).height_offset;
    data.(station).ATI.zLevel = data.(station).ATI.elevation + data.(station).height_offset;
    for numSens = 1:5
        data.(station).DPL.(['H',num2str(numSens)]).zLevel = data.(station).DPL.elevation.(['H',num2str(numSens)]) + data.(station).height_offset;
    end
elseif strcmp(station,'NBCBC')
    data.(station).height = 2.40;  % (m NAVD88)		                        % NBCBC jetty next to MWBL tower
    data.(station).height_offset = data.(station).height-(MHW+MLW)/2;
        data.(station).ATI.zLevel = data.(station).ATI.elevation + data.(station).height_offset;
        for numSens = 1:5
            data.(station).DPL.(['H',num2str(numSens)]).zLevel = data.(station).DPL.elevation.(['H',num2str(numSens)]) + data.(station).height_offset;
        end
end
%% Find Sampling Frequency
if strcmp(station,'SMAST')
    data.(station).Gill.samplingFrequency       = ceil(1./seconds(median(diff(data.(station).Gill.date_time))));
end
data.(station).ATI.samplingFrequency        = ceil(1./seconds(median(diff(data.(station).ATI.date_time))));
data.(station).DataQ.samplingFrequency      = ceil(1./seconds(median(diff(data.(station).DataQ.date_time))));
data.(station).DPL.samplingFrequency        = ceil(1./seconds(median(diff(data.(station).DPL.date_time))));
data.(station).RainwisePortLog.samplingFrequency             = (1./seconds(median(diff(data.(station).RainwisePortLog.date_time))));
data.(station).OnsetHOBO.samplingFrequency                   = (1./seconds(median(diff(data.(station).OnsetHOBO.date_time))));
data.(station).KZScintillometer.samplingFrequency            = ceil(1./seconds(median(diff(data.(station).KZScintillometer.date_time))));
data.(station).NBAirport.samplingFrequency                   = ceil(1./seconds(median(diff(data.(station).NBAirport.date_time))));

%% Resample Data
if strcmp(station,'SMAST')
    % GILL
    for nn = 2:length(data.(station).Gill.variables)
        if ~all(isnan(data.(station).Gill.([data.(station).Gill.variables{nn}])))
            [data.(station).Gill.(data.(station).Gill.variables{nn}),data.(station).Gill.date_time_resampled] = ...
                resample(double(data.(station).Gill.([data.(station).Gill.variables{nn}])), data.(station).Gill.date_time, data.(station).Gill.samplingFrequency,'pchip');
        else
            data.(station).Gill.date_time_resampled= (data.(station).Gill.date_time(1):seconds(1/data.(station).Gill.samplingFrequency):data.(station).Gill.date_time(end))';
            data.(station).Gill.(data.(station).Gill.variables{nn}) = NaN(size(data.(station).Gill.(data.(station).Gill.date_time_resampled)),1);
        end
    end
    %ATI
    for nn = 2:length(data.(station).ATI.variables)
        if ~all(isnan(data.(station).ATI.([data.(station).ATI.variables{nn}])))
            [data.(station).ATI.(data.(station).ATI.variables{nn}),data.(station).ATI.date_time_resampled] = ...
                resample(double(data.(station).ATI.([data.(station).ATI.variables{nn}])), data.(station).ATI.date_time, data.(station).ATI.samplingFrequency,'pchip');
        else
            data.(station).ATI.date_time_resampled= (data.(station).ATI.date_time(1):seconds(1/data.(station).ATI.samplingFrequency):data.(station).ATI.date_time(end))';
            data.(station).ATI.(data.(station).ATI.variables{nn}) = NaN(size(data.(station).ATI.(data.(station).ATI.date_time_resampled)),1);
        end
    end
    % DPL
    for nn = 2:length(data.(station).DPL.variables)
        for numSens = 1:5
            if ~all(isnan(data.(station).DPL.(['H',num2str(numSens)]).(data.(station).DPL.variables{nn})))
                [data.(station).DPL.(['H',num2str(numSens)]).(data.(station).DPL.variables{nn}),...
                    data.(station).DPL.date_time_resampled] =...
                    resample(double(data.(station).DPL.(['H',num2str(numSens)]).([data.(station).DPL.variables{nn}])), ...
                    data.(station).DPL.date_time, data.(station).DPL.samplingFrequency,'pchip');
            else
                data.(station).DPL.date_time_resampled = (data.(station).DPL.date_time(1):seconds(1/data.(station).DPL.samplingFrequency):data.(station).DPL.date_time(end))';
                data.(station).DPL.(['H',num2str(numSens)]).(data.(station).DPL.variables{nn}) = NaN(size(data.(station).DPL.date_time_resampled));
            end
        end
    end
end
%% Determine Colormap
cmap = distinguishable_colors(12);
if strcmp(station,'SMAST')
    data.(station).Gill.color = cmap(1,:);
    data.(station).ATI.color = cmap(2,:);
    data.(station).DataQ.color_lwr = cmap(3,:);
    data.(station).DataQ.color_upr = cmap(4,:);
    for numSens=1:5
        data.(station).DPL.(['H',num2str(numSens)]).color = cmap(numSens,:);
    end
    data.(station).RainwisePortLog.color = cmap(10,:);
    data.(station).OnsetHOBO.color = cmap(11,:);
    data.(station).NBAirport.color = cmap(12,:);
    data.(station).KZScintillometer.color = cmap(13,:);
end
figScaleFactor = 1.5;
%% Coordinate Transformation from Earth-North-Up (ENU) coordinates to Streamwise Coordinates
% SMAST Lattice Gill
if strcmp(station,'SMAST')
    data.(station).Gill.streamCoordData = convertToStreamwiseCoordinates(data.(station).Gill, data.(station).Gill.samplingFrequency, averagingPeriod);
end
%SMAST & NBCBC Lattice ATI
data.(station).ATI.streamCoordData = convertToStreamwiseCoordinates(data.(station).ATI, data.(station).ATI.samplingFrequency, averagingPeriod);
%SMAST & NBCBC Tower DPL
for numSens = 1:5
    data.(station).DPL.(['H',num2str(numSens)]).streamCoordData = convertToStreamwiseCoordinates(data.(station).DPL.(['H',num2str(numSens)]), data.(station).DPL.samplingFrequency, averagingPeriod);
end
%% Tilt Correction Algorithm via Planar Fit Method
% SMAST Lattice Gill
if strcmp(station,'SMAST')
    [data.(station).Gill.u_stream, data.(station).Gill.v_stream, data.(station).Gill.w_stream] = tiltCorrection(data.(station).Gill);
end
%SMAST & NBCBC Lattice ATI
[data.(station).ATI.u_stream, data.(station).ATI.v_stream, data.(station).ATI.w_stream] = tiltCorrection(data.(station).ATI);
%SMAST & NBCBC Tower DPL
for numSens = 1:5
    [data.(station).DPL.(['H',num2str(numSens)]).u_stream, data.(station).DPL.(['H',num2str(numSens)]).v_stream, data.(station).DPL.(['H',num2str(numSens)]).w_stream]= tiltCorrection(data.(station).DPL.(['H',num2str(numSens)]));
end
%% Ensemble Statistics of Variables
variables = {'u';'v';'w';'u_stream';'v_stream';'w_stream';'WindSpd';'WindDir';'T_Air';'T_Air_upr';'T_Air_lwr';'T_Water';'RelHumid';'RelHumid_upr';'RelHumid_lwr';'Baro';'SRad';'Precip';'NetRad';'Pyr';'WL';'Cn2'};

if strcmp(station,'SMAST') && strcmp(substation,'Lattice')
    [data.(station).Gill.ensembledData.date_time_datenum_mean,~,~,~] = ensembleStatistics(datenum(data.(station).Gill.date_time), data.(station).Gill.samplingFrequency, averagingPeriod);
    data.(station).Gill.ensembledData.date_time_mean = datetime(data.(station).Gill.ensembledData.date_time_datenum_mean,'Format','MM/dd/yyyy HH:mm:ss','convertFrom','datenum');

    [data.(station).ATI.ensembledData.date_time_datenum_mean,~,~,~] = ensembleStatistics(datenum(data.(station).ATI.date_time), data.(station).ATI.samplingFrequency, averagingPeriod);
    data.(station).ATI.ensembledData.date_time_mean = datetime(data.(station).ATI.ensembledData.date_time_datenum_mean,'Format','MM/dd/yyyy HH:mm:ss','convertFrom','datenum');

    if averagingFrequency > data.(station).DataQ.samplingFrequency
        [data.(station).DataQ.ensembledData.date_time_datenum_mean,~,~,~] = ensembleStatistics(datenum(data.(station).DataQ.date_time), data.(station).DataQ.samplingFrequency, averagingPeriod);
        data.(station).DataQ.ensembledData.date_time_mean = datetime(data.(station).DataQ.ensembledData.date_time_datenum_mean,'Format','MM/dd/yyyy HH:mm:ss','convertFrom','datenum');
    else
        data.(station).DataQ.ensembledData.date_time_mean = linspace(data.(station).DataQ.date_time(1),data.(station).DataQ.date_time(end),averagingPeriod*data.(station).DataQ.samplingFrequency);
    end

    for nn = 1 : length(variables)
        if isfield(data.(station).Gill,variables{nn})
            [data.(station).Gill.ensembledData.([(variables{nn}),'_mean']) ,data.(station).Gill.ensembledData.([(variables{nn}),'_prime']),data.(station).Gill.ensembledData.([(variables{nn}),'_var']),data.(station).Gill.ensembledData.([(variables{nn}),'_std']) ] = ensembleStatistics(data.(station).Gill.(variables{nn}), data.(station).Gill.samplingFrequency, averagingPeriod);
        end
        if isfield(data.(station).ATI,variables{nn})
            [data.(station).ATI.ensembledData.([(variables{nn}),'_mean']) ,data.(station).ATI.ensembledData.([(variables{nn}),'_prime']),data.(station).ATI.ensembledData.([(variables{nn}),'_var']),data.(station).ATI.ensembledData.([(variables{nn}),'_std']) ] = ensembleStatistics(data.(station).ATI.(variables{nn}), data.(station).ATI.samplingFrequency, averagingPeriod);
        end
        if isfield(data.(station).DataQ,variables{nn})
            if averagingFrequency > data.(station).DataQ.samplingFrequency
                [data.(station).DataQ.ensembledData.([(variables{nn}),'_mean']) ,data.(station).DataQ.ensembledData.([(variables{nn}),'_prime']),data.(station).DataQ.ensembledData.([(variables{nn}),'_var']),data.(station).DataQ.ensembledData.([(variables{nn}),'_std']) ] = ensembleStatistics(data.(station).DataQ.(variables{nn}), data.(station).DataQ.samplingFrequency, averagingPeriod);
            else
                data.(station).DataQ.ensembledData.([(variables{nn}),'_mean']) = interp1(data.(station).DataQ.date_time, data.(station).DataQ.([variables{nn}]) ,data.(station).DataQ.ensembledData.date_time_mean);
            end
        end
    end
elseif strcmp(station,'NBCBC') && strcmp(substation,'Lattice')
    [data.(station).ATI.ensembledData.date_time_datenum_mean,~,~,~] = ensembleStatistics(datenum(data.(station).ATI.date_time), data.(station).ATI.samplingFrequency, averagingPeriod);
    data.(station).ATI.ensembledData.date_time_mean = datetime(data.(station).ATI.ensembledData.date_time_datenum_mean,'Format','MM/dd/yyyy HH:mm:ss','convertFrom','datenum');
    
    if averagingFrequency > data.(station).DataQ.samplingFrequency
        [data.(station).DataQ.ensembledData.date_time_datenum_mean,~,~,~] = ensembleStatistics(datenum(data.(station).DataQ.date_time), data.(station).DataQ.samplingFrequency, averagingPeriod);
        data.(station).DataQ.ensembledData.date_time_mean = datetime(data.(station).DataQ.ensembledData.date_time_datenum_mean,'Format','MM/dd/yyyy HH:mm:ss','convertFrom','datenum');
    else
        data.(station).DataQ.ensembledData.date_time_mean = linspace(data.(station).DataQ.date_time(1),data.(station).DataQ.date_time(end),averagingPeriod*data.(station).DataQ.samplingFrequency);
    end

    for nn = 1 : length(variables)
        if isfield(data.(station).ATI,variables{nn})
            [data.(station).ATI.ensembledData.([(variables{nn}),'_mean']) ,data.(station).ATI.ensembledData.([(variables{nn}),'_prime']),data.(station).ATI.ensembledData.([(variables{nn}),'_var']),data.(station).ATI.ensembledData.([(variables{nn}),'_std']) ] = ensembleStatistics(data.(station).ATI.(variables{nn}), data.(station).ATI.samplingFrequency, averagingPeriod);
        end
        if isfield(data.(station).DataQ,variables{nn})
            if averagingFrequency > data.(station).DataQ.samplingFrequency
                [data.(station).DataQ.ensembledData.([(variables{nn}),'_mean']) ,data.(station).DataQ.ensembledData.([(variables{nn}),'_prime']),data.(station).DataQ.ensembledData.([(variables{nn}),'_var']),data.(station).DataQ.ensembledData.([(variables{nn}),'_std']) ] = ensembleStatistics(data.(station).DataQ.(variables{nn}), data.(station).DataQ.samplingFrequency, averagingPeriod);
            else
                data.(station).DataQ.ensembledData.([(variables{nn}),'_mean']) = interp1(data.(station).DataQ.date_time, data.(station).DataQ.([variables{nn}]) ,data.(station).DataQ.ensembledData.date_time_mean);
            end
        end
    end
elseif strcmp(substation,'Tower')
    [data.(station).DPL.ensembledData.date_time_datenum_mean,~,~,~] = ensembleStatistics(datenum(data.(station).DPL.date_time), data.(station).DPL.samplingFrequency, averagingPeriod);
    for numSens = 1:5
        data.(station).DPL.(['H',num2str(numSens)]).ensembledData.date_time_mean = datetime(data.(station).DPL.ensembledData.date_time_datenum_mean,'Format','MM/dd/yyyy HH:mm:ss','convertFrom','datenum');
    end
    for numSens = 1:5
        for nn = 1 : length(variables)
            if isfield(data.(station).DPL.(['H',num2str(numSens)]), variables{nn})
                [data.(station).DPL.(['H',num2str(numSens)]).ensembledData.([(variables{nn}),'_mean']) ,data.(station).DPL.(['H',num2str(numSens)]).ensembledData.([(variables{nn}),'_prime']),data.(station).DPL.(['H',num2str(numSens)]).ensembledData.([(variables{nn}),'_var']),data.(station).DPL.(['H',num2str(numSens)]).ensembledData.([(variables{nn}),'_std']) ] = ensembleStatistics(data.(station).DPL.(['H',num2str(numSens)]).(variables{nn}), data.(station).DPL.samplingFrequency, averagingPeriod);
            end
        end
    end
elseif isempty
    if averagingFrequency > data.(station).RainwisePortLog.samplingFrequency
        [data.(station).RainwisePortLog.ensembledData.date_time_datenum_mean,~,~,~] = ensembleStatistics(datenum(data.(station).RainwisePortLog.date_time), data.(station).RainwisePortLog.samplingFrequency, averagingPeriod);
        data.(station).RainwisePortLog.ensembledData.date_time_mean = datetime(data.(station).RainwisePortLog.ensembledData.date_time_datenum_mean,'Format','MM/dd/yyyy HH:mm:ss','convertFrom','datenum');
    else
        data.(station).RainwisePortLog.ensembledData.date_time_mean = linspace(data.(station).RainwisePortLog.date_time(1),data.(station).RainwisePortLog.date_time(end),averagingPeriod*data.(station).RainwisePortLog.samplingFrequency);
    end
    if averagingFrequency > data.(station).OnsetHOBO.samplingFrequency
        [data.(station).OnsetHOBO.ensembledData.date_time_datenum_mean,~,~,~] = ensembleStatistics(datenum(data.(station).OnsetHOBO.date_time), data.(station).OnsetHOBO.samplingFrequency, averagingPeriod);
        data.(station).OnsetHOBO.ensembledData.date_time_mean = datetime(data.(station).OnsetHOBO.ensembledData.date_time_datenum_mean,'Format','MM/dd/yyyy HH:mm:ss','convertFrom','datenum');
    else
        data.(station).OnsetHOBO.ensembledData.date_time_mean = linspace(data.(station).DataQ.date_time(1),data.(station).DataQ.date_time(end),averagingPeriod*data.(station).DataQ.samplingFrequency);
    end
    if averagingFrequency > data.(station).NBAirport.samplingFrequency
        [data.(station).NBAirport.ensembledData.date_time_datenum_mean,~,~,~] = ensembleStatistics(datenum(data.(station).NBAirport.date_time), data.(station).NBAirport.samplingFrequency, averagingPeriod);
        data.(station).NBAirport.ensembledData.date_time_mean = datetime(data.(station).NBAirport.ensembledData.date_time_datenum_mean,'Format','MM/dd/yyyy HH:mm:ss','convertFrom','datenum');
    else
        data.(station).NBAirport.ensembledData.date_time_mean = linspace(data.(station).NBAirport.date_time(1),data.(station).NBAirport.date_time(end),averagingPeriod*data.(station).NBAirport.samplingFrequency);
    end
    if averagingFrequency > data.(station).KZScintillometer.samplingFrequency
        [data.(station).KZScintillometer.ensembledData.date_time_datenum_mean,~,~,~] = ensembleStatistics(datenum(data.(station).KZScintillometer.date_time), data.(station).KZScintillometer.samplingFrequency, averagingPeriod);
        data.(station).KZScintillometer.ensembledData.date_time_mean = datetime(data.(station).KZScintillometer.ensembledData.date_time_datenum_mean,'Format','MM/dd/yyyy HH:mm:ss','convertFrom','datenum');
    else
        data.(station).KZScintillometer.ensembledData.date_time_mean = linspace(data.(station).KZScintillometer.date_time(1),data.(station).KZScintillometer.date_time(end),averagingPeriod*data.(station).KZScintillometer.samplingFrequency);
    end

    for nn = 1 : length(variables)
        if isfield(data.(station).RainwisePortLog.variables{nn})
            if averagingFrequency > data.(station).RainwisePortLog.samplingFrequency
                [data.(station).RainwisePortLog.ensembledData.([(variables{nn}),'_mean']) ,data.(station).RainwisePortLog.ensembledData.([(variables{nn}),'_prime']),data.(station).RainwisePortLog.ensembledData.([(variables{nn}),'_var']),data.(station).RainwisePortLog.ensembledData.([(variables{nn}),'_std']) ] = ensembleStatistics(data.(station).RainwisePortLog.(variables{nn}), data.(station).RainwisePortLog.samplingFrequency, averagingPeriod);
            else
                data.(station).RainwisePortLog.ensembledData.([(variables{nn}),'_mean']) = interp1(data.(station).RainwisePortLog.date_time, data.(station).RainwisePortLog.([variables{nn}]) ,data.(station).RainwisePortLog.ensembledData.date_time_mean);
            end
        end
        if isfield(data.(station).OnsetHOBO.variables{nn})
            if averagingFrequency > data.(station).OnsetHOBO.samplingFrequency
                [data.(station).OnsetHOBO.ensembledData.([(variables{nn}),'_mean']) ,data.(station).OnsetHOBO.ensembledData.([(variables{nn}),'_prime']),data.(station).OnsetHOBO.ensembledData.([(variables{nn}),'_var']),data.(station).OnsetHOBO.ensembledData.([(variables{nn}),'_std']) ] = ensembleStatistics(data.(station).OnsetHOBO.(variables{nn}), data.(station).OnsetHOBO.samplingFrequency, averagingPeriod);
            else
                data.(station).OnsetHOBO.ensembledData.([(variables{nn}),'_mean']) = interp1(data.(station).OnsetHOBO.date_time, data.(station).OnsetHOBO.([variables{nn}]) ,data.(station).OnsetHOBO.ensembledData.date_time_mean);
            end
        end
        if isfield(data.(station).NBAirport.variables{nn})
            if averagingFrequency > data.(station).NBAirport.samplingFrequency
                [data.(station).NBAirport.ensembledData.([(variables{nn}),'_mean']) ,data.(station).NBAirport.ensembledData.([(variables{nn}),'_prime']),data.(station).NBAirport.ensembledData.([(variables{nn}),'_var']),data.(station).NBAirport.ensembledData.([(variables{nn}),'_std']) ] = ensembleStatistics(data.(station).NBAirport.(variables{nn}), data.(station).NBAirport.samplingFrequency, averagingPeriod);
            else
                data.(station).NBAirport.ensembledData.([(variables{nn}),'_mean']) = interp1(data.(station).NBAirport.date_time, data.(station).NBAirport.([variables{nn}]) ,data.(station).NBAirport.ensembledData.date_time_mean);
            end
        end
        if isfield(data.(station).KZScintillometer.variables{nn})
            if averagingFrequency > data.(station).KZScintillometer.samplingFrequency
                [data.(station).KZScintillometer.ensembledData.([(variables{nn}),'_mean']) ,data.(station).KZScintillometer.ensembledData.([(variables{nn}),'_prime']),data.(station).KZScintillometer.ensembledData.([(variables{nn}),'_var']),data.(station).KZScintillometer.ensembledData.([(variables{nn}),'_std']) ] = ensembleStatistics(data.(station).KZScintillometer.(variables{nn}), data.(station).KZScintillometer.samplingFrequency, averagingPeriod);
            else
                data.(station).KZScintillometer.ensembledData.([(variables{nn}),'_mean']) = interp1(data.(station).KZScintillometer.date_time, data.(station).KZScintillometer.([variables{nn}]) ,data.(station).KZScintillometer.ensembledData.date_time_mean);
            end
        end
    end
end
%% Compute Correct Mean Wind Direction
%This part of the code is generated from Ocean Wave Data Analysis by Arash Karimpour 
if strcmp(station,'SMAST') && strcmp(substation,'Lattice')

    [data.(station).Gill.ensembledData.WindDir_vert,~,~,~] = ensembleStatistics(sind(data.(station).Gill.WindDir), data.(station).Gill.samplingFrequency, averagingPeriod);
    [data.(station).Gill.ensembledData.WindDir_horz,~,~,~] = ensembleStatistics(cosd(data.(station).Gill.WindDir), data.(station).Gill.samplingFrequency, averagingPeriod);
    data.(station).Gill.ensembledData.WindDir_mean = wrapTo360(atand(data.(station).Gill.ensembledData.WindDir_vert)./(data.(station).Gill.ensembledData.WindDir_horz));

    [data.(station).ATI.ensembledData.WindDir_vert,~,~,~] = ensembleStatistics(sind(data.(station).ATI.WindDir), data.(station).ATI.samplingFrequency, averagingPeriod);
    [data.(station).ATI.ensembledData.WindDir_horz,~,~,~] = ensembleStatistics(cosd(data.(station).ATI.WindDir), data.(station).ATI.samplingFrequency, averagingPeriod);
    data.(station).ATI.ensembledData.WindDir_mean = wrapTo360(atand(data.(station).ATI.ensembledData.WindDir_vert)./(data.(station).ATI.ensembledData.WindDir_horz));

elseif strcmp(station,'NBCBC') && strcmp(substation,'Lattice')
    [data.(station).ATI.ensembledData.WindDir_vert,~,~,~] = ensembleStatistics(sind(data.(station).ATI.WindDir), data.(station).ATI.samplingFrequency, averagingPeriod);
    [data.(station).ATI.ensembledData.WindDir_horz,~,~,~] = ensembleStatistics(cosd(data.(station).ATI.WindDir), data.(station).ATI.samplingFrequency, averagingPeriod);
    data.(station).ATI.ensembledData.WindDir_mean = wrapTo360(atand(data.(station).ATI.ensembledData.WindDir_vert)./(data.(station).ATI.ensembledData.WindDir_horz));

elseif strcmp(substation,'Tower')
    for numSens = 1:5
        [data.(station).DPL.(['H',num2str(numSens)]).ensembledData.WindDir_vert,~,~,~] = ensembleStatistics(sind(data.(station).DPL.(['H',num2str(numSens)]).WindDir), data.(station).DPL.samplingFrequency, averagingPeriod);
        [data.(station).DPL.(['H',num2str(numSens)]).ensembledData.WindDir_horz,~,~,~] = ensembleStatistics(cosd(data.(station).DPL.(['H',num2str(numSens)]).WindDir), data.(station).DPL.samplingFrequency, averagingPeriod);
        data.(station).DPL.(['H',num2str(numSens)]).ensembledData.WindDir_mean = wrapTo360(atand(data.(station).DPL.(['H',num2str(numSens)]).ensembledData.WindDir_vert)./(data.(station).DPL.(['H',num2str(numSens)]).ensembledData.WindDir_horz));
    end
elseif isempty
    if averagingFrequency > data.(station).RainwisePortLog.samplingFrequency
        [data.(station).RainwisePortLog.ensembledData.WindDir_vert,~,~,~] = ensembleStatistics(sind(data.(station).RainwisePortLog.WindDir), data.(station).RainwisePortLog.samplingFrequency, averagingPeriod);
        [data.(station).RainwisePortLog.ensembledData.WindDir_horz,~,~,~] = ensembleStatistics(cosd(data.(station).RainwisePortLog.WindDir), data.(station).RainwisePortLog.samplingFrequency, averagingPeriod);
        data.(station).RainwisePortLog.ensembledData.WindDir_mean = wrapTo360(atand(data.(station).RainwisePortLog.ensembledData.WindDir_vert)./(data.(station).RainwisePortLog.ensembledData.WindDir_horz));
    else
        data.(station).RainwisePortLog.ensembledData.WindDir_mean = interp1(data.(station).RainwisePortLog.date_time, data.(station).RainwisePortLog.WindDir ,data.(station).RainwisePortLog.ensembledData.date_time_mean);
    end
end
%% Plot Mean Wind Speed
if strcmp(station,'SMAST') && strcmp(substation,'Lattice')
    fig = figure(1);
    plot(data.(station).Gill.ensembledData.date_time_mean, data.(station).Gill.ensembledData.WindSpd_mean,'Color',data.(station).Gill.color);
    hold on;
    plot(data.(station).ATI.ensembledData.date_time_mean, data.(station).ATI.ensembledData.WindSpd_mean,'Color',data.(station).ATI.color);
    hold on;
    for numDays = 2:width(d)
        xregion(data.(station).Location.sunset.date_time(numDays-1),  data.(station).Location.sunrise.date_time(numDays)); hold on;
    end
    xlabel('$\textbf{Time of Day (UTC)}$');
    ylabel('$\mathbf{\overline{U}}$ $\mathbf{(ms^{-1})}$');
    title([sprintf('\\bf %s' ,station),' ',sprintf('\\bf %s' ,substation)]);
    subtitle([datestr(start_date,'mm/dd/yyyy'),'-',datestr(end_date,'mm/dd/yyyy')]);
    xtickformat("MM/dd");
    ymin = min(0,round(figScaleFactor.*min([data.(station).Gill.ensembledData.WindSpd_mean,data.(station).ATI.ensembledData.WindSpd_mean])));
    ymax = round(figScaleFactor.*max([data.(station).Gill.ensembledData.WindSpd_mean,data.(station).ATI.ensembledData.WindSpd_mean]));
    xlim([start_date end_date]);
    ylim([ymin ymax]);
    legend(['Gill @ ',num2str(data.(station).Gill.zLevel,'%4.2f') ' (m)'],['ATI @ ',num2str(data.(station).ATI.zLevel,'%4.2f') ' (m)']);
    plotPrettier();
    print(fig,[savepath,'WindSpd_',datestr(start_date,'mmddyyyy'),'_',datestr(end_date,'mmddyyyy'),'.tif'],'-dtiff','-r300');
elseif strcmp(station,'NBCBC') && strcmp(substation,'Lattice')
    fig = figure(1);
    plot(data.(station).ATI.ensembledData.date_time_mean, data.(station).ATI.ensembledData.WindSpd_mean,'Color',data.(station).ATI.color); hold on;
    for numDays = 2:width(d)
        xregion(data.(station).Location.sunset.date_time(numDays-1),  data.(station).Location.sunrise.date_time(numDays)); hold on;
    end
    xlabel('$\textbf{Time of Day (UTC)}$');
    ylabel('$\mathbf{\overline{U}}$ $\mathbf{(ms^{-1})}$');
    title([sprintf('\\bf %s' ,station),' ',sprintf('\\bf %s' ,substation)]);
    subtitle([datestr(start_date,'mm/dd/yyyy'),'-',datestr(end_date,'mm/dd/yyyy')]);
    xtickformat("MM/dd");
    ymin = min(0,round(figScaleFactor.*min([data.(station).ATI.ensembledData.WindSpd_mean])));
    ymax = round(figScaleFactor.*max([data.(station).ATI.ensembledData.WindSpd_mean]));
    xlim([start_date end_date]);
    ylim([ymin ymax]);
    legend(['ATI @ ',num2str(data.(station).ATI.zLevel,'%4.2f') ' (m)']);
    plotPrettier();
    print(fig,[savepath,'WindSpd_',datestr(start_date,'mmddyyyy'),'_',datestr(end_date,'mmddyyyy'),'.tif'],'-dtiff','-r300');
elseif strcmp(substation,'Tower')
    fig = figure(1);
    for numSens = 1:5
        plothandles(numSens) = plot(data.(station).DPL.(['H',num2str(numSens)]).ensembledData.date_time_mean, data.(station).DPL.(['H',num2str(numSens)]).ensembledData.WindSpd_mean,'Color',data.(station).DPL.(['H',num2str(numSens)]).color); hold on;
        plotlabels{numSens} = ['H',num2str(numSens),' @ ',num2str(data.(station).DPL.(['H',num2str(numSens)]).zLevel,'%4.2f') ' (m)']; 
    end
    for numDays = 2:width(d)
        xregion(data.(station).Location.sunset.date_time(numDays-1),  data.(station).Location.sunrise.date_time(numDays)); hold on;
    end
    xlabel('$\textbf{Time of Day (UTC)}$');
    ylabel('$\mathbf{\overline{U}}$ $\mathbf{(ms^{-1})}$');
    title([sprintf('\\bf %s' ,station),' ',sprintf('\\bf %s' ,substation)]);
    subtitle([datestr(start_date,'mm/dd/yyyy'),'-',datestr(end_date,'mm/dd/yyyy')]);
    xtickformat("MM/dd");
    ymin = min(0,round(figScaleFactor.*min([data.(station).DPL.H1.WindSpd_mean, data.(station).DPL.H5.WindSpd_mean])));
    ymax = max(round(figScaleFactor.*max([data.(station).DPL.H1.WindSpd_mean, data.(station).DPL.H5.WindSpd_mean])));
    xlim([start_date end_date]);
    ylim([ymin ymax]);
    legend(plothandles,plotlabels);
    plotPrettier();
    print(fig,[savepath,'WindSpd_',datestr(start_date,'mmddyyyy'),'_',datestr(end_date,'mmddyyyy'),'.tif'],'-dtiff','-r300');
elseif isempty
    fig = figure(1);
    plot(data.(station).RainwisePortLog.date_time_mean, data.(station).RainwisePortLog.ensembledData.WindSpd_mean,'Color',data.(station).RainwisePortLog.color); hold on;
    for numDays = 2:width(d)
        xregion(data.(station).Location.sunset.date_time(numDays-1),  data.(station).Location.sunrise.date_time(numDays)); hold on;
    end
    xlabel('$\textbf{Time of Day (UTC)}$');
    ylabel('$\mathbf{\overline{U}}$ $\mathbf{(ms^{-1})}$');
    title([sprintf('\\bf %s' ,station),' ',sprintf('\\bf %s' ,substation)]);
    subtitle([datestr(start_date,'mm/dd/yyyy'),'-',datestr(end_date,'mm/dd/yyyy')]);
    xtickformat("MM/dd");
    ymin = min(0,round(figScaleFactor.*min([data.(station).RainwisePortLog.ensembledData.WindSpd_mean])));
    ymax = round(figScaleFactor.*max([data.(station).RainwisePortLog.ensembledData.WindSpd_mean]));
    xlim([start_date end_date]);
    ylim([ymin ymax]);
    legend('Rainwise Portlog');
    plotPrettier();
    print(fig,[savepath,'WindSpd_',datestr(start_date,'mmddyyyy'),'_',datestr(end_date,'mmddyyyy'),'.tif'],'-dtiff','-r300');
end
%% Mean Wind Direction
if strcmp(station,'SMAST') && strcmp(substation,'Lattice')
    fig = figure(2);
    scatter(data.(station).Gill.ensembledData.date_time_mean, data.(station).Gill.ensembledData.WindDir_mean,50,data.(station).Gill.color,"filled");
    hold on;
    scatter(data.(station).ATI.ensembledData.date_time_mean, data.(station).ATI.ensembledData.WindDir_mean,50,data.(station).ATI.color,"filled");
    hold on;
    for numDays = 2:width(d)
        xregion(data.(station).Location.sunset.date_time(numDays-1),  data.(station).Location.sunrise.date_time(numDays)); hold on;
    end
    xlabel('$\textbf{Time of Day (UTC)}$');
    ylabel('$\mathbf{\overline{U}}$ $\mathbf{(ms^{-1})}$');
    title([sprintf('\\bf %s' ,station),' ',sprintf('\\bf %s' ,substation)]);
    subtitle([datestr(start_date,'mm/dd/yyyy'),'-',datestr(end_date,'mm/dd/yyyy')]);
    xtickformat("MM/dd");
    ymin = 0;
    ymax = 360;
    xlim([start_date end_date]);
    ylim([ymin ymax]);
    legend(['Gill @ ',num2str(data.(station).Gill.zLevel,'%4.2f') ' (m)'],['ATI @ ',num2str(data.(station).ATI.zLevel,'%4.2f') ' (m)']);
    plotPrettier();
    print(fig,[savepath,'WindDir_',datestr(start_date,'mmddyyyy'),'_',datestr(end_date,'mmddyyyy'),'.tif'],'-dtiff','-r300');
elseif strcmp(station,'NBCBC') && strcmp(substation,'Lattice')
    fig = figure(2);
    scatter(data.(station).ATI.ensembledData.date_time_mean, data.(station).ATI.ensembledData.WindDir_mean,50,data.(station).ATI.color,"filled"); hold on;
    for numDays = 2:width(d)
        xregion(data.(station).Location.sunset.date_time(numDays-1),  data.(station).Location.sunrise.date_time(numDays)); hold on;
    end
    xlabel('$\textbf{Time of Day (UTC)}$');
    ylabel('$\mathbf{\overline{U}}$ $\mathbf{(ms^{-1})}$');
    title([sprintf('\\bf %s' ,station),' ',sprintf('\\bf %s' ,substation)]);
    subtitle([datestr(start_date,'mm/dd/yyyy'),'-',datestr(end_date,'mm/dd/yyyy')]);
    xtickformat("MM/dd");
    ymin = 0;
    ymax = 360;
    xlim([start_date end_date]);
    ylim([ymin ymax]);
    legend(['ATI @ ',num2str(data.(station).ATI.zLevel,'%4.2f') ' (m)']);
    plotPrettier();
    print(fig,[savepath,'WindDir_',datestr(start_date,'mmddyyyy'),'_',datestr(end_date,'mmddyyyy'),'.tif'],'-dtiff','-r300');
elseif strcmp(substation,'Tower')
    fig = figure(2);
    for numSens = 1:5
        plothandles(numSens) = scatter(data.(station).DPL.(['H',num2str(numSens)]).ensembledData.date_time_mean, data.(station).DPL.(['H',num2str(numSens)]).ensembledData.WindDir_mean,50,data.(station).DPL.(['H',num2str(numSens)]).color,"filled"); hold on;
        plotlabels{numSens} = ['H',num2str(numSens),' @ ',num2str(data.(station).DPL.(['H',num2str(numSens)]).zLevel,'%4.2f') ' (m)']; 
    end
    for numDays = 2:width(d)
        xregion(data.(station).Location.sunset.date_time(numDays-1),  data.(station).Location.sunrise.date_time(numDays)); hold on;
    end
    xlabel('$\textbf{Time of Day (UTC)}$');
    ylabel('$\mathbf{\overline{U}}$ $\mathbf{(ms^{-1})}$');
    title([sprintf('\\bf %s' ,station),' ',sprintf('\\bf %s' ,substation)]);
    subtitle([datestr(start_date,'mm/dd/yyyy'),'-',datestr(end_date,'mm/dd/yyyy')]);
    xtickformat("MM/dd");
    ymin = 0;
    ymax = 360;
    xlim([start_date end_date]);
    ylim([ymin ymax]);
    legend(plothandles,plotlabels);
    plotPrettier();
    print(fig,[savepath,'WindDir_',datestr(start_date,'mmddyyyy'),'_',datestr(end_date,'mmddyyyy'),'.tif'],'-dtiff','-r300');
elseif isempty
    fig = figure(2);
    scatter(data.(station).RainwisePortLog.date_time_mean, data.(station).RainwisePortLog.ensembledData.WindDir_mean,50,data.(station).RainwisePortLog.color,"filled"); hold on;
    for numDays = 2:width(d)
        xregion(data.(station).Location.sunset.date_time(numDays-1),  data.(station).Location.sunrise.date_time(numDays)); hold on;
    end
    xlabel('$\textbf{Time of Day (UTC)}$');
    ylabel('\boldmath$\theta$ $\mathbf{(deg N)}$');
    title([sprintf('\\bf %s' ,station),' ',sprintf('\\bf %s' ,substation)]);
    subtitle([datestr(start_date,'mm/dd/yyyy'),'-',datestr(end_date,'mm/dd/yyyy')]);
    xtickformat("MM/dd");
    ymin = 0;
    ymax = 360;
    xlim([start_date end_date]);
    ylim([ymin ymax]);
    legend('Rainwise Portlog');
    plotPrettier();
    print(fig,[savepath,'WindDir_',datestr(start_date,'mmddyyyy'),'_',datestr(end_date,'mmddyyyy'),'.tif'],'-dtiff','-r300');
end
%% Plot Mean Temperature
if strcmp(station,'SMAST') && strcmp(substation,'Lattice')
    fig = figure(2);
    % DataQ Lower
    plot(data.(station).DataQ.ensembledData.date_time_mean, data.(station).DataQ.ensembledData.T_Air_lwr_mean,'Color',data.(station).Gill.color);
    hold on;
    % DataQ Upper
    plot(data.(station).DataQ.ensembledData.date_time_mean, data.(station).DataQ.ensembledData.T_Air_upr_mean,'Color',data.(station).ATI.color);
    hold on;
    for numDays = 2:width(d)
        xregion(data.(station).Location.sunset.date_time(numDays-1),  data.(station).Location.sunrise.date_time(numDays)); hold on;
    end
    xlabel('$\textbf{Time of Day (UTC)}$');
    ylabel('$\mathbf{T}$ $\mathbf{(^{\circ} C)}$');
    title([sprintf('\\bf %s' ,station),' ',sprintf('\\bf %s' ,substation)]);
    subtitle([datestr(start_date,'mm/dd/yyyy'),'-',datestr(end_date,'mm/dd/yyyy')]);
    xtickformat("MM/dd");
    ymin = min(0,round(figScaleFactor.*min([data.(station).DataQ.ensembledData.T_Air_lwr_mean,data.(station).DataQ.ensembledData.T_Air_upr_mean])));
    ymax = round(figScaleFactor.*min([data.(station).DataQ.ensembledData.T_Air_lwr_mean,data.(station).DataQ.ensembledData.T_Air_upr_mean]));
    xlim([start_date end_date]);
    ylim([ymin ymax]);
    legend(['HMP60 @ ',num2str(data.(station).Gill.zLevel,'%4.2f') ' (m)'],['HMP60 @ ',num2str(data.(station).ATI.zLevel,'%4.2f') ' (m)'], 'Rainwise PortLog','OnsetHOBO');
    plotPrettier();
    print(fig,[savepath,'Temperature_',datestr(start_date,'mmddyyyy'),'_',datestr(end_date,'mmddyyyy'),'.tif'],'-dtiff','-r300');
elseif strcmp(station,'NBCBC') && strcmp(substation,'Lattice')
    fig = figure(2);
    plot(data.(station).DataQ.ensembledData.date_time_mean, data.(station).DataQ.ensembledData.T_Air_mean,'Color',data.(station).DataQ.color); 
    hold on;
    for numDays = 2:width(d)
        xregion(data.(station).Location.sunset.date_time(numDays-1),  data.(station).Location.sunrise.date_time(numDays)); 
        hold on;
    end
    xlabel('$\textbf{Time of Day (UTC)}$');
    ylabel('$\mathbf{T}$ $\mathbf{(^{\circ} C)}$');
    title([sprintf('\\bf %s' ,station),' ',sprintf('\\bf %s' ,substation)]);
    subtitle([datestr(start_date,'mm/dd/yyyy'),'-',datestr(end_date,'mm/dd/yyyy')]);
    xtickformat("MM/dd");
    ymin = min(0,round(figScaleFactor.*min([data.(station).DataQ.ensembledData.T_Air_mean])));
    ymax = round(figScaleFactor.*max([data.(station).DataQ.ensembledData.T_Air_mean]));
    xlim([start_date end_date]);
    ylim([ymin ymax]);
    legend(['HMP60 @ ',num2str(data.(station).ATI.zLevel,'%4.2f') ' (m)'], 'OnsetHOBO');
    plotPrettier();
    print(fig,[savepath,'Temperature_',datestr(start_date,'mmddyyyy'),'_',datestr(end_date,'mmddyyyy'),'.tif'],'-dtiff','-r300');
elseif strcmp(substation,'Tower')
    fig = figure(2);
    for numSens = 1:5
        plothandles(numSens) = plot(data.(station).DPL.(['H',num2str(numSens)]).ensembledData.date_time_mean, data.(station).DPL.(['H',num2str(numSens)]).ensembledData.WindSpd_mean,'Color',data.(station).DPL.(['H',num2str(numSens)]).color); hold on;
        plotlabels{numSens} = ['H',num2str(numSens),' @ ',num2str(data.(station).DPL.(['H',num2str(numSens)]).zLevel,'%4.2f') ' (m)']; 
    end
    for numDays = 2:width(d)
        xregion(data.(station).Location.sunset.date_time(numDays-1),  data.(station).Location.sunrise.date_time(numDays)); hold on;
    end
    xlabel('$\textbf{Time of Day (UTC)}$');
    ylabel('$\mathbf{T}$ $\mathbf{(^{\circ} C)}$');
    title([sprintf('\\bf %s' ,station),' ',sprintf('\\bf %s' ,substation)]);
    subtitle([datestr(start_date,'mm/dd/yyyy'),'-',datestr(end_date,'mm/dd/yyyy')]);
    xtickformat("MM/dd");
    ymin = min(0,round(figScaleFactor.*min([data.(station).DPL.H5.T_Air_mean])));
    ymax = round(figScaleFactor.*max([data.(station).DPL.H5.T_Air_mean]));
    xlim([start_date end_date]);
    ylim([ymin ymax]);
    legend(plothandles,plotlabels);
    plotPrettier();
    print(fig,[savepath,'Temperature_',datestr(start_date,'mmddyyyy'),'_',datestr(end_date,'mmddyyyy'),'.tif'],'-dtiff','-r300');
elseif isempty
    fig = figure(1);
    plot(data.(station).RainwisePortLog.date_time_mean, data.(station).RainwisePortLog.ensembledData.T_Air_mean,'Color',data.(station).RainwisePortLog.color); hold on;
    for numDays = 2:width(d)
        xregion(data.(station).Location.sunset.date_time(numDays-1),  data.(station).Location.sunrise.date_time(numDays)); hold on;
    end
    xlabel('$\textbf{Time of Day (UTC)}$');
    ylabel('$\mathbf{T}$ $\mathbf{(^{\circ} C)}$');
    title([sprintf('\\bf %s' ,station),' ',sprintf('\\bf %s' ,substation)]);
    subtitle([datestr(start_date,'mm/dd/yyyy'),'-',datestr(end_date,'mm/dd/yyyy')]);
    xtickformat("MM/dd");
    ymin = min(0,round(figScaleFactor.*min([data.(station).RainwisePortLog.ensembledData.T_Air_mean])));
    ymax = round(figScaleFactor.*max([data.(station).RainwisePortLog.ensembledData.T_Air_mean]));
    xlim([start_date end_date]);
    ylim([ymin ymax]);
    legend('Rainwise Portlog');
    plotPrettier();
    print(fig,[savepath,'Temperature_',datestr(start_date,'mmddyyyy'),'_',datestr(end_date,'mmddyyyy'),'.tif'],'-dtiff','-r300');
end
%% Plot Mean Relative Humidity
if strcmp(station,'SMAST') && strcmp(substation,'Lattice')
    fig = figure(3);
    plot(data.(station).DataQ.ensembledData.date_time_mean, data.(station).DataQ.ensembledData.RelHumid_lwr_mean,'Color',data.(station).Gill.color);
    hold on;
    plot(data.(station).DataQ.ensembledData.date_time_mean, data.(station).DataQ.ensembledData.RelHumid_upr_mean,'Color',data.(station).ATI.color);
    hold on;
    for numDays = 2:width(d)
        xregion(data.(station).Location.sunset.date_time(numDays-1),  data.(station).Location.sunrise.date_time(numDays)); hold on;
    end
    xlabel('$\textbf{Time of Day (UTC)}$');
    ylabel('$\mathbf{RH}$ $\mathbf{(\%)}$');
    title([sprintf('\\bf %s' ,station),' ',sprintf('\\bf %s' ,substation)]);
    subtitle([datestr(start_date,'mm/dd/yyyy'),'-',datestr(end_date,'mm/dd/yyyy')]);
    xtickformat("MM/dd");
    ymin = min(0,round(figScaleFactor.*min([data.(station).DataQ.ensembledData.RelHumid_lwr_mean,data.(station).DataQ.ensembledData.RelHumid_upr_mean])));
    ymax = round(figScaleFactor.*min([data.(station).DataQ.ensembledData.RelHumid_lwr_mean,data.(station).DataQ.ensembledData.RelHumid_upr_mean]));
    xlim([start_date end_date]);
    ylim([ymin ymax]);
    legend(['HMP60 @ ',num2str(data.(station).Gill.zLevel,'%4.2f') ' (m)'],['HMP60 @ ',num2str(data.(station).ATI.zLevel,'%4.2f') ' (m)']);
    plotPrettier();
    print(fig,[savepath,'RelativeHumidity_',datestr(start_date,'mmddyyyy'),'_',datestr(end_date,'mmddyyyy'),'.tif'],'-dtiff','-r300');
elseif strcmp(station,'NBCBC') && strcmp(substation,'Lattice')
    fig = figure(3);
    plot(data.(station).DataQ.ensembledData.date_time_mean, data.(station).DataQ.ensembledData.RelHumid_mean,'Color',data.(station).DataQ.color); hold on;
    for numDays = 2:width(d)
        xregion(data.(station).Location.sunset.date_time(numDays-1),  data.(station).Location.sunrise.date_time(numDays)); hold on;
    end
    xlabel('$\textbf{Time of Day (UTC)}$');
    ylabel('$\mathbf{RH}$ $\mathbf{(\%)}$');
    title([sprintf('\\bf %s' ,station),' ',sprintf('\\bf %s' ,substation)]);
    subtitle([datestr(start_date,'mm/dd/yyyy'),'-',datestr(end_date,'mm/dd/yyyy')]);
    xtickformat("MM/dd");
    ymin = min(0,round(figScaleFactor.*min([data.(station).DataQ.ensembledData.RelHumid_mean])));
    ymax = round(figScaleFactor.*max([data.(station).DataQ.ensembledData.RelHumid_mean]));
    xlim([start_date end_date]);
    ylim([ymin ymax]);
    legend(['HMP60 @ ',num2str(data.(station).ATI.zLevel,'%4.2f') ' (m)']);
    plotPrettier();
    print(fig,[savepath,'RelativeHumidity_',datestr(start_date,'mmddyyyy'),'_',datestr(end_date,'mmddyyyy'),'.tif'],'-dtiff','-r300');
elseif strcmp(substation,'Tower')
    fig = figure(3);
    for numSens = 1:5
        plothandles(numSens) = plot(data.(station).DPL.(['H',num2str(numSens)]).ensembledData.date_time_mean, data.(station).DPL.(['H',num2str(numSens)]).ensembledData.WindSpd_mean,'Color',data.(station).DPL.(['H',num2str(numSens)]).color); hold on;
        plotlabels{numSens} = ['H',num2str(numSens),' @ ',num2str(data.(station).DPL.(['H',num2str(numSens)]).zLevel,'%4.2f') ' (m)']; 
    end
    for numDays = 2:width(d)
        xregion(data.(station).Location.sunset.date_time(numDays-1),  data.(station).Location.sunrise.date_time(numDays)); hold on;
    end
    xlabel('$\textbf{Time of Day (UTC)}$');
    ylabel('$\mathbf{RH}$ $\mathbf{(\%)}$');
    title([sprintf('\\bf %s' ,station),' ',sprintf('\\bf %s' ,substation)]);
    subtitle([datestr(start_date,'mm/dd/yyyy'),'-',datestr(end_date,'mm/dd/yyyy')]);
    xtickformat("MM/dd");
    ymin = min(0,round(figScaleFactor.*min([data.(station).DPL.H5.RelHumid_mean])));
    ymax = round(figScaleFactor.*max([data.(station).DPL.H5.RelHumid_mean]));
    xlim([start_date end_date]);
    ylim([ymin ymax]);
    legend(plothandles,plotlabels);
    plotPrettier();
    print(fig,[savepath,'RelativeHumidity_',datestr(start_date,'mmddyyyy'),'_',datestr(end_date,'mmddyyyy'),'.tif'],'-dtiff','-r300');
elseif isempty
    fig = figure(3);
    plot(data.(station).RainwisePortLog.date_time_mean, data.(station).RainwisePortLog.ensembledData.RelHumid_mean,'Color',data.(station).RainwisePortLog.color); hold on;
    for numDays = 2:width(d)
        xregion(data.(station).Location.sunset.date_time(numDays-1),  data.(station).Location.sunrise.date_time(numDays)); hold on;
    end
    xlabel('$\textbf{Time of Day (UTC)}$');
    ylabel('$\mathbf{RH}$ $\mathbf{(\%)}$');
    title([sprintf('\\bf %s' ,station),' ',sprintf('\\bf %s' ,substation)]);
    subtitle([datestr(start_date,'mm/dd/yyyy'),'-',datestr(end_date,'mm/dd/yyyy')]);
    xtickformat("MM/dd");
    ymin = min(0,round(figScaleFactor.*min([data.(station).RainwisePortLog.ensembledData.RelHumid_mean])));
    ymax = round(figScaleFactor.*max([data.(station).RainwisePortLog.ensembledData.RelHumid_mean]));
    xlim([start_date end_date]);
    ylim([ymin ymax]);
    legend('Rainwise Portlog');
    plotPrettier();
    print(fig,[savepath,'RelativeHumidity_',datestr(start_date,'mmddyyyy'),'_',datestr(end_date,'mmddyyyy'),'.tif'],'-dtiff','-r300');
end
%% Mean Water Temperature
fig = figure(4);
plot(data.(station).OnsetHOBO.ensembledData.date_time_mean, data.(station).OnsetHOBO.ensembledData.T_Water_mean,'Color',data.(station).OnsetHOBO.color);
for numDays = 2:width(d)
    xregion(data.(station).Location.sunset.date_time(numDays-1),  data.(station).Location.sunrise.date_time(numDays)); hold on;
end
xlabel('$\textbf{Time of Day (UTC)}$');
ylabel ('$\mathbf{T}$ $\mathbf{(^{\circ} C)}$');
title([sprintf('\\bf %s' ,station),' ',sprintf('\\bf %s' ,substation)]);
subtitle([datestr(start_date,'mm/dd/yyyy'),'-',datestr(end_date,'mm/dd/yyyy')]);
xtickformat("MM/dd");
ymin = min(0,round(figScaleFactor.*min([data.(station).OnsetHOBO.ensembledData.WL_mean])));
ymax = round(figScaleFactor.*max([data.(station).OnsetHOBO.ensembledData.WL_mean]));
xlim([start_date end_date]);
ylim([ymin ymax]);
legend('OnsetHOBO');
plotPrettier();
print(fig,[savepath,'WaterTemperature_',datestr(start_date,'mmddyyyy'),'_',datestr(end_date,'mmddyyyy'),'.tif'],'-dtiff','-r300');
%% Mean Water Level
fig=figure(5);
plot(data.(station).OnsetHOBO.ensembledData.date_time_mean, data.(station).OnsetHOBO.ensembledData.WL_mean,'Color',data.(station).OnsetHOBO.color);
for numDays = 2:width(d)
    xregion(data.(station).Location.sunset.date_time(numDays-1),  data.(station).Location.sunrise.date_time(numDays)); hold on;
end
xlabel('$\textbf{Time of Day (UTC)}$');
ylabel('$\mathbf{WL}$ $\mathbf{(m)}$');
title([sprintf('\\bf %s' ,station),' ',sprintf('\\bf %s' ,substation)]);
subtitle([datestr(start_date,'mm/dd/yyyy'),'-',datestr(end_date,'mm/dd/yyyy')]);
xtickformat("MM/dd");
ymin = min(0,round(figScaleFactor.*min([data.(station).OnsetHOBO.ensembledData.WL_mean])));
ymax = round(figScaleFactor.*max([data.(station).OnsetHOBO.ensembledData.WL_mean]));
xlim([start_date end_date]);
ylim([ymin ymax]);
legend('OnsetHOBO');
plotPrettier();
print(fig,[savepath,'WaterLevel_',datestr(start_date,'mmddyyyy'),'_',datestr(end_date,'mmddyyyy'),'.tif'],'-dtiff','-r300');
%% Mean Barometric Pressure
% Rainwise PortLog
fig=figure(6);
plot(data.(station).RainwisePortLog.ensembledData.date_time_mean, data.(station).RainwisePortLog.ensembledData.Baro_mean,'Color',data.(station).RainwisePortLog.color);
for numDays = 2:width(d)
    xregion(data.(station).Location.sunset.date_time(numDays-1),  data.(station).Location.sunrise.date_time(numDays)); hold on;
end
xlabel('$\textbf{Time of Day (UTC)}$');
ylabel('$\mathbf{\overline{P}}$ $\mathbf{(mBar)}$');
title([sprintf('\\bf %s' ,station),' ',sprintf('\\bf %s' ,substation)]);
subtitle([datestr(start_date,'mm/dd/yyyy'),'-',datestr(end_date,'mm/dd/yyyy')]);
xtickformat("MM/dd");
ymin = min(0,round(figScaleFactor.*min([data.(station).RainwisePortLog.ensembledData.Baro_mean])));
ymax = round(figScaleFactor.*max([data.(station).RainwisePortLog.ensembledData.Baro_mean]));
xlim([start_date end_date]);
ylim([ymin ymax]);
legend('Rainwise PortLog');
plotPrettier();
print(fig,[savepath,'BarometricPressure_',datestr(start_date,'mmddyyyy'),'_',datestr(end_date,'mmddyyyy'),'.tif'],'-dtiff','-r300');
% OnsetHOBO
fig=figure(7);
plot(data.(station).OnsetHOBO.ensembledData.date_time_mean, data.(station).OnsetHOBO.ensembledData.Baro_mean,'Color',data.(station).OnsetHOBO.color);
for numDays = 2:width(d)
    xregion(data.(station).Location.sunset.date_time(numDays-1),  data.(station).Location.sunrise.date_time(numDays)); hold on;
end
xlabel('$\textbf{Time of Day (UTC)}$');
ylabel('$\mathbf{\overline{P}}$ $\mathbf{(mBar)}$');
title([sprintf('\\bf %s' ,station),' ',sprintf('\\bf %s' ,substation)]);
subtitle([datestr(start_date,'mm/dd/yyyy'),'-',datestr(end_date,'mm/dd/yyyy')]);
xtickformat("MM/dd");
ymin = min(0,round(figScaleFactor.*min([data.(station).OnsetHOBO.ensembledData.Baro_mean])));
ymax = round(figScaleFactor.*max([data.(station).OnsetHOBO.ensembledData.Baro_mean]));
xlim([start_date end_date]);
ylim([ymin ymax]);
legend('OnsetHOBO');
plotPrettier();
print(fig,[savepath,'BarometricPressure_',datestr(start_date,'mmddyyyy'),'_',datestr(end_date,'mmddyyyy'),'.tif'],'-dtiff','-r300');
%% Mean Solar & Net Raditation
if strcmp(substation,'Lattice')
    fig=figure(8);
    plot(data.(station).DataQ.ensembledData.date_time_mean, data.(station).DataQ.NetRad_mean,'Color',data.(station).Gill.color);
    hold on;
    plot(data.(station).DataQ.ensembledData.date_time_mean, data.(station).DataQ.Pyr_mean,'Color',data.(station).ATI.color);
    hold on;
    for numDays = 2:width(d)
        xregion(data.(station).Location.sunset.date_time(numDays-1),  data.(station).Location.sunrise.date_time(numDays)); hold on;
    end
    xlabel('$\textbf{Time of Day (UTC)}$');
    ylabel('$\mathbf{\overline{R}} \mathbf{(W/m^{2})}$');
    title([sprintf('\\bf %s' ,station),' ',sprintf('\\bf %s' ,substation)]);
    subtitle([datestr(start_date,'mm/dd/yyyy'),'-',datestr(end_date,'mm/dd/yyyy')]);
    xtickformat("MM/dd");
    ymin = -200;
    ymax = 1200;
    xlim([start_date end_date]);
    ylim([ymin ymax]);
    legend('K&Z Net Radiometer','K&Z Pyranometer');
    plotPrettier();
    print(fig,[savepath,'Radiance_',datestr(start_date,'mmddyyyy'),'_',datestr(end_date,'mmddyyyy'),'.tif'],'-dtiff','-r300');
elseif isempty
    fig=figure(8);
    plot(data.(station).RainwisePortLog.ensembledData.date_time_mean, data.(station).RainwisePortLog.SRad_mean,'Color',data.(station).RainwisePortLog.color);
    hold on;
    for numDays = 2:width(d)
        xregion(data.(station).Location.sunset.date_time(numDays-1),  data.(station).Location.sunrise.date_time(numDays)); hold on;
    end
    xlabel('$\textbf{Time of Day (UTC)}$');
    ylabel('$\mathbf{\overline{R}} \mathbf{(W/m^{2})}$');
    title([sprintf('\\bf %s' ,station),' ',sprintf('\\bf %s' ,substation)]);
    subtitle([datestr(start_date,'mm/dd/yyyy'),'-',datestr(end_date,'mm/dd/yyyy')]);
    xtickformat("MM/dd");
    ymin = -200;
    ymax = 1200;
    xlim([start_date end_date]);
    ylim([ymin ymax]);
    legend('Rainwise PortLog');
    plotPrettier();
    print(fig,[savepath,'Radiance_',datestr(start_date,'mmddyyyy'),'_',datestr(end_date,'mmddyyyy'),'.tif'],'-dtiff','-r300');
end
%% Mean Precipitation
fig = figure(9);
bar(data.(station).RainwisePortLog.ensembledData.date_time_mean, data.(station).RainwisePortLog.ensembledData.Precip_mean,'FaceColor',data.(station).RainwisePortLog.color , 'EdgeColor',data.(station).RainwisePortLog.color);
hold on;
for numDays = 2:width(d)
    xregion(data.(station).Location.sunset.date_time(numDays-1),  data.(station).Location.sunrise.date_time(numDays)); hold on;
end
xlabel('$\textbf{Time of Day (UTC)}$');
ylabel('$\mathbf{\overline{Precip}}$ $\mathbf{(mm)}$');
title([sprintf('\\bf %s' ,station),' ',sprintf('\\bf %s' ,substation)]);
subtitle([datestr(start_date,'mm/dd/yyyy'),'-',datestr(end_date,'mm/dd/yyyy')]);
xtickformat("MM/dd");
ymin = 0;
ymax = 1;
xlim([start_date end_date]);
ylim([ymin ymax]);
legend('OnsetHOBO');
plotPrettier();
print(fig,[savepath,'Precipitation_',datestr(start_date,'mmddyyyy'),'_',datestr(end_date,'mmddyyyy'),'.tif'],'-dtiff','-r300');
%% K&Z Scintillometer
fig =figure(10);
semilogy(data.(station).KZScintillometer.ensembledData.date_time_mean, data.(station).KZScintillometer.Cn2_mean,'Color',data.(station).KZScintillometer.color);
hold on;
for numDays = 2:width(d)
    xregion(data.(station).Location.sunset.date_time(numDays-1),  data.(station).Location.sunrise.date_time(numDays)); hold on;
end
xlabel('$\textbf{Time of Day (UTC)}$');
ylabel('$\mathbf{C_{n}^{2} [m^{-2/3}]}$');
title([sprintf('\\bf %s' ,station),' ',sprintf('\\bf %s' ,substation)]);
subtitle([datestr(start_date,'mm/dd/yyyy'),'-',datestr(end_date,'mm/dd/yyyy')]);
xtickformat("MM/dd");
ymin = 1e-17;
ymax = 1e-10;
xlim([start_date end_date]);
ylim([ymin ymax]);
legend('K\&ZScintillometer');
plotPrettier();
print(fig,[savepath,'RefracIdxStructPar_',datestr(start_date,'mmddyyyy'),'_',datestr(end_date,'mmddyyyy'),'.tif'],'-dtiff','-r300');
end
%% Ecotech Nephelometer