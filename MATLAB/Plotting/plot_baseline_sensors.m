%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plots baseline sensors for Marine Wave Boundary Layer data, as 
% time series as well as profiles, including:
%   Wind Speed
%   Wind Direction
%   Barometric Pressure
%   Relative Humidity
%   Precipitation
%   Cn2
%   Air & Water Temperature
%   Tide Range
%   Solar Radiation & Net Radiometer
%
% Additionally can choose which data streams to include or not include:
%   SMAST Tower
%   SMAST Lattice
%   SMAST HOBO
%   CBC Tower
%   CBC Lattice
%   CBC HOBO
%   NBAirport
%
% Written by Miles A. Sundermeyer, 6/6/2023
% Updated by Miles A. Sundermeyer, 6/14/2023
% Updated by Miles A. Sundermeyer, 9/22/2023
% Updated by Miles A. Sundermeyer, 1/6/2023	- streamlined data set and time selection, plus legend scripts
% Updated by Tyler D. Knapp, 12/19/2024 - Organization and cleanup, adjusting some plot y-limits to accommodate data
% Updated by Tyler D. Knapp, 01/07/2025 - Rearranging and changing display of plot variables to match variable plotted,updated sensor heights for Portlogs
% Updated by Tyler D. Knapp, 01/24/2025 - Added individual data streams for apogee/AQMesh sensors Apogee_3238/3239 AQMesh_2451070/2451071
% Updated by Tyler D. Knapp, 04/30/2025 - Moving heights, and colors to seperate function
% Updated by Tyler D. Knapp, 07/30/2025 - Added DPL Testrack to sensor list
% Updated by Tyler D. Knapp, 09/11/2025 - Updated to use get_File_Path.m and get_File_Date.m
% Updated by Tyler D. Knapp, 09/11/2025 - Commenting out conversions to Northerly, now done in computeCn2.m
% Updated by Tyler D. Knapp, 09/30/2025 - Modification to findSubList, T_Sonic is now plotted in Temperature plot
% Updated by Tyler D. Knapp, 10/02/2025 - Changing HOBO plot to using WL, re-calculated in NAVD88 in csv2mat
                                      % - Updating sensor list to include individual DataQ sensors
                                      % - Added 'spectraFlag' to toggle anemometer spectra calc and plots

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Preliminaries
clear
close all
printflag = true; % true => print figures to file
spectraFlag = false; % Plot Spectra

Path = pwd;
if ~(Path(end-3:end) == "MWBL")
  cd('..')
end
addpath('Utilities');
addpath('Plotting');

if(1)
  set(0,'DefaultAxesFontName','Times');
  set(0,'DefaultAxesFontSize',12);
  set(0,'DefaultAxesFontWeight','bold');
  set(0,'DefaultAxesLineWidth',1.5);
  set(0,'DefaultLineLineWidth',1.5);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set days to plot and analyze, loading 1 week of data at a time, plotting 1 day at a time
% Use the following start and end times to set which period to plot

% this_start = datetime(2025,01,01);
% this_end = datetime(2025,12,19);

this_start = datetime(2026,01,21); 
this_end = this_start + days(14);	% 7 days after start

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The following automatically chops the requested date range into 7-day chunks for plotting
timeduration = this_end - this_start;
timechunk = days(14);

start_date_array = this_start : timechunk : this_start + timeduration;
end_date_array = start_date_array + timechunk;

% make sure final end_date_array does not go past requested end date
if end_date_array(end) > this_end
  end_date_array(end) = this_end;
end

% subtract 1 s from all but final end time to avoid loading extra day in each chunk
end_date_array(1:end) = end_date_array(1:end) - seconds(1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create list of data streams, plus list of which to load and plot
struct('Sensors',[]);

SensorList = [18,19]; % All currently active sensors

Sensors.name{1} = 		  'PortLog_SMAST';    Sensors.dataStream{1} = 'RainwisePortLog';   Sensors.subdataStream{1} = 'SMAST';
Sensors.name{2} = 		  'PortLog_CBC';      Sensors.dataStream{2} = 'RainwisePortLog';   Sensors.subdataStream{2} = 'CBC';
Sensors.name{3} = 		  'ATI_SMAST';        Sensors.dataStream{3} = 'Lattice';           Sensors.subdataStream{3} = {'SMAST';'ATI'};
Sensors.name{4} = 		  'HMP60_SMAST_Upr';  Sensors.dataStream{4} = 'Lattice';           Sensors.subdataStream{4} = {'SMAST';'HMP60_Upr'};
Sensors.name{5} = 		  'Gill_SMAST';       Sensors.dataStream{5} = 'Lattice';           Sensors.subdataStream{5} = {'SMAST';'Gill'};
Sensors.name{6} = 		  'HMP60_SMAST_Lwr';  Sensors.dataStream{6} = 'Lattice';           Sensors.subdataStream{6} = {'SMAST';'HMP60_Lwr'};
Sensors.name{7} = 		  'Young_SMAST';      Sensors.dataStream{7} = 'Lattice';           Sensors.subdataStream{7} = {'SMAST';'Young'};
Sensors.name{8} = 		  'NetRad_SMAST';     Sensors.dataStream{8} = 'Lattice';           Sensors.subdataStream{8} = {'SMAST';'NetRadiometer'};
Sensors.name{9} = 		  'Pyrano_SMAST';     Sensors.dataStream{9} = 'Lattice';           Sensors.subdataStream{9} = {'SMAST';'Pyranometer'};
Sensors.name{10} = 		  'ATI_CBC';          Sensors.dataStream{10} = 'Lattice';          Sensors.subdataStream{10} = {'CBC';'ATI'};
Sensors.name{11} = 		  'HMP60_CBC';        Sensors.dataStream{11} = 'Lattice';          Sensors.subdataStream{11} = {'CBC';'HMP60'};
Sensors.name{12} = 		  'Young_CBC';        Sensors.dataStream{12} = 'Lattice';          Sensors.subdataStream{12} = {'CBC';'Young'};
Sensors.name{13} = 		  'NetRad_CBC';       Sensors.dataStream{13} = 'Lattice';          Sensors.subdataStream{13} = {'CBC';'NetRadiometer'};
Sensors.name{14} = 		  'Pyrano_CBC';       Sensors.dataStream{14} = 'Lattice';          Sensors.subdataStream{14} = {'CBC';'Pyranometer'};
Sensors.name{15} = 		  'KZScintillometer'; Sensors.dataStream{15} = 'KZScintillometer'; Sensors.subdataStream{15} = [];
Sensors.name{16} = 		  'NBAirport';        Sensors.dataStream{16} = 'NBAirport';        Sensors.subdataStream{16} = [];
Sensors.name{17} = 		  'NOAA_WaterT';      Sensors.dataStream{17} = 'NOAA_WaterT';      Sensors.subdataStream{17} = [];
Sensors.name{18} = 		  'HOBO_SMAST';       Sensors.dataStream{18} = 'OnsetHOBO';        Sensors.subdataStream{18} = 'SMAST';
Sensors.name{19} = 		  'HOBO_CBC';         Sensors.dataStream{19} = 'OnsetHOBO';        Sensors.subdataStream{19} = 'CBC';
Sensors.name{20} = 		  'Ambilabs_2WIN';    Sensors.dataStream{20} = 'Ambilabs_2WIN';    Sensors.subdataStream{20} = [];
Sensors.name{21} = 		  'Ecotech_M9003';    Sensors.dataStream{21} = 'Ecotech_M9003';    Sensors.subdataStream{21} = [];
Sensors.name{22} = 		  'AQMesh_2451070';   Sensors.dataStream{22} = 'AQMesh';           Sensors.subdataStream{22} = '2451070';
Sensors.name{23} = 		  'AQMesh_2451071';   Sensors.dataStream{23} = 'AQMesh';           Sensors.subdataStream{23} = '2451071';
Sensors.name{24} = 		  'Apogee_3238';      Sensors.dataStream{24} = 'Apogee';           Sensors.subdataStream{24} = '3238';
Sensors.name{25} = 		  'Apogee_3239';      Sensors.dataStream{25} = 'Apogee';           Sensors.subdataStream{25} = '3239';
Sensors.name{26} = 		  'EPA_PM25';         Sensors.dataStream{26} = 'EPA_PM25';         Sensors.subdataStream{26} = [];
Sensors.name{27} = 		  'DPL_SMAST';        Sensors.dataStream{27} = 'DPL';              Sensors.subdataStream{27} = 'SMAST';
Sensors.name{28} = 		  'DPL_CBC';          Sensors.dataStream{28} = 'DPL';              Sensors.subdataStream{28} = 'CBC';
Sensors.name{29} = 		  'DataQ_SMAST';      Sensors.dataStream{29} = 'Lattice';          Sensors.subdataStream{29} = {'SMAST','DataQ'};
Sensors.name{30} = 		  'DataQ_CBC';        Sensors.dataStream{30} = 'Lattice';          Sensors.subdataStream{30} = {'CBC','DataQ'};

% Get line colors/set sensor heights
[cset, ~] = MWBL_plot_const();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Make lists of variables to plot for different groups of data
% Main variables:
plot_variables =      {'WindSpd';      'WindDir';      'Baro'; 'T_Air';   'RelHumid';      'Precip'; 'Cn2'; 'SRad';   'WL'};

% For turbulenceData (ATIs, Gill, DPLs) (slightly different names than above due to ensemble average)
plot_variables_alt =  {'WindSpd_mean'; 'WindDir_mean'; 'Baro'; 'T_mean';  'RelHumid_mean'; 'Precip'; 'Cn2'; 'NetRad'; 'WL'};

% For HOBOs, Apogee, and/or DataQ (slightly different names than above due to water temperature)
plot_variables_alt2 = {'WindSpd';      'WindDir';      'Baro'; 'T_Water'; 'RelHumid';      'Precip'; 'Cn2'; 'Pyr';    'WL'};

% Labels for all three of the above
plot_variables_label = {'Wind Speed (m/s)'; 'Wind Dir (deg N)'; 'Barometric Pressure (mBar)'; 'T (^oC)'; ...
	  'Rel Humid (%)'; 'Precipitation (mm/hr)'; 'C_n^2 (m^{-2/3})'; 'Solar Radiation (W/m^2)'; 'Water Level (m-NAVD88)'};
plot_variables_ylims = [0 15; 0 360; 990 1050; -20 40; 20 100; 0 10; 1e-16 2e-12; -200 1000; -0.1 2];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Create and/or clear figures
x = 0;
y = 1440;
x_int = 1280;
y_int = 360;
x_buffer = 10;
y_buffer = 90;
numfigs = 9;

FigHandle = figure();
for n=1:numfigs
  FigHandle(n) = figure(n);
  % MWBL Monitors are 2560x1440
  if(y <= 0)
    y = 1440;
    x = x + x_int; % 0, 1280, 2560, ...
  end
  y = y - y_int; % 1440, 1080, 720, ...

  % 'position' array: [Start_x Start_y Size_x Size_y]
  set(gcf,'position',[x y x_int-x_buffer y_int-y_buffer])
  clf
end
% first time through each figure, make legend, then flip to false
legendflag = true;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Loop through time periods (days) to plot, adding each day to the plot as we go
for nnnn=1:length(start_date_array)
  startDate = start_date_array(nnnn);
  endDate = end_date_array(nnnn);
  
  disp(string(startDate) + ' - ' + string(endDate))

  % Load the data
  % NOTES: PortLog data give wind direction as direction toward which wind is blowing - 0 deg = Northward
  for mm=1:length(Sensors.dataStream)
    if any(mm==SensorList)	% only load data streams if in SensorList
      eval(['[',Sensors.name{mm},',errorLog] = get_MWBL_data(startDate,endDate,Sensors.dataStream{mm},Sensors.subdataStream{mm});']);
    end
  end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % If we have ATI, Gill or DPL data for this period, compute Cn2 and
  % power spectra
  
  if any(strcmp(Sensors.name(SensorList),'ATI_SMAST')) && ~isempty(ATI_SMAST)
    ATI_SMAST_turbulenceData = computeCn2(ATI_SMAST, 5*60, [],[]);
    if spectraFlag
      ATI_SMAST_Spectra = computeSpectrum(ATI_SMAST);
    end
  end
  
  if any(strcmp(Sensors.name(SensorList),'Gill_SMAST')) && ~isempty(Gill_SMAST)
    Gill_SMAST_turbulenceData = computeCn2(Gill_SMAST, 5*60, [],[]);
    if spectraFlag
      Gill_SMAST_Spectra = computeSpectrum(Gill_SMAST);
    end
  end
  
  if any(strcmp(Sensors.name(SensorList),'ATI_CBC')) && ~isempty(ATI_CBC)
    ATI_CBC_turbulenceData = computeCn2(ATI_CBC, 5*60, [],[]);
    if spectraFlag
      ATI_CBC_Spectra = computeSpectrum(ATI_CBC);
    end
  end
  
  if any(strcmp(Sensors.name(SensorList),'DPL_SMAST')) && ~isempty(DPL_SMAST)
    disp('Computing SMAST DPL Cn2 ...')
    for nn=1:5
      DPL_SMAST_turbulenceData.(['H',num2str(nn)]) = computeCn2(DPL_SMAST.(['H',num2str(nn)]), 5*60, [],[]);
      if spectraFlag
        DPL_SMAST_Spectra.(['H',num2str(nn)]) = computeSpectrum(DPL_SMAST.(['H',num2str(nn)]));
      end
    end
  end
  
  if any(strcmp(Sensors.name(SensorList),'DPL_CBC')) && ~isempty(DPL_CBC)
    for nn=1:5
      DPL_CBC_turbulenceData.(['H',num2str(nn)]) = computeCn2(DPL_CBC.(['H',num2str(nn)]), 5*60, [],[]);
      if spectraFlag
        DPL_CBC_Spectra.(['H',num2str(nn)]) = computeSpectrum(DPL_CBC.(['H',num2str(nn)]));
      end
    end
  end

  if any(strcmp(Sensors.name(SensorList),'DPL_SMAST_TESTRACK')) && ~isempty(DPL_SMAST_TESTRACK)
    for nn=1:5
      DPL_SMAST_TESTRACK_turbulenceData.(['H',num2str(nn)]) = computeCn2(DPL_SMAST_TESTRACK.(['H',num2str(nn)]), 5*60, [],[]);
      if spectraFlag
        DPL_SMAST_TESTRACK_Spectra.(['H',num2str(nn)]) = computeSpectrum(DPL_SMAST_TESTRACK.(['H',num2str(nn)]));
      end
    end
  end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %% Compute u,v wind components from Rainwise and NBAirport data
  % Test with: 
  %   Northward: [wu,wv] = pol2cart((90-[0 90 180 270])*pi/180,[1 1 1 1]); [wu; wv]
  %   Northerly: [wu,wv] = pol2cart((270-[180 270 0 90])*pi/180,[1 1 1 1]); [wu; wv]
  
  % Assumes PortLog and NBAirport are Northerly convention
  if any(strcmp(Sensors.name(SensorList),'PortLog_SMAST')) && ~isempty(PortLog_SMAST)
    [PortLog_SMAST.u,PortLog_SMAST.v] = pol2cart((270-PortLog_SMAST.WindDir)*pi/180,PortLog_SMAST.WindSpd);
  end
  if any(strcmp(Sensors.name(SensorList),'PortLog_CBC')) && ~isempty(PortLog_CBC)
    [PortLog_CBC.u,PortLog_CBC.v] = pol2cart((270-PortLog_CBC.WindDir)*pi/180,PortLog_CBC.WindSpd);
  end
  if any(strcmp(Sensors.name(SensorList),'NBAirport')) && ~isempty(NBAirport)
    [NBAirport.u,NBAirport.v] = pol2cart((270-NBAirport.WindDir)*pi/180,NBAirport.WindSpd);
  end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Loop through variables of interest and make plots with data from various sensors
  for pp=1:length(plot_variables)	 % for pp=[3,9]
    plotScint = 0;
    figure(FigHandle(pp))
    % Use 'findSubList' script to find which sensor data streams called for above contain the desired variable
    variable_name = plot_variables{pp};		% "variable_name" variable needed by findSubList script
    variable_name_alt = plot_variables_alt{pp};
    variable_name_alt2 = plot_variables_alt2{pp};
    findSubList; % Create SensorSubList
    
    % use MWBL_legend function to set figure legend.  Note, this leaves plot in "hold on" state, which is useful below. 
    if legendflag
      MWBL_legend(cset,Sensors,SensorSubList);
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Loop through each sensor in SensorSubList generated by findSubList script
    for n=1:length(SensorSubList)
      % set line type to be different for WindDir only (to avoid wrap-arounds)
      if contains(plot_variables{pp},'WindDir')
	      thislinestyle = 'none';
	      thismarker = '.';
      else
	      thislinestyle = '-';
	      thismarker = 'none';
      end
  
      if contains(Sensors.name{SensorSubList(n)},'ATI') || contains(Sensors.name{SensorSubList(n)},'Gill')
        try	% Try plotting selected variable using turbulenceData data stream, if fails, revert to full data stream
          eval(['plot(',Sensors.name{SensorSubList(n)},'_turbulenceData.date_time_mean,', ...
            Sensors.name{SensorSubList(n)},'_turbulenceData.',plot_variables_alt{pp},',', ...
            '''Color'',cset.',Sensors.name{SensorSubList(n)}, ...
            ',''LineStyle'',thislinestyle,''Marker'',thismarker)']);
          disp([' Plotting ',Sensors.name{SensorSubList(n)},', ',plot_variables_alt{pp}])
        catch
          warning(['No turbulenceData variable for ',Sensors.name{SensorSubList(n)},' ... plotting full data instead'])
          disp([' Plotting ',Sensors.name{SensorSubList(n)},', ',variable_name])
          eval(['plot(',Sensors.name{SensorSubList(n)},'.date_time,', ...
            Sensors.name{SensorSubList(n)},'.',variable_name,',', ...
            '''Color'',cset.',Sensors.name{SensorSubList(n)}, ...
            ',''LineStyle'',thislinestyle,''Marker'',thismarker)']);
        end
      elseif contains(Sensors.name{SensorSubList(n)},'DPL')
        for nn=1:5
          try		% Try plotting selected variable using turbulenceData data stream, if fails, revert to full data stream
            eval(['plot(',Sensors.name{SensorSubList(n)},'_turbulenceData.H',num2str(nn),'.date_time_mean,', ...
              Sensors.name{SensorSubList(n)},'_turbulenceData.H',num2str(nn),'.',plot_variables_alt{pp},',', ...
              '''Color'',cset.',Sensors.name{SensorSubList(n)},'{nn},''LineStyle'',thislinestyle,''Marker'',thismarker)']);
            disp([' Plotting ',Sensors.name{SensorSubList(n)},', ',plot_variables_alt{pp}])
          catch
            warning(['No turbulenceData variable for ',Sensors.name{SensorSubList(n)},' ... plotting full data instead'])
            disp([' Plotting ',Sensors.name{SensorSubList(n)},', ',variable_name])
            eval(['plot(',Sensors.name{SensorSubList(n)},'.H',num2str(nn),'.date_time,', ...
              Sensors.name{SensorSubList(n)},'.H',num2str(nn),'.',variable_name,',','''Color'',cset.',Sensors.name{SensorSubList(n)}, ...
              '{nn},''LineStyle'',thislinestyle,''Marker'',thismarker)']);
          end
        end
      elseif contains(Sensors.name{SensorSubList(n)},'HOBO')
        if contains(variable_name,'DiffPress')
          warning(['Plotting variable DiffPress/100 for ',Sensors.name{SensorSubList(n)},' ... check units!'])
          eval(['plot(',Sensors.name{SensorSubList(n)},'.date_time,',Sensors.name{SensorSubList(n)},'.',plot_variables_alt2{pp},'/100,', ...
            '''Color'',cset.',Sensors.name{SensorSubList(n)}, ...
            ',''LineStyle'',thislinestyle,''Marker'',thismarker)']);
          disp([' Plotting ',Sensors.name{SensorSubList(n)},', ',plot_variables_alt2{pp}])
        else
          disp([' Plotting ',Sensors.name{SensorSubList(n)},', ',plot_variables_alt2{pp}])
          eval(['plot(',Sensors.name{SensorSubList(n)},'.date_time,',Sensors.name{SensorSubList(n)},'.',plot_variables_alt2{pp},',', ...
            '''Color'',cset.',Sensors.name{SensorSubList(n)}, ...
            ',''LineStyle'',thislinestyle,''Marker'',thismarker)']);
        end
      elseif contains(Sensors.name{SensorSubList(n)},'KZScintillometer')
        % Raise flag to plot Scintillometer last
        plotScint = 1;
      else
	      try	% do the default variable plotting per variables in 'variable_name'
	        eval(['plot(',Sensors.name{SensorSubList(n)},'.date_time,',Sensors.name{SensorSubList(n)},'.',variable_name,',', ...
		        '''Color'',cset.',Sensors.name{SensorSubList(n)}, ...
		        ',''LineStyle'',thislinestyle,''Marker'',thismarker)']);
          disp([' Plotting ',Sensors.name{SensorSubList(n)},', ',variable_name])
        catch
          try % alt
  	        warning(['Triggered catch when plotting ',Sensors.name{SensorSubList(n)},' ... using alt variable name!'])
            disp([' Plotting ',Sensors.name{SensorSubList(n)},', ',plot_variables_alt{pp}])
	          eval(['plot(',Sensors.name{SensorSubList(n)},'.date_time,',Sensors.name{SensorSubList(n)},'.',plot_variables_alt{pp},',', ...
		          '''Color'',cset.',Sensors.name{SensorSubList(n)}, ...
		          ',''LineStyle'',thislinestyle,''Marker'',thismarker)']);
          catch % alt2
	          warning(['Triggered catch when plotting ',Sensors.name{SensorSubList(n)},' ... using alt2 variable name!'])
            disp([' Plotting ',Sensors.name{SensorSubList(n)},', ',plot_variables_alt2{pp}])
	          eval(['plot(',Sensors.name{SensorSubList(n)},'.date_time,',Sensors.name{SensorSubList(n)},'.',plot_variables_alt2{pp},',', ...
		          '''Color'',cset.',Sensors.name{SensorSubList(n)}, ...
		          ',''LineStyle'',thislinestyle,''Marker'',thismarker)']);
          end
	      end
      end
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Set axis limits, etc 
    if contains(plot_variables{pp},'Cn2')
      if plotScint
        % Plot Scintillometer very last
        plot(KZScintillometer.date_time, KZScintillometer.Cn2,"Color",cset.KZScintillometer,"LineStyle",thislinestyle,"Marker",thismarker)
      end
      set(gca,'yscale','log')
    end
  
    xlim([this_start this_end])
    ylim(plot_variables_ylims(pp,:))
    xlabel('Time (UTC)')
    ylabel(plot_variables_label{pp});
    box on

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Last time through main sensor plots, also plot day/night shading on plots
    if nnnn==length(start_date_array)
      plot_day_night
    end
  end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %% Do some QA/QC
  % Note: suggest first step is to look at individual PortLog files and 
  % compare to NB Airport to make sure no time corrections needed!
  
  % Check wind direction and compass corrections
  if(0)
    % Compute and plot wind direction error relative to NB Airport
    % do NBAirport with itself - should give zero
    WindDirRef = interp1(datenum(NBAirport.date_time(NBAirport.date_time ~= NaT)), NBAirport.WindDir(NBAirport.date_time ~= NaT), datenum(NBAirport.date_time(NBAirport.date_time ~= NaT)));
    NBAirport.WindDirErr = mod(NBAirport.WindDir(NBAirport.date_time ~= NaT)-WindDirRef,360);
    % check that NB Airport wind directions look right after interpolation
    %figure(2)
    %plot(NBAirport.date_time,WindDirRef,'g')
    try
      WindDirRef = interp1(datenum(NBAirport.date_time(NBAirport.date_time ~= NaT)), NBAirport.WindDir(NBAirport.date_time ~= NaT), datenum(PortLog_SMAST.date_time(PortLog_SMAST.date_time ~= NaT)));
      PortLog_SMAST.WindDirErr = mod(PortLog_SMAST.WindDir(PortLog_SMAST.date_time ~= NaT)-WindDirRef,360);
    end
    try
      WindDirRef = interp1(datenum(NBAirport.date_time(NBAirport.date_time ~= NaT)), NBAirport.WindDir(NBAirport.date_time ~= NaT), datenum(PortLog_CBC.date_time(PortLog_CBC.date_time ~= NaT)));
      PortLog_CBC.WindDirErr = mod(PortLog_CBC.WindDir(PortLog_CBC.date_time ~= NaT)-WindDirRef,360);
    end
    try
      WindDirRef = interp1(datenum(NBAirport.date_time(NBAirport.date_time ~= NaT)), NBAirport.WindDir(NBAirport.date_time ~= NaT), datenum(Gill_SMAST_turbulenceData.date_time_mean(Gill_SMAST_turbulenceData.date_time_mean~=NaT)));
      Gill_SMAST_turbulenceData.WindDirErr = mod(Gill_SMAST_turbulenceData.WindDir(Gill_SMAST_turbulenceData.date_time_mean~=NaT)-WindDirRef,360);
    end
    try
      WindDirRef = interp1(datenum(NBAirport.date_time(NBAirport.date_time ~= NaT)), NBAirport.WindDir(NBAirport.date_time ~= NaT), datenum(ATI_SMAST_turbulenceData.date_time_mean(ATI_SMAST_turbulenceData.date_time_mean~=NaT)));
      ATI_SMAST_turbulenceData.WindDirErr = mod(ATI_SMAST_turbulenceData.WindDir(ATI_SMAST_turbulenceData.date_time_mean~=NaT)-WindDirRef,360);
    end
    try
      WindDirRef = interp1(datenum(NBAirport.date_time(NBAirport.date_time ~= NaT)), NBAirport.WindDir(NBAirport.date_time ~= NaT), datenum(ATI_CBC_turbulenceData.date_time_mean(ATI_CBC_turbulenceData.date_time_mean~=NaT)));
      ATI_CBC_turbulenceData.WindDirErr = mod(ATI_CBC_turbulenceData.WindDir(ATI_CBC_turbulenceData.date_time_mean~=NaT)-WindDirRef,360);
    end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Plot wind direction error relative to NBAirport as time series
    figure(numfigs + 1)
    subplot(2,1,1)
    
    % Use 'findSubList' script to find which sensor data streams 
    % contain the desired variable
    variable_name = 'WindDir'; % "variable_name" variable needed by findSubList script
    findSubList
    
    if legendflag
      % use MWBL_legend function to set figure legend.  Note, this leaves plot in "hold on" state, which is useful below.
      MWBL_legend(cset,Sensors,[1,3,4,6,14]);
    end
    
    plot(NBAirport.date_time,NBAirport.WindDirErr,'.','Color',cset.NBAirport)
    hold on
    try
      plot(PortLog_SMAST.date_time(PortLog_SMAST.date_time ~= NaT),PortLog_SMAST.WindDirErr,'.','Color',cset.PortLog_SMAST)
      plot([NBAirport.date_time(1),NBAirport.date_time(end)],mean(PortLog_SMAST.WindDirErr)*[1,1],'-','Color',cset.PortLog_SMAST)
    end
    try
      plot(PortLog_CBC.date_time(PortLog_CBC.date_time ~= NaT),PortLog_CBC.WindDirErr,'.','Color',cset.PortLog_CBC)
      plot([NBAirport.date_time(1),NBAirport.date_time(end)],mean(PortLog_CBC.WindDirErr)*[1,1],'-','Color',cset.PortLog_CBC)
    end
    try
      plot(ATI_SMAST_turbulenceData.date_time_mean,ATI_SMAST_turbulenceData.WindDirErr,'.','Color',cset.ATI_SMAST)
      plot([NBAirport.date_time(1),NBAirport.date_time(end)],mean(ATI_SMAST_turbulenceData.WindDirErr)*[1,1],'-','Color',cset.ATI_SMAST)
    end
    try
      plot(Gill_SMAST_turbulenceData.date_time_mean,Gill_SMAST_turbulenceData.WindDirErr,'.','Color',cset.Gill_SMAST)
      plot([NBAirport.date_time(1),NBAirport.date_time(end)],mean(Gill_SMAST_turbulenceData.WindDirErr)*[1,1],'-','Color',cset.Gill_SMAST)
    end
    try
      plot(ATI_CBC_turbulenceData.date_time_mean,ATI_CBC_turbulenceData.WindDirErr,'.','Color',cset.ATI_CBC)
      plot([NBAirport.date_time(1),NBAirport.date_time(end)],mean(ATI_CBC_turbulenceData.WindDirErr)*[1,1],'-','Color',cset.ATI_CBC)
    end
    try						% this only if SMAST DPL data were loaded as well
      subplot(2,1,2)
      if legendflag
        % use MWBL_legend function to set figure legend.  
        % Note, this leaves plot in "hold on" state, which is useful below.
        MWBL_legend(cset,Sensors,[10]);
      end
      for nn=[1:5]
        % force the x-axis to be datetime format even if there are no DPL data
        plot(NBAirport.date_time(1),nan);
        
        WindDirRef = interp1(datenum(NBAirport.date_time(NBAirport.date_time ~= NaT)), NBAirport.WindDir(NBAirport.date_time ~= NaT), datenum(DPL_SMAST_turbulenceData.(['H',num2str(nn)]).date_time_mean(DPL_SMAST_turbulenceData.(['H',num2str(nn)]).date_time_mean~=NaT)));
        DPL_SMAST_turbulenceData.(['H',num2str(nn)]).WindDirErr = mod(DPL_SMAST_turbulenceData.(['H',num2str(nn)]).WindDir(DPL_SMAST_turbulenceData.(['H',num2str(nn)]).date_time_mean~=NaT)-WindDirRef,360);
        
        plot(DPL_SMAST_turbulenceData.(['H',num2str(nn)]).date_time_mean,DPL_SMAST_turbulenceData.(['H',num2str(nn)]).WindDirErr,'.','Color',cset.DPL_SMAST{nn})
        hold on
      end
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for nn=1:2
       subplot(2,1,nn)
       ylim([0 360])
       xlabel('Time (UTC)')
       ylabel('Wind Dir Error (Deg)')
       box on
  
       plot_day_night
     end
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Plot WindDirErr as a function of wind speed and direction for each sensor
    figure(numfigs+2)
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % WindDirErr vs. WinSpd
    subplot(2,1,1)
  
    plot(NBAirport.WindSpd,NBAirport.WindDirErr,'.','Color',cset.NBAirport)
    hold on
    plot(PortLog_SMAST.WindSpd,PortLog_SMAST.WindDirErr,'.','Color',cset.PortLog_SMAST)
    plot(PortLog_SMAST.WindSpd,PortLog_SMAST.WindDirErr,'.','Color',cset.PortLog_SMAST)
  
    try
      plot(ATI_SMAST_turbulenceData.WindSpd,ATI_SMAST_turbulenceData.WindDirErr,'.','Color',cset.ATI_SMAST)
    end
    try
      plot(Gill_SMAST_turbulenceData.WindSpd,Gill_SMAST_turbulenceData.WindDirErr,'.','Color',cset.Gill_SMAST)
    end
    try
      plot(ATI_CBC_turbulenceData.WindSpd,ATI_CBC_turbulenceData.WindDirErr,'.','Color',cset.ATI_CBC)
    end
  
    xlabel('Wind Speed (m/s)')
    ylabel('Wind Dir Error (deg)')
    ylim([0 360])
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % WindDirErr vs. WinDir
    subplot(2,1,2)
  
    plot(NBAirport.WindDir,NBAirport.WindDirErr,'.','Color',cset.NBAirport)
    hold on
    plot(PortLog_SMAST.WindDir,PortLog_SMAST.WindDirErr,'.','Color',cset.PortLog_SMAST)
    plot(PortLog_SMAST.WindDir,PortLog_SMAST.WindDirErr,'.','Color',cset.PortLog_SMAST)
  
    % Note: when NBAirport WindDir is zero, wind error is equal to the other sensor's wind direction.
    % This accounts for the 1:1 line of the Wind Dir Error vs. Wind Dir plot.
    zeroind = find(NBAirport.WindDir==0);
    plot(NBAirport.WindDir(zeroind),NBAirport.WindDirErr(zeroind),'k.')
    plot(PortLog_SMAST.WindDir(zeroind),PortLog_SMAST.WindDirErr(zeroind),'b.')
    plot(PortLog_SMAST.WindDir(zeroind),PortLog_SMAST.WindDirErr(zeroind),'g.')
  
    try
      plot(ATI_SMAST_turbulenceData.WindDir,ATI_SMAST_turbulenceData.WindDirErr,'.','Color',cset.ATI_SMAST)
    end
    try
      plot(Gill_SMAST_turbulenceData.WindDir,Gill_SMAST_turbulenceData.WindDirErr,'.','Color',cset.Gill_SMAST)
    end
    try
      plot(ATI_CBC_turbulenceData.WindDir,ATI_CBC_turbulenceData.WindDirErr,'.','Color',cset.ATI_CBC)
    end
  
    xlabel('Wind Dir (deg)')
    ylabel('Wind Dir Error (deg)')
    xlim([0 360])
    ylim([0 360])
  end

  drawnow
  legendflag = false;
end % End of nnnn loop through time chunk periods

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PUT PRINT STATEMENT INSIDE MAIN LOOP ONLY TO SEE TIME CHUNK UPDATES DURING REMOTE EXECUTION
if printflag
  for m=1:numfigs
    figure(FigHandle(m))

    if(0)
      xlim([datetime(2025,01,01) datetime(2025,12,31)])
      ax = gcf;
      exportgraphics(ax,['./2025-01-01_baseline_sensor_plots/plot_baseline_sensors_',datestr(start_date_array(1)),'_',num2str(m),'.jpg'],'Resolution',300)
  
      xlim([datetime(2025,09,03) datetime(2025,09,10)])
      ax = gcf;
      exportgraphics(ax,['./2025-09-22_baseline_sensor_plots_too/plot_baseline_sensors_',datestr(start_date_array(1)),'_',num2str(m),'.jpg'],'Resolution',300)
    elseif(0)
      xlim([datetime(2025,08,27) datetime(2025,09,10)])
      ax = gcf;
      mkdir('2025-12-19_baseline_sensor_plots')
      exportgraphics(ax,['./2025-12-19_baseline_sensor_plots/plot_baseline_sensors_',datestr(start_date_array(1)),'_',num2str(m),'.jpg'],'Resolution',300)
    elseif(0)
      xlim([datetime(2024,10,01) datetime(2024,11,01)])
      xlim([this_start this_end])
      print('-djpeg',['./2024-11-28_baseline_sensor_plots_DPL/plot_baseline_sensors_',datestr(start_date_array(1)),'_',num2str(m)])
    end
  end
end


