function [] = ATI_raw2mat_Lab(inputFile,inputDir,outputDir)
%
% Marine Wave Boundary Layer Analysis
% Script for converting ATI sonic anemometer data files from .log/.dat/.txt file to .mat format.
% Only for use with benchtop files without a timestamp
%
% Input: 
%   inputFile 	- string variable, ATI .dat file name
%   inputDir	- string vairable, absolute or relative path to .dat inputFile (e.g., '../Data/Campbell Station 1/ATI/raw/')
%   outputDir	- string vairable, absolute or relative path to write .mat file (e.g., '../Data/Campbell Station 1/ATI/processed/')
%
% Output: .mat file containing the following variables:
%   date_time - Matlab formatted date and time
%   u		- velocity (m/s)
%   v		- velocity (m/s)
%   w		- velocity (m/s)
%   T_Air	- temperature (deg C)
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
% Written by Tyler Knapp, 03/13/2025

Version = 'ATI_csv2mat, Version 03/14/2025';
disp([Version, ' is running']);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% list the variables in the file (presumes we know these prior)
variables = {'u'; 'v'; 'w'; 'T_Air'; 'Cs'; 'x'; 'y'; 'z'; 'Pitch'; 'Roll'; 'Tu' ; 'Tv'; 'Tw'; 'a';'WindSpd';'WindDir'};
units = {'m/s';'m/s';'m/s';'deg C'; 'm/s';'g';'g';'g';'degrees';'degrees';'deg C' ; 'deg C'; 'deg C'; '[]'; 'm/s';'degrees'};

numvars = length(variables);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get info about ATI .dat file, and open file
fileInfo = dir([inputDir,inputFile]);
input_bytes = fileInfo.bytes;

disp(['   Reading ',inputFile]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Attempt to read the entire data file

% Check character length of data record
fid=fopen([inputDir,inputFile]);
  chr=textscan(fid,'%s',1,'delimiter','\r\n');
  data_charnum=length(chr{1}{1})+3;
fclose(fid);

% Set variable options
opts = delimitedTextImportOptions('Delimiter',{'\t'});
%opts = setvartype(opts,{'Var1','Var2','Var3','Var4','Var5'},{'char','char','double','double','double','double'});
file_dat = readtable([inputDir,inputFile],opts);

% initialize variables with blank arrays
for n = 1:numvars
  eval([variables{n},' = [];']);
end

raw_data = table2array(file_dat(:,1));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find most frequent line number length - assume that is the correct
%      line length and any line that is different has bad characters

numtxt = height(raw_data);
linelnth=zeros(numtxt,1);
for ij=1:numtxt
  linelnth(ij)=width(raw_data{ij});
end

goodlength=mode(linelnth);
goodindex=(linelnth==goodlength);

raw_data=raw_data(goodindex);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% extract data from string array
raw_data_chr = char(raw_data);
chr_length = size(raw_data_chr,2);

nfile = size(raw_data_chr,1);
% Preallocate arrays
u = repmat('',size(nfile,1),1);
v = nan(nfile,1);
w = nan(nfile,1);
T_Air = nan(nfile,1);
Cs = nan(nfile,1);
x = nan(nfile,1);
y = nan(nfile,1);
z = nan(nfile,1);
Pitch = nan(nfile,1);
Roll = nan(nfile,1);
Tu = nan(nfile,1);
Tv = nan(nfile,1);
Tw = nan(nfile,1);
a = nan(nfile,1);

U_indx = strfind(raw_data_chr(1,:),'U');
V_indx = strfind(raw_data_chr(1,:),'V');
W_indx = strfind(raw_data_chr(1,:),'W');
T_Air_indx = strfind(raw_data_chr(1,:),'T');
T_Air_indx = T_Air_indx(1);  % To exclude multiple instances of 'T'
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
w = str2num(raw_data_chr(:,W_indx+1:T_Air_indx-1));
T_Air = str2num(raw_data_chr(:,T_Air_indx+1:T_Air_indx+6));
disp('   Read completed');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check file size against number of charactersoutputFile
numlines = size(u,1);
bytesread = numlines.*data_charnum;	% Number of characters per line in data records
pctread = bytesread./input_bytes;

if pctread > 0.99		% 99% of data read - make sure we didn't miss blocks of data
  disp(['   ',num2str(100*pctread),'% read: ',num2str(bytesread),' of ', num2str(input_bytes),' bytes in file']);
elseif pctread > 0.98		% 98% of data read - make sure we didn't miss blocks of data
  warning('**** Warning: only able to read 98% of data file')
else
  warning(['**** Warning: could not read full ATI data file ****',num2str(100*pctread),'% read'])
end

WindSpd = sqrt(u.^2 + v.^2);
WindDir = NaN;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Save this file to identically named .mat file
% get rid of any appended '.dat' string at end of file name, only if it exists
outputFile = strrep(inputFile,'.dat','');
outputFile = strrep(outputFile,'.txt','');
outputFile = strrep(outputFile,'.log','');

disp(['   Saving output to ',outputDir,outputFile])

% save variable names and units
save([outputDir,outputFile],'variables','units','Version');

% save variables themselves (appended)
for n = 1:numvars
  save([outputDir,outputFile],variables{n},'-append');
end

disp('Completed');
