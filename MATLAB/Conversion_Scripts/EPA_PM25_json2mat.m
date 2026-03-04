function [] = EPA_PM25_json2mat(input_file, inputDir,outputDir)
%function [] = EPA_PM25_json2mat(input_file, inputDir,outputDir)
%
% Marine Wave Boundary Layer Analysis
% Script for converting historical EPA Air Quality Data PM2.5 files .csv (originally .json format) to .mat format.
%
% Loads select daily variables from data files downloaded from NOAA NCDC:
%   https://www.ncdc.noaa.gov/cdo-web/datasets/LCD/stations/WBAN:94726/detail
% where files selected are downloaded in "LCD CSV" file format.
% To download additional data:
%   go to above link
%   click "add to cart"
%   click on orange box in upper right of screen labeled "Cart (Free Data) 1 item"
%   select "LCD CSV" (as opposed to "LCD PDF" or "LCD text")
%   select date range (to limit file sizes, select one month at time), and press "Continue" on bottom of page
%   on "Review Order page" page, near bottom, enter email address for order in both boxes and click submit
% Link to data file will be emailed to address provided on form
%
% Input: 
%   input_file 	- string variable, EPA .json file name
%   inputDir	- string vairable, absolute or relative path to .csv input_file (e.g., '../Data/EPA_PM2.5/raw/')
%   outputDir	- string vairable, absolute or relative path to write .mat file (e.g., '../Data/EPA_PM2.5/processed/')
%
% Output: .mat file containing the following variables:
%   date_time	- Matlab date and time (GMT) (adjusted from LST + 5 hrs)
%   PM25	- Hourly PM 2.5 measurements (ug/m^3)
%
% Written by Miles A. Sundermeyer, 11/13/2023
% Modified by Miles A. Sundermeyer, 1/6/2024; included O3, T_Air, Wind spd & dir - NOT YET IMPLEMENTED - THIS MODIFICATION FOR .csv FILES, NOT .json
% Modified by Miles A. Sundermeyer, 1/6/2024; added sorting by time after all data loaded

Version = 'EPA_PM2.5_json2mat, V1.0, 11/13/2023';

README = {'EPA Air Quality data, PM2.5 concentrations for Fall River station, 250051004, downloaded from EPA website:';
	'https://aqs.epa.gov/aqsweb/documents/data_api.html';
		['Converted to Matlab format ',datestr(now)];
		'using EPA_PM2.5_json2mat.m, by Miles A. Sundermeyer'};

%variables = {'date_time'; 'PM25'; 'O3'; 'T_Air'; 'Wind_Spd','Wind_Dir'};
%units = {'Matlab date and time, GMT'; 'ug/m^3 (LC)'; 'ppm'; 'Degrees C'; 'Degrees'; 'm/s'};
variables = {'date_time'; 'PM25'};
units = {'Matlab date and time, GMT'; 'ug/m^3 (LC)'};
numvars = length(variables);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Open EPA data .json file 
fileID = fopen([inputDir,input_file]);

raw = fread(fileID,inf);
str = char(raw');
fclose(fileID);

dataPheader = jsondecode(str);
data = dataPheader.Data;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% save lat,lon info
StationLatitude = data(1).latitude;
StationLongitude = data(1).longitude;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% clear variable arrays
for n = [2:numvars]
  eval([variables{n},'=[];'])
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% as painful as it is, loop through data to turn into numbers - this easiest
for n = 1:length(data)
  %disp(['n=',num2str(n)])

  date_time(n) = datetime([data(n).date_gmt,' ',data(n).time_gmt],'Format','yyyy-MM-dd HH:mm');
  this_PM25 = data(n).sample_measurement;

  % set empty values to NaN
  if ~isempty(this_PM25)
    PM25(n) = this_PM25;
  else
    PM25(n) = NaN;
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp([' EPA_PM2.5_csv2mat:'])
disp(['   ',num2str(length(date_time)),' lines read'])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% sort the data in time
[B,I] = sort(date_time);
for n = [1:numvars]
  eval([variables{n},'=',variables{n},'(I);'])
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Save this file to identically named .mat file
% get rid of any appended '.json' string at end of file name, only if it exists
ind = findstr(input_file,'.json');
if ~isempty(ind)
  output_file = input_file(1:ind-1);
else
  output_file = input_file;
end

disp(['   Saving output to ',outputDir,output_file])

% save variable names and units
save([outputDir,output_file],'variables','units','StationLatitude','StationLongitude','Version','README');

% save variables themselves (appended)
for n=1:length(variables)
  eval([variables{n},' = ',variables{n},'(:);'])
  save([outputDir,output_file],variables{n},'-append');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if(0)
  figure(1)
  clf

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  subplot(2,1,1)
  plot(date_time,PM25,'b-')
  xlabel('Date (UTC)')
  ylabel('PM2.5 (\mu g/m^3)')

  grid on
  datetick('x',2,'keeplimits')

  disp(' Press any key to continue ...')
  pause
end
