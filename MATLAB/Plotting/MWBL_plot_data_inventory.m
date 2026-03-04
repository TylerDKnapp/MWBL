% MWBL_plot_data_inventory.m
% Syntax: MWBL_plot_data_inventory
%
% Marine Wave Boundary Layer Analysis
% Script for cycling through matlab formatted data files from MWBL sensors and plotting a timeline 
% for which data sets exist for what periods.
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
% Author: Miles A. Sundermeyer, 12/3/2021
% School for Marine Science and Technology, University of Massachusetts Dartmouth
% Modified by Miles A. Sundermeyer, 6/13/2023 - updated for minor tweaks & exceptions in data collection periods, 
%		updated to automate finding user and hence paths
% Modified by Miles A. Sundermeyer, 8/14/2024 - fixed issue with PierCam not plotting correctly (end statements misplaced); 
% 		screened for bad time stamps
% Modified by Tyler Knapp, 10/23/2025 - Added support for get_File_Date
%                                     - Added date to save functionality.
%                                     - 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Version = 'MWBL_plot_data_inventory.m, Ver. 10/23/2025';

clc
clearvars

% startDate = datetime(2023,07,13);			% start of Aerosol Phase I?
startDate = datetime(2021,05,07);			% start of MWBL data collection

testflag = 0;                   % limit list of files read in order to test functionality

plotflag = 1;		% turn on/off whether plots with timelines are generated - 0 means only list most recent file name
saveFlag = 0;
printflag = 1;
overrideflag = 0;		% To override certain time intervals to make plots look better
				% Set to false to show true listing of converted data in plottable format

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Provide list of data sets to look for (this list should be a subset of those listed in MWBL_data_csv2mat.m)
datastreams = {'RainwisePortLog' 'SMAST ATI' 'SMAST Gill' 'SMAST DataQ' 'CBC ATI' 'CBC DataQ' 'KZScintillometer' 'NBAirport' 'DPL_SMAST' 'DPL_CBC' 'OnsetHOBO' 'Apogee' 'Ecotech_M9003' 'Ambilabs_2WIN' 'AQMesh'};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set directories
try   % please keep this user check here so that MAS can run code from across NFS mount
  username = getenv('USER');
  if username=='sunderm'
    baseDir = '/mnt/MWBL/Data/';
  else
    baseDir = '/usr2/MWBL/Data/';
  end
catch
  baseDir = '/usr2/MWBL/Data/';
 end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set up a figure for plotting data timeline
for n=1:2
  figure(n)
  thispos = get(gca,'position');
  set(gca,'position', [thispos(1:2) 700, 800]);

  clf
  subplot(2,1,1)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Loop through the data streams, plotting as bar plots where data exist
% use same date functions that are used in get_MWBL_data.m
clear last_file
for n=1:length(datastreams)
  disp(['Loading ',datastreams{n},' ...'])
  subdatastreams = [];
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  switch datastreams{n}
  % set directories for where data live, and make list of .mat files contained there
  case 'RainwisePortLog'
    DataDir = [baseDir,'RainwisePortLog/processed/'];
    DataLabels{n} = 'Wind Spd & Dir, T, RH, Precip';
  case 'SMAST Gill'
    datastreams{n} = 'Lattice';
    subdatastreams = {'SMAST';'Gill'};
    DataDir = [baseDir,'Lattice_SMAST_Station1/Gill/processed/'];
    DataLabels{n} = 'SMAST Gill Sonic Anemomometer';
  case 'SMAST ATI'
    datastreams{n} = 'Lattice';
    subdatastreams = {'SMAST';'ATI'};
    DataDir = [baseDir,'Lattice_SMAST_Station1/ATI/processed/'];
    DataLabels{n} = 'SMAST ATI Sonic Anemomometer';
  case 'SMAST DataQ'
    datastreams{n} = 'Lattice';
    subdatastreams = {'SMAST';'DataQ'};
    DataDir = [baseDir,'Lattice_SMAST_Station1/DataQ/processed/'];
    DataLabels{n} = 'SMAST: Sun Photometer, Net Radiometer';
  case 'CBC DataQ'
    datastreams{n} = 'Lattice';
    subdatastreams = {'CBC';'DataQ'};
    DataDir = [baseDir,'Lattice_CBC_Station2/DataQ/processed/'];
    DataLabels{n} = 'CBC: Sun Photometer, Net Radiometer';
   case 'CBC ATI'
    datastreams{n} = 'Lattice';
    subdatastreams = {'CBC';'ATI'};
    DataDir = [baseDir,'Lattice_CBC_Station2/ATI/processed/'];
    DataLabels{n} = 'CBC ATI Sonic Anemomometer';
  case 'KZScintillometer'
    DataDir = [baseDir,'KZScintillometer/processed/'];
    DataLabels{n} = 'Scintillometer';
  case 'MZA_DELTA'
    DataDir = [baseDir,'MZA_DELTA/processed/'];
    DataLabels{n} = 'MZA DELTA';
  case 'NBAirport'
    DataDir = [baseDir,'NBAirport/processed/'];
    DataLabels{n} = 'New Bedford Airport';
  case 'PierCam'
    DataDir = [];
    DataLabels{n} = 'SMAST Pier Camera';
  case 'DPL_SMAST'
    datastreams{n} = 'DPL';
    subdatastreams = {'SMAST'};
    DataDir = [baseDir,'DPL_SMAST/processed/'];
    DataLabels{n} = 'SMAST Met Tower';
  case 'DPL_CBC'
    datastreams{n} = 'DPL';
    subdatastreams = {'CBC'};
    DataDir = [baseDir,'DPL_CBC/processed/'];
    DataLabels{n} = 'CBC Met Tower';
  case 'OnsetHOBO'
    DataDir = [baseDir,'OnsetHOBO/processed/'];
    DataLabels{n} = 'HOBO Tide Range/Water Temp';
  case 'Apogee'
    DataDir = [baseDir,'Apogee/processed/'];
    DataLabels{n} = 'Apogee IR (8-14\mum) Ocean Skin Temp';
  case 'EPA_PM25'
    DataDir = [baseDir,'EPA_PM25/processed/'];
    DataLabels{n} = 'Regional EPA 2.5\mum Particle Concentrations';
  case 'Ecotech_M9003'
    DataDir = [baseDir,'Ecotech_M9003/processed/'];
    DataLabels{n} = 'Ecotech M9003 (520 nm) Nephelometer';
  case 'AQMesh'
    DataDir = [baseDir,'AQMesh/processed/'];
    DataLabels{n} = 'Ambilabs AQMesh Aerosols/Gas';
  case 'Ambilabs_2WIN'
    DataDir = [baseDir,'Ambilabs_2WIN/processed/'];
    DataLabels{n} = 'Ambilabs 2WIN (450 & 635 nm) Nephelometer';
  end

  if ~exist(DataDir)
    error("Sensor not found check datastreams")
  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if contains(datastreams{n},'PierCam')
    thisdate_time = [NaT datetime(2021,11,03,22,50,01) datetime(2022,10,14,05,10,01) NaT datetime(2023,03,23,13,13,00) datetime(2024,08,10,00,00,00)]';
    thisdate_time_missing = [datetime(2022,10,14,05,10,01) datetime(2023,03,23,13,13,00)]'; 
  else
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % make list of files to load and plot
    if strcmp(datastreams{n},'EPA_PM25')
      FList = dir([DataDir,'*Narragansett*.mat']);
    else
      FList = dir([DataDir,'*.mat']);
    end
    
    if isempty(FList)
      error(['Did not find any files in: ',DataDir])
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % initialize as datetime array
    thisdate_time = NaT;		
    thisdate_time(1) = [];

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Get and sort file dates
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % first get dates for all files, clearing list first for each data stream
    clear file_date
    for nn = 1:length(FList)
      file_date(nn) = get_File_Date(FList(nn).name,datastreams{n},subdatastreams);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % sort the list by date
    [file_date,sortind] = sort(file_date);
    FList = FList(sortind);
    
    if(testflag)	% limit number of files read for testing
      FList = FList(1:length(FList)/10:end);
      if n==1
	      warning('Subsampling file list')
        %disp('PAUSED EXECUTION - Press any key to continue ...')
	      %pause
      end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Get the file name with the most recent date
    if ~contains(datastreams{n},'PierCam')
      last_file(n) = FList(end);
    end

    if plotflag
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % loop through files and grab date_time arrays
      for nn=1:length(FList)
        if(mod(nn,10)==0)
          disp(['  ',num2str(nn),' of ',num2str(length(FList)),' ...'])
        end
  
        try	% use try:catch since some ATI files are empty
          thisdata = load([DataDir,FList(nn).name],'date_time');
          %thisdate_time = [thisdate_time; NaT; min(thisdata.date_time); max(thisdata.date_time)];
	        if any(thisdata.date_time<datetime(2021,05,01))
	          % skip this file, dates are before actual start of project, so must be time stamp issue
	          disp(['Skipping file due to bad time stamp: ',FList(nn).name])
	        else
            thisdate_time = [thisdate_time; NaT; ...
	  		    datetime(datestr([datenum(min(thisdata.date_time)):datenum(max(thisdata.date_time))]')); ...
	  		    max(thisdata.date_time)];	% [start of interval, increment by days, end of interval]
          end
        catch
          disp([' Skipping file: ',FList(nn).name]);
        end
      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % for logic below, make sure never start with but always end with NaT
      if isnat(thisdate_time(1))
	      thisdate_time = [thisdate_time(2:end); NaT];
      else
	      thisdate_time = [thisdate_time; NaT];
      end

      % also eliminate any series of NaT's within the array
      NaTind = find(isnat(thisdate_time));
      dupNaTind = find(diff(NaTind)==1);
      thisdate_time(NaTind(dupNaTind)) = [];

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % find earliest time of this data stream (only count missing data since then)
      start_date = min(thisdate_time);

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % expand thisdate_time array to cover all integer days
      thisdate_time_full = [thisdate_time(1)];
      NaTind = [0; find(isnat(thisdate_time))];
      for nn=1:length(NaTind)-1
	      thisdate_time_full = [thisdate_time_full; datetime(datestr(datenum(thisdate_time(NaTind(nn)+1)) ...
			    : 1 : datenum(thisdate_time(NaTind(nn+1)-1)))); NaT];
      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % Before implementing overrides, loop through dates to find all dates with missing data
      thisdate_time_missing = NaT; 
      %thisdate_time_missing(1) = []; 

      for nn=floor(datenum(start_date)):ceil(now)
	      thisind = find((thisdate_time > datetime(datestr(nn))) & (thisdate_time < datetime(datestr(nn+1 - 1/86400))));
	      [~,thisind] = min(abs(datenum(thisdate_time_full) - datestr(nn)));
	      % Find data gaps greater than 1 day
	      if min(abs(thisdate_time_full - datestr(nn))) > 1
	        thisdate_time_missing = [thisdate_time_missing datetime(datestr(nn)) datetime(datestr(nn+1 - 1/86400)) NaT];
	      end
      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      if(0)
	      figure(99)
	      clf
	      plot(thisdate_time_full,thisdate_time_full,'b.')
	      hold on
	      plot(thisdate_time_missing, thisdate_time_missing,'r.')
      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      if overrideflag
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % override EPA data to indicate to present
        if contains(datastreams{n},'EPA_PM25')
          thisdate_time(end) = datetime(2024,08,10,00,00,00);
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % override NB Airport data to indicate to present
        if contains(datastreams{n},'NBAirport')
          %thisdate_time(end) = datetime(datestr(now));
          %thisdate_time(end) = datetime(2024,08,10,00,00,00);
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % override Scintillometer to account for data starting in summer 2024
        %if contains(datastreams{n},'Scintillometer')
        %  thisdate_time = [thisdate_time; NaT; datetime(2024,07,31,00,00,00); datetime(2024,10,31,00,00,00)];
        %end
	        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if contains(datastreams{n},'MZA_DELTA')
          thisdate_time = [thisdate_time; NaT; datetime(2024,03,23,00,00,00); datetime(2024,10,31,00,00,00)];
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if (contains(datastreams{n},'ATI') || contains(datastreams{n},'Gill') || contains(datastreams{n},'DataQ'))
          thisdate_time = [thisdate_time; NaT; datetime(2024,08,19,00,00,00); datetime(2024,10,31,00,00,00)];
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % override DPL_SMAST to indicate spring deployment (omit this once all files have been converted to .mat format)
        if contains(datastreams{n},'DPL_SMAST')
          %thisdate_time = [thisdate_time; NaT; datetime(2023,04,25,16,08,00); datetime(datestr(now))];
        %  thisdate_time = [thisdate_time; NaT; datetime(2023,04,25,16,08,00); datetime(2023,09,30); ...
	%	  				NaT; datetime(2024,05,15,00,00,00); datetime(2024,10,31)];
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % override DPL_CBC to indicate spring deployment (omit this once all files have been converted to .mat format)
        if contains(datastreams{n},'DPL_CBC')
          %thisdate_time = [thisdate_time; NaT; datetime(2022,12,08,00,00,00); datetime(2022,12,21,00,00,00); ...
	  %					NaT; datetime(2023,05,09,16,35,30); datetime(datestr(now))];
          %thisdate_time = [thisdate_time; NaT; datetime(2022,12,08,00,00,00); datetime(2022,12,21,00,00,00); ...
	  %					NaT; datetime(2023,05,09,16,35,30); datetime(2023,09,30)];
          thisdate_time = [thisdate_time; NaT; datetime(2022,12,08,00,00,00); datetime(2022,12,21,00,00,00); ...
		  				NaT; datetime(2023,05,09,16,35,30); datetime(2023,09,30); ...
		  				NaT; datetime(2024,08,29,00,00,00); datetime(2024,09,10)];
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if contains(datastreams{n},'Apogee')
        %  thisdate_time = [thisdate_time; NaT; datetime(2024,07,31,00,00,00); datetime(2024,10,31,00,00,00)];
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if contains(datastreams{n},'Ecotech_M9003')
        %  thisdate_time = [thisdate_time; NaT; datetime(2024,07,31,00,00,00); datetime(2024,10,31,00,00,00)];
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if contains(datastreams{n},'Ambilabs_2WIN')
        %  thisdate_time = [thisdate_time; NaT; datetime(2024,07,31,00,00,00); datetime(2024,10,31,00,00,00)];
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if contains(datastreams{n},'AQMesh')
        %  thisdate_time = [thisdate_time; NaT; datetime(2024,07,31,00,00,00); datetime(2024,10,31,00,00,00)];
        end
      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % Make plots as we do each datastream
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      figure(1)
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % plot a bold line where there are data - note, NaT's allow for data gaps
      % until data QA/QC'd, only plot dates after 5/7/2021
      keep1 = find(isnat(thisdate_time) | thisdate_time>startDate);	% all data since start of MWBL deployment
      h1 = plot(thisdate_time(keep1),n*ones(size(thisdate_time(keep1))),'-','linewidth',10);
      hold on

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      figure(2)
      % plot a bold line where data are missing
      % until data QA/QC'd, only plot dates after 5/7/2021
      keep2 = find(isnat(thisdate_time_missing) | thisdate_time_missing>startDate);
      h2 = plot(thisdate_time_missing(keep2),n*ones(size(thisdate_time_missing(keep2))),'-','linewidth',10);
      hold on

      % also plot a narrow black line during gaps to make sure "missing" plots are accurate - THIS MESSES UP LEGEND
      if(0)
        figure(1)
        plot(thisdate_time_missing(keep2),n*ones(size(thisdate_time_missing(keep2))),'-','linewidth',1);
      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      for nn=1:2
        figure(nn)
        set(gca,'ydir','rev')
        axis tight
        % xlim([datetime(2021,05,01) datetime(2023,11,10)]);
        xlim([startDate datetime(datestr(now))]);
        ylim([1 max([2 n])])		% need 2 min, otherwise gives error
        xlims = xlim;
        ylims = ylim;
      end
  
      drawnow
    end		% end plotflag conditional
  end		% end check whether this data stream is PierCam or not
end		% end loop through data streams

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% echo list of most recent processed files to screen
disp('Most recent processed file names:')
for n=1:length(datastreams)
  if ~contains(datastreams{n},'PierCam')
    disp([datastreams{n},':  ',last_file(n).name])
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if plotflag && printflag
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % expand the axes just a little bit
  for nn=1:2
    figure(nn)
    grid on
    xlim([xlims(1)-0.0*(diff(xlims(1:2))) xlims(2)]);
    ylim(ylims(1:2)+0.1*diff(ylims(1:2))*[-1 1]);
    yticks('')
  
    if nn==1
      title({'University of Massachusetts Dartmouth';'Marine Wave Boundary Layer Data Collection'})
    elseif nn==2
      title({'University of Massachusetts Dartmouth';'Marine Wave Boundary Layer MISSING DATA'})
    end
    legend(DataLabels,'Location','SouthOutside')
  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %% Override the above for saving figures to file
  figname = {'MWBL_plot_data_inventory'; 'MWBL_plot_data_inventory_MISSING'};
  for nn=1:2
    if(saveFlag)
      figure(nn)
      set(gcf,'position',[800 350 800 700])
    else
      figure(nn)
      set(gca,'position',[0.13 0.53 0.78 0.4])
      set(gcf,'position',[800 350 800 700])
    end
    ax = gcf;
    if nn == 1
      exportgraphics(ax,['/usr2/MWBL/Analysis/Inventory_Plots/MWBL_plot_data_inventory_',char(datetime('today')),'.jpg'],'Resolution',300)
    else
      exportgraphics(ax,['/usr2/MWBL/Analysis/Inventory_Plots/MWBL_plot_data_inventory_MISSING_',char(datetime('today')),'.jpg'],'Resolution',300)
    end
  end
end
