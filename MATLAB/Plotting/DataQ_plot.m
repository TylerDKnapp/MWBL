% DataQ_plot.m
% Syntax: DataQ_plot
%
% Marine Wave Boundary Layer Analysis
% Script for cycling through matlab formatted DataQ data files and plotting basic data. 
% Current version loads data from DataQ unit, SN ????, and plots data on 
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
% Author: Steven Lohrenz, 3/22/2022 (revised from Portlog_plot.m script by
%   Miles Sundermeyer)
% School for Marine Science and Technology, University of Massachusetts Dartmouth

clc
clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Version = 'DataQ_plot.m, V1.0, 3/22/22';

printflag = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set paths to each of the data types, raw and processed (.mat) directories
userflag = 2;			% set directory path: 0 for OneDrive, 1 for MAS, 2 for SEL

if(userflag==0)
  baseDir = 'C:\Users\sunderm\OneDrive - University of Massachusetts Dartmouth\MWBL\Data\';
elseif(userflag==1)
  baseDir = 'H:\projects\2020-05-10 MWBL NP Photonics\Data\';
elseif(userflag==2)
  baseDir ='C:\Users\slohrenz\OneDrive - UMASS Dartmouth\MWBL\Data\'; %'C:\Users\slohrenz\Documents\Steve\DATA\NUWC\';  %
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load all NB Airport data for plotting over the DataQ time series
DataDir = [baseDir,'NBAirport\processed\'];
FList = dir([DataDir,'*.mat']);

NBAirpt = [];
NBAirptjday = [];

for n=1:length(FList)
  thisdataNB = load([DataDir,FList(n).name]);

  %NBAirpt.Version = thisdataNB.Version;
  %NBAirpt.README = thisdataNB.README;
  NBAirpt.variables = thisdataNB.variables;
  NBAirpt.units = thisdataNB.units;
  for nn=1:length(thisdataNB.variables)
    if n==1
      NBAirpt.(thisdataNB.variables{nn}) = thisdataNB.(thisdataNB.variables{nn});
    else
      NBAirpt.(thisdataNB.variables{nn}) = [NBAirpt.(thisdataNB.variables{nn});thisdataNB.(thisdataNB.variables{nn})];
    end
  end
end

clear thisdataNB

% also make a single sequential time array;
NBAirptjday = NBAirpt.datetime;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load and cycle through the DataQ data files
DataDir = [baseDir,'SMAST_Station1\DataQ\processed\'];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% make list of all .mat files to load and plot
%FList = dir([DataDir,'*.mat']);

% Get list of files 
FList = dir([DataDir,'*.mat']);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for n=1:length(FList)

    % Load a DataQ data file
    thisdata1 = load([DataDir,FList(n).name]);
    disp([' First file:  ',FList(n).name])
    
    % make a combined date-time array
    thisjday1 = thisdata1.datetime;

    %Set dates to limit which files are read
    if thisjday1<datenum('2021-09-01')
        continue
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Plot time series
    figure(1)
    clf
    
    T_max=30;
    T_min=5;
    RH_max=100;
    RH_min=10;
    Bar_max=1040;
    Bar_min=990;
    Rad_max=800;
    Rad_min=-100;

    msize=2;
    subplot(3,2,1)
    plot(thisjday1, thisdata1.T_Air_upr,'o','Color','b','MarkerSize',msize)
    hold on
    plot(thisjday1, thisdata1.T_Air_lwr,'.','Color','c')
    xlimits=get(gca,'Xlim');
    ylim([T_min,T_max]);
    plot(NBAirptjday, NBAirpt.T_Air,'-','Color','k')
    xlim(xlimits);
    ylabel('^oC');
    title('Air Temp (b=SMAST upr, c=SMAST lwr)');
    
    subplot(3,2,2)
    plot(thisjday1, thisdata1.RelHumid_upr,'o','Color','b','MarkerSize',msize)
    hold on
    plot(thisjday1, thisdata1.RelHumid_lwr,'.','Color','c')
    plot(NBAirptjday, NBAirpt.RelHumid,'-','Color','k')
    ylim([RH_min,RH_max]);
    xlim(xlimits);
    ylabel('%');
    title('Rel Hum (b=SMAST upr, c=SMAST lwr)');
    
    subplot(3,2,3)
    plot(thisjday1, thisdata1.Baro,'o','Color','b','MarkerSize',msize)
    hold on
    plot(NBAirptjday, NBAirpt.Baro,'-','Color','k')
    ylim([Bar_min,Bar_max]);
    xlim(xlimits);
    ylabel('mBar');
    title('Barometric Pressure');
    
    subplot(3,2,4)
    plot(thisjday1, thisdata1.NetRad,'o','Color','b','MarkerSize',msize)
    hold on
    plot(thisjday1, thisdata1.Pyr,'.','Color','c')
    ylim([Rad_min,Rad_max]);
    xlim(xlimits);
    ylabel('W m^{-2}');
    title('Radiometry (b=Net Rad, c=Pyr)')
    
    subplot(3,2,5)
    plot(thisjday1, thisdata1.Volts,'o','Color','b','MarkerSize',msize)
    hold on
    xlim(xlimits);
    title('Battery Volts (SMAST)');
    
    for nn=1:5
      subplot(3,2,nn);
      datetick keeplimits
    end
    
    sgtitle(strrep(FList(n).name,'_',' '));
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Create a common time array following any corrections above - need to think of how to do this w/o loops
    % start on an even time in 10's of minutes past the hour, assume both data sets start on 10's of minutes past hr.
    clear commonjday thisdata1_interp NBAirpt_interp
    
    commonjday = floor(min(thisjday1*24*6))/(24*6):10/(24*60):max(thisjday1);
    %Skip file if less than two data points
    if length(thisdata1.datetime)<2
        continue
    end

    % map all data onto this common time array
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for nnn=2:length(thisdata1.variables)	% only do non-date,time variables
        thisdata1_interp.(thisdata1.variables{nnn}) = interp1(thisjday1,thisdata1.(thisdata1.variables{nnn}),commonjday,'linear',nan);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Assume airport data start before DataQ data and end after, so do straight interpolation
    % Find and eliminate data w/ repeat time stamp
    toss = find(diff(NBAirptjday*24)==0);
    NBAirptjday(toss) = [];			% do jday variable separately
        for nnn=1:length(NBAirpt.variables)		% truncate all variables, including date, time
    NBAirpt.(NBAirpt.variables{nnn})(toss)=[];
    end
    
    % now interpolate
    for nnn=3:length(NBAirpt.variables)		% only do non-date,time variables
        NBAirpt_interp.(NBAirpt.variables{nnn})=interp1(NBAirptjday,NBAirpt.(NBAirpt.variables{nnn}),commonjday,'linear',nan);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Plot scatter plots - first set is DataQ stations against each other
    figure(2)
    clf
    
    subplot(2,2,1)
    plot(thisdata1_interp.T_Air_upr,thisdata1_interp.T_Air_lwr,'.','Color','b')
    hold on
    xlabel('^oC (Upper)');
    ylabel('^oC (Lower)');
    title('Air Temperature');
    
    subplot(2,2,2)
    plot(thisdata1_interp.RelHumid_upr,thisdata1_interp.RelHumid_lwr,'.','Color','b')
    hold on
    xlabel('% (Upper)');
    ylabel('% (Lower)');
    title('Relative Humidity');
    
    subplot(2,2,3)
    plot(thisdata1_interp.NetRad,thisdata1_interp.Pyr,'.','Color','b')
    hold on
    xlabel('W m^{-2} (Net Rad)');
    ylabel('W m ^{-2} (Pyr)');
    title('Solar Radiation');
    
    for nplt=1:3
    subplot(2,2,nplt)
    axis equal
    axis square
    h1 = refline(1,0); set(h1,'Color','k')
    end
    
    sgtitle(strrep(FList(n).name,'_',' '));
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Plot scatter plots - next set is DataQ stations against NB Airport data
    figure(3)
    clf
    
    subplot(2,2,1)
    plot(NBAirpt_interp.T_Air, thisdata1_interp.T_Air_upr,'.','Color','b')
    hold on
    plot(NBAirpt_interp.T_Air, thisdata1_interp.T_Air_lwr,'.','Color','c')
    xlabel('^oC (NB Airport)');
    ylabel('^oC (b=Upper, c=Lower)');
    title('Air Temperature');
    
    subplot(2,2,2)
    plot(NBAirpt_interp.RelHumid,thisdata1_interp.RelHumid_upr,'.','Color','b')
    hold on
    plot(NBAirpt_interp.RelHumid,thisdata1_interp.RelHumid_lwr,'.','Color','c')
    xlabel('% (NB Airport)');
    ylabel('% (b=Upper, c=Lower)');
    title('Relative Humidity');
    
    subplot(2,2,3)
    plot(NBAirpt_interp.Baro,thisdata1_interp.Baro,'.','Color','b')
    hold on
    xlabel('mBar (NB Airport)');
    ylabel('mBar (b=SMAST)');
    title('Barometric Pressure');
    
    for nplt=1:3
        subplot(2,2,nplt)
        axis equal
        axis square
        h1 = refline(1,0); set(h1,'Color','k')
    end
    
    sgtitle(strrep(FList(n).name,'_',' '));
    
    %mypause
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if printflag
        for nfg=1:3
          figure(nfg);
          print('-djpeg',[baseDir,'SMAST_Station1\DataQ\plots\DataQ_plot_',FList(n).name(end-23:end-4),'_',num2str(nfg)]);
        end
    end
end

disp('Completed');

%%%% END OF CODE %%%%%%%%%%%%%
