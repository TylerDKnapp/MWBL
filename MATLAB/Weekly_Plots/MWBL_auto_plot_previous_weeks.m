%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NOTE: This function will recreate the weekly plots for a given range of dates
% This is not the same as the MWBL_auto_plot.m file, and has a different function
% Plots baseline sensors for Marine Wave Boundary Layer data, as 
% time series as well as profiles, including:
%   Wind Speed
%   Wind Direction
%   Barometric Pressure
%   Relative Humidity
%   Precipitation
%   Cn2
%   Air & Water Temperature
%   Tide Range
%   Solar Radiation & Net Radiometer
%
% Created by Tyler D. Knapp, 01/29/2025 - Branched off of "plot_baseline_sensors.mat"
% Edited by Tyler D. Knapp, 02/21/2025 - Removed extra functionallity, modified plots to seperate data

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Preliminary Setup
clear
close all
showPlots = 0; % true => display plots as they're created
saveFlag = 1; % true => save figures to file
process = 0;
reprocessAll = 0;
reprocessSome = 0;
processAll = 0;
spectrumPlots = 0;

timeDuration = days(14); % Plotted time
timeIteration = days(14); % Time between plots
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
totalStart = datetime('2022-10-22 00:00:00');
totalEnd = datetime('2026-01-01 00:00:00');

% Modify dates to fit sunday 0:00 - saturday 23:59
totalStart = totalStart - days(weekday(totalStart)-1);
if (weekday(totalEnd) ~= 1)
  totalEnd = totalEnd + days(8-weekday(totalEnd));
end

currentStart = totalStart;
currentEnd = currentStart + timeDuration;
weeks(1,:) = currentEnd;
itr = 2;
while currentEnd < totalEnd
  currentStart = totalStart + timeIteration*(itr-1);
  currentEnd = currentStart + timeDuration;

  weeks(itr,:) = currentEnd;
  itr = itr + 1;
end

for i = 1:length(weeks)
  endDate = weeks(i,:);
  fprintf("\nPlotting for %s - %s:\n",endDate-days(14),endDate)
  MWBL_auto_plot(endDate,showPlots,saveFlag,process,reprocessAll,reprocessSome,processAll,spectrumPlots)
end