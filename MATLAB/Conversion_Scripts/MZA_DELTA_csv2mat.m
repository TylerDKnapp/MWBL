function [] = Delta_csv2mat(input_file,inputDir,outputDir)
% function [] = Delta_csv2mat(input_file,inputDir,outputDir)
%
% Marine Wave Boundary Layer Analysis
% Script for converting Delta log files from .txt to .mat format.
%
% Input: 
%   input_file 	- string variable, Delta .txt file name
%   inputDir	- string variable, absolute or relative path to .dat input_file (e.g., '../Data/Campbell Station 1/KP_Scint/raw/')
%   outputDir	- string variable, absolute or relative path to write .mat file (e.g., '../Data/Campbell Station 1/KP_Scint/processed/')
%
% Output: .mat file containing the following variables:
% Variables:
%   date_time	- Matlab datetime format (UTC)
%   Con		- %
%   WindSpd	- m/s
%   r0A		- cm
%   r0B		- cm
%   t0A		- urad
%   t0B		- urad
%   Ryt		- unitless
%   Cn2_Ryt	- m^2/3
%   Cn2_Mean	- m^2/3
%   NONUNIF	- unitless
%   
% Written by Steven Lohrenz, 01/07/2022
% School for Marine Science and Technology, University of Massachusetts Dartmouth
% email address: slohrenz@umassd.edu
% Website: http://www.umassd.edu/smast/
% Revised by Miles A. Sundermeyer, 03/12/2022
% Last revision by Steven Lohrenz, 04/04/2022
% Revised by Steven Lohrenz, 05/29/2022 - Changed variable to 'date_time' using datetime format

Version = 'Delta_csv2mat, V1.4, 05/29/2022';

disp(' Delta_csv2mat:')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% list the variables in the file (presumes we know these a priori)
variables = {'date_time';'Con';'WindSpd';'r0A';'r0B';'t0A';'t0B';'Ryt';'Cn2_Ryt';'Cn2_Mean';'NONUNIF'};
units = {'Matlab formated datetime (UTC)';'%';'m/s';'cm';'cm';'urad';'urad';'None';'m^-2/3';'m^-2/3';'None'};
numvars = length(variables);
header_charnum = 344;
bytesperrec = 87;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get info about Delta .txt file, and open file
fileInfo = dir([inputDir,input_file]);
input_bytes = fileInfo.bytes;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read data file  
% first get file date
thisind = strfind(input_file,'202');
thisdate = input_file(thisind:thisind+9);

thisind = strfind(inputDir,'MZA_DELTA');	% get ready to set directory path needed to store opts.mat file
opts = detectImportOptions([inputDir,input_file]);
opts.VariableNames = ['date';'time';variables(2:end)];
opts = setvartype(opts,'date','datetime');
opts = setvartype(opts,'time','duration');
opts = setvaropts(opts,'date','InputFormat','MM/dd/uu');
opts = setvaropts(opts,opts.VariableNames,'TreatAsMissing',{'NaN'});
opts.DataLines = 5;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
file_dat = readtable([inputDir,input_file],opts);
 
if size(file_dat,1)<4  %Skip bad files
    disp(['Input file ',input_file,' incomplete; continuing to next file']);
    return
end

%date = file_dat.date ;		% Matlab formatted date
%time = file_dat.time;
date_time = datetime([char(file_dat.date),repmat(' ',size(file_dat,1),1),char(file_dat.time)],'Format','MM/dd/yy HH:mm:ss');	%combine date and time

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Pull variables out of table structure
for n = 2:numvars
  eval([variables{n},' = file_dat.(variables{n});']);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check file size against number of characters
numlines = size(date_time,1);
bytesread = header_charnum + numlines.*bytesperrec; 	% Number of characters per line in data records
pctread = 1-((input_bytes-bytesread))./input_bytes;

disp(['   ',num2str(100*pctread),'% read: ',num2str(bytesread),' of ', num2str(input_bytes),' bytes in file']);
if (pctread > 0.99) || abs(fileInfo.bytes - bytesread)<(10*bytesperrec) 	% make sure we didn't miss blocks of data
  % 99% of data read -or- missed less than 10 lines of data
  % Do nothing - carry on!  We got 99% of the data!
elseif pctread > 0.98    	% 98% of data read - make sure we didn't miss blocks of data
  warning('**** Warning: only able to read 98% of data file')
else
  error('**** Error: could not read full Delta data file ****')
end

disp(' Read completed');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Save this file to identically named .mat file
% get rid of any appended '.txt' string at end of file name, only if it exists
ind = strfind(input_file,'.txt');
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
