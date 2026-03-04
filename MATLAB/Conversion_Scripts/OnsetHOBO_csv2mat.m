% Marine Wave Boundary Layer Analysis
% Script for converting tide gauge data files from .csv file to .mat format.
%
% Input: 
%   input_file	- string variable, OnsetHOBO .csv file name
%   inputDir	- string variable, absolute or relative path to .txt input_file 
%   outputDir	- string variable, absolute or relative path to write .mat file 
%
% Output: .mat file containing the following variables:
%   date_time	- Matlab formatted date and time (UTC)
%   DiffPress	- Differential pressure (mBar or hPa)
%   AbsPress	- Absolute pressure (mBar or hPa)
%   T_Water	- Temperature (deg C)
%   WL		- Water level (m)
%   Baro	- Barometric Pressure (mBar or hPa)
%   RefWL	- Reference water level (m) (single value only, not time series)
%   Rho_Water	- Salt water density (kg/m^3) (single value only, not time series)
%   
% Written by Kayhan Ulgen, 09/20/2022
% Modified by Miles A. Sundermeyer, 10/8/2022 - revised some variable names,
%   converted pressure variables to mBar, revised RefWL and Rho_Water, deleted NaN lines
% Modified by Miles A. Sundermeyer, 6/12/2023 - addition conditional to set RefWL and Rho_water in case not in data file
% Modified by Rae Stanley, 5/3/2024 - commented out lines 103 & 104, which read final column (Rho_water) in table, can be
%    uncommented if needed 
% Undid modifications by RStanley from 5/3/24 to correctly load all variables when they are available, also implemneted 
% correct pressure conversion for both Differential Pressure and Absolute Pressure
% Modified by Tyler Knapp, 04/03/2025 - Added simple data processing to Temp. Fixed NaN tossing (previously would error out 100% of the time)
% Modified by Tyler Knapp, 04/03/2025 - Overwritting WL with DiffPress and offset calc

function [] = OnsetHOBO_csv2mat(input_file,inputDir,outputDir)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  Version = 'OnsetHOBO_csv2mat, Version 04/03/2025';
  disp([Version, ' is running']);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Offsets based on NAVD 88
  height_SMAST_pier = 2.827; % Measured with RTK by TK and JC on 01/16/2025
  offset_21265946 = -0.8875 + 0.009; % Measured with RTK by TK and JC on 06/08/2025 (Plus offset for PVC)
  offset_21265947 = -0.7391 + 0.009; % Based off offset_21265946, update.
  % offset_21265947 = height_SMAST_pier - ???; 

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % specify the variables and units
  variables={'date_time','DiffPress', 'AbsPress', 'T_Water','WL','Baro','RefWL','Rho_Water'};
  units = {'Matlab formatted datetime (UTC)';'mBar';'mBar';'deg C';'m';'mBar';'m';'kg/m^3'};
  numvars = length(variables);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Get info about HOBO file, and parse some info from its file name (e.g., SN, download date, etc)
  fileInfo = dir([inputDir,input_file]);
  input_bytes = fileInfo.bytes;
  disp([' Reading ',input_file]);
  
  thisdata = extract(input_file,digitsPattern);
  thisgaugeSN = thisdata{1};
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Read the file as character array
  filename = fullfile(inputDir,input_file);
  Data = char(readlines(filename));
  numlines=size(Data,1);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Set baseline for bad line and total line counts
  badlines=0;
  goodlindx=[];
  for n=1:numlines
    char_ln = char(Data(n,:));
    if length(char_ln) < size(Data,2)
      disp([ 'Line incorrect length in ',input_file,' at line ',num2str(ichr)]);
      badlines = badlines+1;
    else
      goodlindx = [goodlindx,n];
    end
    if badlines > 0.98 * numlines 
      disp(' No complete data records in file. Skipping to next file');
      return
    else
      continue
    end
  end
  disp([' Bad line count is ',num2str(badlines)]);
  disp([' Good line count is ',num2str(length(goodlindx))]);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Read data file as table
  if(1)			% modified by M. Sundermeyer, 12/5/2024; not positive this is correct, change to other option if not
    opts = detectImportOptions([inputDir,input_file]);
    % The following option to set the date format assumes the variable name is "..._UTC...", which is not always true;
    % some data files appear to have been saved with EDT rather than UTC, which then will require adding 4 hrs to get UTC.
    % Need to investigate this further by looking at NOAA tide data to confirm time offsets for the periods in question.
    % Without this next line of code, all files still convert, but the time variable might be local rather than UTC.
    %opts = setvaropts(opts,'Date_Time_UTCStandardTime_','InputFormat','MM/dd/uu HH:mm:ss');
    opts.VariableNamingRule = 'preserve';
  
    file_dat = readtable([inputDir,input_file],opts);
  else
    file_dat = readtable([inputDir,input_file],'PreserveVariableNames',true);
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Get reference water level and water density
  % make sure we found values - not sure why these would have gone away, but these are absent in most of the 2023 files and all 2024 files
  % TDK 12/30/24: This section was not working as intended, modified RefWL and Rho_Water declarations and reorganized into try statement
  try
    RefWL = extractBefore(file_dat.("Reference Water Level"){2},' m');
    Rho_Water = extractBefore(file_dat.("Water Density"){2},' kg');
  catch
    warning(' Could not retrieve RefWL or Rho_Water ...')
    disp(' Setting default values: RefWL=0.0 m, Rho_Water=1025.005 kg/m^3')
    RefWL = 0.0;			% (m)
    Rho_Water = 1025.005;		% (kg/m^3)
  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Clear rows of data that have NaNs
  try
    toss = isnan(table2array(file_dat(:,3)));
    file_dat(toss,:) = [];
  catch
    warning("Unable to toss NaNs from file: %s",input_file)
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Parse all variables from table format to array format
  for n=1:numvars
    if n==1
      eval([variables{n},' = datetime(table2array(file_dat(:,n+1)));']);	% use file_dat(:,n+1) since first variable is line #
    elseif ge(n,2) && le(n,6)
      eval([variables{n},' = table2array(file_dat(:,n+1));']);
    else			% early files had additional variables, including 'RefWL','Rho_Water'};
      try
        eval([variables{n},' = str2double(table2array(file_dat(:,n+1)));']);
      end
    end
  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Convert units of pressure from kPa to hPa==mBar
    if contains(variables{n},'Press') || contains(variables{n},'Baro')
      eval([variables{n},' = 10*',variables{n},';']);	% convert pressures from kPa to hPa==mBar
    end
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % THIS BLOCK OF CODE INCORRECT AS WRITTEN - BOTH "EST and UTC" APPEAR IN FILE NAME EVEN WHEN DATA ARE IN UTC - MAS 12/5/2024
  % Instead, use OnsetHOBO_EST2UTC.m, this will convert EST/EDT files to UTC
  %% Convert EDT and EST to UTC if needed
  %if contains(input_file,'EDT')
  %  date_time = date_time + hours(4);
  %elseif contains(input_file,'EST') 			% WHAT HAPPENS TO FILE NAME WHEN WE GO TO EST?
  %  date_time = date_time + hours(5);			% Do this just in case?
  %end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Data Processing
  if length(T_Water) > 1
    % DiffPress	= remove_spikes(DiffPress,5);
    % AbsPress	= remove_spikes(AbsPress,5);
    T_Water  	= remove_spikes(T_Water,5);
    % WL        = remove_spikes(WL,0.1);
  end

  if contains(input_file,'21265946')
    WL = DiffPress/100 + offset_21265946;
  elseif contains(input_file,'21265947')
    WL = DiffPress/100 + offset_21265947;
  else
    warning("Serial # not known/found in file: %s",input_file)
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Save this file to identically named .mat file
  % get rid of any appended '.csv' string at end of file name, only if it exists
  ind = findstr(input_file,'.csv');
  if ~isempty(ind)
    output_file = input_file(1:ind-1);
  else
    output_file = input_file;
  end
  
  disp([' Saving output to ',outputDir,output_file]);
  disp(' ');
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Save variable names and units
  save([outputDir,output_file],'Version','variables','units','badlines');
  for n = 1:numvars 
    save([outputDir,output_file],variables{n},'-append');
  end
end