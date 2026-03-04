function [] = AQMesh_csv2mat(inputFile,inputDir,outputDir)
arguments
  inputFile = 'aqmeshA-2451070-20260212050004.csv'
  inputDir = '/usr2/MWBL/Data/AQMesh/raw/'
  outputDir = '/usr2/MWBL/Data/AQMesh/processed/'
end
% Marine Wave Boundary Layer Analysis
% Script for converting Ecotech/Ambilabs AQMesh pod data files from .xlsx file to .mat format.
%
% Input: 
%   inputFile	- string variable, AQMesh .xlsx file name (assume we will look for two files per data set, one "A" one "E")
%   inputDir	- string variable, absolute or relative path to .xlsx inputFile 
%   outputDir	- string variable, absolute or relative path to write .mat file 
%
% Output: .mat file containing the variables listed below (approx 40 of them)
% Note, as of version 1/4/2024, not ALL variables have been saved, just ones deemed most important
%
% Written by Miles A. Sundermeyer, 1/4/2024
% Last modified by Miles A. Sundermeyer, 8/12/2024; modified CO2 table heading read based on data file change 
%	from Jan to Feb 2024; edited units of CO2 to mg/m^3 based on real-world values and conversion factors.
% % Modified by Tyler Knapp, 10/09/2025 - Adding support for files downloaded with API

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Version = 'AQMesh_csv2mat, Version 8/29/2024';
disp([Version, ' is running']);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% specify the variables and units
variables={'date_time'; 'IntervalStart'; 'IntervalEnd'; 'COPreScaled'; 'COScaled'; 'CO2PreScaled'; 'CO2Scaled'; 'NOPreScaled'; 'NOScaled'; 'NO2PreScaled'; 'NO2Scaled'; 'NOxPreScaled'; 'NOxScaled'; 'O3PreScaled'; 'O3Scaled'; 'SO2PreScaled'; 'SO2Scaled'; 'PM1PreScaled'; 'PM1Scaled'; 'PM25PreScaled'; 'PM25Scaled'; 'PM4PreScaled'; 'PM4Scaled'; 'PM10PreScaled'; 'PM10Scaled'; 'PMTotalPreScaled'; 'PMTotalScaled'; 'TCPPreScaled'; 'TCScaled'; 'Baro'; 'Volts'; 'RelHumid'; 'T_Air'};

units = {'Matlab formatted datetime (UTC)'; 'Matlab formatted datetime (UTC)'; 'Matlab formatted datetime (UTC)'; 'ug/m^3'; 'ug/m^3'; 'mg/m^3'; 'mg/m^3'; 'ug/m^3'; 'ug/m^3'; 'ug/m^3'; 'ug/m^3'; 'ug/m^3'; 'ug/m^3'; 'ug/m^3'; 'ug/m^3'; 'ug/m^3'; 'ug/m^3'; 'ug/m^3'; 'ug/m^3'; 'ug/m^3'; 'ug/m^3'; 'ug/m^3'; 'ug/m^3'; 'ug/m^3'; 'ug/m^3'; 'count/m^3'; 'count/m^3'; 'count/m^3'; 'count/m^3'; 'mBar'; 'Volts'; '%'; 'Deg C'};

numvars = length(variables);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get info about AQMesh file, and parse some info from its file name (e.g., SN, download date, etc)
% fileInfo = dir([inputDir,inputFile]);
% input_bytes = fileInfo.bytes;
% disp([' Reading ',inputFile]);
% 
% thisdata = extract(inputFile,digitsPattern);
% thisgaugeSN = thisdata{1};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read the file as a table
filename = fullfile(inputDir,inputFile);
thisdata = readtable(filename);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read data file as table
fileData = readtable([inputDir,inputFile],'PreserveVariableNames',false);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Parse all variables from table format to array format
%for n=2:numvars
%  if n==2 | n==3
%    eval([variables{n},' = datetime(fileData.UTC_IntervalStart_, "InputFormat","dd-mmm-yyyy HH:MM:SS");']);
%  else
%    eval([variables{n},' = table2array(fileData(:,n));']);
%  end
%end
% Hard wire the variables for now ...
if inputFile(end-3:end) == "xlsx"
  eval([variables{2},' = datetime(fileData.UTC_IntervalStart_, "InputFormat","dd/MMM/yyyy HH:mm:SS");']);
  eval([variables{3},' = datetime(fileData.UTC_IntervalEnd_, "InputFormat","dd/MMM/yyyy HH:mm:SS");']);
  eval([variables{4},' = fileData.COPreScaledUgm3;']);
  eval([variables{5},' = fileData.COScaledUgm3;']);
  
  try	% for files pre Feb 1, 2024
    eval([variables{6},' = fileData.CO2PreScaledUgm3;']);
    eval([variables{7},' = fileData.CO2ScaledUgm3;']);
  catch	% for files post Feb 1, 2024; 
    % Note: CO2 has a molecular wt of 44.01 g/M, so @ 1 Atm, 25C, expect 421 ppm (typical current day CO2 level) to be 757.8 mg/m^3.
    % This latter is about the value reading in the data (734-ish in early Feb, 2024 (see column J in the raw data).
    % This value did not change from Jan to Feb 2024, but would have expected it to change by a factor of 2 or so based on
    % above - e.g., see: http://niosh.dnacih.com/nioshdbs/calc.htm
    % Will assume here that values in AQMesh data files are in fact mg/m^3, not ug/m^3 or ppm, even though the label had changed.
  
    eval([variables{6},' = fileData.CO2PreScaledPpm;']);
    eval([variables{7},' = fileData.CO2ScaledPpm;']);
  end
  
  eval([variables{8},' = fileData.NOPreScaledUgm3;']);
  eval([variables{9},' = fileData.NOScaledUgm3;']);
  eval([variables{10},' = fileData.NO2PreScaledUgm3;']);
  eval([variables{11},' = fileData.NO2ScaledUgm3;']);
  eval([variables{12},' = fileData.NOxPreScaledUgm3;']);
  eval([variables{13},' = fileData.NOxScaledUgm3;']);
  eval([variables{14},' = fileData.O3PreScaledUgm3;']);
  eval([variables{15},' = fileData.O3ScaledUgm3;']);
  eval([variables{16},' = fileData.SO2PreScaledUgm3;']);
  eval([variables{17},' = fileData.SO2ScaledUgm3;']);
  eval([variables{18},' = fileData.PM1PreScaled_g_m_;']);
  eval([variables{19},' = fileData.PM1Scaled_g_m_;']);
  eval([variables{20},' = fileData.PM2_5PreScaled_g_m_;']);
  eval([variables{21},' = fileData.PM2_5Scaled_g_m_;']);
  eval([variables{22},' = fileData.PM4PreScaled_g_m_;']);
  eval([variables{23},' = fileData.PM4Scaled_g_m_;']);
  eval([variables{24},' = fileData.PM10PreScaled_g_m_;']);
  eval([variables{25},' = fileData.PM10Scaled_g_m_;']);
  eval([variables{26},' = fileData.PMTotalPreScaled_g_m_;']);
  eval([variables{27},' = fileData.PMTotalScaled_g_m_;']);
  eval([variables{28},' = fileData.TPCPreScaledCount_m_;']);
  eval([variables{29},' = fileData.TPCScaledCount_m_;']);
  
  date_time = mean([IntervalStart IntervalEnd],2);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % read the second data file with the environmental data and append it to the Air Quality data set in Matlab file
  inputFile2 = [inputFile(1:6),'E',inputFile(8:end)];
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Read data file as table
  fileData2 = readtable([inputDir,inputFile2],'PreserveVariableNames',false);
  
  eval([variables{30},' = fileData2.PressureMbar;']);
  
  try
    % Battery Voltage seems to remove itself, adding check to set to nan
    eval([variables{31},' = fileData2.BatteryVoltage;']);
  catch
    eval([variables{31},' = NaN(size(fileData2.PressureMbar));']);
  end
  
  eval([variables{32},' = fileData2.Humidity_RH;']);
  eval([variables{33},' = fileData2.TemperatureC;']);

else % API Formatting
  eval([variables{2},' = datetime(fileData.reading_datestamp, "InputFormat","dd/MMM/yyyy HH:mm:SS");']);
  eval([variables{3},' = datetime(fileData.reading_datestamp, "InputFormat","dd/MMM/yyyy HH:mm:SS")+seconds(30);']); % Add pump runtime for interval end
  eval([variables{4},' = fileData.co_prescaled;']);
  eval([variables{5},' = fileData.co_prescaled;']);
  eval([variables{6},' = fileData.uart_slope;']);
  eval([variables{7},' = fileData.uart_slope;']);
  eval([variables{8},' = fileData.no_prescaled;']);
  eval([variables{9},' = fileData.no_prescaled;']);
  eval([variables{10},' = fileData.no2_prescaled;']);
  eval([variables{11},' = fileData.no2_prescaled;']);
  eval([variables{12},' = fileData.no_prescaled + fileData.no2_prescaled;']); % Sum for total NOx
  eval([variables{13},' = fileData.no_prescaled + fileData.no2_prescaled;']);
  eval([variables{14},' = fileData.o3_prescaled;']);
  eval([variables{15},' = fileData.o3_prescaled;']);
  eval([variables{16},' = fileData.so2_prescaled;']);
  eval([variables{17},' = fileData.so2_prescaled;']);

  
  date_time = mean([IntervalStart IntervalEnd],2);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % read the second data file with the environmental data and append it to the Air Quality data set in Matlab file
  inputFile2 = [inputFile(1:6),'P',inputFile(8:end)];
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Read data file as table
  fileData2 = readtable([inputDir,inputFile2],'PreserveVariableNames',false);
  if ~isempty(fileData2)
    eval([variables{18},' = fileData2.pm1_prescale;']);
    eval([variables{19},' = fileData2.pm1_prescale;']);
    eval([variables{20},' = fileData2.pm2_5_prescale;']);
    eval([variables{21},' = fileData2.pm2_5_prescale;']);
    eval([variables{22},' = fileData2.pm4_prescale;']);
    eval([variables{23},' = fileData2.pm4_prescale;']);
    eval([variables{24},' = fileData2.pm10_prescale;']);
    eval([variables{25},' = fileData2.pm10_prescale;']);
    eval([variables{26},' = fileData2.pm_total_prescale;']);
    eval([variables{27},' = fileData2.pm_total_prescale;']);
    try
      eval([variables{28},' = fileData2.pm_tpc_prescale;']);
      eval([variables{29},' = fileData2.pm_tpc_prescale;']);
    catch
      eval([variables{28},' = NaN(size(fileData2.pm_total_prescale));']);
      eval([variables{29},' = NaN(size(fileData2.pm_total_prescale));']);
      fprintf("No TPC found\n")
    end
    % Following vars are in first raw file as well
        % Following vars are in first raw file as well
    eval([variables{30},' = fileData2.pressure;']);
    eval([variables{31},' = fileData2.battery_voltage;']);
    eval([variables{32},' = fileData2.humidity;']);
    eval([variables{33},' = fileData2.temperature_c;']);
  else % 02/12/26-02/16/26 Physical files were blank, adding case - TK
    eval([variables{18},' = NaN(size(fileData.co_prescaled));']);
    eval([variables{19},' = NaN(size(fileData.co_prescaled));']);
    eval([variables{20},' = NaN(size(fileData.co_prescaled));']);
    eval([variables{21},' = NaN(size(fileData.co_prescaled));']);
    eval([variables{22},' = NaN(size(fileData.co_prescaled));']);
    eval([variables{23},' = NaN(size(fileData.co_prescaled));']);
    eval([variables{24},' = NaN(size(fileData.co_prescaled));']);
    eval([variables{25},' = NaN(size(fileData.co_prescaled));']);
    eval([variables{26},' = NaN(size(fileData.co_prescaled));']);
    eval([variables{27},' = NaN(size(fileData.co_prescaled));']);
    eval([variables{28},' = NaN(size(fileData.co_prescaled));']);
    eval([variables{29},' = NaN(size(fileData.co_prescaled));']);
    eval([variables{30},' = NaN(size(fileData.co_prescaled));']);
    eval([variables{31},' = NaN(size(fileData.co_prescaled));']);
    eval([variables{32},' = NaN(size(fileData.co_prescaled));']);
    eval([variables{33},' = NaN(size(fileData.co_prescaled));']);
  end
   
end
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Save this file to identically named .mat file
% get rid of any appended '.xlsx' string at end of file name, only if it exists
outputFile = strrep(inputFile,'.xlsx','');
outputFile = strrep(outputFile,'.csv','');

% get rid of "A" or "E", assuming it is in the designated place
inputFile(7) = [];

disp([' Saving output to ',outputDir,outputFile]);
disp(' ');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Save variable names and units
save([outputDir,outputFile],'Version','variables','units');

for n = 1:numvars 
  save([outputDir,outputFile],variables{n},'-append');
end
