%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NOTE: This function will recreate the weekly plots for a given range of dates
% This is not the same as the MWBL_auto_plot.m file, and has a different function
% Plots baseline sensors for Marine Wave Boundary Layer data, as 
% time series as well as profiles, including:
%   Wind Speed
%   Wind Direction
%   Barometric Pressure
%   Relative Humidity
%   Precipitation
%   Cn2
%   Air Temperature
%   Water Temperature
%   Tide Level
%   Solar Radiation & Net Radiometer
%   PM25 Level
%
% Created by Tyler D. Knapp, 01/29/2025 - Branched off of "plot_baseline_sensors.mat"
% Edited by Tyler D. Knapp, 02/21/2025 - Removed extra functionallity, modified plots to seperate data
% Edited by Tyler D. Knapp, 03/19/2025 - Turned into function, added version control, added EPA and NOAA streams
% Edited by Tyler D. Knapp, 05/13/2025 - Fixed datetime zeroing and showPlots functionality
% Edited by Tyler D. Knapp, 09/29/2025 - Added individual DataQ Sensors, modified plot colors, changed sensors on each plot, removed CBC tower

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Run with: MWBL_auto_plot(datetime('now','Format','MMMM d, yyyy HH:mm:ss'),1,1,1,0,0,0)

function MWBL_auto_plot(endDate,showPlots,saveFlag,process,reprocessAll,reprocessSome,processAll,spectrumPlots)
arguments
  % Default to between today and two weeks ago
  endDate = datetime('yesterday','Format','MMMM d, yyyy HH:mm:ss');
  showPlots = false; % true => display plots as they're created
  saveFlag = true; % true => save figures to file
  process = true;
  reprocessAll = false;
  reprocessSome = false;
  processAll = true;
  spectrumPlots = false;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                         % Preliminary Setup %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  close all
  version = "MWBL_auto_plot, 09/29/2025";
  log = version + '\n';
  Path = pwd;
  if ~(Path(end-3:end) == "MWBL")
    cd('..')
  end
  addpath('Weekly_Plots')
  addpath('Utilities');
  addpath('Plotting');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Modify dates to fit sunday 0:00 - saturday 23:59
  % endDate = datetime('now','Format','uuuu-MM-dd hh:mm:ss.sss');
  endDate = endDate + days(8-weekday(endDate)) - hours(hour(endDate)) - minutes(minute(endDate)+1) - seconds(second(endDate));
  startDate = endDate - days(14) + minutes(1);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Defaults
  set(0,'DefaultAxesFontName','Times');
  set(0,'DefaultAxesFontSize',12);
  set(0,'DefaultAxesFontWeight','bold');
  set(0,'DefaultAxesLineWidth',1.5);
  set(0,'DefaultLineLineWidth',1.5);
  if showPlots
    FigHandle = figure();
  else
    FigHandle = figure('visible','off');
  end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Process files for the time period at hand
  if process
    dayMargin = days(14); % Offset start/end by 2 weeks to catch weekly downloads
    log = log + Function_data_raw2mat(startDate-dayMargin, endDate + dayMargin, reprocessAll, reprocessSome, processAll);
  end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Create list of data streams, plus list of which to load and plot
  struct('Sensors',[]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                         % Sensor Selection %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Note: Sensors.name should not contain any spaces because it is used as a varible name later
  % Note(2): These have been re-arranged for MWBL_auto_plot
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
  Sensors.name{14} = 		  'Pyrano_CBC';        Sensors.dataStream{14} = 'Lattice';         Sensors.subdataStream{14} = {'CBC';'Pyranometer'};
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
  % Sensors.name{28} = 		  'DPL_CBC';          Sensors.dataStream{28} = 'DPL';              Sensors.subdataStream{28} = 'CBC';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % The following is based on /usr2/MWBL/Analysis/TKnapp/Organizing_Sensor_Plots.ods
  % Set sensors to be grouped together for each set of plots
  numGroups = 2; % change to 3 if CBC Tower is desired
  sensorGroup{1} = 1:26;
  sensorGroup{2} = [15,16,27];
  % sensorGroup{3} = [15,16,28];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         %Wind Speed, Wind dir, Pressure, Air-Temp, Sonic-Temp, Water-Temp, RH, Precip, C2, Radiation, tide, PPM
  plots =    [1,          1,        1,       1,          1,          1,      1,    1,    1,     1,       1,   1;
              1,          1,        0,       0,          1,          0,      1,    0,    1,     0,       0,   0;
              1,          1,        0,       0,          1,          0,      1,    0,    1,     0,       0,   0;];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Main variables:
  plot_variables = {'WindSpd','WindSpd_mean',''; 'WindDir','WindDir_mean',''; 'Baro','',''; 'T_Air','',''; 'T_mean', '','';...
    'T_Water','',''; 'RelHumid','RelHumid_mean',''; 'Precip','',''; 'Cn2','',''; 'SRad','NetRad','Pyr';...
    'DiffPress','',''; 'PM25','PM25Scaled',''};
  % Labels for the above:
  plot_variables_label = {'Wind Speed (m/s)'; 'Wind Dir (deg N)'; 'Barometric Press. (mBar)'; 'Air T (^oC)'; 'Sonic T (^oC)'; 'Water T (^oC)'; ...
      'Rel Humid (%)'; 'Precipitation (mm/hr)'; 'C_n^2 (m^{-2/3})'; 'Solar Irradiance/Radiation (W/m^2)'; 'Water Level (m)'; 'PM25 (mg/m^3)'};
  % y-axis limits:
  plot_variables_ylims = [0 15; 0 360; 970 1050; -10 40; -10 40; 0 30; 10 100; 0 10; 1e-16 2e-12; -200 1000; -0.1 2; 0 50];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Get line colors
  [cset, ~] = MWBL_plot_const();

  for i = 1:length(Sensors.name)
    [dataTmp, logTmp] = get_MWBL_data(startDate,endDate,Sensors.dataStream{i},Sensors.subdataStream{i});
    if class(dataTmp) == "struct"
      eval([Sensors.name{i}, ' = dataTmp;']);
    end
    log = log + logTmp;
  end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                             % Plot Setup %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  itr = 0;
  FigHandle = figure();
  iOffset = zeros(1,5);
  % MWBL Monitors are 2560x1440
  screenSize_y = 1440;
  screenSize_x = 2560;
  numFigs = sum(sum(plots));
  if spectrumPlots
    numFigs = numFigs + 5; % +5 for spectrum plots
  end
  numScreens = 2;
  numFigsPerScreen_y = 4;
  numFigsPerScreen_x = ((numFigs/numFigsPerScreen_y - rem(numFigs,numFigsPerScreen_y)/numFigsPerScreen_y + 1)/numScreens...
    - rem((numFigs/numFigsPerScreen_y - rem(numFigs,numFigsPerScreen_y)/numFigsPerScreen_y + 1),numScreens)/numScreens + 1);
  x_buffer = 10;
  y_buffer = 90;
  % Starting point (Top Left)
  x = 0;
  y = screenSize_y;
  x_sz = screenSize_x/numFigsPerScreen_x;
  y_sz = 360;
  if spectrumPlots
    if showPlots
      %% Format Spectrum Plots
      for n=1:5
        itr = itr + 1;
        FigHandle(itr) = figure(itr);
        
        if(y <= 0)
          y = screenSize_y;
          x = x + x_sz; % 0, 1280, 2560, ...
        end
        y = y - y_sz; % 1440, 1080, 720, ...
      
        % 'position' array: [Start_x Start_y Size_x Size_y]
        set(gcf,'position',[x y x_sz-x_buffer y_sz-y_buffer])
        clf
      end
    else
      x_sz = screenSize_x/4;
      y_sz = screenSize_y/4;
      for n=1:5
        itr = itr + 1;
        FigHandle(itr) = figure(itr);
        % 'position' array: [Start_x Start_y Size_x Size_y]
        set(gcf,'position',[0 0 x_sz y_sz])
        clf
      end
    end
    iOffset(1) = itr; % Offset to keep track of figures
    % SMAST Lattice 
    if exist('ATI_SMAST','var')
      ATI_SMAST_Spectra = Compute_Spectrum_auto_plot(ATI_SMAST,1,FigHandle,spectrumPlots);
    end
    if exist('Gill_SMAST','var')
      Gill_SMAST_Spectra = Compute_Spectrum_auto_plot(Gill_SMAST,2,FigHandle,spectrumPlots);
    end
    % CBC Lattice
    if exist('ATI_CBC','var')
      ATI_CBC_Spectra = Compute_Spectrum_auto_plot(ATI_CBC,3,FigHandle,spectrumPlots);
    end
    % SMAST Tower
    if exist('DPL_SMAST','var')
      for nn=1:5
        DPL_SMAST_Spectra.(['H',num2str(nn)]) = Compute_Spectrum_auto_plot(DPL_SMAST.(['H',num2str(nn)]),4,FigHandle,spectrumPlots); % NOTE: This will only plot H5/Last Sonic
      end
    end
    % CBC Tower
    if exist('DPL_CBC','var')
      for nn=1:5
        DPL_CBC_Spectra.(['H',num2str(nn)]) = Compute_Spectrum_auto_plot(DPL_CBC.(['H',num2str(nn)]),5,FigHandle,spectrumPlots); % NOTE: This will only plot H5/Last Sonic
      end
    end
  end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % NOTE: Trailing 0 in function call will prevent printing
  % SMAST Lattice
  if exist('ATI_SMAST','var')
    ATI_SMAST_turbulenceData = computeCn2(ATI_SMAST, 5*60, [],[]);
  end
  if exist('Gill_SMAST','var')
    Gill_SMAST_turbulenceData = computeCn2(Gill_SMAST, 5*60, [],[]);
  end
  % CBC Lattice
  if exist('ATI_CBC','var')
    ATI_CBC_turbulenceData = computeCn2(ATI_CBC, 5*60, [],[]);
  end
  % SMAST Tower
  if exist('DPL_SMAST','var')
    for nn=1:5
      DPL_SMAST_turbulenceData.(['H',num2str(nn)]) = computeCn2(DPL_SMAST.(['H',num2str(nn)]), 5*60, [],[]);
    end
  end
  % CBC Tower
  if exist('DPL_CBC','var')
    for nn=1:5
      DPL_CBC_turbulenceData.(['H',num2str(nn)]) = computeCn2(DPL_CBC.(['H',num2str(nn)]), 5*60, [],[]);
    end
  end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        % Data Processing %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %% Compute u,v wind components from Rainwise and NBAirport data
  % Test with: 
  %   Northward: [wu,wv] = pol2cart((90-[0 90 180 270])*pi/180,[1 1 1 1]); [wu; wv]
  %   Northerly: [wu,wv] = pol2cart((270-[180 270 0 90])*pi/180,[1 1 1 1]); [wu; wv]
  % Assumes PortLog and NBAirport are Northerly convention
  if exist('PortLog_SMAST','var')
    [PortLog_SMAST.u,PortLog_SMAST.v] = pol2cart((270-PortLog_SMAST.WindDir)*pi/180,PortLog_SMAST.WindSpd);
  end
  if exist('PortLog_CBC','var')
    [PortLog_CBC.u,PortLog_CBC.v] = pol2cart((270-PortLog_CBC.WindDir)*pi/180,PortLog_CBC.WindSpd);
  end
  if exist('PortLog_NBAirport','var')
    [NBAirport.u,NBAirport.v] = pol2cart((270-NBAirport.WindDir)*pi/180,NBAirport.WindSpd);
  end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Unit conversions
  if exist('HOBO_SMAST','var')
    HOBO_SMAST.DiffPress = HOBO_SMAST.DiffPress/100; % Convert units 
  end
  if exist('HOBO_CBC','var')
    HOBO_CBC.DiffPress = HOBO_CBC.DiffPress/100; % Convert units
  end
  if exist('Ambilabs_2WIN','var')
    Ambilabs_2WIN.PM25 = Ambilabs_2WIN.PM25/10; % Convert ug/m^3 to mg/m^3??? (This makes no sense)
  end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                              % Plotting %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  for i = 1:numGroups
    % Create figures
    for n=1:size(plots,2)
      if showPlots
        if plots(i,n) % Check if plot is desired
          itr = itr + 1;
          FigHandle(itr) = figure(itr);
          if(y <= 0)
            y = screenSize_y;
            x = x + x_sz; % 0, 1280, 2560, ...
          end
          y = y - y_sz; % 1440, 1080, 720, ...
          % 'position' array: [Start_x Start_y Size_x Size_y]
          set(gcf,'position',[x y x_sz-x_buffer y_sz-y_buffer])
          clf
        end
      else
        x_sz = screenSize_x/2;
        y_sz = screenSize_y/4;
        if plots(i,n) % Check if plot is desired
          itr = itr + 1;
          FigHandle(itr) = figure(itr);
          % 'position' array: [Start_x Start_y Size_x Size_y]
          set(gcf,'position',[screenSize_x screenSize_y x_sz y_sz])
          clf
        end
      end
    end
    iOffset(i+1) = itr; % Offset to keep track of figures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Loop through variables and plot data
    itr2 = 0;
    for pp = 1:length(plots)
      plotScint = 0;
      if plots(i,pp) % Reset legend for each plot
        LList = [];
        LLabels = {};
        itr2 = itr2 + 1;
        % Loop through each sensor
        for n=1:length(sensorGroup{i})
          if sensorGroup{i}(n) > 0 % Check if sensor contains plot variable & is greater than 0 in size
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Check if var exists for turbulenceData
            variableExist = 0;
            sonicTurbulenceExists = 0;
            ppItr = 0;
            for j = 1:size(plot_variables,2)
              ppItr = ppItr + 1;
              try
                if (eval(['isfield(',Sensors.name{sensorGroup{i}(n)},'_turbulenceData',',"',plot_variables{pp,ppItr},'")'])...
                    && eval(['0 < size(',Sensors.name{sensorGroup{i}(n)},'_turbulenceData.',plot_variables{pp,ppItr},',1)']))
                  sonicTurbulenceExists = true;
                  break
                end
              end
            end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
            % Check if var exists for turbulenceData (for DPL)
            if ~sonicTurbulenceExists
              for numSensor = 1:5
                ppItr = 0;
                for j = 1:size(plot_variables,2)
                  ppItr = ppItr + 1;
                  try
                    if (eval(['isfield(',Sensors.name{sensorGroup{i}(n)},'_turbulenceData.H',num2str(numSensor),',"',plot_variables{pp,ppItr},'")'])...
                      && eval(['0 < size(',Sensors.name{sensorGroup{i}(n)},'_turbulenceData.H',num2str(numSensor),'.',plot_variables{pp,ppItr},',1)']))
                      sonicTurbulenceExists = true;
                      break
                    end
                  end
                end
                if sonicTurbulenceExists == true
                  break
                end
              end
            end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
            % Check if var exists for standard var
            if ~sonicTurbulenceExists
              ppItr = 0;
              for j = 1:size(plot_variables,2)
                ppItr = ppItr + 1;
                try
                  if (eval(['isfield(',Sensors.name{sensorGroup{i}(n)},',"',plot_variables{pp,ppItr},'")'])...
                      && eval(['0 < size(',Sensors.name{sensorGroup{i}(n)},'.',plot_variables{pp,ppItr},',1)']))
                    variableExist = true;
                    break
                  end
                end
              end
            end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Select current figure
            figure(FigHandle(itr2+iOffset(i)));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if variableExist || sonicTurbulenceExists
              hold on
              % set line type to be different for WindDir only (to avoid wrap-arounds)
              if contains(plot_variables{pp,ppItr},'WindDir')
                thislinestyle = 'none';
                thismarker = '.';
              else
                thislinestyle = '-';
                thismarker = 'none';
              end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
              % use MWBL_legend function to get figure legend info
              [LList_tmp, LLabels_tmp] = MWBL_legend_auto_plot(cset,Sensors,sensorGroup{i}(n));
              LList = [LList, LList_tmp];
              LLabels = [LLabels(:)' LLabels_tmp(:)'];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
              % Plot based on sensor type
              if sonicTurbulenceExists && ~contains(Sensors.name{sensorGroup{i}(n)},'DPL')
                eval(['plot(',Sensors.name{sensorGroup{i}(n)},'_turbulenceData.date_time_mean,',...
                  Sensors.name{sensorGroup{i}(n)},'_turbulenceData.',plot_variables{pp,ppItr},',', ...
                  '"Color",cset.',Sensors.name{sensorGroup{i}(n)},',"LineStyle","',thislinestyle,'","Marker","',thismarker,'")']);
              elseif sonicTurbulenceExists && contains(Sensors.name{sensorGroup{i}(n)},'DPL')
                for nn=1:5
                  eval(['plot(',Sensors.name{sensorGroup{i}(n)},'_turbulenceData.H',num2str(nn),'.date_time_mean,', ...
                    Sensors.name{sensorGroup{i}(n)},'_turbulenceData.H',num2str(nn),'.',plot_variables{pp,ppItr}, ...
                    ',"Color",cset.',Sensors.name{sensorGroup{i}(n)},'{nn},"LineStyle","',thislinestyle,'","Marker","',thismarker,'")']);
                  hold on
                end
              elseif contains(Sensors.name{sensorGroup{i}(n)},'KZScintillometer') && eval(['isfield(',Sensors.name{sensorGroup{i}(n)},',"',plot_variables{pp,ppItr},'")']) % Double check variable is present in sensor var
                % Special formatting for Scintillometer, keep line on top
                plotScint = 1;
              elseif eval(['isfield(',Sensors.name{sensorGroup{i}(n)},',"',plot_variables{pp,ppItr},'")']) % Double check variable is present in sensor var
                  eval(['plot(',Sensors.name{sensorGroup{i}(n)},'.date_time,',Sensors.name{sensorGroup{i}(n)},'.',plot_variables{pp,ppItr},',"Color",cset.', ...
                    Sensors.name{sensorGroup{i}(n)},',"LineStyle","',thislinestyle,'","Marker","',thismarker,'")']);
              else
                warning("Unable to plot sensor: %s",Sensors.name{sensorGroup{i}(n)})
              end
            else
              % Plot NaNs to get the correct time range, also prevents error in plot_day_night
              plot([startDate endDate], [NaN NaN]);
            end
          end
        end % End of n loop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
        try
          xlim([startDate endDate])
          ylim(plot_variables_ylims(pp,:))
          xlabel('Time (UTC)')
          ylabel(plot_variables_label{pp});
          box on
        catch
          warning('In plot: %s (Group: %d) No data found.',plot_variables{pp,ppItr},i)
        end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % After Plotting all sensors, add day/night shading and legend
        plot_day_night
        legend(LList,strrep(LLabels,'_',' '),'AutoUpdate','off','Orientation','Vertical','Location','Best','NumColumns',2)
        if showPlots
         drawnow % Force updating of plots
        end
      end % End of if plots
      if pp == 9 % Change Cn2 plot to log scale
        if plotScint
          % Plot scint very last
          plot(KZScintillometer.date_time, KZScintillometer.Cn2,"Color",cset.KZScintillometer,"LineStyle",thislinestyle,"Marker",thismarker)
        end
        set(gca,'yscale','log')
      end
    end % End of pp loop
  end % End of i loop
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                              % Save Plots %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if saveFlag 
    % Folder for year
    folderName = char(datetime(endDate,'format','yyyy'));
    saveDir = ['/usr2/MWBL/Analysis/Weekly_Plots/' folderName];
    if ~exist(saveDir, 'dir')
      mkdir(saveDir)
    end
    % Folder for month/day
    folderName = [char(datetime(endDate,'format','yyyy')),'/',char(datetime(endDate,'format','yyyy-MM-dd'))];
    saveDir = ['/usr2/MWBL/Analysis/Weekly_Plots/' folderName];
    if ~exist(saveDir, 'dir')
      mkdir(saveDir)
    end
    % Save plots
    for m = 1:itr
      figure(FigHandle(m));
      ax = gcf;
      exportgraphics(ax,[saveDir '/' 'weekly_plot_' num2str(m) '.png'],'Resolution',300)
    end
    % Try to save spectrum plots
    for m = 95:99
      try
        figure(FigHandle(m));
        ax = gcf;
        exportgraphics(ax,[saveDir '/' 'weekly_plot_' num2str(m) '.png'],'Resolution',300)
      end
    end

    logFile = fopen([saveDir,'/log.txt'],'wt');
    fprintf(logFile,log);
  end
end