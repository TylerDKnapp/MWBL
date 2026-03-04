% function [u_corr,v_corr,WindDir_corr,WindSpd_corr] = compass_correction_function(start_date,end_date,sensor,u,v,WindDir,WindSpd)
% compass_correction_function.m - Matlab function for sensor compass corrections
%
% Inputs:
%   start_date,end_date 	- start and end times of data
%   sensor			- string indicating instrument type - see list of choices below
%   u,v  -or-  WindDir,WindSpd 	- either u,v or WindDir, WindSpd from sonic anemometers PortLog
%
% Sensor must be one of the following:
%   'SMAST_Lattice_A'
%   'SMAST_Lattice_V'
%   'SMAST_Lattice_Gill'
%   'SMAST_Tower_A'
%   'SMAST_Tower_V'
%   'CBC_Lattice_A'
%   'CBC_Lattice_V'
%   'CBC_Tower_A'
%   'CBC_Tower_V'
%   'SMAST_PortLog'
%   'CBC_PortLog'
%
% Outputs:  Compass-corrected u, v, WindDir, WindSpd
%
% Other m-files required: This function is called by csv2mat scripts for
% the individual sensors
%
% MAT-files required: Sensor data files converted to *.mat format
%
% Author: Steven E. Lohrenz
% School for Marine Science and Technology, University of Massachusetts Dartmouth
% email address: slohrenz@umassd.edu
% Website: http://www.umassd.edu/smast/
% Created by Steven Lohrenz: 5/27/2023
% Revised by Steven Lohrenz, 6/2/2023 - Modified compass settings
% Modified by Miles A. Sundermeyer, 6/10/2023 - added additional sensor types, separated structure orientations from sensor
%	coordinate rotations, corrected SMAST Portlog and CBC DPL angle corrections, streamlined rotation calculation
% Revised by Tyler Knapp, 06/12/2025 - Fixed SMAST PortLog angle (90 => -90)
% Revised by Tyler Knapp, 09/08/2025 - Updated pier angle from RTK measurements and streamlined angle calculations (V1.1)

%% ------------- BEGIN CODE --------------%%

function [u_corr,v_corr,WindDir_corr,WindSpd_corr] = compass_correction_function(start_date,end_date,sensor,u,v,WindDir,WindSpd)
arguments
  start_date = []
  end_date = []
  sensor = 'SMAST_Tower_A'
  % sensor = 'SMAST_Lattice_Gill'
  u = 1:0.01:10 %[0,1,1]
  v = 1:0.01:10 %[1,0,1]
  WindDir = []
  WindSpd = []
end
  
  Version = 'compass_correction_function, V1.1, 09/25/2025';
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % COMPASS CORRECTION FUNCTION
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Compass Corrections
  % Angles in degrees from true North (compass orientation), positive clockwise.
  % These are added to measured wind direction to correct to true N
  
  angle_SMAST_pier = 49.36;				% angle between axis of SMAST pier (facing seaward) and true North - Measured with RTK 03/2025 (TK,JC)
  angle_SMAST_tower = 90 + angle_SMAST_pier;		% angle between SMAST tower sensor arms (facing seaward) and true North
  angle_SMAST_lattice = 120 + angle_SMAST_pier;	% angle between SMAST lattice sensor arms (facing seaward) and true North
  
  % SMAST sonic anglesand and
  angle_SMAST_tower_ATI_A = 90 + angle_SMAST_tower;	% angle between SMAST tower ATI A positive v-velocity and true North
  angle_SMAST_tower_ATI_V = 135 + angle_SMAST_tower;	% angle between SMAST tower ATI V positive v-velocity and true North

  angle_SMAST_lattice_ATI_A = 90 + angle_SMAST_lattice; % angle between SMAST lattice ATI A positive v-velocity and true North
  angle_SMAST_lattice_ATI_V = 135 + angle_SMAST_lattice; % angle between SMAST lattice ATI V positive v-velocity and true North
  angle_SMAST_lattice_Gill = 150 + angle_SMAST_lattice; % angle between SMAST lattice ATI A positive v-velocity and true North
  
  % CBC jetty angles
  angle_CBC_jetty = 87.5;				% angle between axis of CBC jetty (facing seaward) and true North
  angle_CBC_tower = -60 + angle_CBC_jetty;		% angle between CBC tower sensor arms (facing seaward) and true North
  angle_CBC_lattice = 64;				% angle between CBC lattice sensor arm (facing seaward) and true North
  
  % CBC sonic angles
  angle_CBC_tower_ATI_A = 90 + angle_CBC_tower;	% angle between CBC tower ATI A positive v-velocity and true North
  angle_CBC_tower_ATI_V = 135 + angle_CBC_tower;	% angle between CBC tower ATI V positive v-velocity and true North

  angle_CBC_lattice_ATI_A = 90 + angle_CBC_lattice;	% angle between CBC lattice ATI A positive v-velocity and true North
  angle_CBC_lattice_ATI_V = 135 + angle_CBC_lattice;	% angle between CBC lattice ATI V positive v-velocity and true North

  infmt = 'MM/dd/uuuu HH:mm:ss';
  
  % SMAST portlog angles
  angle_SMAST_portlog = 270 + angle_SMAST_pier;	% angle portlog solar panel (opposing side) relative to true South (North)
  
  % CBC portlog angles
  if contains(sensor,'CBC')
    if start_date <= datetime('05/30/2022 02:50:00','InputFormat',infmt)
        angle_CBC_portlog = -11;				% angle relative to true North
    elseif start_date >= datetime('07/05/2022 00:00:00','InputFormat',infmt) && ...
            end_date <= datetime('01/01/2023 00:00:00','InputFormat',infmt)
        angle_CBC_portlog = 0;
    % elseif start_date >= datetime('03/30/2023 00:00:00','InputFormat',infmt) && ...
    %         end_date < datetime('05/18/2023 15:40:00','InputFormat',infmt)	% start_date is guess-timate of when
    %     % sensor became rotated on piling
    %     angle_CBC_portlog = -44;
    elseif start_date >= datetime('01/02/2023 00:00:01','InputFormat',infmt) && ...
            end_date < datetime('04/25/2023 11:59:00','InputFormat',infmt)	
        angle_CBC_portlog = 0;
    elseif start_date >= datetime('04/26/2023 00:00:00','InputFormat',infmt) && ...
            end_date < datetime('05/18/2023 15:40:00','InputFormat',infmt)	% start_date is guess-timate of when
        % sensor became rotated on piling
        angle_CBC_portlog = -44;
    elseif start_date >= datetime('05/18/2023 15:40:00','InputFormat',infmt)
        angle_CBC_portlog = 0;
    else
      angle_CBC_portlog = 0;
    end
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Different cases for combinations of u and v in current configuration
  switch sensor
      case 'SMAST_Lattice_A'
          angleCorrection = angle_SMAST_lattice_ATI_A;
      case 'SMAST_Lattice_V'
          angleCorrection = angle_SMAST_lattice_ATI_V;
      case 'SMAST_Lattice_Gill'
          angleCorrection = angle_SMAST_lattice_Gill;
        
      case 'SMAST_Tower_A'
          angleCorrection = angle_SMAST_tower_ATI_A;
      case 'SMAST_Tower_V'
          angleCorrection = angle_SMAST_tower_ATI_V;
  
      case 'CBC_Lattice_A'
          angleCorrection = angle_CBC_lattice_ATI_A;
      case 'CBC_Lattice_V'
          angleCorrection = angle_CBC_lattice_ATI_V;
  
      case 'CBC_Tower_A'
          angleCorrection = angle_CBC_tower_ATI_A;
      case 'CBC_Tower_V'
          angleCorrection = angle_CBC_tower_ATI_V;
  
      case 'SMAST_PortLog'
          angleCorrection = angle_SMAST_portlog;
      case 'CBC_PortLog'
          angleCorrection = angle_CBC_portlog;
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Compass corrections for u,v

  % Convert from cartesian u,v (Eastward,Northward) to compass coordinates (0 deg => wind *from* true North)
  if ~contains(sensor,'PortLog')
      [WindDir,WindSpd] = cart2pol(v,u);	% (rad,m/s) Pure u is 0 and v is 90, swap u and v axes
      WindDir = 180/pi*WindDir - 180;	% (deg, change to northerly)
  else
      % Do nothing - Portlog winds aready in compass coordinates
  end
  
  % Apply compass correction 
  WindSpd_corr = WindSpd;			% (m/s) no correction needed on speed
  WindDir_corr = mod(WindDir + angleCorrection,360);	% (deg from true N, i.e., wind *from* N = 0 deg)
  
  % Convert back to cartesian u,v (Eastward,Northward)
  [v_corr,u_corr] = pol2cart((WindDir_corr-180)*pi/180,WindSpd_corr); % Where v is at 0 Deg. and u is at 90 Deg.
  %%%%%%%%%% END OF FUNCTION %%%%%%%%%%%%%%%%%%
end