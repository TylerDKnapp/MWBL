% DataQ_csv2mat.m - Function for converting DataQ data files from .csv file to .mat format
% Marine Wave Boundary Layer Analysis
% Script for converting DataQ files from .csv to .mat format.
%
% Input: 
%   input_file 	- string variable, DataQ file name
%   inputDir	- string variable, absolute or relative path to ascii input_file (e.g., '../Data/Rainwise PortLog/ascii/')
%   outputDir	- string variable, absolute or relative path to write .mat file (e.g., '../Data/Rainwise PortLog/processed/')
%
%   Input file variables:  "Date/Time (UTC)","Barometric Pressure (Young)","Relative Humidity(HMP60)Up","Air Temp (HMP60) Up",
%      "Relative Humidity (HMP60)Down","Air Temp (HMP60)Down","Net Radiometer (NR-LITE2-L)",
%       "Pyranometer(CM3)","Battery Voltage"
%
% Output: .mat file containing the following variables (temperature, barometer, humidity and solar radiation data
%   are sampled at the data save interval):
%   date_time		- Matlab date and time format (UTC)
%   Baro		- Barometric Pressure (mBar or hPa) (Young)
%   RelHumid_upr	- Relative humidity (%) (HMP60) - upper sensor
%   T_Air_upr		- Air temperature (deg C) - upper sensor
%   RelHumid_lwr	- Relative humidity (%) (HMP60) - lower sensor
%   T_Air_lwr		- Air temperature (deg C) - lower sensor
%   NetRad		- Net Radiometer (W/m2) (NR-LITE2-L)
%   Pyr			- Pyranometer(CM3) (W/m2)
%   Volts		- Battery voltage (volts)
%
% Adapted from script by Miles Sundermeyer; revised by Steven Lohrenz
% School for Marine Science and Technology, University of Massachusetts Dartmouth
% email address: msundermeyer@umassd.edu; slohrenz@umassd.edu
% Website: http://www.umassd.edu/smast/
% Last revision by Steven Lohrenz, 03/11/2022
% Revised by Miles A. Sundermeyer, 03/12/2022
% Revised by Steven Lohrenz, 05/02/2022 - Changed datetime variable to date_time; now in Matlab datetime format
% Revised by Steven Lohrenz, 03/03/2023 - Changed partially read file message from error to warning and reported percent read
% Revised by Miles A. Sundermeyer, 06/09/2023 - Changed units for Baro from 'mb' to 'mBar'
% Revised by Steven Lohrenz, 07/21/2023 - Modified read format for CBC DataQ
% Revised by Miles A. Sundermeyer, 11/12/2023 - Added error flag for files w/ zero bytes - otherwise was hung looking for "Data"
% Revised by Steven E. Lohrenz - Modified format specifier for datetime and looking for "Date/Time (UTC)" in header
% Revised by Tyler Knapp, 01/07/2025 - Removing "date_time_minus_4", reprocessing all files.
% Revised by Tyler Knapp, 04/03/2025 - Added simple data processing to Temp(lwr&upr), Baro(lwr&upr) and RH(lwr&upr)

% NOTE: Pyr units confirmed as instantaneous measure of W/m2
function [] = DataQ_csv2mat(input_file,inputDir,outputDir)
  
  Version = 'DataQ_csv2mat, V1.5, 04/03/2025';
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Get data from filename
  file_date=datetime([input_file(end-22:end-13),' ',input_file(end-11:end-4)],'InputFormat','yyyy-MM-dd HH-mm-ss');
  
  % list the variables in the file
  if contains(input_file,'CBC') && file_date<datetime('2023-06-03 23:00:00','InputFormat','yyyy-MM-dd HH:mm:ss')
      % variables = {'date_time';'date_time_minus_4'; 'Baro'; 'T_Air';'RelHumid'; 'Pyr'; 'NetRad'; 'Volts'};
      % units = {'Matlab formatted datetime (UTC)';'Matlab formatted datetime (UTC-4)';'mBar';'%';'Deg C';'%';'Deg C';'W/m^2';'W/m^2';'Volts'};      
      variables = {'date_time'; 'Baro'; 'T_Air';'RelHumid'; 'Pyr'; 'NetRad'; 'Volts'};
      units = {'Matlab formatted datetime (UTC)';'mBar';'%';'Deg C';'%';'Deg C';'W/m^2';'W/m^2';'Volts'};
      header_charnum = 185;
      data_charnum = 103;
      
      % set data line format
      delimiter = ',';
      formatSpec = ['%D%D',repmat('%f',1,6),'%*s%[^\r\n]'];
  elseif contains(input_file,'CBC')
      variables = {'date_time';'Baro'; 'T_Air';'RelHumid'; 'Pyr'; 'NetRad'; 'Volts'};
      units = {'Matlab formatted datetime (UTC)';'mBar';'%';'Deg C';'%';'Deg C';'W/m^2';'W/m^2';'Volts'};
      header_charnum = 164;
      data_charnum = 84;
      
      % set data line format
      delimiter = ',';
      formatSpec = ['%{yyyy-MM-dd HH:mm:ss}D',repmat('%f',1,6),'%*s%[^\r\n]'];
  else
      variables = {'date_time';'Baro'; 'RelHumid_upr'; 'T_Air_upr'; 'RelHumid_lwr'; 'T_Air_lwr'; 'NetRad'; 'Pyr'; 'Volts'};
      units = {'Matlab formatted datetime (UTC)';'mBar';'%';'Deg C';'%';'Deg C';'W/m^2';'W/m^2';'Volts'};
      header_charnum = 220;
      data_charnum = 104;
      
      % set data line format
      delimiter = ',';
      formatSpec = ['%{yyyy-MM-dd HH:mm:ss}D',repmat('%f',1,8),'%*s%[^\r\n]'];
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Get info about Delta .txt file, and open file
  fileInfo = dir([inputDir,input_file]);
  input_bytes = fileInfo.bytes;
  
  % Open and read DataQ csv file 
  fileID = fopen([inputDir,input_file]);
  
  disp(['   Reading ',input_file]);
  
  if fileInfo.bytes==0		% file is zero bytes - generate error
    disp(['**** ERROR **** File is zero bytes:',inputDir,input_file])
    error(['**** ERROR **** File is zero bytes:',inputDir,input_file])
  else
    textstring_test = '';
  
    bytesread = 0;
  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Read file one line at a time, checking for header and saving data from lines that are complete data records
    while ~contains(textstring_test,'Date/Time (UTC)')  % find header line with words "Date/Time (UTC)" in it
      textstring1 = textscan(fileID,'%s',1,'delimiter','\n','headerLines',0);
      textstring_test = char(textstring1{1});
      bytesread = bytesread+size(textstring_test,2);
    end
  
    % Add headerline characters to byte count
    bytesread = bytesread+header_charnum;
  
    % Assign values to header variable
    header = textstring_test;
  
    % Read data
    dataArray = textscan(fileID,formatSpec,'delimiter',delimiter,'TreatasEmpty','EOF');
    fclose(fileID);
  
    % Check for variable length consistency due to interrupted file save and adjust if necessary
    maxn = size(dataArray{1},1);
    newn = [];
    for idat = 1:size(dataArray,2)
      coln = length(dataArray{idat});
      if coln<maxn
        newn = coln;
      end
    end
  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Eliminate incomplete records if necessary
    if ~isempty(newn)
      for idat = 1:size(dataArray,2)
        dataArray{idat} = dataArray{idat}(1:newn);
      end
    end

    if size(dataArray{1},2) < 1
      error("File: %s contians no readable data.",input_file)
    end
  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Check file size against number of characters
    numlines = size(dataArray{1},1);
    bytesread = bytesread+numlines.*data_charnum; %Number of characters per line in data records
    pctread = bytesread./input_bytes;
  
    if pctread > 0.99				% 99% of data read - make sure we didn't miss blocks of data
      disp(['   ',num2str(100*pctread),'% read: ',num2str(bytesread),' of ', num2str(input_bytes),' bytes in file']);
    elseif pctread > 0.98				% 98% of data read - make sure we didn't miss blocks of data
      warning('**** Warning: only able to read 98% of data file')
    else
      warning(['**** Warning: DataQ data file only partially read ****',' ',num2str(100*pctread),'% read'])
    end
  
    disp(' Read completed');
  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Populate variables
    if contains(input_file,'CBC') && file_date<datetime('2023-06-03 23:00:00','InputFormat','yyyy-MM-dd HH:mm:ss')
        date_time = datetime(dataArray{1},"Format",'yyyy-MM-dd HH:mm:ss');
        % date_time_minus_4 = datetime(dataArray{2},"Format",'yyyy-MM-dd HH:mm:ss');
        Baro = dataArray{3};
        T_Air = dataArray{4};
        RelHumid = dataArray{5};
        Pyr = dataArray{6};
        NetRad = dataArray{7};
        Volts = dataArray{8};
    elseif contains(input_file,'CBC')
        date_time = datetime(dataArray{1},"Format",'yyyy-MM-dd HH:mm:ss');
        Baro = dataArray{2};
        T_Air = dataArray{3};
        RelHumid = dataArray{4};
        Pyr = dataArray{5};
        NetRad = dataArray{6};
        Volts = dataArray{7};
    else
        date_time = datetime(dataArray{1},"Format",'yyyy-MM-dd HH:mm:ss');
        Baro = dataArray{2};
        RelHumid_upr = dataArray{3};
        T_Air_upr = dataArray{4};
        RelHumid_lwr = dataArray{5};
        T_Air_lwr = dataArray{6};
        NetRad = dataArray{7};
        Pyr = dataArray{8};
        Volts = dataArray{9};
    end
  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Data Processing
    if maxn > 1
      if contains(input_file,'CBC')
        Baro = remove_spikes(Baro,5);
        RelHumid = remove_spikes(RelHumid,5);
        T_Air = remove_spikes(T_Air,5);
      else
        Baro = remove_spikes(Baro,5);
        RelHumid_upr = remove_spikes(RelHumid_upr,5);
        T_Air_upr = remove_spikes(T_Air_upr,5);
        RelHumid_lwr = remove_spikes(RelHumid_lwr,5);
        T_Air_lwr = remove_spikes(T_Air_lwr,5);
      end
    end
  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Save this file to identically named .mat file
    % get rid of any appended '.txt' or '.csv' string at end of file name, only if it exists
    if contains(input_file,'.txt') || contains(input_file,'.csv')
      output_file = input_file(1:end-4);
    else
      output_file = input_file;
    end
  
    disp(['   Saving output to ',outputDir,output_file,'.mat'])
  
    % save variable names and units
    save([outputDir,output_file],'variables','units','Version');
  
    % save variables themselves (appended)
    for n = 1:length(variables)
      save([outputDir,output_file],variables{n},'-append');
    end
  end	% end skipping files that are zero bytes
end