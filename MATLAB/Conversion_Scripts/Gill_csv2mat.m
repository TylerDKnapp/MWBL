function [] = Gill_csv2mat(input_file,inputDir,outputDir)
%
% Marine Wave Boundary Layer Analysis
% Script for converting Gill sonic anemometer data files from .dat file to .mat format.
%
% Input: 
%   input_file 	- string variable, Gill .dat file name
%   inputDir	- string vairable, absolute or relative path to .dat input_file (e.g., '../Data/Lattice_SMAST_Station1/Gill/raw/')
%   outputDir	- string vairable, absolute or relative path to write .mat file (e.g., '../Data/Lattice_SMAST_Station1/Gill/processed/')
%
% Output: .mat file containing the following variables:
%   date_time	- Matlab date and time format (UTC), but with 6 decimal places in the seconds field (careful not to lose these!)
%   status_addr - [01-06] - code for sensor status check
%   status_data	- code status
%   u		- velocity (m/s)
%   v		- velocity (m/s)
%   w		- velocity (m/s)
%   T_Sonic	- temperature (deg C)
%   checksum	- checksum
%
% Written by Miles A. Sundermeyer, 11/01/2021
% Revised by Steven Lohrenz, 03/08/2022
% Revised by Miles A. Sundermeyer, 03/12/2022 - unsuccessful attempts to make work for early data files
% Revised by Steven Lohrenz, 03/14/2022 - fixed read problem with tables
% Revised by Steven Lohrenz, 05/02/2022 - revised readtable options
% Revised by Steven Lohrenz, 05/29/2022 - changed function name to remove '_tables' label
% Revised by Kayhan Ulgen, 09/29/2022 - added compass corrections
% Revised by Kayhan Ulgen, 02/17/2023 - changed signs of v and w when Gill mounted upside down - since 2/11/2022
% Revised by Kayhan Ulgen, 02/20/2023 - Added height variable and corrected wind direction.
% Revised by Steven Lohrenz, 05/11/2023 - Cleaned up function naming
% Revised by Miles A. Sundermeyer, 6/8/2023 - changed variable types to reduce overall file size of converted data
% 					changed air temperature from Kelvin to Celsius (to be consistent with rest of data)
% Revised by Kayhan Ulgen, 06/22/2023 -  Added wind speed and wind
% Revised by Tyler Knapp, 01/23/2025 - Removed '-' from delimiter options
% direction with compass correction function. When new Gills are added,
% check the compass correction here and modify it for the sensor name.
% Revised by Tyler Knapp, 07/01/2025 - Removed 'Whitespace' from opts, was causing weirdness with anything reformatted with ASCII.
% Revised by Tyler Knapp, 09/23/2025 - Changed T_Air to T_Sonic

Version = 'Gill_csv2mat, Version 01/23/2025';
disp([Version, ' is running']);

file_date=input_file(end-13:end-4);

if datenum(file_date)>datenum('09-15-2021')
  data_charnum=66;
else
  data_charnum=67;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% list the variables in the file (presumes we know these a priori)
variables = {'date_time'; 'status_addr'; 'status_data'; 'u'; 'v'; 'w'; 'T_Sonic'; 'WindSpd'; 'WindDir'};
units = {'Matlab formatted datetime (UTC)';'status addr';'status';'m/s';'m/s';'m/s';'deg C';'m/s';'degrees'};
elevation = -0.7453; % the measured height below the deck.
numvars = length(variables);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get info about Gill .dat file, and open file
fileInfo = dir([inputDir,input_file]);
input_bytes = fileInfo.bytes;

disp(['   Reading ',input_file]);

% initialize variables with blank arrays
for n = 1:numvars
  eval([variables{n},'=[];']);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set variable options
% opts = delimitedTextImportOptions('NumVariables',9,'Delimiter',{'\t', ' ', '  ', '   ', '    ', ','},'LineEnding','\r','Whitespace','\n');
opts = delimitedTextImportOptions('NumVariables',9,'Delimiter',{'\t', ' ', '  ', '   ', '    ', ','},'Whitespace','\n');
opts = setvartype(opts,{'Var1','Var2','Var3','Var4','Var5','Var6','Var7','Var8','Var9'},...
	{'char','char','int8','int8','single','single','single','single','string'});
% pre-6/8/2023, MAS	
%	{'char','char','char','char','double','double','double','double','char'});

% Read data file  
file_dat = readtable([inputDir,input_file],opts);

raw_date_time = strcat(file_dat.Var1,{' '},file_dat.Var2);

date_time = datetime(raw_date_time,'Format','yyyy-MM-dd HH:mm:ss.SSSSSS'); % High precision form of datetime

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% screen for bad time stamps
good_indx = ~isnat(date_time);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% keep only good timestamp data
date_time = date_time(good_indx);		% (Matlab datetime)
status_addr = file_dat.Var3(good_indx);	% (int, status code)
status_data = file_dat.Var4(good_indx);	% (int, status code)
u = file_dat.Var5(good_indx);			% (m/s)
v = -file_dat.Var6(good_indx);			% (m/s) NOTE: Flipping signs
w = -file_dat.Var7(good_indx);			% (m/s) NOTE: Flipping signs
T_Sonic = file_dat.Var8(good_indx)-273.15;% (deg C)
checksum = file_dat.Var9(good_indx);	% (char)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% convert checksum to [nx3] character array rather than string array (less memory intensive)
% check for missing values
missingind = find(ismissing(checksum));
checksum(missingind) = "   ";

% convert
checksum = char(checksum);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check file size against number of characters
numlines = size(date_time,1);
bytesread = numlines.*data_charnum; 			% number of characters per line in data records
pctread = 1-((input_bytes-bytesread))./input_bytes;

disp(['   ',num2str(100*pctread),'% read: ',num2str(bytesread),' of ', num2str(input_bytes),' bytes in file']);
if pctread > 0.99		% 99% of data read - make sure we didn't miss blocks of data
elseif pctread > 0.98		% 98% of data read - make sure we didn't miss blocks of data
  warning('**** Warning: only able to read 98% of data file')
else
  error('**** Error: could not read full Gill data file ****')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compass correction function
[u_corr,v_corr,WindDir_corr,WindSpd_corr] = compass_correction_function(date_time(1),date_time(end),'SMAST_Lattice_Gill',u,v,[],[]);

u = u_corr;
v = v_corr;

WindSpd = WindSpd_corr;
WindDir = WindDir_corr;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Save this file to identically named .mat file
% get rid of any appended '.dat' string at end of file name, only if it exists
ind = findstr(input_file,'.dat');
if ~isempty(ind)
  output_file = input_file(1:ind-1);
else
  output_file = input_file;
end

disp(['   Saving output to ',outputDir,output_file])

% save variable names and units
save([outputDir,output_file],'variables','elevation','units','Version');

% save variables themselves (appended)
for n = 1:numvars
  save([outputDir,output_file],variables{n},'-append');
end
