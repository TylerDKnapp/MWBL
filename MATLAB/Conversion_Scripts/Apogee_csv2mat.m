% Marine Wave Boundary Layer Analysis
% Script for converting Apogee IR sensor data files from .csv file to .mat format.
%
% Input: 
%   input_file	- string variable, Apogee .csv file name
%   inputDir	- string variable, absolute or relative path to .txt input_file 
%   outputDir	- string variable, absolute or relative path to write .mat file 
%
% Output: .mat file containing the following variables:
%   date_time	- Matlab formatted date and time (UTC)
%   T_Water	- skin water temperature (deg C) 
%   T_Sensor    - Sensor temperature (deg C) 
% Written by Kayhan Ulgen, 01/04/2024
% Modified by Tyler Knapp, 03/10/2025 - Added function to smooth out erronious spikes in data
% Modified by Tyler Knapp, 04/03/2025 - Added simple data processing to Temp

function [] = Apogee_csv2mat(input_file,inputDir,outputDir)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  Version = 'Apogee_csv2mat, Version 04/03/2025';
  disp([Version, ' is running']);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % specify the variables and units
  
  variables={'date_time'; 'T_Water'; 'T_Sensor'};
  units = {'Matlab formatted datetime (UTC)';'deg C';'deg C'};
  numvars = length(variables);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Get info about HOBO file, and parse some info from its file name (e.g., SN, download date, etc)
  fileInfo = dir([inputDir,input_file]);
  input_bytes = fileInfo.bytes;
  disp([' Reading ',input_file]);
  
  thisdata = extract(input_file,digitsPattern);
  thissensorSN = thisdata{1};
  
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
  file_dat = readtable([inputDir,input_file],'Delimiter','comma','PreserveVariableNames',false);
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % File Processing:
  % Filter Water temp, interpolate any points exceeding 5deg. C from previous point
  file_dat(:,2) = remove_spikes(file_dat(:,2),5);
  try
    % Filter Sensor temp, interpolate any points exceeding 5deg. C from previous point
    file_dat(:,3) = remove_spikes(file_dat(:,3),5);
  catch
    warning("Warning: File does not contain T_Sensor")
    file_dat.T_Sensor = (0/0)*ones(size(file_dat(:,2)));
  end
  % Rename first column
  file_dat.Properties.VariableNames{1} = 'date_time';
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Parse all variables from table format to array format
  for n=1:numvars
    if n==1
      try 	% allow for two different datetime formats in raw data files
        eval([variables{n},' = datetime(datenum(datestr(file_dat.date_time)),"Format","MM/dd/yyyy HH:mm","convertFrom","datenum");']);
      catch
        eval([variables{n},' = datetime(datenum(datestr(file_dat.date_time)),"Format","MMM dd yyyy HH:mm:ss","convertFrom","datenum");']);
      end
    else
      eval([variables{n},' = table2array(file_dat(:,n));']);
    end
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