% Marine Wave Boundary Layer Analysis
% Script for converting Ambilabs nephelometer data files from .csv file to .mat format.
%
% Input: 
%   input_file	- string variable, Ambilabs .csv file name
%   inputDir	- string variable, absolute or relative path to .txt input_file 
%   outputDir	- string variable, absolute or relative path to write .mat file 
%
% Output: .mat file containing the following variables:
%   date_time		- Matlab formatted date and time (UTC)
%   major_state		- major system state 
%   major_state_status	- major system state 
%   sigma_sp		- 5 min. averaged particulate scattering coefficient, Ch 1 (red)
%   sigma_sp_status	- status of 5 min. averaged particulate scattering coefficient, Ch 1 (red)
%   T_Air		- Air temperature (deg C)
%   T_Air_status	- status of air temperature
%   T_Cell		- Cell body temperature (deg C)
%   T_Cell_status	- status of cell body temperature 
%   Baro		- Barometric Pressure (mBar or hPa)
%   Baro_status		- status of barometric pressure
%
% Written by Kayhan Ulgen, 02/15/2024
% Modified by Bhavana Gowda, 10/11/2024 - Updated missing variables and units; fixed date_time format for MM/dd/yyyy HH/mm;
% Modified by Miles A. Sundermeyer, 11/2/2024 - renamed T_Sample and T_Air, to T_Air and T_Encl; renamed Angstrom
% Modified by Tyler Knapp, 02/20/2025 - Commented out time corrections. As of 01/2025, 2WIN is set with UTC time
% Modified by Tyler Knapp, 04/03/2025 - Added simple data processing to Temp, RH, and Baro

function Ambilabs_2WIN_csv2mat(input_file,inputDir,outputDir)  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  Version = 'Ambilabs_2WIN_csv2mat, Version 04/03/2025';
  disp([Version, ' is running']);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % specify the variables and units
  
  variables={'date_time';'major_state';'major_state_status';'scat_coefficient_channel_1_RED';'scat_coefficient_channel_1_RED_status';'backscatter_channel_1_RED';'backscatter_channel_1_RED_status';'T_Air';'T_Air_status';'T_Encl';'T_Encl_status';'RelHumid';'RelHumid_status';'Baro';'Baro_status';'Angstrom_exp';'Angstrom_exp_status';'PM25';'PM25_status';'DIO_state';'DIO_state_status'};
  units = {'Matlab formatted datetime (UTC)';'[-]';'[-]';'[-]';'[-]';'[-]';'[-]';'deg C';'[-]';'deg C';'[-]';'%';'[-]';'mBar';'[-]';'[-]';'[-]';'mg/m^3';'[-]';'[-]';'[-]';};
  numvars = length(variables);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Get info about Ambilabs file, and parse some info from its file name (e.g., SN, download date, etc)
  fileInfo = dir([inputDir,input_file]);
  input_bytes = fileInfo.bytes;
  disp([' Reading ',input_file]);

  % thisdata = extract(input_file,digitsPattern);
  % thisgaugeSN = thisdata{1};

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
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Data Processing
  % Note, limits are over the course of 5 minutes
  file_dat(:,8)  = remove_spikes(file_dat(:,8),5); % Sample (Air) Temp
  file_dat(:,12) = remove_spikes(file_dat(:,12),10); % Relative Humidity
  file_dat(:,14) = remove_spikes(file_dat(:,14),5); % Barometric Pressure
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Clear rows of data that have NaNs
  for n = 2:(numvars)
      toss = isnan(file_dat.(n));
      file_dat(toss,:) = [];
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Parse all variables from table format to array format
  for n=1:numvars
    if n==1
      eval([variables{n},' = datetime(table2array(file_dat(:,n)), "InputFormat","yyyy/MM/dd HH:mm:ss");']);
    else
      eval([variables{n},' = table2array(file_dat(:,n));']);
    end
  end

  % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % if date_time(1) < datetime('01/01/2025', 'format','MM/dd/yyyy')
  %   % advance from local time to UTC, adding 5 hrs during winter months, 4 hrs during summer months
  % 
  %   EDT2UTC = hours(4);
  %   EST2UTC = hours(5);
  % 
  %   warning('Local to UTC Time correction currently only for EST (+5 hrs), not EDT (+4 hrs) - confirm correct adjustment for future dates')
  %   date_time = date_time + EST2UTC;
  % end
  
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