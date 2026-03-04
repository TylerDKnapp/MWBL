% Marine Wave Boundary Layer Analysis
% Script for converting Ecotech nephelometer data files from .csv file to .mat format.
%
% Input: 
%   input_file	- string variable, Ecotech .csv file name
%   inputDir	- string variable, absolute or relative path to .csv input_file 
%   outputDir	- string variable, absolute or relative path to write .mat file 
%
% Output: .mat file containing the following variables:
%   date_time		- Matlab formatted date and time (UTC)
%   major_state		- major system state 
%   major_state_status	- major system state 
%   sigma_sp		- 5 min. averaged particulate scattering coefficient
%   sigma_sp_status	- status of 5 min. averaged particulate scattering coefficient
%   T_Air		- Air temperature (deg C)
%   T_Air_status	- status of air temperature
%   T_Cell		- Cell body temperature (deg C)
%   T_Cell_status	- status of cell body temperature
%   RelHumid - Relative Humidity of sample (%)
%   RelHumid_Status - status of Relative Humidity
%   Baro		- Barometric Pressure (mBar or hPa)
%   Baro_status		- status of barometric pressure
%
% Written by Kayhan Ulgen, 12/20/2023
% Modified by Miles A. Sundermeyer, 12/16/2024; corrected factor of 10 unit error in Baro, added delimiter to table read 
% to allow for lines with missing values
% Modified by Tyler Knapp, 02/20/2025; Removed time corrections as of 01/2025 Ecotech is set with UTC time
% Modified by Tyler Knapp, 04/03/2025 - Added simple data processing to T and Baro

function [] = Ecotech_csv2mat(input_file,inputDir,outputDir)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  Version = 'Ecotech_csv2mat, Version 04/03/2025';
  disp([Version, ' is running']);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % specify the variables and units
  
  variables={'date_time'; 'major_state'; 'major_state_status';'sigma_sp'; 'sigma_sp_status';'T_Air';'T_Air_status';'T_Cell';'T_Cell_Status';'RelHumid';'RelHumid_Status';'Baro';'Baro_Status'};
  units = {'Matlab formatted datetime (UTC)';'[-]';'[-]';'[-]';'[-]';'deg C';'[-]';'deg C';'[-]';'%';'[-]';'mBar';'[-]'};
  numvars = length(variables);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Get info about Ecotech file, and parse some info from its file name (e.g., SN, download date, etc)
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
  if input_file(end-2:end) == "adf"
    file_dat = readtable([inputDir,input_file],FileType="text");
    file_dat.Var1 = datetime(string(table2array(file_dat(:,1))),InputFormat="uuuuMMddHHmmss");
    file_dat.Properties.VariableNames = variables;
  else
    file_dat = readtable([inputDir,input_file],'PreserveVariableNames',true);
  end
  % file_dat = readtable([inputDir,input_file],'delimiter',',','PreserveVariableNames',true);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Clear rows of data that have NaNs
  for n = 2:(numvars)
    try
      toss = isnan(file_dat.(n));
      file_dat(toss,:) = [];
    end
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Parse all variables from table format to array format
  for n=1:numvars
    if n==1
      try			% try a couple different datetime formats
        eval([variables{n},' = datetime(table2array(file_dat(:,n)), "InputFormat","yyyy/MM/dd HH:mm:ss");']);
      catch		% early file, 'M9003 5 Minute - 20231113 0945.csv', used this format
        eval([variables{n},' = datetime(table2array(file_dat(:,n)), "InputFormat","MM/dd/yyyy HH:mm");']);
      end
    else
      eval([variables{n},' = table2array(file_dat(:,n));']);
    end
  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if strcmp(variables{n},'T_Air') | strcmp(variables{n},'T_Cell')
      eval([variables{n},' = ',variables{n},'-273.15;']);	% convert temperature from K to C
    end
  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Data Processing
  % Samples are over 5 minutes
  T_Air  = remove_spikes(T_Air,5); % Sample (Air) Temp
  RelHumid = remove_spikes(RelHumid,10); % Relative Humidity
  Baro = remove_spikes(Baro,5); % Relative Humidity
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Save this file to identically named .mat file
  % get rid of '.csv' or '.adf' at end of filename
  output_file = strrep(input_file,'.csv','');
  output_file = strrep(output_file,'.adf','');
  
  disp([' Saving output to ',outputDir,output_file]);
  disp(' ');
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Save variable names and units
  save([outputDir,output_file],'Version','variables','units','badlines');
  
  for n = 1:numvars 
    save([outputDir,output_file],variables{n},'-append');
  end
end