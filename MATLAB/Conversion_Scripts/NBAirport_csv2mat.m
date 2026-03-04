function [] = NBAirport_csv2mat(input_file, inputDir,outputDir)
% function [] = NBAirport_csv2mat(input_file, inputDir,outputDir)
%
% Marine Wave Boundary Layer Analysis
% Script for converting historical New Bedford Regional Aiport data files from .csv to .mat format.
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
%   input_file 	- string variable, NBAirport csv file name
%   inputDir	- string vairable, absolute or relative path to .csv input_file (e.g., '../Data/New Bedford Airport/raw/')
%   outputDir	- string vairable, absolute or relative path to write .mat file (e.g., '../Data/New Bedford Airport/processed/')
%
% Output: .mat file containing the following variables:
%   date_time	- Matlab date and time (GMT) (adjusted from LST + 5 hrs)
%   Baro_inHg	- Barometric pressure (inches mercury sea level pressure)
%   Baro	- Barometric pressure (mBar sea level pressure)
%   T_Air	- Dry bulb temperature (deg F)
%   RelHumid	- %
%   WindSpd	- Wind speed (m/s) (converted from mph)
%   WindDir	- Wind direction (deg from N)
%   Precip	- Hourly precipitation (mm/hr; original data in inches/hr)
%
% Written by Miles A. Sundermeyer, 9/23/2021
% Modified by Miles A. Sundermeyer, 12/10/2021 to make all output variables column variables
% Modified by Miles A. Sundermeyer, 12/13/2021 time adjusted to GMT (LST + 5 hrs)
% Modified by Miles A. Sundermeyer, 10/07/2022 to make time be in Matlab datetime format
% Modified by Miles A. Sundermeyer, 6/9/2023 - changed 'Rain' to 'Precip', units to mm/hr
% Modified by Tyler D. Knapp, 08/21/2025 - Changed indexes and unit conversions to support new file format from: https://www.ncei.noaa.gov/access/search/data-search/local-climatological-data-v2

Version = 'NBAirport_csv2mat, V1.4, 08/21/2025';

README = {'Meteorological data for New Bedford Airport, downloaded from NCDC website:';
	'https://www.ncdc.noaa.gov/cdo-web/datasets/LCD/stations/WBAN:94726/detail';
		['Converted to Matlab format ',datestr(now)];
		'using NBAirport_csv2mat.m, by Miles A. Sundermeyer'};

variables = {'date_time'; 'Baro'; 'T_Air'; 'RelHumid'; 'WindSpd'; 'WindDir'; 'Precip'};
units = {'Matlab formatted Date'; 'Matlab formatted Time, GMT'; 'inches Hg'; 'mBar'; 'dry bulb, deg F'; '%'; 'm/s'; 'deg from true N';'mm/hr'};
numvars = length(variables);

% set data line format
delimiter = ',';
formatSpec = [repmat('%q',1,124),'%*[^\r\n]'];
headerlines = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Open Airport data .csv file 
fileID = fopen([inputDir,input_file]);

% Load Airport data downloaded from: https://www.ncdc.noaa.gov/cdo-web/datasets/LCD/stations/WBAN:94726/detail
alldata = textscan(fileID,formatSpec, 'Delimiter', delimiter, 'ReturnOnError', true, 'EndOfLine', '\r\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Parse date and time into Matlab datetime variable
date_array = char(alldata{2});
date_time = datetime([date_array(headerlines+1:end,1:19)],'Format','yyyy-MM-dd''T''HH:mm:SS');

% Note:New Bedford airport data use Local Standard Time, i.e., GMT - 5 hrs, and not adjusted for daylight savings time in the summer
date_time = date_time + duration(hours(5));			% adjust from EST to GMT (+5 hrs)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get various other met records
% Note: for scanning data for additional variables use:  for n=1:124;  disp([num2str(n), alldata{n}(1)]); pause; end

% first get everything as character arrays
% Baro_inHg_c = char(alldata{53}(headerlines+1:end));		% (inches mercury) sea level pressure
% T_Air_c = char(alldata{45}(headerlines+1:end));		% (deg F) dry bulb temperature
% RelHumid_c = char(alldata{50}(headerlines+1:end));		% (%) relative humidity
% 
% WindSpd_c = char(alldata{58}(headerlines+1:end));		% (mph) wind speed
% WindDir_c = char(alldata{56}(headerlines+1:end));		% (deg from N) wind direction
% Precip_c = char(alldata{46}(headerlines+1:end));		% (inches) hourly precipitation

Baro_mBar_c = char(alldata{18}(headerlines+1:end));		% (mBar) sea level pressure
T_Air_c = char(alldata{11}(headerlines+1:end));			% (deg C) dry bulb temperature
RelHumid_c = char(alldata{16}(headerlines+1:end));		% (%) relative humidity
WindSpd_c = char(alldata{24}(headerlines+1:end));		% (m/s) wind speed
WindDir_c = char(alldata{22}(headerlines+1:end));		% (deg from N) wind direction
Precip_c = char(alldata{12}(headerlines+1:end));		% (mm) hourly precipitation

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% clear arrays
for n=[3 5:numvars]
  eval([variables{n},'=[];'])
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% as painful as it is, loop through the data to turn everything into numbers - this easiest, due to spurious characters in some variables
for n=1:length(date_time)
  %disp(['n=',num2str(n)])

  % this_Baro_inHg = str2num(Baro_inHg_c(n,:));
  % this_T_Air = (str2num(T_Air_c(n,:))-32)*5/9;		% convert from deg F to deg C
  % this_RelHumid = str2num(RelHumid_c(n,:));
  % this_WindSpd = str2num(WindSpd_c(n,:))*0.44704;		% convert from mph to m/s
  % this_WindDir = str2num(WindDir_c(n,:));
  % this_Precip = str2num(Precip_c(n,:))*25.4;			% convert from inches/hr to mm/hr

  this_Baro_mBar = str2num(Baro_mBar_c(n,:)); % mBar
  this_T_Air = str2num(T_Air_c(n,:));				% deg C
  this_RelHumid = str2num(RelHumid_c(n,:));
  this_WindSpd = str2num(WindSpd_c(n,:));			% m/s
  this_WindDir = str2num(WindDir_c(n,:));
  this_Precip = str2num(Precip_c(n,:));				% mm/hr

  % set empty values to NaN
  % if ~isempty(this_Baro_inHg)
  %   Baro_inHg(n) = this_Baro_inHg;
  % else
  %   Baro_inHg(n) = NaN;
  % end
  if ~isempty(this_Baro_mBar)
    Baro_mBar(n) = this_Baro_mBar;
  else
    Baro_mBar(n) = NaN;
  end
  
  if ~isempty(this_T_Air)
    T_Air(n) = this_T_Air;
  else
    T_Air(n) = NaN;
  end
  
  if ~isempty(this_RelHumid)
    RelHumid(n) = this_RelHumid;
  else
    RelHumid(n) = NaN;
  end
  
  if ~isempty(this_WindSpd)
    WindSpd(n) = this_WindSpd;
  else
    WindSpd(n) = NaN;
  end
  
  if ~isempty(this_WindDir)
    WindDir(n) = this_WindDir;
  else
    WindDir(n) = NaN;
  end
  
  if ~isempty(this_Precip)
    Precip(n) = this_Precip;
  else
    Precip(n) = NaN;
  end
end

% Baro = Baro_inHg * 33.8638873;				% (mbar)
Baro = Baro_mBar;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp([' NBAirport_csv2mat:'])
disp(['   ',num2str(length(date_time)),' lines read'])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Save this file to identically named .mat file
% get rid of any appended '.txt' string at end of file name, only if it exists
ind = findstr(input_file,'.csv');
if ~isempty(ind)
  output_file = input_file(1:ind-1);
else
  output_file = input_file;
end

disp(['   Saving output to ',outputDir,output_file])

% save variable names and units
save([outputDir,output_file],'variables','units','Version','README');

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
  subplot(4,1,1)
  plot(date_time,Baro)
  xlabel('Date (UTC)')
  ylabel('Atmos Press (mBar)')
  title('New Bedford SeaLevel Press')

  grid on
  datetick('x',2,'keeplimits')

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  subplot(4,1,2)
  plot(date_time,T_Air)
  xlabel('Date (UTC)')
  ylabel('T (^oC)')
  title('Air Temperature')

  grid on
  datetick('x',2,'keeplimits')

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  subplot(4,1,3)
  plot(date_time,WindSpd)
  xlabel('Date (UTC)')
  ylabel('Wind Spd (m/s)')
  title('Wind Speed')

  grid on
  datetick('x',2,'keeplimits')

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  subplot(4,1,4)
  plot(date_time,Precip)
  xlabel('Date (UTC)')
  ylabel('Precip (mm/hr)')
  title('Hourly Precipitation')

  grid on
  datetick('x',2,'keeplimits')

  disp(' Press any key to continue ...')
  pause
end
