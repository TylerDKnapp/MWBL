% Check if te most recent files of a selected group of sensors have been collected and converted successfully.
% Created by Tyler Knapp 06/05/2025
% Updated by Tyler Knapp, 09/11/2025 - Updated to use get_File_Path.m and get_File_Date.m

% NOTE: As of 06/27/2025 Sensors 3:8 (ATI_SMAST,Gill_SMAST,DPL_SMAST,DataQ_SMAST,ATI_CBC,DataQ_CBC,KZ_Scintillometer)
%       have automatic daily collection. 

function Verify_Daily_Files(startDate, endDate)
arguments
  startDate = datetime('today') - days(14)
  endDate = datetime('today') - minutes(1) % Go until 23:59 of previous day
end
  % fileState = 'processed';
  fileState = 'raw';
  filepathbase = '/usr2/MWBL/Data/';

  % SensorList = [1,3:8,11,17,18];
  SensorList = [1,3:8,17,18]; %Without SMAST Tower
  fprintf('')
  fprintf('Checking for missing data:\n')

  Sensors.name{1} = 		  'PortLog_SMAST';    Sensors.dataStream{1} = 'RainwisePortLog';  Sensors.subdataStream{1} = 'SMAST';
  Sensors.name{2} = 		  'PortLog_CBC';      Sensors.dataStream{2} = 'RainwisePortLog';  Sensors.subdataStream{2} = 'CBC';
  Sensors.name{3} = 		  'ATI_SMAST';        Sensors.dataStream{3} = 'Lattice';          Sensors.subdataStream{3} = {'SMAST';'ATI'};
  Sensors.name{4} = 		  'Gill_SMAST';       Sensors.dataStream{4} = 'Lattice';          Sensors.subdataStream{4} = {'SMAST';'Gill'};
  Sensors.name{5} = 		  'DataQ_SMAST';      Sensors.dataStream{5} = 'Lattice';          Sensors.subdataStream{5} = {'SMAST';'DataQ'};
  Sensors.name{6} = 		  'ATI_CBC';          Sensors.dataStream{6} = 'Lattice';          Sensors.subdataStream{6} = {'CBC';'ATI'};
  Sensors.name{7} = 		  'DataQ_CBC';        Sensors.dataStream{7} = 'Lattice';          Sensors.subdataStream{7} = {'CBC';'DataQ'};
  Sensors.name{8} = 		  'KZScintillometer'; Sensors.dataStream{8} = 'KZScintillometer'; Sensors.subdataStream{8} = [];
  Sensors.name{9} = 		  'NBAirport';        Sensors.dataStream{9} = 'NBAirport';        Sensors.subdataStream{9} = [];
  Sensors.name{10} = 		  'NOAA_WaterT';      Sensors.dataStream{10} = 'NOAA_WaterT';     Sensors.subdataStream{10} = [];
  Sensors.name{11} = 		  'DPL_SMAST';        Sensors.dataStream{11} = 'DPL';             Sensors.subdataStream{11} = 'SMAST';
  Sensors.name{12} = 		  'DPL_CBC';          Sensors.dataStream{12} = 'DPL';             Sensors.subdataStream{12} = 'CBC';
  Sensors.name{13} = 		  'HOBO_SMAST';       Sensors.dataStream{13} = 'OnsetHOBO';       Sensors.subdataStream{13} = 'SMAST';
  Sensors.name{14} = 		  'HOBO_CBC';         Sensors.dataStream{14} = 'OnsetHOBO';       Sensors.subdataStream{14} = 'CBC';
  Sensors.name{15} = 		  'Ambilabs_2WIN';    Sensors.dataStream{15} = 'Ambilabs_2WIN';   Sensors.subdataStream{15} = [];
  Sensors.name{16} = 		  'Ecotech_M9003';    Sensors.dataStream{16} = 'Ecotech_M9003';   Sensors.subdataStream{16} = [];
  Sensors.name{17} = 		  'AQMesh_2451070';   Sensors.dataStream{17} = 'AQMesh';          Sensors.subdataStream{17} = '2451070';
  Sensors.name{18} = 		  'AQMesh_2451071';   Sensors.dataStream{18} = 'AQMesh';          Sensors.subdataStream{18} = '2451071';
  Sensors.name{19} = 		  'Apogee_3238';      Sensors.dataStream{19} = 'Apogee';          Sensors.subdataStream{19} = '3238';
  Sensors.name{20} = 		  'Apogee_3239';      Sensors.dataStream{20} = 'Apogee';          Sensors.subdataStream{20} = '3239';
  Sensors.name{21} = 		  'EPA_PM25';         Sensors.dataStream{21} = 'EPA_PM25';        Sensors.subdataStream{21} = [];
  
  for i = 1:length(Sensors.dataStream)
    if any(i==SensorList)	% only load data streams if in SensorList
     
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % Get list of all files, then trim for desired time window
      filePath = get_File_Path(filepathbase,Sensors.dataStream{i}, Sensors.subdataStream{i});
      % override filePath processed/raw
      if string(fileState) == "raw"
        filePath = strrep(filePath,'processed','raw');
        filePath = strrep(filePath,'*.mat','*');
      end
      filePath = strrep(filePath,'processed',fileState);
      fileList = dir(filePath);
      for j=1:length(fileList)
        if fileList(j).name ~= ".." && fileList(j).name ~= "." && fileList(j).name ~= ""  && ~contains(fileList(j).name,'lock')
          fileDate(j) = get_File_Date(fileList(j).name, Sensors.dataStream{i}, Sensors.subdataStream{i}); % Can't prelocate datetime arrays
        end
      end
   
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % sort by date
      [fileDate,sortind] = sort(fileDate);
      fileList = fileList(sortind);
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % Get index of file dates in the range we need, plus one more before and after
      % First try to get file dates within date range of interest
      fileIndx = find(fileDate>=startDate & fileDate<=endDate);
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      if ~isempty(fileIndx) 	% non-empty fileIndx means files found within our requested date range
        % strip file list to just the ones we want
        fileList = fileList(fileIndx);
        fileDate = fileDate(fileIndx);
      else
        fileList = [];
        fileDate = [];
      end
      
      if string(Sensors.dataStream{i}) == "DPL"
        missingDates = find_missing_time(startDate,endDate,fileDate);
      else
        missingDates = find_missing_date(startDate,endDate,fileDate);
      end

      if ~isempty(missingDates)
        fprintf('Sensor: %s Missing days:\n',Sensors.name{i})
        for j = 1:length(missingDates)
          fprintf('%s\n',missingDates(j))
        end
      else
        fprintf('Sensor: %s Not missing any days:\n',Sensors.name{i})
      end

      % Reset Array
      clear fileDate
    end
  end 
    
end % End Func

function missingDates = find_missing_date(startDate,endDate,fileDate)
  itr = 1;
  dates(itr) = startDate;
  while dates(itr) <= endDate
    dates(itr+1) = startDate + days(itr);
    itr = itr + 1;
  end

  missing = ones(1,length(dates)-1);
  for i = 1:length(dates)-1
    for j = 1:length(fileDate)
      % fprintf('%s >= %s && %s <= %s = %d\n',fileDate(j), dates(i), fileDate(j), dates(i+1),fileDate(j) >= dates(i) && fileDate(j) <= dates(i+1))
      if fileDate(j) >= dates(i) && fileDate(j) < dates(i+1)
        missing(i) = 0;
      end
    end
  end
  missingDates = dates(missing==1);
end

function missingTimes = find_missing_time(startDate,endDate,fileDate)
  itr = 1;
  dates(1) = startDate;
  while dates(itr) <= endDate
    dates(itr+1) = startDate + hours(itr); % Add one hour instead of one day
    itr = itr + 1;
  end

  missing = ones(1,length(dates)-1);
  for i = 1:length(dates)-1
    for j = 1:length(fileDate)
      % fprintf('%s >= %s && %s <= %s = %d\n',fileDate(j), dates(i), fileDate(j), dates(i+1),fileDate(j) >= dates(i) && fileDate(j) <= dates(i+1))
      if fileDate(j) >= dates(i) && fileDate(j) < dates(i+1)
        missing(i) = 0;
      end
    end
  end
  missingTimes = dates(missing==1);
end