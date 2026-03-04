% Marine Wave Boundary Layer Analysis
% Script for converting Kestral porable weather station data files from .csv file to .mat format
%
% Input: 
%   input_file	- string variable, Kestral .csv file name
%   inputDir	- string variable, absolute or relative path to .txt input_file 
%   outputDir	- string variable, absolute or relative path to write .mat file 
%
% Output: .mat file containing the following variables:
%   date_time	- Matlab formatted date and time (UTC)
%   T_Water	- skin water temperature (deg C) 
%   T_Sensor    - Sensor temperature (deg C) 
% Created by Tyler Knapp, 01/20/2026

function [] = Kestral_csv2mat(inputFile,inputDir,outputDir)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  Version = 'Kestral_csv2mat, Version 04/03/2025';
  disp([Version, ' is running']);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % specify the variables and units
  
  input_variables={'Temperature_F';	'Wet_Bulb_Temp_f';	'Relative_Humidity_%';	'Barometric_InHg';
    'Pressure_Altitude_Ft';	'Station_Pressure_InHg';	'Wind_Speed_MiPHr';	'Heat_Index_F';
  	'Dew_Point_F';	'Density_Altitude_ft';	'Crosswind_Headwind_MiPHr';
  	'Compass_Magnetic_Direction_Deg';	'Compass_True_Direction_Deg';	'Wind_Chill_F';};

  units = {'Matlab formatted datetime (UTC)';'deg C';'deg C'};
  numvars = length(input_variables);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Get info about HOBO file, and parse some info from its file name (e.g., SN, download date, etc)
  fileInfo = dir([inputDir,inputFile]);
  input_bytes = fileInfo.bytes;
  disp([' Reading ',inputFile]);
  
  thisdata = extract(inputFile,digitsPattern);
  thissensorSN = thisdata{1};
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Read the file as character array
  filename = fullfile(inputDir,inputFile);
  Data = char(readlines(filename));
  numlines=size(Data,1);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Set baseline for bad line and total line counts
  badlines=0;
  goodlindx=[];
  for n=1:numlines
    char_ln = char(Data(n,:));
    if length(char_ln) < size(Data,2)
      disp([ 'Line incorrect length in ',inputFile,' at line ',num2str(ichr)]);
      badlines = badlines+1;
    else
      goodlindx = [goodlindx,n];
    end
    if badlines > 0.98 * numlines 
      disp('No complete data records in file. Skipping to next file');
      return
    else
      continue
    end
  end
  disp([' Bad line count is ',num2str(badlines)]);
  disp([' Good line count is ',num2str(length(goodlindx))]);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Read data file as table
  % file_dat = readtable([inputDir,input_file],'PreserveVariableNames',true);
  file_dat = readtable([inputDir,inputFile],'Delimiter','comma','PreserveVariableNames',false);
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % File Processing:
  % Rename first column
  file_dat.Properties.VariableNames{1} = 'date_time';
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Parse all variables from table format to array format
  for n=1:numvars
    if n==1
      try 	% allow for two different datetime formats in raw data files
        eval([variables{n},' = datetime(datenum(datestr(file_dat.date_time)),"Format","yyyy/MM/dd HH:mm:ss","convertFrom","datenum");']);
      catch
        error("Could not convert datetime in file: %s",inputFile)
      end
    else
      eval([variables{n},' = table2array(file_dat(:,n));']);
    end
  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Save this file to identically named .mat file
  % get rid of any appended '.csv' string at end of file name, only if it exists
  ind = findstr(inputFile,'.csv');
  if ~isempty(ind)
    output_file = inputFile(1:ind-1);
  else
    output_file = inputFile;
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