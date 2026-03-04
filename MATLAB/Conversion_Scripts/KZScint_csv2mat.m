function [] = KZScint_csv2mat(input_file,inputDir,outputDir)
% function [] = KZScint_csv2mat(input_file,inputDir,outputDir)
%
% Marine Wave Boundary Layer Analysis
% Script for converting Kipp and Zonen Scintilometer data files from .txt file to .mat format.
%
% Input: 
%   input_file 	- string variable, KP_Scint .txt file name
%   inputDir	- string vairable, absolute or relative path to .dat input_file (e.g., '../Data/Campbell Station 1/KP_Scint/raw/')
%   outputDir	- string vairable, absolute or relative path to write .mat file (e.g., '../Data/Campbell Station 1/KP_Scint/processed/')
%
% Output: .mat file containing the following variables:
%   'date_time'		- Matlab date and time format (UTC)
%   'RecordNo'		- Record number
%   'StatusFlags'	-
%   'Udemod'		- Average demodulated carrier wave signal (milliVolts)
%   'UdemodSig'		- sqrt(Variance) of demodulated voltage (Var(Udemod))^0.5 (milliVolts)
%   'Cn2'		- Averaged Cn^2 (m^-2/3)
%   'Cn2Sig'		- sqrt(Variance(Cn^2)) (m^-2/3)
%   'Cn2Min'		- Minimum Cn^2 (m^-2/3)
%   'Cn2Max'		- Maximum Cn^2  (m^-2/3)
%   'Srt'		- 
%   'Hfree'		-
%   'DeviceTemp'	- Device temperature (deg C)
%   'AirTemp'		- Air temperature (dec C) - Note: this is for external sensor inputs, not read by sensor
%   'AirPressure'	- Air pressure (mBar) - Note: this is for external sensor input, not read by sensor
%   'WindSpeed'		- Wind speed (m/s) - Note: this is for external sensor input, not read by sensor
%
% Written by Steven Lohrenz, 01/06/2022
% School for Marine Science and Technology, University of Massachusetts Dartmouth
% email address: slohrenz@umassd.edu
% Website: http://www.umassd.edu/smast/
% Last revision by Steven Lohrenz, 03/07/2022
% Revised by Miles A. Sundermeyer, 03/12/2022
% Revised by Steven Lohrenz, 05/29/2022 - Changed date_time variable name and changed format to datetime
% Revised by Tyler Knapp, 11/03/2025 - Adding support for files logged directly through serial (via python)

Version = 'KZScint_csv2mat, V1.2, 05/29/2022';

disp(' KZScint_csv2mat:')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% list the variables in the file (presumes we know these a priori)
variables = {'date_time';'RecordNo';'StatusFlags';'Udemod';'UdemodSig';'Cn2';'Cn2Sig';'Cn2Min';'Cn2Max';'Srt';'Hfree';'DeviceTemp';'AirTemp';'AirPressure';'WindSpeed'};
units = {'-';'-';'Matlab formatted datetime (UTC)';'mV';'mV';'m^-2/3';'m^-2/3';'m^-2/3';'m^-2/3';'K^2/m^2/3';'W/m2';'u8734 C';'deg C';'mBar';'m/s'};
numvars = length(variables);
header_charnum = 243;
data_charnum = 162;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get info about Scintillometer .txt file, and open file
fileInfo = dir([inputDir,input_file]);
input_bytes = fileInfo.bytes;

disp(['   Reading ',input_file]);

% initialize variables with blank arrays
for n = 1:numvars
  eval([variables{n},' = [];']);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read data file  
try % Logging with Python
  opts = detectImportOptions([inputDir,input_file]);
  opts.VariableNames = ['the_number_10?';'RecordNo';'StatusFlags';'date';'time';variables(4:end)];
  file_dat = readtable([inputDir,input_file],opts);
  date_time = datetime([char(file_dat.date),repmat(' ',size(file_dat,1),1),char(file_dat.time)],'Format','yy/MM/dd HH:mm:ss');	% combine date and time, need to add '20' to date
catch % Logging with EVASION (Old Conversion Method)
  variables = {'date_time';'RecordNo';'StatusFlags';'Udemod';'UdemodSig';'Cn2';'Cn2Sig';'Cn2Min';'Cn2Max';'Srt';'Hfree';'DeviceTemp';'AirTemp';'AirPressure';'WindSpeed'};
  units = {'Matlab formatted datetime (UTC)';'-';'-';'mV';'mV';'m^-2/3';'m^-2/3';'m^-2/3';'m^-2/3';'K^2/m^2/3';'W/m2';'u8734 C';'deg C';'mBar';'m/s'};
  opts = detectImportOptions([inputDir,input_file]);
  opts.VariableNames = ['date';'time';variables(2:end)];
  file_dat = readtable([inputDir,input_file],opts);
  date_time = datetime([char(file_dat.date),repmat(' ',size(file_dat,1),1),char(file_dat.time)],'Format','yyyy/MM/dd HH:mm:ss');	% combine date and time
end

% Convert to UTC where necessary (only confirmed for SMAST data files at this point)
if (date_time(1)>datetime(2021,11,23) && date_time(end)<datetime(2021,12,01))
  disp('   Converting data to UTC')
  date_time = date_time + days(5/24);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check file size against number of characters
numlines = size(date_time,1);
bytesread = header_charnum+numlines.*data_charnum;	% Number of characters per line in data records
pctread = 1-((input_bytes-bytesread))./input_bytes;

if pctread > 0.99		% 99% of data read - make sure we didn't miss blocks of data
  disp(['   ',num2str(100*pctread),'% read: ',num2str(bytesread),' of ', num2str(input_bytes),' bytes in file']);
elseif pctread > 0.98		% 98% of data read - make sure we didn't miss blocks of data
  warning('**** Warning: only able to read 98% of data file')
else
  error('**** Error: could not read full KZ Scint data file ****')
end

disp('Read completed');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Pull variables out of table structure
for n = 2:numvars
  eval([variables{n},' = file_dat.',variables{n},';']);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Save this file to identically named .mat file
% get rid of any appended '.dat' string at end of file name, only if it exists
ind = findstr(input_file,'.log');
if ~isempty(ind)
  output_file = input_file(1:ind-1);
else
  output_file = input_file;
end

disp(['   Saving output to ',outputDir,output_file])

% save variable names and units
save([outputDir,output_file],'variables','units','Version');

% save variables themselves (appended)
for n = 1:numvars
  save([outputDir,output_file],variables{n},'-append');
end

