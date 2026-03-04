function [data, errorLog] = get_MWBL_data(startDate, endDate, dataStream, subdataStream, max_cont_time)
% This script loads data from a selected data stream between a start and end time
% Example: get_MWBL_data('07/01/2021 00:00:00','08/01/2021 00:00:00','RainwisePortLog',60)
%  - OR -
% 	       get_MWBL_data(<start datetime>,<end datetime>,'RainwisePortLog','13448')
  arguments
    startDate % Start time of requested data, 'MM/DD/YYYY HH:MM:SS'; or starting datetime value
    endDate % End time of requested data, 'MM/DD/YYYY HH:MM:SS'; or ending datetime value
    dataStream % Selected from get_File_Date or get_File_Path
    subdataStream = [];
    max_cont_time = 61; % Maximum continuous timespan. Data will show NaNs between data when timespan limit it met
    % Defualt: 61 min - Big enough not to be triggered accidentilly
  end
% Note, please pass-in [] for substream if not needed for a particular data set.
%
% Outputs - structure variable containing the requested time range of data
% in same format as individual m-files.
%
% Written by Eric Le-Zabarsky, 03/16/2022
% Revised by Miles A. Sundermeyer to incorporate sub-data types, 5/4/2022
% Edited by Eric Le-Zabarsky to implement KZScintillometer and incorporate SMAST_Tower and CBC_Tower
% Edited by Kayhan Ulgen to read ATI, Gill, Portlog, DPL_SMAST data and
% 	added allowance for some DPL H# variables being empty
% Modified by Miles A. Sundermeyer, 4/16/2023; corrected a couple filedate functions, adjusted some formatting,
% Modified by Miles A. Sundermeyer, 6/9/2023; added naming option in addition to SN for Portlog and Onset HOBOs
% Modified by Miles A. Sundermeyer, 6/14/2023; re-coded redundancy check plus sorting and windowing of data
% 	to ensure data set (even if empty) is reported back with no redundant data
%	removed redundant datetime function calls on star & end times
%	added ad hoc conditional for Portlog files that contain variable 'Rain' rather than 'Precip';
% Modified by Steven Lohrenz, 6/14/2023; added 'slohrenz' as default user if no other username is found
% Modified by Miles A. Sundermeyer, 9/22/2023 to adjust user 'sunderm' paths
% Modified by Kayhan Ulgen, 12/27/2023 Added Ecotech nephelometer and EPA_PM25 data collection
% Modified by Kayhan Ulgen, 01/04/2024 Added Apogee IR sensor data
% Revised by Miles A. Sundermeyer to include AQMesh data, 1/4/2024
% Revised by Miles A. Sundermeyer 1/7/2024; corrected Apogee date format
% Revised by Kayhan Ulgen 02/22/2024; added Ambilabs nephelometer data.
% Revised by Tyler Knapp 01/06/2025 - modified DPL section to accommodate modern data format
%   adding optional argument "max_cont_time" and associated code to insert NaNs
% Revised by Tyler Knapp 01/24/2025 - Replaced Apogee subdata with individual data streams
% Revised by Tyler Knapp 02/24/2025 - Removed subdataStream and adjusted appropriately
% Revised by Tyler Knapp 03/21/2025 - Added EPA and NOAA streams
% Revised by Tyler Knapp 04/14/2025 - Modified NaN insertion function to use matrix math
% Revised by Tyler Knapp, 08/15/2025 - Added new DPL formatting
% Revised by Tyler Knapp, 09/11/2025 - Updated to use get_File_Path.m and get_File_Date.m
% Revised by Tyler Knapp, 09/18/2025 - Fixed new DPL formatting truncation, previously returned wrong time steps
% Revised by Tyler Knapp, 09/18/2025 - Modified date warning to use date_time instead of fileDate
% Revised by Tyler Knapp, 12/08/2025 - Added check to read actual datetime before loading whole file, and added handling for missing variables

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %% Input Processing
  % make sure start and end dates are in date_time format
  startDate = datetime(startDate,"InputFormat",'MM/dd/yyyy HH:mm:ss');
  endDate = datetime(endDate,"InputFormat",'MM/dd/yyyy HH:mm:ss');
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Set directories
  try	% please keep this user check here so that MAS can run code from across NFS mount
    username = getenv('USER');
    if string(username) == "sunderm"
      filePathBase = '/mnt/MWBL/Data/';
    else
      filePathBase = '/usr2/MWBL/Data/';
    end
  catch
    filePathBase = '/usr2/MWBL/Data/';
  end
  errorLog = '';
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Get list of all files, then later will reduce to files for window we need, plus one on each end
  filePath = get_File_Path(filePathBase, dataStream, subdataStream);
  fileList = dir(filePath);			% this is list of all files for this sensor
  if size(fileList,1) == 0
    data = NaN;
    errorLog = errorLog + "No Files for" + dataStream;
    return  % end function if there are no files
  end
  % get dates for all these files
  for n=1:length(fileList)
    fileDate(n) = get_File_Date(fileList(n).name, dataStream, subdataStream); % Note: You cannot preallocate datetime arrays (as of 02/2025)
  end
  
  % sort these by date, just to be sure
  [fileDate,sortind] = sort(fileDate);
  fileList = fileList(sortind);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Get index of file dates in the range we need, plus one more before and after
  % First try to get file dates within date range of interest
  if string(dataStream) == "NBAirport"
    fileind = find(fileDate.Year>=startDate.Year & fileDate.Year<=endDate.Year);
  else
    fileind = find(fileDate>=startDate & fileDate<=endDate);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if ~isempty(fileind) 	% non-empty fileind means files found within our requested date range
      if fileind(1) > 1				% first fileind not already 1, include file just before this
        fileind = [fileind(1)-1, fileind];
      end
      if fileind(end) < length(fileList)		% last fileind not already end, include file just after the last we might need
        fileind = [fileind, fileind(end)+1];
      end
    else 			% empty fileind means date range is narrow or beyond list of file name dates
      % may still have data depending on whether data record start or end date is reflected in file date
      if startDate>=max(fileDate) 		% startDate after last file time stamp, load last file in case contains requested data
        fileind = length(fileList);
      elseif endDate<=min(fileDate)		% endDate before first file time stamp, load first file in case contains requested data
        fileind = 1;
      else						% neither of the above conditions holds, requested date range within file dates
        fileind(1) = find(fileDate>=startDate, 1, 'first')-1;	% get last file before startDate, then go back one
        fileind(2) = find(fileDate<=endDate, 1, 'last')+1;	% get next file after endDate, then go forward one
        if fileind(2)>length(fileList)		% if went beyond last index, get rid of it (note: do this before checking first index)
          fileind(2) = [];
        end
        if fileind(1)==0				% if went beyond first index, get rid of it
          fileind(1) = [];
        end
      end
    end
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % strip file list to just the ones we want
  fileList = fileList(fileind);
  fileDate = fileDate(fileind);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %% Loop through list of files and concatenate data
  % Note, intentionally get a little more data than needed on both the front and back end
  counter = 0;
  for n=1:length(fileList)
    filename = fileList(n).name;
    disp(['  Loading file ',filename] );
    try
      datetime_tmp = load([fileList(n).folder,'/',filename],'date_time');
      startDate_tmp = datetime_tmp.date_time(1);
      endDate_tmp = datetime_tmp.date_time(end);
      inRange = (startDate_tmp >= startDate && startDate_tmp <= endDate) || ...
                (endDate_tmp >= startDate && endDate_tmp <= endDate) || ...
                (startDate_tmp <= startDate && endDate_tmp >= endDate);
    catch
      warning('In get_MWBL_data, variable "datetime" not found/empty')
      inRange = 1; % Fallback, read in data if error triggered above
    end
    if inRange
      counter = counter + 1;
      thisData = load([fileList(n).folder,'/',filename]);
  
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % ad hoc for Portlog files that still have "Rain" rather than "Precip"
      if isfield(thisData,'Rain')
        thisData.Precip = thisData.Rain;
        thisData = rmfield(thisData,'Rain');
        varIndx = find(strcmp(thisData.variables,'Rain'));
        thisData.variables{varIndx} = 'Precip';
      elseif isfield(thisData,'checksum')
        thisData = rmfield(thisData,'checksum');
        varIndx = find(strcmp(thisData.variables,'checksum'));
        thisData.variables = {thisData.variables{1:varIndx-1} thisData.variables{varIndx+1:end}}';
      end
  
      if isfield(thisData,"readMe") && isscalar(thisData)
        % Catch DPL Files that have been converted by complile2daily.m
        counter = counter - 1;
        continue
      end
   
      if counter==1 	% first time through, load first file not as structure
        data = thisData;
      else % otherwies append the file we are on to the previous ones we loaded
        if contains(dataStream,'DPL')
          for numSens = 1:5
            for nn = 1:length(data.variables)
              var = data.variables{nn};
              % Append thisData to data
              if isfield(thisData.(['H',num2str(numSens)]),var)
                data.(['H',num2str(numSens)]).(var) = [data.(['H',num2str(numSens)]).(var); thisData.(['H',num2str(numSens)]).(var)];
              else
                if var == "T_Air" && isfield(thisData.(['H',num2str(numSens)]),'T_Sonic')
                  data.(['H',num2str(numSens)]).(var) = [data.(['H',num2str(numSens)]).(var); thisData.(['H',num2str(numSens)]).T_Sonic];
                elseif var == "T_Sonic" && isfield(thisData.(['H',num2str(numSens)]),'T_Air')
                  data.(['H',num2str(numSens)]).(var) = [data.(['H',num2str(numSens)]).(var); thisData.(['H',num2str(numSens)]).T_Air];
                else
                  data.(['H',num2str(numSens)]).(var) = [data.(['H',num2str(numSens)]).(var); NaN(size(thisData.(['H',num2str(numSens)]).date_time))];
                  warning("File: %s Missing: H%d.%s",filename,numSens,var)
                end
              end
            end
          end
          % Append "thisData" date_time to date_time
          data.date_time = [data.date_time; thisData.date_time];
        else
          for nn=1:length(data.variables)
            var = data.variables{nn};
    	      if contains(dataStream,'HOBO') && ((strcmp(var,'RefWL') || strcmp(var,'Rho_Water')))
    	        % Only first value is valid, keep just first file first value from first time through
    	        % all other times through this nn loop, will skip variables 'RefWL' and 'Rho_Water'
    	        if counter==2
                data.(var) = data.(var)(1);
    	        end
            else
              if var ~= "checksum" && var ~= "Units" && var ~= "Variables" % Avoid re-writting misc info
                if isfield(thisData,var)
                  data.(var) = [data.(var); thisData.(var)];
                else
                  data.(var) = [data.(var); NaN(size(thisData.date_time))];
                  warning("File: %s Missing: %s",filename,var)
                end
              end
    	      end
          end
        end
      end
    end
  end
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
  if exist('data','var')
    %% Keep only unique time stamp data, and sort, since files are not necessarily in order (e.g., due to naming convention changes)
    if strcmp('DPL',dataStream)		% handle DPL sub-structures
      % FOR OLD CONVERSIONS:
      % % Trim redundancies and put in time-sorted order
      % [~,IA,~] = unique(data.date_time,'sorted');
      % 
      % emptyflag = true;		% set a flag to know if we encountered a non-empty data variable, H[1:5]
      % startItr = 1;
      % if data.variables{1} == "date_time"
      %   startItr = 2;
      % end
      % for n = startItr:length(data.variables)
      %   for numSens = 1:5
      %     if ~isempty(data.(['H',num2str(numSens)]).(data.variables{n}))
      %   	  if length(data.(['H',num2str(numSens)]).(data.variables{n})) == length(data.date_time)	% check if H var has same length as H time array
      %         data.(['H',num2str(numSens)]).(data.variables{n}) = data.(['H',num2str(numSens)]).(data.variables{n})(IA);
      %         emptyflag = false;
      %       else			% if H has different length than time array, clear it and raise warning
      %           warning(['H',num2str(numSens)] + "." + string(data.variables{n}) + ': Missing data, setting to []')
      %     	    data.(['H',num2str(numSens)]).(data.variables{n}) = [];
      %   	  end
      %     end
      %   end
      % end
      % FOR NEW CONVERSIONS:
      for numSens = 1:5
        if ~isempty(data.(['H',num2str(numSens)]).date_time)
          keep = datetime(data.(['H',num2str(numSens)]).date_time)>=startDate & datetime(data.(['H',num2str(numSens)]).date_time)<=endDate;
          for n = 1:length(data.variables)
            var = data.variables{n};
            if ~isempty(data.(['H',num2str(numSens)]).(var))
              data.(['H',num2str(numSens)]).(var) = data.(['H',num2str(numSens)]).(var)(keep);
            end
          end
        end
      end
      
      % Truncate date_time
      keep = datetime(data.date_time)>=startDate & datetime(data.date_time)<=endDate;
      data.date_time = data.date_time(keep);
    else			% all data streams
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % get number of records in this data stream before searching for unique time stamps and windowing data
      nrecs = length(data.date_time);
    
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % Trim redundancies and put in time-sorted order
      [~,IA,~] = unique(data.date_time,'sorted');
    
      for n=1:length(data.variables)
        if length(data.(data.variables{n}))==nrecs		% only apply this to variables that are full time arrays
          data.(data.variables{n}) = data.(data.variables{n})(IA);
        end
      end
    
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % get revised number of records after above unique sorting and purging
      nrecs = length(data.date_time);
    
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % Truncate any data outside the bounds requested.
      keep = datetime(data.date_time)>=startDate & datetime(data.date_time)<=endDate;
    
      for n=1:length(data.variables)
        if length(data.(data.variables{n}))==nrecs		% only apply this to variables that are full time arrays
          data.(data.variables{n}) = data.(data.variables{n})(keep);
        end
      end
      
      % Seperate DataQ sensors
      if contains(dataStream,'Lattice')
        if contains(subdataStream{2},'Young')
          dataTmp = data;
          clearvars data
          data.date_time = dataTmp.date_time;
          data.Baro = dataTmp.Baro;
          data.variables = {'date_time'; 'Baro'};
          data.units = {'Matlab formatted datetime (UTC)'; 'mbar'};
        elseif contains(subdataStream{2},'NetRad')
          dataTmp = data;
          clearvars data
          data.date_time = dataTmp.date_time;
          data.NetRad = dataTmp.NetRad;
          data.variables = {'date_time'; 'NetRad'};
          data.units = {'Matlab formatted datetime (UTC)'; 'W/m^2'};
        elseif contains(subdataStream{2},'Pyr')
          dataTmp = data;
          clearvars data
          data.date_time = dataTmp.date_time;
          data.Pyr = dataTmp.Pyr;
          data.variables = {'date_time'; 'Pyr'};
          data.units = {'Matlab formatted datetime (UTC)'; 'W/m^2'};
        elseif contains(subdataStream{2},'HMP60')
          dataTmp = data;
          clearvars data
          if contains(subdataStream{1},'CBC')
            data.date_time = dataTmp.date_time;
            data.T_Air = dataTmp.T_Air;
            data.RelHumid = dataTmp.RelHumid;
          elseif contains(subdataStream{1},'SMAST') && contains(subdataStream{2},'HMP60_Upr')
            data.date_time = dataTmp.date_time;
            data.T_Air = dataTmp.T_Air_upr;
            data.RelHumid = dataTmp.RelHumid_upr;
          elseif contains(subdataStream{1},'SMAST') && contains(subdataStream{2},'HMP60_Lwr')
            data.date_time = dataTmp.date_time;
            data.T_Air = dataTmp.T_Air_lwr;
            data.RelHumid = dataTmp.RelHumid_lwr;
          end
          data.variables = {'date_time'; 'T_Air'; 'RelHumid'};
          data.units = {'Matlab formatted datetime (UTC)'; 'Deg C'; '%'};
        end
      end
    end
    
    data = insert_nan_matrix(data,dataStream,max_cont_time);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Provide a warning of data requested were outside of date range of data
    % Note: In this case, the above logic should still give empty structure variables
    if startDate > max(data.date_time)
      warning([' Data not available after ',datestr(max(data.date_time)),' ... please check start and end dates']);
    end
    if endDate < min(data.date_time)
      warning([' Data not available before ',datestr(min(data.date_time)),' ... please check start and end dates']);
    end
  else
    data = [];
    errorLog = errorLog + "No Files for" + dataStream;
  end
end
