% Marine Wave Boundary Layer Analysis
% Script for converting Portlog data files from .txt file to .mat format.
%
% Input: 
%   input_file 	- string variable, Portlog ascii file name
%   inputDir	- string vairable, absolute or relative path to ascii input_file (e.g., '../Data/Rainwise PortLog/raw/')
%   outputDir	- string vairable, absolute or relative path to write .mat file (e.g., '../Data/Rainwise PortLog/processed/')
%
% Output: .mat file containing the following variables (temperature, barometer, humidity and solar radiation data
%   are sampled at the data save interval):
%   date_time	- Matlab date and time (UTC) in datetime format
%   T_Air	- Air temperature (deg C) (Note: T, barometer, RH, & solar radiation are sampled at the data save interval)
%   RelHumid	- Relative humidity (%)
%   Dew		- Dewpoint temperature (deg C)
%   Baro	- Barometric pressure (mBar or hPa)
%   WindDir	- Compass direction from which wind is blowing (average over data save interval sampled every 2s, deg)
%   WindSpd	- Wind speed (average over data save interval sampled every 2s, m/s)
%   WS_Max	- Max wind speed (maximum over data save interval, m/s)
%   SRad	- Solar radiation (W/m2)
%   SR_sum	- Solar Energy or Radiant Exposure (cumulative over data save interval, J/m2) 
%   Precip	- Rainfall (cumulative over data save interval, mm) (Note, uncertain how this performs for snow/sleet)
%   Volts	- battery power (volts)
%   Units	- 0=English & mph, 1=English & knts,  2=metric & mps, 3=metric & kph, 4=metric & knts
%   Cksum	- data checksum
%
% Adapted from script by Steven E. Lohrenz
% School for Marine Science and Technology, University of Massachusetts Dartmouth
% email address: slohrenz@umassd.edu
% Website: http://www.umassd.edu/smast/
% Revised by Miles A. Sundermeyer, 10/12/2021
% Last revision by Steven Lohrenz, 10/13/2021
% Revised by Miles A. Sundermeyer, 12/10/2021 to make all output variables column variables
% Revised by Miles A. Sundermeyer, 2/20/2022 convert to UTC where needed, rename RelHumid, Precip to be same as Airport data
% Revised by Steven Lohrenz, 7/15/2022, minor edits to move time adjustment warning inside 'if' statement
% Revised by Steven Lohrenz, 7/22/2022, modified date_time variable to be in Matlab datetime format
% Revised by Kayhan Ulgen, 10/04/2022, conversion of datenum to matlab
%     date-time format is added. Compass corrections are also added
%     considering the deployment times.
% Revised by Steven Lohrenz, 05/11/2023, cleaned up function naming
% Revised by Steven Lohrenz, 05/11/2023, cleaned up function naming
% Revised by Steven Lohrenz, 05/29/23, added compass correction function
% Revised by Steven Lohrenz, 06/02/23, modified compass correction function and added Sensor and SerialNo as variables
% Revised by Miles A. Sundermeyer, 6/9/23, changed "Rain" to "Precip", to match standard met data sets, 
%	changed units from 'mm' to 'mm/hr'; streamlined compass correction call
% Modified by Tyler Knapp, 04/03/2025 - Added simple data processing to Temp, RH, and Baro

function [] = Portlog_csv2mat(input_file,inputDir,outputDir)
  Version = 'Portlog_csv2mat, Version 04/03/2025';			
  disp([Version, ' is running']);

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % list the variables in the file (presumes we know these a prior)
  variables = {'date_time'; 'T_Air'; 'RelHumid'; 'Dew'; 'Baro'; 'WindDir'; 'WindSpd'; 'WS_Max'; 'SRad'; 'SR_sum'; 'Precip'; 'Volts'; 'u'; 'v'};
  units = {'Matlab formatted date and time (UTC)';'Deg C';'%';'Deg C';'mb';'Compass Degrees (e.g. 360 => from N)';'m/s';'m/s';'Watts/m2';'J/m2';'mm/hr';'Volts';'m/s';'m/s'};
  
  % set data line format
  delimiter = ',';
  formatSpec = ['%q%q',repmat('%f',1,12),'%*s%[^\r\n]'];
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Open Portlog ascii file 
  fullfnm = [inputDir,input_file];
  fileID = fopen(fullfnm);
  
  % create blank data array and zero counter
  counter = 0;
  badlines = 0;
  
  %Create blank structure to house variables
  var_struc=struct();
  
  % Read file one line at a time, checking for header and saving data from lines that are complete data records
  while ~feof(fileID)
    thisline = fgetl(fileID);
  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if contains(thisline,'DATE')			% find header line with word "DATE" in it
      header = thisline;
  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    elseif (length(thisline)==90 && sum(strfind(thisline,','))==701)	% find complete data lines; 
	  						  % 2nd argument is checksum of comma locations
      counter = counter + 1;
      % parse data lines into individual fields, appending to data from previous records
      dataArray = textscan(thisline, formatSpec, 'Delimiter', delimiter, 'TextType', 'string',...
    				  'ReturnOnError', false, 'EndOfLine', '\r\n','TreatasEmpty','EOF');
      
      % put these in their respective arrays
      for n=1:length(variables)-2
        if n==1			% date and time need special conversion 
          var_struc.(variables{1})(counter,:)=datetime([char(dataArray{1}),' ',char(dataArray{2})],'InputFormat','MM/dd/uu HH:mm');
        elseif n==14		% final field unknown, but will record as string array
          var_struc.(variables{n})(counter,:)=nan;
        else			% all other entries
          var_struc.(variables{n})(counter,:)=dataArray{n+1};
        end
      end
  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    else						% bad line - ignore
      badlines = badlines+1;
    end
  end
  disp(' Portlog_csv2mat:')
  disp(['   ',num2str(counter),' lines read'])
  disp(['   ',num2str(badlines),' lines could not be parsed'])
  
  fclose(fileID);
  
  var_struc.date_time = var_struc.date_time + years(2000); %This is needed to adjust two digit year to 2000's
  date_time = var_struc.date_time(:);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Do some corrections and time stamp adjustments on specific files
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % All files before move to Boating Center need to be adjusted to GMT
  if ~isempty(findstr(fullfnm,'20210513')) ||  ~isempty(findstr(fullfnm,'13449_Data_20210616')) || ...
          ~isempty(findstr(fullfnm,'20210629')) ||  ~isempty(findstr(fullfnm,'20210706')) || ...
          ~isempty(findstr(fullfnm,'20210720')) ||  ~isempty(findstr(fullfnm,'20210727')) || ...
          ~isempty(findstr(fullfnm,'20210803')) ||  ~isempty(findstr(fullfnm,'20210810')) || ...
          ~isempty(findstr(fullfnm,'20210823'))
  
      warning('***** APPLYING TIME CORRECTIONS TO DATA *****')
  
      date_time = date_time + hours(4);				% adjust from EDT to UTC (+4 hrs)
  
  elseif ~isempty(findstr(fullfnm,'13448_Data_20210616'))		% this one the most serious
								  % 2nd half of this file has wrong date - 01/01/07
								  % Previously attempted to correct this, 
								  % now just delete bad data in raw .txt file
    adjustind = find((date_time)<datetime(2021,05,01));		% Get indices of erroneously early time stamps
    t_offset = years(14+5./12)+duration('16:14:30:00');		% apply years/hours correction to get to local time
  
    date_time = date_time + hours(4);				% adjust from EDT to GMT (+4 hrs)
    date_time(adjustind) = date_time(adjustind) + t_offset;	% adjust section w/ wrong date & time
  
  elseif ~isempty(findstr(fullfnm,'13448_Data_20210902')) 
    ind = find(date_time<datetime(2021,08,23));			% adjust first part of data record
    date_time(ind) = date_time(ind) + hours(4);			% adjust from EDT to GMT (+4 hrs)
  
    ind = find(date_time>datetime(2021,08,23));			% adjust second part of data record
    date_time(ind) = date_time(ind) + hours(18);			% just eyeballing this one - how is this so far off?!
  
  elseif ~isempty(findstr(fullfnm,'13449_Data_20210902'))
    date_time = date_time + hours(4);				% adjust from EDT to GMT (+4 hrs)
  
  elseif ~isempty(findstr(fullfnm,'13448_Data_20210911'))
    date_time = date_time + hours(4);				% adjust from EDT to GMT (+4 hrs)
  
  elseif ~isempty(findstr(fullfnm,'13449_Data_20210911'))
    date_time = date_time + hours(4);				% adjust from EDT to GMT (+4 hrs)
  
  end
  
  % date_time = datetime(date_time,'ConvertFrom','datenum'); % convert datenum to matlab date-time format
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Populate SerialNo and Sensor variables
  if contains(fullfnm, '13448')
    SerialNo = '13448';
  elseif contains(fullfnm, '13449')
    SerialNo = '13449';
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Data Processing
  var_struc.T_Air = remove_spikes(var_struc.T_Air,5);
  var_struc.RelHumid = remove_spikes(var_struc.RelHumid,15);
  var_struc.Dew = remove_spikes(var_struc.Dew,5);
  var_struc.Baro = remove_spikes(var_struc.Baro,5);

  % Compass corrections
  if contains(fullfnm,'SMAST')
    Sensor = 'SMAST_PortLog';
  elseif contains(fullfnm,'CBC')
    Sensor = 'CBC_PortLog';
  end
  
  [u_corr,v_corr,WindDir_corr,WindSpd_corr] = compass_correction_function(date_time(1),date_time(end),Sensor,[],[],var_struc.WindDir,var_struc.WindSpd);
  
  var_struc.u = u_corr;
  var_struc.v = v_corr;
  var_struc.WindDir = WindDir_corr;
  var_struc.WindSpd = WindSpd_corr;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Screen for obviously bad data
  toss = find(var_struc.WS_Max>100);
  var_struc.WS_Max(toss) = NaN;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Save this file to identically named .mat file
  % get rid of any appended '.txt' string at end of file name, only if it exists
  ind = findstr(input_file,'.txt');
  if ~isempty(ind)
    output_file = input_file(1:ind-1);
  else
    output_file = input_file;
  end
  
  disp(['   Saving output to ',outputDir,output_file])
  
  % save variable names and units
  save([outputDir,output_file],'variables','units','Version','Sensor','SerialNo','badlines');
  
  % save variables themselves (appended)
  for n=1:length(variables)
    if n > 1  % Skip date_time variable as it is already populated, including any time adjustments
        eval([variables{n},' = var_struc.(variables{n});']);
    end
    save([outputDir,output_file],variables{n},'-append');
  end
end