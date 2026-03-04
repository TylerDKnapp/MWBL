% Portlog_plot.m
% Syntax: Portlog_plot
%
% Marine Wave Boundary Layer Analysis
% Script for cycling through matlab formatted RainWise Portlog data files and plotting basic data. 
% Current version loads data from both portlog units, SN 13448 and 13449, and plots data on 
% same plot for comparison and in order to apply any necessary time corrections.
%
% Inputs:
%   none (run as script, not function)
%
% Outputs:
%   none - plots only
%   
% Directory paths (absolute or relative) for various raw MWBL data files are specified below.
%
% Additional .m-files required to run this script: 
%   none
%
% Additional .mat-files required to run this script:
%   .mat formatted files created by script MWBL_data_csv2mat.m
%
% Author: Miles A. Sundermeyer, 12/9/2021
% School for Marine Science and Technology, University of Massachusetts Dartmouth

clc
clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Version = 'Portlog_plot.m, V1.0, 12/9/21';

printflag = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set paths to each of the data types, raw and processed (.mat) directories
userflag = 0;			% set directory path: 0 for OneDrive, 1 for MAS, 2 for SEL

if(userflag==0)
  baseDir = 'C:\Users\sunderm\OneDrive - University of Massachusetts Dartmouth\MWBL\Data\';
  baseDir = 'D:\OneDrive - University of Massachusetts Dartmouth\MWBL\Data\';
elseif(userflag==1)
  baseDir = 'H:\projects\2020-05-10 MWBL NP Photonics\Data\';
elseif(userflag==2)
  baseDir ='C:\Users\slohrenz\Documents\Steve\DATA\NUWC\';
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load all NB Airport data for plotting over the Portlog time series
DataDir = [baseDir,'NBAirport\processed\'];
FList = dir([DataDir,'*.mat']);

NBAirpt = [];

for n=1:length(FList)
  thisdataNB = load([DataDir,FList(n).name]);

  %NBAirpt.Version = thisdataNB.Version;
  %NBAirpt.README = thisdataNB.README;
  NBAirpt.variables = thisdataNB.variables;
  NBAirpt.units = thisdataNB.units;
  for nn=1:length(thisdataNB.variables)
    if n==1
      eval(['NBAirpt.',thisdataNB.variables{nn},' = [thisdataNB.',thisdataNB.variables{nn},'];']);
    else
      eval(['NBAirpt.',thisdataNB.variables{nn},' = [NBAirpt.',thisdataNB.variables{nn},'; thisdataNB.',thisdataNB.variables{nn},'];']);
    end
  end
end

clear thisdataNB


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load and cycle through the Portlog data files
DataDir = [baseDir,'RainwisePortLog\processed\'];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% make list of all .mat files to load and plot
%FList = dir([DataDir,'*.mat']);

% Just get files for SN 13448, then see if there is a corresponding 13449 file to compare
FList = dir([DataDir,'*13448*.mat']);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for n=1:length(FList)
  clear thisdata1 thisdata2 

  % Load a Portlog 13448 data file
  thisdata1 = load([DataDir,FList(n).name]);
  disp([' First file:  ',FList(n).name])

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % look for a similarly named 13449 file
  thisnameind = findstr(FList(n).name,'13448');

  % swap the '13448' string with a '13449' string
  fnm2 = [FList(n).name(1:thisnameind-1),'13449',FList(n).name(thisnameind+5:end)];

  if ~isempty(findstr(fnm2,'CBC'))
    thisnameind_too = findstr(fnm2,'CBC');
    % swap the 'CBC' string with a 'SMAST' string
    fnm2 = [fnm2(1:thisnameind_too-1),'SMAST',fnm2(thisnameind_too+3:end)];
  end

  if exist([DataDir,fnm2])==2;			% see if a corresponding file exists for Portlog 13449
    disp([' Second file: ',fnm2])
    if ~isempty(findstr(FList(n).name,'PortLog_13448_Data_20210902'))	% this case only, load an additional file
      disp(['        and : Portlog_13449_Data_20210823.mat'])
      thisdata2_pre = load([DataDir,'Portlog_13449_Data_20210823']);
      thisdata2 = load([DataDir,fnm2]);

      % loop through variables, and pre-append the data downloaded on 08/23/2021
      for nn=1:length(thisdata2.variables)
        eval(['thisdata2.',thisdata2.variables{nn},' = [thisdata2_pre.',thisdata2.variables{nn},'; thisdata2.',thisdata2.variables{nn},'];']);
      end
    else
      thisdata2 = load([DataDir,fnm2]);
    end
    data2flag = 1;				% use this to indicate whether or not to plot data2 data
  else						% if file of this name doesn't exist, try loading data with get_MWBL_data.m
    thisdata2 = get_MWBL_data(thisdata1.date_time(1),thisdata1.date_time(end),'RainwisePortLog','13449');
    if isempty(thisdata2)
      disp(' No corresponding sensor 2 data found for this file')
      data2flag = 0;				% use this to indicate whether or not to plot data2 data
    else
      data2flag = 1;				% use this to indicate whether or not to plot data2 data
    end
  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Do some targeted corrections to the data
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % NOTE: The analysis below is for initial review of data, to find issues and figure out how to correct.
  % Once issues are identified, these should be fixed in Portlog_csv2mat, rendering corrections here obsolete
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if 0 %~isempty(findstr(FList(n).name,'20210616'))	% this one the most serious
    % this file has a bad set of dates - look closely at files where time stamps look off
    clear regjday1 regjday2 thisdata1_interp thisdata2_interp

    adjustind = find(thisdata1.date_time<datenum(2021,05,01));

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % plot the two data series
    figure(99)
    clf

    subplot(2,1,1)
    plot(thisdata1.date_time(adjustind),thisdata1.T_Air(adjustind),'b.')
    datetick keeplimits

    subplot(2,1,2)
      plot(thisdata2.date_time,thisdata2.T_Air,'b.')
    datetick keeplimits

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % map data from 1st Portlog onto a regular time array w/ nan's where there is no data
    regjday1 = [floor(min(thisdata1.date_time(adjustind))*24*6)/(24*6):10/(24*60):max(thisdata1.date_time(adjustind))];
    for nn=1:length(regjday1)
      thisind = find(regjday1(nn)==thisdata1.date_time);
      if ~isempty(thisind)
        thisdata1_interp.T_Air(nn) = thisdata1.T_Air(thisind);
      else
        thisdata1_interp.T_Air(nn) = nan;
      end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % map data from 2nd Portlog onto a regular time array w/ nan's where there is no data
    regjday2 = [floor(min(thisdata2.date_time)*24*6)/(24*6):10/(24*60):max(thisdata2.date_time)];
    for nn=1:length(regjday2)
      thisind = find(regjday2(nn)==thisdata2.date_time);
      if ~isempty(thisind)
        thisdata2_interp.T_Air(nn) = thisdata2.T_Air(thisind);
      else
        thisdata2_interp.T_Air(nn) = nan;
      end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % replot
    figure(999)
    clf
    subplot(2,1,1)
    hold on
    plot(regjday1,thisdata1_interp.T_Air,'b.')
    datetick keeplimits

    subplot(2,1,2)
    hold on
    plot(regjday2,thisdata2_interp.T_Air,'b.')
    datetick keeplimits

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % loop through lagged correlations with to identify time offset for the 1st Portlog
    clear thiscov corrlag
    for nn=1:length(regjday1)/4
      startind = 1;
      endind = 1+length(regjday1);

      ind1 = startind:min([length(regjday1) length(regjday1)]-(nn-1));
      ind2 = startind+(nn-1):min([length(regjday1) length(regjday1)]);

      keep = find(~isnan(thisdata1_interp.T_Air(ind1)+thisdata2_interp.T_Air(ind2)));

      thiscorrcoeff = corrcoef(thisdata1_interp.T_Air(ind1(keep)),thisdata2_interp.T_Air(ind2(keep)));
      corrcoeff(nn) = thiscorrcoeff(1,2);

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % optionally plot as we go
      if(0)
        figure(999)
        clf
        subplot(2,1,1)
        plot(thisdata1_interp.T_Air(ind1(keep)),'b.')
        hold on
        plot(thisdata2_interp.T_Air(ind2(keep)),'c.')

        mypause
      end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % find what offset yielded max correlation
    [maxcorr,maxind] = max(corrcoeff);
    figure(999)
    clf
    plot(corrcoeff,'.')
    hold on
    plot(maxind,corrcoeff(maxind),'r*')

    % compute a time offset based on the max lagged correlation
    t_offset = regjday2((maxind-1)+1) - regjday1(1);
    disp(['t_offset = ',datestr(t_offset)]);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % plot again to make sure this looks right
    figure(999)
    clf

    subplot(2,1,1)
    plot(thisdata1.date_time(adjustind)+t_offset,thisdata1.T_Air(adjustind),'b.')
    hold on
    plot(thisdata2.date_time,thisdata2.T_Air,'c.')
    datetick keeplimits

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % add this time offset to the segment of data in 1st Portlog that was off in time
    thisdata1.date_time(adjustind) = thisdata1.date_time(adjustind) + t_offset;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % plot the full corrected data series
    subplot(2,1,2)
    plot(thisdata1.date_time,thisdata1.T_Air,'b.')
    hold on
    plot(thisdata2.date_time,thisdata2.T_Air,'c.')
    datetick keeplimits
  end
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Done doing corrections to data
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Plot time series
  figure(1)
  clf

  subplot(5,2,1)
  plot(thisdata1.date_time, thisdata1.T_Air,'.','Color','b')
  hold on
  if data2flag
    plot(thisdata2.date_time, thisdata2.T_Air,'.','Color','c')
  end
  plot(NBAirpt.date_time, NBAirpt.T_Air,'-','Color','k')
  %plot(thisjday, thisdata.Dew,'.','Color','g')
  %legend('T_{air}','DewPt')
  ylabel('^oC');
  title('Air Temperature (b=13448=CBC, c=13449=SMAST)');
  %title('Temperature (b=air, r=dew pt)');
  
  subplot(5,2,2)
  plot(thisdata1.date_time, thisdata1.RelHumid,'.','Color','b')
  hold on
  if data2flag
    plot(thisdata2.date_time, thisdata2.RelHumid,'.','Color','c')
  end
  plot(NBAirpt.date_time, NBAirpt.RelHumid,'-','Color','k')
  ylabel('%');
  title('Relative Humidity (b=13448=CBC, c=13449=SMAST)');
  
  subplot(5,2,3)
  plot(thisdata1.date_time, thisdata1.Baro,'.','Color','b')
  hold on
  if data2flag
    plot(thisdata2.date_time, thisdata2.Baro,'.','Color','c')
  end
  plot(NBAirpt.date_time, NBAirpt.Baro,'-','Color','k')
  ylabel('mBar');
  title('Barometric Pressure (b=13448=CBC, c=13449=SMAST)');
  
  subplot(5,2,4)
  plot(thisdata1.date_time, thisdata1.WindSpd,'.','Color','b')
  hold on
  plot(thisdata1.date_time, thisdata1.WS_Max,'.','Color','r')
  if data2flag
    plot(thisdata2.date_time, thisdata2.WindSpd,'.','Color','c')
    plot(thisdata2.date_time, thisdata2.WS_Max,'.','Color','m')
  end
  plot(NBAirpt.date_time, NBAirpt.WindSpd*0.44704,'-','Color','k')
  ylabel('m/s');
  title('Wind Speed (b=13448=CBC, c=13449=SMAST; r/m=max)');
  
  subplot(5,2,5)
  plot(thisdata1.date_time, thisdata1.SRad,'.','Color','b')
  hold on
  if data2flag
    plot(thisdata2.date_time, thisdata2.SRad,'.','Color','c')
  end
  ylabel('W/m^2');
  title('Solar Radiation (b=13448=CBC, c=13449=SMAST)')
  
  subplot(5,2,6)
  plot(thisdata1.date_time, thisdata1.WindDir,'.','Color','b')
  hold on
  if data2flag
    plot(thisdata2.date_time, thisdata2.WindDir,'.','Color','c')
  end
  plot(NBAirpt.date_time, NBAirpt.WindDir,'.','Color','k')
  ylabel('Degrees (360=from N)');
  title('Wind Direction (b=13448=CBC, c=13449=SMAST)');
  
  subplot(5,2,7)
  plot(thisdata1.date_time, thisdata1.SR_sum,'.','Color','b')
  hold on
  if data2flag
    plot(thisdata2.date_time, thisdata2.SR_sum,'.','Color','c')
  end
  ylabel('J/m^2');
  title('Solar Energy (b=13448=CBC, c=13449=SMAST)')
  
  subplot(5,2,8)
  plot(thisdata1.date_time, thisdata1.Rain,'.','Color','b')
  hold on
  if data2flag
    plot(thisdata2.date_time, thisdata2.Rain,'.','Color','c')
  end
  xlims = xlim;		% save the axes before overplotting airport data
  ylims = ylim;
  plot(NBAirpt.date_time, NBAirpt.Precip,'-','Color','k')
  ylabel('mm/hr');
  title('Rain (b=13448=CBC, c=13449=SMAST)');
  ylim([0 ylims(2)])
  
  subplot(5,2,9)
  plot(thisdata1.date_time, thisdata1.Volts,'.','Color','b')
  hold on
  if data2flag
    plot(thisdata2.date_time, thisdata2.Volts,'.','Color','c')
  end
  ylabel('Volts');
  title('Battery Volts (b=13448=CBC, c=13449=SMAST)');
  
  for nn=1:9
    subplot(5,2,nn)
    xlim(xlims(1:2))
    datetick keeplimits
  end

  bigtitle(verbatim([FList(n).name(1:thisnameind-1),'*',FList(n).name(thisnameind+5:end)]))

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Create a common time array following any corrections above - need to think of how to do this w/o loops
  % start on an even time in 10's of minutes past the hour, assume both data sets start on 10's of minutes past hr.
  clear commonjday thisdata1_interp thisdata2_interp NBAirpt_interp

  if data2flag
    commonjday = [floor(min(datenum([thisdata1.date_time; thisdata2.date_time]))*24*6)/(24*6):10/(24*60):max(datenum([thisdata1.date_time; thisdata2.date_time]))];
  else
    commonjday = [floor(min(datenum([thisdata1.date_time]))*24*6)/(24*6):10/(24*60):max(datenum([thisdata1.date_time]))];
  end

  % map all data onto this common time array
  for nn=1:length(commonjday)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    thisind1 = find(commonjday(nn)==datenum(thisdata1.date_time));
    if ~isempty(thisind1)
      for nnn=2:length(thisdata1.variables)	% only do non-date,time variables
        eval(['thisdata1_interp.',thisdata1.variables{nnn},'(nn) = thisdata1.',thisdata1.variables{nnn},'(thisind1);']);
      end
    else
      for nnn=1:length(thisdata1.variables)
        eval(['thisdata1_interp.',thisdata1.variables{nnn},'(nn) = nan;']);
      end
    end

    if data2flag
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      thisind2 = find(commonjday(nn)==datenum(thisdata2.date_time));
      if ~isempty(thisind2)
        for nnn=2:length(thisdata2.variables)	% only do non-date,time variables
          eval(['thisdata2_interp.',thisdata2.variables{nnn},'(nn) = thisdata2.',thisdata2.variables{nnn},'(thisind2);']);
        end
      else
        for nnn=1:length(thisdata2.variables)
          eval(['thisdata2_interp.',thisdata2.variables{nnn},'(nn) = nan;']);
        end
      end
    end

  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Assume airport data start before Portlog data and end after, so do straight interpolation
  % Find and eliminate data w/ repeat time stamp
  toss = find(diff(datenum(NBAirpt.date_time)*24)==0);
  for nnn=1:length(NBAirpt.variables)		% truncate all variables, including date, time
    eval(['NBAirpt.',NBAirpt.variables{nnn},'(toss)=[];']);
  end

  % now interpolate
  for nnn=2:length(NBAirpt.variables)		% only do non-date,time variables
    eval(['NBAirpt_interp.',NBAirpt.variables{nnn},'=interp1(datenum(NBAirpt.date_time),NBAirpt.',NBAirpt.variables{nnn},',commonjday);']);
  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Plot scatter plots - first set is Portlog stations against each other
  figure(2)
  clf

  if data2flag
    subplot(2,3,1)
    plot(thisdata1_interp.T_Air,thisdata2_interp.T_Air,'.','Color','b')
    hold on
    xlabel('^oC (13448, CBC)');
    ylabel('^oC (13449, SMAST)');
    title('Air Temperature');

    subplot(2,3,2)
    plot(thisdata1_interp.RelHumid,thisdata2_interp.RelHumid,'.','Color','b')
    hold on
    xlabel('% (13448, CBC)');
    ylabel('% (13449, SMAST)');
    title('Relative Humidity');

    subplot(2,3,3)
    plot(thisdata1_interp.Baro,thisdata2_interp.Baro,'.','Color','b')
    hold on
    xlabel('mBar (13448, CBC)');
    ylabel('mBar (13449, SMAST)');
    title('Barometric Pressure');

    subplot(2,3,4)
    plot(thisdata1_interp.WindSpd,thisdata2_interp.WindSpd,'.','Color','b')
    hold on
    xlabel('m/s (13448, CBC)');
    ylabel('m/s (13449, SMAST)');
    title('Wind Speed');

    subplot(2,3,5)
    plot(thisdata1_interp.WindDir,thisdata2_interp.WindDir,'.','Color','b')
    hold on
    xlabel('deg N (13448, CBC)');
    ylabel('deg N (13449, SMAST)');
    title('Wind Direction');

    subplot(2,3,6)
    plot(thisdata1_interp.SRad,thisdata2_interp.SRad,'.','Color','b')
    hold on
    xlabel('W/m^2 (13448, CBC)');
    ylabel('W/m^2 (13449, SMAST)');
    title('Solar Radiation');

    for nn=1:6
      subplot(2,3,nn)
      axis equal
    axis square
    h1 = refline(1,0); set(h1,'Color','k')
    end

    bigtitle(verbatim([FList(n).name(1:thisnameind-1),'*',FList(n).name(thisnameind+5:end)]))
  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Plot scatter plots - next set is Portlog stations against NB Airport data
  figure(3)
  clf

  subplot(2,3,1)
  plot(NBAirpt_interp.T_Air, thisdata1_interp.T_Air,'.','Color','b')
  hold on
  if data2flag
    plot(NBAirpt_interp.T_Air, thisdata2_interp.T_Air,'.','Color','c')
  end
  xlabel('^oC (NB Airport)');
  ylabel('^oC (b=13448, c=13449)');
  title('Air Temperature');

  subplot(2,3,2)
  plot(NBAirpt_interp.RelHumid,thisdata1_interp.RelHumid,'.','Color','b')
  hold on
  if data2flag
    plot(NBAirpt_interp.RelHumid,thisdata2_interp.RelHumid,'.','Color','c')
  end
  xlabel('% (NB Airport)');
  ylabel('% (b=13448, c=13449)');
  title('Relative Humidity');

  subplot(2,3,3)
  plot(NBAirpt_interp.Baro,thisdata1_interp.Baro,'.','Color','b')
  hold on
  if data2flag
    plot(NBAirpt_interp.Baro,thisdata2_interp.Baro,'.','Color','c')
  end
  xlabel('mBar (NB Airport)');
  ylabel('mBar (b=13448, c=13449)');
  title('Barometric Pressure');

  subplot(2,3,4)
  plot(NBAirpt_interp.WindSpd,thisdata1_interp.WindSpd,'.','Color','b')
  hold on
  if data2flag
    plot(NBAirpt_interp.WindSpd,thisdata2_interp.WindSpd,'.','Color','c')
  end
  xlabel('m/s (NB Airport)');
  ylabel('m/s (b=13448, c=13449)');
  title('Wind Speed');

  subplot(2,3,5)
  plot(NBAirpt_interp.WindDir,thisdata1_interp.WindDir,'.','Color','b')
  hold on
  if data2flag
    plot(NBAirpt_interp.WindDir,thisdata2_interp.WindDir,'.','Color','c')
  end
  xlabel('deg N (NB Airport)');
  ylabel('deg N (b=13448, c=13449)');
  title('Wind Direction');

  for nn=1:5
    subplot(2,3,nn)
    axis equal
    axis square
    h1 = refline(1,0); set(h1,'Color','k')
  end

  bigtitle(verbatim([FList(n).name(1:thisnameind-1),'*',FList(n).name(thisnameind+5:end)]))

  %mypause
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if printflag
    for nn=1:3
      figure(nn)
      print('-djpeg',['Portlog_plot_',FList(n).name(end-11:end-4),'_',num2str(nn)]);
    end
  end
end

