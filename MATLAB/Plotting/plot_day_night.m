function [] = plot_day_night()
% function [] = plot_day_night()
% For plotting shading between sunset and sunrise on current axes of a plot.
%
%   Inputs 	- None
%   Outputs 	- None
%
% Assumes latitude of SMAST, 706 S. Rodney French Blvd, New Bedford, MA.
% 
% Written by Miles A. Sundermeyer, 2/18/2024

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get limits of x-axis, assuming it is in Matlab date_time format
xlims = xlim;
ylims = ylim;

sdate = xlims(1);
edate = xlims(2);

% Get sunrise and sunset times for the days plotted, in UTC
srisedates = [sdate : days(1) : edate];

for n=1:length(srisedates)
  TZ = 0;
  ALT = 0;
  [SRISE(n),SSET(n),NOON(n)] = sunrise(41.5944,-70.9110,ALT,TZ,srisedates(n));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cycle through days and plot patches for nighttime
for nn=1:length(SRISE)
  clear h1
  % add white shading to show day
  h1 = fill([datetime(datestr(SRISE(nn)*[1 1]))' datetime(datestr(SSET(nn)*[1 1]))'], ...
				ylims([1 2 2 1]),[1 1 1]);
  set(h1,'EdgeColor','none');
  uistack(h1,'bottom');             % put day-night shading on bottom of other graphics
end

% set background color to gray to indicate night
if(0)                               % This doesn't work on home machine - prints black background
  set(gca,'color',0.95*[1 1 1])
else                                % make big gray fill patch covering entire axis
  clear h2
  % set background of axis to be gray, only white will be the daytime periods created above
  h2 = fill(xlims([1 1 2 2]),ylims([1 2 2 1]),0.95*[1 1 1]);
  set(h2,'EdgeColor','none');
  uistack(h2,'bottom');             % put day-night shading on bottom of other graphics
end
set(gca,'Layer','Top')              % put axis ticks and edges on top of fill color

xlim(xlims)
