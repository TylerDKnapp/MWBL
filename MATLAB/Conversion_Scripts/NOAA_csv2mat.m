function [] = NOAA_csv2mat(input_file, inputDir,outputDir)
% Marine Wave Boundary Layer Analysis
% Script for converting historical NOAA station data files from .csv to .mat format.
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
%   inputDir	- string vairable, absolute or relative path to .csv input_file (e.g., '../Data/NOAA_WaterT/raw/')
%   outputDir	- string vairable, absolute or relative path to write .mat file (e.g., '../Data/NOAA_WaterT/processed/')
%
% Output: .mat file containing the following variables:
%   date_time	- Matlab date and time (GMT) (adjusted from LST + 5 hrs)
%   T_Water - Water Temperature (C)
%
% Written by Tyler Knapp, 03/21/2025

Version = 'NOAA_csv2mat, 03/21/2025';

variables = {'date_time'; 'T_Water'};
units = {'Matlab formatted Date'; 'deg. C'};
numvars = length(variables);

% set data line format
delimiter = ',';
formatSpec = [repmat('%q',1,2),'%*[^\r\n]'];
headerlines = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Open NOAA .csv file 
fileID = fopen([inputDir,input_file]);
alldata = textscan(fileID,formatSpec, 'Delimiter', delimiter, 'ReturnOnError', true, 'EndOfLine', '\r\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Parse date and time into Matlab datetime variable
date_array = char(alldata{1});
date_time = datetime([date_array(headerlines+1:end,1:16)],'Format','yyyy-MM-dd HH:mm');

% Note:New Bedford airport data use Local Standard Time, i.e., GMT - 5 hrs, and not adjusted for daylight savings time in the summer
date_time = date_time + duration(hours(5));			% adjust from LST to GMT (+5 hrs)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% first get everything as character arrays
T_Water_Cell = alldata{2};			% (deg C) water temperature
T_Water = str2double([T_Water_Cell(headerlines+1:end,1:end)]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp([' NOAA_csv2mat:   ',num2str(length(date_time)),' lines read'])

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
save([outputDir,output_file],'variables','units','Version','date_time','T_Water');