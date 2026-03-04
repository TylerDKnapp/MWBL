% Scint_plot.m
% Syntax: Scint_plot.m
%
% Marine Wave Boundary Layer Analysis
% Script for cycling through matlab formatted Scintillometer data files and 
% plotting in comparison to MZA Delta. Current version loads all Delta data 
% and selected subset of data from Scintillometer unit, SN ????, and plots data on 
% same plot for comparison.
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
% Author: Haley Synan, 4/03/2022 (revised from DataQ_plot.m script by Steven Lohrenz)
% School for Marine Science and Technology, University of Massachusetts Dartmouth
% Revised:  Steven Lohrenz, 05/29/2022
% Revision: EVLZ , add my own user flag, commented out DELTA lines 

clc
clearvars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Version = 'Scint_plot.m, V1.2, 5/29/22';

printflag = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set paths to each of the data types, raw and processed (.mat) directories
userflag = 3;			% set directory path: 0 for OneDrive, 1 for MAS, 2 for SEL

if(userflag==0)
  baseDir = 'C:\Users\sunderm\OneDrive - University of Massachusetts Dartmouth\MWBL\Data\';
elseif(userflag==1)
  baseDir = 'C:\Users\14134\Downloads\MWBL\'; %'H:\projects\2020-05-10 MWBL NP Photonics\Data\';
elseif(userflag==2)
  baseDir ='C:\Users\slohrenz\OneDrive - UMASS Dartmouth\MWBL\Data\'; %'C:\Users\slohrenz\Documents\Steve\DATA\NUWC\';  %
elseif(userflag ==3)
     baseDir ='C:\Users\ezabarsky\OneDrive - University of Massachusetts Dartmouth\MWBL\Data\';
end
PlotDir = [baseDir,'MZA_Delta\plots\'];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Load all Delta data for comparison to Scintillometer
DataDir = [baseDir,'MZA_Delta\processed\'];
FList = dir([DataDir,'*Log.mat']);

Delta = [];
Deltajday = [];

for ifile=1:length(FList)
  disp(['Reading ',FList(ifile).name]);

  thisdata2 = load([DataDir,FList(ifile).name]);

  for nn=1:length(thisdata2.variables)
    if ifile==1
      Delta.variables = thisdata2.variables;
      Delta.units = thisdata2.units;
      Delta.(thisdata2.variables{nn}) = thisdata2.(thisdata2.variables{nn});
    else
      Delta.(thisdata2.variables{nn}) = [Delta.(thisdata2.variables{nn});thisdata2.(thisdata2.variables{nn})];
    end
  end
end

clear thisdata2

% also make a single sequential time array;
Deltajday = datenum(Delta.date_time);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load and cycle through the DataQ data files
DataDir = [baseDir,'KZScintillometer\processed\'];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% make list of all .mat files to load and plot
%FList = dir([DataDir,'*.mat']);

% Get list of files 
FList = dir([DataDir,'*.mat']);
FList = FList(43:end);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for nfile=1:length(FList)

    % Load a Scintillometer data file
    thisdata1 = load([DataDir,FList(nfile).name]);
    disp([' First file:  ',FList(nfile).name]);
    
    % make a combined date-time array
    thisjday1 = thisdata1.date_time;

    %Set dates to limit which files are read
    if thisjday1<datetime('2021-11-24')
        %continue
    end

     % Plot time series
    figure(1);
    clf
    
    msize=2;
    subplot(3,1,1)
    kzmax=plot(thisjday1,thisdata1.Cn2Max,'o','Color','b','MarkerSize',msize);
    hold on
    xlimits=get(gca,'Xlim');
    kzmin=plot(thisjday1,thisdata1.Cn2Min,'-','Color','k');
    set(gca,'YScale','log','YLim',[10^-16,10^-13]);
    xlabel('DATE/TIME'); ylabel('C_n^{2} mean (m^{-2/3})');
    hl1=legend([kzmax,kzmin],{'C_n^2 max','C_n^2 min'},'location','southeastoutside');
    title('KZScint Cn2 max and min');
    
    subplot(3,1,2)
    kzsig=plot(thisjday1,thisdata1.Cn2+thisdata1.Cn2Sig,'-','Color','b');
    hold on
    plot(thisjday1,thisdata1.Cn2-thisdata1.Cn2Sig,'-','Color','b');
    kzmean=plot(thisjday1,smoothdata(thisdata1.Cn2,'movmean',4),'o','Color',[0.4,0.4,0.4],'MarkerSize',msize);
    set(gca,'Xlim',xlimits,'YScale','log','YLim',[10^-16,10^-13]);
    xlabel('DATE/TIME'); ylabel('C_n^{2} mean (m^{-2/3})');
    hl2=legend([kzmean,kzsig],{'C_n^2 mean (1 min avg)','Std Dev'},'location','southeastoutside');
    title('KZ Scint Cn2 mean and std dev');

%     subplot(3,1,3)
%     plot(Delta.date_time,Delta.Cn2_Mean,'-','Color','k');
%     hold on
%     set(gca,'Xlim',xlimits,'YScale','log','YLim',[10^-16,10^-13]);
%     xlabel('DATE/TIME'); ylabel('C_n^{2} mean (m^{-2/3})');
%     hl3=legend('C_n^2 mean (1 min avg)','location','southeast');
%     title('MZA Delta');
    
    for nn=1:3
      subplot(3,1,nn);
      datetick keeplimits
    end

    sgtitle(strrep(FList(nfile).name,'_','\_'));

        %####################

    if printflag
        print(gcf,[PlotDir,strrep(FList(nfile).name,'.mat',''),'.tif'],'-dtiff','-r300')
    end
end