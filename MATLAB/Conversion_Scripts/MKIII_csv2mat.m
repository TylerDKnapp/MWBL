% MKIII_csv2mat.m:
% Marine Wave Boundary Layer Analysis
% Script for converting Rainwise MKIII data files from .csv to .mat
%
% Input: 
%   inputFile	- string variable, Ambilabs .csv file name
%   inputDir	- string variable, absolute or relative path to .txt input_file
%   outputDir	- string variable, absolute or relative path to write .mat file
%
% Output: A .mat file containing the following variables:
%   date_time	- Matlab formatted date and time (UTC)
%   WindSpd - (m/s)
%   WindDir - (Deg.), 0 is Northerly
%   Baro - Barometric Pressure (mBar)
%   

% Created by Tyler Knapp, 09/09/2025

function MKIII_csv2mat(fileName,inputDir,outputDir)
arguments
  % Test a file as default
  fileName = 'Rainwise_MK_W3425_20260220_SMAST.csv';
  inputDir = '/usr2/MWBL/Data/RainwisePortLog/raw/';
  outputDir = '/usr2/MWBL/Data/RainwisePortLog/processed/';
end
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  Version = 'KMIII_csv2mat, Version 09/09/2025';
  disp([Version, ' is running']);
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
  samplePeriod = 300; % seconds
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % specify the variables and units
  
  MKvarIn={'date_time';'T_Air_F';'RelHumid_%';'Baro_InHg';'WindSpd_MiPHr';'WindDir_Deg';'Precip_In';'SRad_WPM2';'T_Encl_F';'Battery_V'};
  MKvarOut={'date_time';'T_Air';'RelHumid';'Baro';'WindSpd';'WindDir';'Precip';'SRad';'T_Encl';'Battery_V'};
  additionalVar = {'Dew'; 'WS_Max'; 'SR_sum';};

  variables = {'date_time';'T_Air';'RelHumid';'Dew';'Baro';'WindDir';'WindSpd';
    'WS_Max';'SRad';'SR_sum';'Precip';'Battery_V';'u'; 'v'};
  units = {'Matlab formatted date and time (UTC)';'Deg C';'%';'Deg C';'mbar';
    'Compass Degrees (e.g. 360 => from N)';'m/s';'m/s';'Watts/m2';'J/m2';'mm/hr';'Volts';'m/s';'m/s'};
  
  numvars = length(MKvarIn);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  disp([' Reading ',fileName]);

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Read data file as table
  fileData = readtable([inputDir,fileName],'PreserveVariableNames',true,'Delimiter',',');
  dataRaw = table;
  % fileData = movevars(fileData, "date_time", 'before',"time (Sec. from Epoch)");
  % fileData.("time (Sec. from Epoch)") = [];

  key = ["°";"%";'"';" mph";"°";'"';'W/m²';'°';'v'];
  for i = 1:numvars
    try
      dataRaw.(MKvarIn{i}) = str2double(strrep(fileData{:,i},key(i-1),""));
    catch % If data is already a number above will throw error
      dataRaw.(MKvarIn{i}) = fileData{:,i};
    end
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Data Processing
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Convert units
  dataAdj.('date_time') = dataRaw.('date_time'); % No change
  dataAdj.('T_Air') = (dataRaw.('T_Air_F')-32)*5/9; % F => C
  dataAdj.('RelHumid') = dataRaw.('RelHumid_%'); % No change
  dataAdj.('Baro') = dataRaw.('Baro_InHg')*33.86389; % InHg => mBar
  dataAdj.('WindSpd') = dataRaw.('WindSpd_MiPHr')*0.44704; % mph => m/s
  dataAdj.('WindDir') = dataRaw.('WindDir_Deg'); % No change
  dataAdj.('Precip') = dataRaw.('Precip_In')*25.4; % in => mm
  dataAdj.('SRad') = dataRaw.('SRad_WPM2'); % No change
  dataAdj.('T_Encl') = (dataRaw.('T_Encl_F')-32)*5/9; % F => C
  dataAdj.('Battery_V') = dataRaw.('Battery_V'); % No change
  % Average Data
  dataOut = table;
  for i = 2:length(MKvarIn)
    [dataOut.(MKvarOut{1}),dataOut.(MKvarOut{i}),~] = ...
      ensembleAverage(dataAdj.(MKvarOut{1}),dataAdj.(MKvarOut{i}),samplePeriod);
  end
  % Filter out spikes
  % Note: Limits are over the course of 5 minutes
  try
    dataOut.('T_Air') = remove_spikes(dataOut.('T_Air'),10); % Sample (Air) Temp
  end
  try
    dataOut.('RelHumid') = remove_spikes(dataOut.('RelHumid'),10); % Relative Humidity
  end
  try
    dataOut.('Baro') = remove_spikes(dataOut.('Baro'),10); % Barometric Pressure
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Parse all variables from table format to array format
  date_time = datetime(dataOut.date_time,'convertFrom','epochTime');
  date_time = datetime(date_time, "InputFormat","dd-MMM-yyyy HH:mm:ss");
  for n=2:numvars
    eval([MKvarOut{n},' = dataOut{:,n};']);
  end

  [u_corr,v_corr,WindDir_corr,WindSpd_corr] = ...
    compass_correction_function(date_time(1),date_time(end),'SMAST_PortLog'...
    ,[],[],dataOut.WindDir,dataOut.WindSpd);
  
  u = u_corr;
  v = v_corr;
  WindDir = WindDir_corr;
  WindSpd = WindSpd_corr;

  % Add additional vars
  for i = 1:length(additionalVar)
    eval([additionalVar{i},' = NaN(length(dataOut.date_time),1);']);
  end

  outputFile = strrep(fileName,'.csv','');
  
  disp([' Saving output to ',outputDir,outputFile]);
  disp(' ');

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Save variable names and units
  save([outputDir,outputFile],'Version','variables','units');
  for n = 1:length(variables)  
    save([outputDir,outputFile],variables{n},'-append');
  end
end