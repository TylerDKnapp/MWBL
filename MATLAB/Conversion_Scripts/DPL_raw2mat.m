% Created by Tyler Knapp, 08//2025
% Revised by Tyler Knapp, 09/23/2025 - Changed T_Air to T_Sonic

function [] = DPL_raw2mat(inputFile,inputDir,outputDir)

arguments
  inputFile = 'DPL_SMAST__Test__Data_00-00-00-00-00-00.txt';
  inputDir = '/usr2/MWBL/Data/DPL_SMAST/'
  outputDir = '/usr2/MWBL/Data/DPL_SMAST/'
end

% Created by Tyler Knapp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                          % Version Control %
  Version = 'DPL_raw2mat, Version 08/01/2025';
  disp([Version, ' is running']);
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                      % List variables and units %
  variables = {'date_time';'u';'v'; 'w'; 'T_Sonic'; 'RelHumid'; 'Cs'; 'x'; 'y'; 'z'; 'Pitch'; 'Roll'; 'Tu' ; 'Tv'; 'Tw'; 'a';'WindSpd';'WindDir'};
  variableNames = {'U', 'V', 'W', 'T', 'H', 'C', 'X', 'Y', 'Z', 'P', 'R', 'Tu' , 'Tv', 'Tw', 'a'}; % How vars are formatted in raw file
  varLength = [6,6,6,6,4,6,4,4,4,7,7,6,6,6,4]; % Hardcode numbers to avoid weridness, assuming uniform spacing
  units = {'m/s';'m/s';'m/s';'deg C';'%';'m/s';'g';'g';'g';'degrees';'degrees';'deg C' ; 'deg C'; 'deg C'; '[]';'m/s';'degrees from N'};
  elevation = struct('H1',2.03,'H2',3.78,'H3',5.54,'H4',7.29,'H5',9.04); % Need values for CBC
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        % Identify station name %
  if contains(inputFile,'SMAST') || contains(inputDir,'SMAST')
    DPL_station = 'SMAST';
  elseif contains(inputFile,'CBC') || contains(inputDir,'CBC')
    DPL_station = 'CBC';
  else
    error('Location not identified.')
  end
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                   % Get DPL file info, and open file %
  disp([' Reading ',inputFile]);
  fileInfo = dir([inputDir,inputFile]);
  input_bytes = fileInfo.bytes;
  
  rawData = readlines([inputDir,inputFile]); % This gets read in as an array of strings
  rawData = rawData(2:end-1); % Strip fist index because of DPL weirdness and last index because it is always blank
  rawData = strrep(rawData,"  # 10 10 10",""); % Remove odd string from data, only occurs in DPL 1
  charData = char(rawData); % Convert to char

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                     % Date and Time Corrections %
  dataGPS = strfind(rawData(1:end,:),'Date');
  t = strfind(charData(1,1:5),'Time');
  if (~isempty(t))
    dateTimeTotal = datetime(charData(:,t+5:t+26), "Format", "yy:MM:dd:HH:mm:ss.SSS");
  else
    try
      dateTimeTotal = datetime(charData(:,1:21), 'Format', 'yy:MM:dd:HH:mm:ss.SSS');
    catch
      try
        % Some files contain "ID " before time
        dateTimeTotal = datetime(charData(:,4:25), 'Format', 'yy:MM:dd:HH:mm:ss.SSS');
      catch
        % DPL 2 without GPS
        dateTimeTotal = datetime(charData(:,4:20), 'Format', 'yy:MM:dd:HH:mm:ss');
      end
    end
  end
  
  % Remove data entries if datetime is < 2020, to filter out 1980 files (default date after power loss)
  std_date = datetime([2020 01 01 00 00 00], 'Format', 'yy:MM:dd:HH:mm:ss');
  badindx = dateTimeTotal>std_date;
  if ~isempty(badindx)
    goodindx = dateTimeTotal>std_date;
    rawData = rawData(goodindx,:);
    charData = charData(goodindx,:);
    % Find the 'Time' string (if it exists) and read the DPL clock datetime AGAIN
    t = strfind(charData(1,1:5),'Time');
    if (~isempty(t))
      dateTimeTotal = datetime(charData(:,t+5:t+26), "Format", "yy:MM:dd:HH:mm:ss.SSS");
    else
      try
        dateTimeTotal = datetime(charData(:,1:21), 'Format', 'yy:MM:dd:HH:mm:ss.SSS');
      catch
        try
          % Some files contain "ID " before time
          dateTimeTotal = datetime(charData(:,4:25), 'Format', 'yy:MM:dd:HH:mm:ss.SSS');
        catch
          dateTimeTotal = datetime(charData(:,4:20), 'Format', 'yy:MM:dd:HH:mm:ss');
        end
      end
    end
  end
  dateTimeTotal = DPL_time_correct(DPL_station,dateTimeTotal,dataGPS); % Correct and interpolate GPS time

  % data = arrayfun(@safeStr2Int, rawData);
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                          % Sensor indexes %
  % key = ["S1","S2","S3","S4","S5","S6","S7"];
  % for i = 1:7
  %     eval("S"+num2str(i)+"Indx = strfind(rawData,key(i));");
  % end
  lineLength = 137; % mode(S2Indx-S1Indx)-2; % Hardcode number to avoid processing and weirdness if S1/2 dropped out
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                         % Sensor Processing %
  % indexU = strfind(rawData(1,:),'U');
  % u = str2num(charData(:,indexU(1)+1:indexU(1)+varLength(1)));
  % 
  % % When a transducer goes bad it will usually, randomly, read -99.99, however it may read lower or higher in some cases. Filter these indexes out
  % goodIndex = find(abs(u)<50); % 50 m/s ~ 100knts
  % if length(goodIndex) < length(goodIndex)
  %   warning("Values in excess of 50m/s found in file: %s",inputFile)
  % end
  % dateTime = dateTimeTotal(goodIndex);
  % rawData = rawData(goodIndex,:);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                         % Variable Assignment %
  for i = 1:7
    [sensorData, sensorIndex] = data2array(rawData,"S"+num2str(i),lineLength); % Extract sensor data into its own array
    dateSensor = dateTimeTotal(sensorIndex);
    if isempty(sensorData)
      itr = 1;
      for var = variables.'
        var = char(var);
        AllS.("S"+num2str(i)).(var) = []; % Set all variables to empty sets
        itr = itr + 1;
      end
      continue % Skip the rest of loop if sensor is empty
    end

    AllS.("S"+num2str(i)).date_time = dateSensor;

    itr = 1;
    for varName = variableNames
      var = char(variables(itr+1)); % Add 1 to skip date_time assignment
      try
        index_1 = strfind(sensorData(1,:),varName) + length(char(varName));
        index_2 = strfind(sensorData(2,:),varName) + length(char(varName));
        index_3 = strfind(sensorData(3,:),varName) + length(char(varName));
        if ~isempty(index_1) && ~isempty(index_2) && ~isempty(index_3)
          index = mode([index_1(1),index_2(1),index_3(1)]); % Take mode to avoid weird chars when swapping channels
        else
          index = [];
        end
      catch
        index = [];
      end
      if ~isempty(index)
        index(2) = min(lineLength,index(1)+varLength(itr));
        AllS.("S"+num2str(i)).(var) = str2double(string(sensorData(:,index(1):index(2))));
        if isempty(AllS.("S"+num2str(i)).(var))
          AllS.("S"+num2str(i)).(var) = arrayfun(@safeStr2Int, sensorData(:,index(1):index(2)));
        end
      else
        AllS.("S"+num2str(i)).(var) = NaN(length(sensorData),1);
      end
      itr = itr + 1;
    end
  end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                           % Post Processing %
  for n = 1:7
    if ~isempty(AllS.(['S',num2str(n)]))
      if strcmp(DPL_station,'SMAST') && n <= 2 % assumes lowest 2 sensor positions are V-style, the rest A-style
        sensor = [DPL_station,'_Tower_V'];
      elseif strcmp(DPL_station,'SMAST') && n > 2
        sensor = [DPL_station,'_Tower_A'];
      else
        sensor = [DPL_station,'_Tower_A']; % Assumes sensors are A style if CBC or not otherwise specified
      end
    
      % Apply compass correction function
      [u_corr,v_corr,WindDir_corr,WindSpd_corr] = compass_correction_function(dateTimeTotal(1),dateTimeTotal(end),sensor,AllS.(['S',num2str(n)]).u,AllS.(['S',num2str(n)]).v,[],[]);

      AllS.(['S',num2str(n)]).u = single(u_corr);
      AllS.(['S',num2str(n)]).v = single(v_corr);
      AllS.(['S',num2str(n)]).WindDir = single(WindDir_corr);
      AllS.(['S',num2str(n)]).WindSpd = single(WindSpd_corr);

      % typecast rest of variables to necessary size
      AllS.(['S',num2str(n)]).w = single(AllS.(['S',num2str(n)]).w);
      AllS.(['S',num2str(n)]).T_Sonic = single(AllS.(['S',num2str(n)]).T_Sonic);
      AllS.(['S',num2str(n)]).RelHumid = uint8(AllS.(['S',num2str(n)]).RelHumid);
      AllS.(['S',num2str(n)]).Cs = single(AllS.(['S',num2str(n)]).Cs);
      AllS.(['S',num2str(n)]).x = int16(AllS.(['S',num2str(n)]).x);
      AllS.(['S',num2str(n)]).y = int16(AllS.(['S',num2str(n)]).y);
      AllS.(['S',num2str(n)]).z = int16(AllS.(['S',num2str(n)]).z);
      AllS.(['S',num2str(n)]).Pitch = single(AllS.(['S',num2str(n)]).Pitch);
      AllS.(['S',num2str(n)]).Roll = single(AllS.(['S',num2str(n)]).Roll);
      AllS.(['S',num2str(n)]).Tu = single(AllS.(['S',num2str(n)]).Tu);
      AllS.(['S',num2str(n)]).Tv = single(AllS.(['S',num2str(n)]).Tv);
      AllS.(['S',num2str(n)]).Tw = single(AllS.(['S',num2str(n)]).Tw);
      AllS.(['S',num2str(n)]).a = single(AllS.(['S',num2str(n)]).a);

      % Process RH Data
      if length(AllS.(['S',num2str(n)]).RelHumid) > 1 % Check if rh data is larger than 1 point
        AllS.(['S',num2str(n)]).RelHumid = remove_spikes(AllS.(['S',num2str(n)]).RelHumid,5);
      end
    end
  end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                             % Final Check %
  for i = 1:7
    for var = variables.'
      var = char(var);
      if length(AllS.(['S',num2str(n)]).date_time) ~= length(AllS.(['S',num2str(n)]).(var))
        error("ERROR: In DPL_raw2mat - In file %s, H%d: %s is an invalid size.",inputFile,i,var);
      end
    end
  end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                          % Position setting %
  if strcmp(DPL_station,'SMAST')
    if dateTimeTotal(1) < datetime('10/19/2022 17:30:00', 'Format', "MM/dd/uuuu HH:mm:ss")
      H1=AllS.S1;
      H2=AllS.S2;
      H3=AllS.S3;
      H4=AllS.S4;
      H5=AllS.S5;
    elseif dateTimeTotal(1) >= datetime('10/19/2022 17:30:00', 'Format', "MM/dd/uuuu HH:mm:ss") && ...
        dateTimeTotal(1) < datetime('10/26/2022 19:00:00', 'Format', "MM/dd/uuuu HH:mm:ss")
      H1=AllS.S1;
      H2=AllS.S2;
      H3=AllS.S4;
      H4=AllS.S5;
      H5=AllS.S7;
    elseif dateTimeTotal(1) >= datetime('10/26/2022 19:00:00', 'Format', "MM/dd/uuuu HH:mm:ss") && ...
        dateTimeTotal(1) < datetime('12/24/2023 19:00:00', 'Format', "MM/dd/uuuu HH:mm:ss")
      H1=AllS.S1;
      H2=AllS.S2;
      H3=AllS.S3;
      H4=AllS.S4;
      H5=AllS.S5;
    elseif dateTimeTotal(1) >= datetime('12/24/2023 00:00:00', 'Format', "MM/dd/uuuu HH:mm:ss") && ...
        dateTimeTotal(1) < datetime('01/01/2026 00:00:00', 'Format', "MM/dd/uuuu HH:mm:ss")
      H1=AllS.S1;
      H2=AllS.S2;
      H3=AllS.S4;
      H4=AllS.S5;
      H5=AllS.S6;
    else
      error("ERROR: Data singals have not been mapped for date: %s in DPL_csv2mat.m",dateTimeTotal(1))
    end
  
    if dateTimeTotal(1)>datetime('10/24/2022 00:00:00', 'Format', "MM/dd/uuuu HH:mm:ss") && dateTimeTotal(end)<=datetime('12/21/2022 23:59:00','Format',"MM/dd/uuuu HH:mm:ss")
      H5.u = -H5.u;
      H5.v = -H5.v;
      H5.w = -H5.w;
      H5.x = -H5.x;
      H5.y = -H5.y;
      H5.z = -H5.z;
      H5.Pitch = -H5.Pitch;
      H5.Roll = -H5.Roll;
    end
  end
  
  if strcmp(DPL_station,'CBC')
    H1=AllS.S1;
    H2=AllS.S2;
    H3=AllS.S3;
    H4=AllS.S4;
    H5=AllS.S5;
  end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                               % Saving %
date_time = dateTimeTotal;

  try
    SerialNo = inputFile(end-32:end-27);
  catch
    SerialNo = [];
  end

  outputFile = strrep(inputFile,'.txt','');  
  fprintf(' Saving output to %s%s\n',outputDir,outputFile);
  save([outputDir,outputFile],'date_time','H1','H2','H3','H4','H5','variables','units','elevation','Version','DPL_station','SerialNo');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                             % Functions %
                            
function [outData, isData] = data2array(inData,key,lineLength)
  indexKey = strfind(inData,key); % Find where each line of inData contain key
  longerThan1 = @(x) length(x) > 1;
  indexEmpty = cellfun('isempty', indexKey); % Find indices of empty cells
  indexMulti = cellfun(longerThan1, indexKey); % Find indices of cells with mutliple values
  if sum(indexEmpty) == length(inData)
    outData = [];
    isData = [];
    return
  else
    indexKey(indexEmpty) = {0}; % Fill empty cells with 0
    indexKey(indexMulti) = {0}; % Fill erronious cells with 0
    indexKey = cell2mat(indexKey(1:end)); % Convert the cell array
  end
  isData = find(indexKey~=0);
  charData = char(inData(isData));
  indexMatrix = indexKey(isData) + (0:lineLength-1);
  rows = (1:size(indexMatrix,1))';             % column vector: [1; 2; 3]
  rows = repmat(rows, 1, size(indexMatrix,2)); % replicate to match size of range_indices
  
  % Convert row/col subscripts to linear indices
  try
    % This will error out if there is only one line of data
    linear_idx = sub2ind(size(charData), rows, indexMatrix);
    outData = charData(linear_idx);
  catch
    outData = [];
    isData = [];
  end
end

function date_time_interp = DPL_time_correct(DPL_station,date_time,GPS_datetime)
  dtformat='MM/dd/yyyy HH:mm:ss';
  begin_time=datetime(date_time(1),'Format',dtformat);
  end_time=datetime(date_time(end),'Format',dtformat);
  switch DPL_station
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % SMAST Tower Time Correction
    case 'SMAST'
      if begin_time>=datetime('09/08/2022 19:40:00','InputFormat',dtformat) && end_time<=datetime('10/26/2022 15:37:22','InputFormat',dtformat)
        % List of actual UTC times
        UTC=datetime(['09/08/2022 19:40:30';'09/14/2022 18:28:00';'09/14/2022 18:36:00';'09/19/2022 19:50:00';'09/19/2022 19:51:00';...
          '09/19/2022 19:52:00'; '09/19/2022 19:53:00';'09/19/2022 19:54:00';'09/27/2022 16:44:30';'09/27/2022 16:46:00';'10/06/2022 18:27:00';...
          '10/06/2022 18:35:00';'10/11/2022 19:15:00';'10/19/2022 13:43:00';'10/19/2022 15:08:00';'10/20/2022 16:52:00';'10/24/2022 20:19:00';...
          '10/25/2022 15:58:00';'10/27/2022 15:18:00'],'InputFormat',dtformat);

        % Corresponding DPL times
        DPL=datetime(['09/08/2022 19:40:30';'09/14/2022 15:29:13';'09/14/2022 15:37:03';'09/19/2022 14:13:43';'09/19/2022 14:14:42'; ...
          '09/19/2022 14:15:40';'09/19/2022 14:16:39';'09/19/2022 14:17:38';'09/27/2022 06:56:40';'09/27/2022 06:58:08';'10/06/2022 03:34:05'; ...
          '10/06/2022 03:41:54';'10/11/2022 01:01:39';'10/18/2022 15:23:55';'10/18/2022 16:44:56';'10/19/2022 17:12:34';'10/23/2022 20:38:10';...
          '10/24/2022 16:17:14';'10/26/2022 15:37:22'],'InputFormat',dtformat);

        %Create table for conversion
        time_table = table(UTC,DPL);
        time_table = table2array(time_table);

        % Do time correction
        date_time_interp=interp1(time_table(:,2),time_table(:,1),date_time);

      elseif end_time<datetime('08/24/2022 18:00:00','InputFormat',dtformat)
        %Data acquired prior to this date may have had invalid time record
        warning('No time correction data currently available for this time interval');
        date_time_interp = date_time;
  
      elseif begin_time>=datetime('08/24/2022 18:00:00','InputFormat',dtformat) && end_time<=datetime('09/08/2022 14:52:18','InputFormat',dtformat)
        % List of actual UTC times
        UTC=datetime(['08/24/2022 18:00:00';'09/08/2022 19:31:00'],'InputFormat',dtformat);
  
        % Corresponding DPL times
        DPL=datetime(['08/24/2022 18:00:00';'09/08/2022 14:52:18'],'InputFormat',dtformat);
  
        %Create table for conversion
        time_table = table(UTC,DPL);
        time_table = table2array(time_table);
  
        % Do time correction
        date_time_interp=interp1(time_table(:,2),time_table(:,1),date_time);
  
      elseif begin_time>=datetime('10/26/2022 17:00:00','InputFormat',dtformat) && end_time<=datetime('12/21/2022 23:59:00','InputFormat',dtformat)
        date_time_interp=date_time-seconds(26);  %Assumes times are correct from this point on - adjust as needed
  
      elseif begin_time>=datetime('04/25/2023 16:00:00','InputFormat',dtformat) && end_time<datetime('05/11/2023 17:47:08','InputFormat',dtformat)
        % List of actual UTC times
        UTC=datetime(['04/25/2023 16:08:00';'05/03/2023 15:08:00';'05/11/2023 17:46:00'],'InputFormat',dtformat);
  
        % Corresponding DPL times
        DPL=datetime(['04/25/2023 16:08:00';'05/03/2023 15:08:34';'05/11/2023 17:47:08'],'InputFormat',dtformat);
  
        %Create table for conversion
        time_table = table(UTC,DPL);
        time_table = table2array(time_table);
  
        % Do time correction
        date_time_interp=interp1(time_table(:,2),time_table(:,1),date_time);
  
      elseif begin_time>=datetime('05/12/2023 16:23:00','InputFormat',dtformat) && end_time<=datetime('12/08/2023 15:25:54','InputFormat',dtformat)
        % List of actual UTC times
        UTC=datetime(['05/12/2023 16:23:00';'05/18/2023 18:07:00';'05/25/2023 17:47:00';'06/08/2023 19:14:30';...
          '06/29/2023 13:44:00';'07/06/2023 18:28:30';'07/13/2023 17:32:00';'07/20/2023 16:28:00';...
          '07/27/2023 17:11:30';'08/03/2023 14:10:00';'08/10/2023 18:03:30';'08/22/2023 19:20:30';...
          '08/31/2023 14:59:30';'09/08/2023 15:29:00';'09/15/2023 14:19:00';'09/29/2023 16:06:00';...
          '10/13/2023 16:18:00';'10/20/2023 14:25:00';'10/27/2023 15:08:00';'11/03/2023 14:30:30';...
          '11/10/2023 15:39:30';'11/27/2023 21:45:30';'12/01/2023 15:15:00';'12/08/2023 15:25:30'],'InputFormat',dtformat);
  
        % Corresponding DPL times
        DPL=datetime(['05/12/2023 16:23:00';'05/18/2023 18:07:01';'05/25/2023 17:47:04';'06/08/2023 19:14:38';...
          '06/29/2023 13:44:14';'07/06/2023 18:28:45';'07/13/2023 17:32:15';'07/20/2023 16:28:15';...
          '07/27/2023 17:11:45';'08/03/2023 14:10:15';'08/10/2023 18:03:45';'08/22/2023 19:20:47';...
          '08/31/2023 14:59:48';'09/08/2023 15:29:18';'09/15/2023 14:19:18';'09/29/2023 16:06:19';...
          '10/13/2023 16:18:22';'10/20/2023 14:25:23';'10/27/2023 15:08:24';'11/03/2023 14:30:54';...
          '11/10/2023 15:39:56';'11/27/2023 21:45:55';'12/01/2023 15:15:24';'12/08/2023 15:25:54'],'InputFormat',dtformat);
  
        %Create table for conversion
        time_table = table(UTC,DPL);
        time_table = table2array(time_table);
  
        % Do time correction
        date_time_interp=interp1(time_table(:,2),time_table(:,1),date_time);
  
      elseif begin_time>=datetime('12/08/2023 15:26:00','InputFormat',dtformat) && end_time<=datetime('12/23/2023 23:59:00','InputFormat',dtformat)
        
        % Do time correction
        date_time_interp=date_time-seconds(24);   %Based on prior time offsets
  
      elseif ~isempty(GPS_datetime)
        % Find unique values of date_time and interpolate intermediate values
        [~,dt_indx,~] = unique(date_time);
        dt_indx = sort(dt_indx);
        date_time_interp = [];
        for idt = 1:length(dt_indx)
          if idt < length(dt_indx)
            intrvl_n = dt_indx(idt+1)-dt_indx(idt); % Number of lines between GPS reports
            if intrvl_n > 1
              date_time_interp = [date_time_interp;date_time(dt_indx(idt):dt_indx(idt+1)-1,1) + seconds(0:1/intrvl_n:1-1/intrvl_n)'];
            else
              date_time_interp = [date_time_interp;date_time(dt_indx(idt))];
            end
          else
            intrvl_n = size(date_time,1) - dt_indx(idt) + 1; % Length of last interval
            if intrvl_n > 1
              date_time_interp = [date_time_interp;date_time(dt_indx(idt):end) + seconds(0:1/intrvl_n:1-1/intrvl_n)'];
            else
              date_time_interp = [date_time_interp;date_time(dt_indx(idt))];
            end
          end
        end
      else
        % List of actual UTC times
        warning('No time correction data currently available for this time interval');
        date_time_interp=date_time;
      end
  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % CBC Tower Time Correction
    case 'CBC'
      if begin_time>=datetime('05/09/2023 16:00:00','InputFormat',dtformat) && end_time<=datetime('05/12/2023 18:12:15','InputFormat',dtformat)
        % List of actual UTC times
        UTC=datetime(['05/09/2023 16:45:30';'05/11/2023 19:55:00';'05/12/2023 18:12:00'],'InputFormat',dtformat);
  
        % Corresponding DPL times
        DPL=datetime(['05/09/2023 16:45:30';'05/11/2023 19:55:09';'05/12/2023 18:12:12'],'InputFormat',dtformat);
  
        %Create table for conversion
        time_table = table(UTC,DPL);
        time_table = table2array(time_table);
  
        % Do time correction
        date_time_interp=interp1(time_table(:,2),time_table(:,1),date_time);
  
      elseif begin_time>=datetime('05/12/2023 18:17:00','InputFormat',dtformat) %&& end_time<=datetime('10/13/2023 14:10:00','InputFormat',dtformat)
        % List of actual UTC times
        UTC=datetime(['05/12/2023 18:18:00';'05/25/2023 15:48:00';'05/31/2023 19:13:00';'06/08/2023 14:53:00';...
          '06/22/2023 16:11:15';'06/29/2023 14:58:00';'07/06/2023 14:57:30';'07/13/2023 15:04:15';...
          '07/20/2023 14:58:00';'07/27/2023 18:06:00';'08/10/2023 15:20:30';...
          '08/22/2023 14:45:00';'08/31/2023 17:26:30';'09/08/2023 17:03:30';...
          '09/15/2023 15:57:30';'09/29/2023 19:57:30';'10/13/2023 14:09:00';...
          '10/20/2023 17:53:00';'10/27/2023 20:18:30';'11/03/2023 17:50:00';...
          '11/10/2023 18:25:00';'11/27/2023 19:30:30';'12/01/2023 18:47:00';...
          '12/08/2023 17:05:00'],'InputFormat',dtformat);
  
        % Corresponding DPL times
        DPL=datetime(['05/12/2023 18:18:00';'05/25/2023 15:48:00';'05/31/2023 19:13:01';'06/08/2023 14:53:03';...
          '06/22/2023 16:11:23';'06/29/2023 14:58:08';'07/06/2023 14:57:38';'07/13/2023 15:04:23';...
          '07/20/2023 14:58:07';'07/27/2023 18:06:11';'08/10/2023 15:20:35';...
          '08/22/2023 14:45:03';'08/31/2023 17:26:34';'09/08/2023 17:03:34';...
          '09/15/2023 15:57:31';'09/29/2023 19:57:31';'10/13/2023 14:09:00';...
          '10/20/2023 17:52:58';'10/27/2023 20:18:28';'11/03/2023 17:49:58';...
          '11/10/2023 18:24:55';'11/27/2023 19:30:19';'12/01/2023 18:46:47';...
          '12/08/2023 17:04:44'],'InputFormat',dtformat);
  
        %Create table for conversion
        time_table = table(UTC,DPL);
        time_table = table2array(time_table);
  
        % Do time correction
        date_time_interp=interp1(time_table(:,2),time_table(:,1),date_time);
      else
        % List of actual UTC times
        warning('No time correction data currently available for this time interval');
        date_time_interp=date_time;
      end
  end
end


function num = safeStr2Int(str)
  % Check if string is completely numeric
  if all(isstrprop(str, 'digit')) || (str(1) == '-' && all(isstrprop(str(2:end), 'digit')))
    num = str2double(str);
    return
  end
  % Otherwise check with regexp to extract number
  numericStr = regexp(str, '-?\d+(\.\d+)?', 'match');
  if ~isempty(numericStr)
    num = str2double(numericStr);
  else
    num = NaN;
  end
end