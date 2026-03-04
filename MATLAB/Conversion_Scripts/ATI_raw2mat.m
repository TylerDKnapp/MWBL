function ATI_raw2mat(input_file,inputDir,outputDir)
%
% Marine Wave Boundary Layer Analysis
% Script for converting ATI sonic anemometer data files from .dat file to .mat format.
%
% Input: 
%   input_file 	- string variable, ATI .dat file name
%   inputDir	- string vairable, absolute or relative path to .dat input_file (e.g., '../Data/Campbell Station 1/ATI/raw/')
%   outputDir	- string vairable, absolute or relative path to write .mat file (e.g., '../Data/Campbell Station 1/ATI/processed/')
%
% Output: .mat file containing the following variables:
%   date_time - Matlab formatted date and time
%   u		- velocity (m/s)
%   v		- velocity (m/s)
%   w		- velocity (m/s)
%   T_Sonic	- temperature (deg C)
%   Cs		- speed of sound (m/s)
%   x		- accelerometer (g)
%   y		- accelerometer (g)
%   z       - accelerometer (g)
%   Pitch   - level (deg)
%   Roll    - level (deg)
%   Tu      - raw temperature x (deg C)
%   Tv      - raw temperature y (deg C)
%   Tw      - raw temperature z (deg C)
%   a       - ADC output (unknown)
%
% Written by Miles A. Sundermeyer, 11/01/2021
% Revised by Steven Lohrenz, 03/08/2022
% Revised by Miles A. Sundermeyer, 03/12/2022; Does not work on older files that have different write formats.
% Revised by Steven Lohrenz, 05/17/2022; Changed readtable input format
% Revised by Steven Lohrenz, 05/29/2022 - changed function name to remove '_tables'
% Revised by Steven Lohrenz, 12/24/2022 - Added check for bad data lines (lines have too few characters)
% Revised by Steven Lohrenz, 01/24/2023 - Modified check for incorrect data line length using mode; 
%                                          also added compass correction developed by Kayhan Ulgen 
% Revised by Steven Lohrenz, 01/26/2023 - Modified check for linelength statement and changed error for
%                                          partial file read to warning and added statement to display percent read
% Revised by Kayhan Ulgen, 02/20/2023 - Added height variable and corrected the wind speed direction.
% Revised by Kayhan Ulgen, 04/20/2023 - Added Tu,Tv,Tw and ADC variables as output
% Revised by Steven Lohrenz, 05/11/2023 - Cleaned up function name
% Revised by Kayhan Ulgen, 06/05/2023 - Added compass correction function.
% Revised by Miles A. Sundermeyer, 6/11/2023 - streamlined compass correction call, added time when ATI A-style 
%		was switched to ATI V-style on 6/8/2023
% Revised by Kayhan Ulgen, 06/21/2023  -  Cs output was enabled after 12/15/2023, This isssue is fixed.
% Revised by Kayhan Ulgen, 06/22/2023  -  Compass correction function is
% fixed, checked and it's working.
% Revised by Kayhan Ulgen, 06/28/2023 - date_time was not reading the
%    variables properly for additional variables added after 12/15/2022, fixed
%    checked and it's working
%      input_file='Station1 Anemometer_SNXX_2022-12-16.dat';
%      inputDir = '/Users/kayhanulgen/Library/CloudStorage/OneDrive-UniversityofMassachusettsDartmouth/Analysis/';
%      outputDir='/Users/kayhanulgen/Library/CloudStorage/OneDrive-UniversityofMassachusettsDartmouth/Analysis/';
% Revised by Steven Lohrenz, 7/21/2023 - Modified compass correction to account for different sensor names
% Revised by Tyler Knapp, 03/13/2025 - Adjusted roll index from 8 to 7 digits
% Revised by Tyler Knapp, 07/07/2025 - Added catch for faulty sensor (abs(U) > 50), added strip to remove trailing spaces, and removed unnecessary array pre-allocation
% Revised by Tyler Knapp, 09/18/2025 - Fixed datetime check for SMAST sensor type
% Revised by Tyler Knapp, 09/23/2025 - Changed T_Air to T_Sonic

Version = 'ATI_csv2mat, Version 07/07/2025';
disp([Version, ' is running']);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% list the variables in the file (presumes we know these a prior)
variables = {'date_time'; 'u'; 'v'; 'w'; 'T_Sonic'; 'Cs'; 'x'; 'y'; 'z'; 'Pitch'; 'Roll'; 'Tu' ; 'Tv'; 'Tw'; 'a'; 'WindSpd';'WindDir'};
units = {'Matlab formatted datetime (UTC)';'m/s';'m/s';'m/s';'deg C';'m/s';'g';'g';'g';'degrees';'degrees';'deg C';'deg C'; 'deg C'; '[]'; 'm/s';'degrees'};

numvars = length(variables);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if contains(inputDir,'SMAST_Station1') || contains(input_file,'Station1')
  elevation = 2.86;    % elevation above the deck;
elseif contains(inputDir,'CBC_Station2') || contains(input_file,'Station2')
  elevation = 2.86;    % elevation above the deck; This is not known.
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get info about ATI .dat file, and open file
disp(['   Reading ', [inputDir,input_file]]);
fileInfo = dir([inputDir,input_file]);
input_bytes = fileInfo.bytes;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Attempt to read the entire data file

% Check character length of data record
fid=fopen([inputDir,input_file]);
  chr=textscan(fid,'%s',1,'delimiter','\r\n');
  data_charnum=length(chr{1}{1})+3;
fclose(fid);

% Set variable options
opts = delimitedTextImportOptions('Delimiter',{'\t'});
%opts = setvartype(opts,{'Var1','Var2','Var3','Var4','Var5'},{'char','char','double','double','double','double'});
file_dat = readtable([inputDir,input_file],opts);

% initialize variables with blank arrays
for n = 1:numvars
  eval([variables{n},' = [];']);
end

try
  raw_data = table2array(file_dat(:,2));
catch
  raw_data = table2array(file_dat);
end
raw_data = strip(raw_data); % Remove trailing spaces

try
  date_time = datetime(file_dat.Var1,'Format','yyyy-MM-dd HH:mm:ss.SSSSSS');		% Matlab formatted datetime
catch
  date_time = datetime('00:00:00.000',InputFormat='HH:mm:ss.SSS') + seconds(1:length(raw_data))/20;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find most frequent line number length - assume that is the correct
%      line length and any line that is different has bad characters

numtxt = height(raw_data);
linelnth = zeros(numtxt,1);
for ij=1:numtxt
  linelnth(ij) = width(raw_data{ij});
end

goodlength = mode(linelnth);
goodIndex = linelnth == goodlength;

date_time = date_time(goodIndex);
raw_data = raw_data(goodIndex);

raw_data_chr = char(raw_data);
U_indx = strfind(raw_data_chr(1,:),'U');
V_indx = strfind(raw_data_chr(1,:),'V');
u = str2num(raw_data_chr(:,U_indx+1:V_indx-1));

% When sensor goes bad it randomly reads -99.99, however it may read lower or higher in rare cases. Filter these indexes out.
goodIndex_2 = find(abs(u)<50); % 50 m/s ~ 100knts

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% extract data from string array
date_time = date_time(goodIndex_2);
raw_data = raw_data(goodIndex_2);

raw_data_chr = char(raw_data);

W_indx = strfind(raw_data_chr(1,:),'W');
T_Sonic_indx = strfind(raw_data_chr(1,:),'T');
T_Sonic_indx = T_Sonic_indx(1);  % To exclude multiple instances of 'T'
Cs_indx = strfind(raw_data_chr(1,:),'C');
x_indx = strfind(raw_data_chr(1,:),'X');
y_indx = strfind(raw_data_chr(1,:),'Y');
z_indx = strfind(raw_data_chr(1,:),'Z');
Pitch_indx = strfind(raw_data_chr(1,:),'P');
Roll_indx = strfind(raw_data_chr(1,:),'R');
Tu_indx = strfind(raw_data_chr(1,:),'Tu');
Tv_indx = strfind(raw_data_chr(1,:),'Tv');
Tw_indx = strfind(raw_data_chr(1,:),'Tw');
a_indx = strfind(raw_data_chr(1,:),'a');

u = str2num(raw_data_chr(:,U_indx+1:V_indx-1));
v = str2num(raw_data_chr(:,V_indx+1:W_indx-1));
w = str2num(raw_data_chr(:,W_indx+1:T_Sonic_indx-1));
T_Sonic = str2num(raw_data_chr(:,T_Sonic_indx+1:T_Sonic_indx+6));

if date_time(1) > datetime('2022-12-15 00:00:00.00000','InputFormat','yyyy-MM-dd HH:mm:ss.SSSSSS')
    Cs = str2num(raw_data_chr(:,Cs_indx+1:x_indx-1));
    x = str2num(raw_data_chr(:,x_indx+1:y_indx-1));
    y = str2num(raw_data_chr(:,y_indx+1:z_indx-1));
    z = str2num(raw_data_chr(:,z_indx+1:Pitch_indx-1));
    Pitch = str2num(raw_data_chr(:,Pitch_indx+1:Roll_indx-1));
    Roll = str2num(raw_data_chr(:,Roll_indx+1:Roll_indx+7));
end

if date_time(1) > datetime('2023-04-19 17:03:00.00000','InputFormat','yyyy-MM-dd HH:mm:ss.SSSSSS')
    Tu = str2num(raw_data_chr(:,Tu_indx+2:Tv_indx-1));
    Tv = str2num(raw_data_chr(:,Tv_indx+2:Tw_indx-1));
    if ~isempty(a_indx)
        Tw = str2num(raw_data_chr(:,Tw_indx+2:a_indx-1));
        a = str2num(raw_data_chr(:,a_indx+1:end));
    else
        Tw = str2num(raw_data_chr(:,Tw_indx+2:end));
        a = nan(size(Tu,1),1);
    end
end

disp('   Read completed');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check file size against number of characters
numlines = size(date_time,1);
bytesread = numlines.*data_charnum;	% Number of characters per line in data records
pctread = bytesread./input_bytes;

if pctread > 0.99		% 99% of data read - make sure we didn't miss blocks of data
  disp(['   ',num2str(100*pctread),'% read: ',num2str(bytesread),' of ', num2str(input_bytes),' bytes in file']);
elseif pctread > 0.98		% 98% of data read - make sure we didn't miss blocks of data
  warning('**** Warning: only able to read 98% of data file')
else
  warning(['**** Warning: could not read full ATI data file ****',num2str(100*pctread),'% read'])
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Dates of any angle adjustments
beginTime = datetime('2000-01-01 00:00:00.000000', 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSSSSS');
sensorFlipTime = datetime('2022-02-11 00:00:00.000000','InputFormat','yyyy-MM-dd HH:mm:ss.SSSSSS'); % date of flipping sensor right side up
if date_time(1) > beginTime && date_time(end) <= sensorFlipTime
  for n = 1:numlines
    if isbetween(date_time(n),beginTime,sensorFlipTime)
      v(n) = -v(n);
      w(n) = -w(n);
    else
      % Do nothing
    end
  end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compass Correction
if date_time(end) < datetime('2023-06-08 13:00:00','InputFormat','yyyy-MM-dd HH:mm:ss') && contains(input_file,'Station1')
    sensor = 'SMAST_Lattice_A';
elseif date_time(end) >= datetime('2023-06-08 13:00:00','InputFormat','yyyy-MM-dd HH:mm:ss')...
    && date_time(end) < datetime('2023-11-07 20:00:00','InputFormat','yyyy-MM-dd HH:mm:ss')  && contains(input_file,'Station1')
    sensor = 'SMAST_Lattice_V';
elseif date_time(end) >= datetime('2023-11-07 20:00:00','InputFormat','yyyy-MM-dd HH:mm:ss') && contains(input_file,'Station1')
    sensor = 'SMAST_Lattice_A';
elseif contains(input_file,'Station2')
    sensor = 'CBC_Lattice_A';
else
  error('ERROR: In ATI_raw2mat.m: No Sensor Type set')
end  

% Compass correction function
[u_corr,v_corr,WindDir_corr,WindSpd_corr] = compass_correction_function(date_time(1),date_time(end),sensor,u,v,[],[]);

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

disp('Completed');
