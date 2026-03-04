% Generic function to convert raw files into mat files, calls each csv2mat function
% Note: If DPL files are reprocessed into individual .mat files, compile2daily will automatically recompile and overwrite the old 24hr file

% Created by Tyler Knapp, 05/01/2025
% Revised by Tyler Knapp, 06/03/2025 - If statements now check if raw file is newer than mat file and converts if true (if in date range)
% Revised by Tyler Knapp, 06/24/2025 - Added 'processAll' flag to process any and all non-processed files and moved previous revision to this functionality instead of with a range of dates
% Revised by Tyler Knapp, 08/21/2025 - Modified NBAirport to only read in year of raw file, to accomedate new auto download protocol
% Revised by Tyler Knapp, 09/05/2025 - Changed DPL conversion script to new DPL_raw2mat.m

function failedList = raw2mat(startDate,endDate,flags)
  baseDir = '/usr2/MWBL/Data/';
  %baseDir = '/mnt/MWBL/Data/';
  failedList = "";
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Convert Ambilabs nephelometer data
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if flags.AmbilabsFlag
    % Input filenames for reading
    inputDir=[baseDir,'Ambilabs_2WIN/raw/'];
    outputDir=[baseDir,'Ambilabs_2WIN/processed/'];
    
    % Retrieve file information
    srchKey = '*.csv';
    postFixLen = length(srchKey)-1;
    FList=dir([inputDir,srchKey]);
    % srchKey = '*.adf';
    % FList2=dir([inputDir,srchKey]);
    % FList = CatStructFields(FList,FList2);
      
    % loop through list and convert files to .mat format
    for n = 1:length(FList)
      dataDate = get_File_Date(strip_char(FList(n).name),'Ambilabs_2WIN',[]);
      fileDate = datetime(FList(n).date); % Raw file
      filePath = [outputDir,FList(n).name(1:end-postFixLen),'.mat']; % Processed file
      fileProcessed = isfile(filePath);
      if flags.reprocessAll || flags.processAll && (~fileProcessed || dir(filePath).date < fileDate) || ...
          (flags.reprocessSome && (dataDate >=startDate && dataDate <=endDate )) || ...
          ((dataDate >= startDate && dataDate <= endDate) && ~fileProcessed)

        disp([' Converting Ambilabs 2WIN file ',num2str(n),' of ',num2str(length(FList))]);
        try
          Ambilabs_2WIN_csv2mat(FList(n).name,inputDir,outputDir);
        catch ME
	        warning(['Ambilabs: ',FList(n).name,', ',ME.message])
	        failedList = failedList + 'Ambilabs: ' + FList(n).name + ', ' + ME.message + '\n';
        end
      end
    end
  end
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Convert Apogee IR Sensor data
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if flags.ApogeeFlag
    % Input filenames for reading
    inputDir=[baseDir,'Apogee/raw/'];
    outputDir=[baseDir,'Apogee/processed/'];

    % Retrieve file information
    srchKey = '*.csv';
    postFixLen = length(srchKey)-1;
    FList=dir([inputDir,srchKey]);

    % loop through list and convert files to .mat format
    for n = 1:length(FList)
      dataDate = get_File_Date(strip_char(FList(n).name),'Apogee',[]);
      fileDate = datetime(FList(n).date);
      filePath = [outputDir,FList(n).name(1:end-postFixLen),'.mat'];
      fileProcessed = isfile(filePath);
      if flags.reprocessAll || ...
         flags.processAll && (~fileProcessed || dir(filePath).date < fileDate) || ...
         (flags.reprocessSome && (dataDate >= startDate && dataDate <= endDate )) || ...
         ((dataDate >= startDate && dataDate <= endDate) && ~fileProcessed)
        disp([' Converting Apogee file ',num2str(n),' of ',num2str(length(FList))]);
        try
          Apogee_csv2mat(FList(n).name,inputDir,outputDir);
        catch ME
	        warning(['Apogee: ',FList(n).name,', ',ME.message])
	        failedList = failedList + 'Apogee: ' + FList(n).name + ', ' + ME.message + '\n';
        end
      end
    end
  end
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Convert AQMesh data
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if flags.AQMeshFlag
    % Input filenames for reading
    inputDir=[baseDir,'AQMesh/raw/'];
    outputDir=[baseDir,'AQMesh/processed/'];
      
    % Retrieve file information
    srchKey = 'aqmeshA*'; % .xlsx or .csv
    % postFixLen = 5;
    FList=dir([inputDir,srchKey]);

    % loop through list and convert files to .mat format
    for n = 1:length(FList)
      dataDate = get_File_Date(FList(n).name,'AQMesh',[]);
      fileDate = datetime(FList(n).date);
      if FList(n).name(end-4:end) == ".xlsx"
        filePath = [outputDir,FList(n).name(1:end-5),'.mat'];
      else
        filePath = [outputDir,FList(n).name(1:end-4),'.mat'];
      end
      fileProcessed = isfile(filePath);
      if flags.reprocessAll || flags.processAll && (~fileProcessed || dir(filePath).date < fileDate) || ...
          (flags.reprocessSome && (dataDate >=startDate && dataDate <=endDate )) || ...
          ((dataDate >= startDate && dataDate <= endDate) && ~fileProcessed)
        disp([' Converting AQMesh file ',num2str(n),' of ',num2str(length(FList))]);
        try
          AQMesh_csv2mat(FList(n).name,inputDir,outputDir);
        catch ME
	        warning(['AQMesh: ',FList(n).name,', ',ME.message])
	        failedList = failedList + 'AQMesh: ' + FList(n).name + ', ' + ME.message + '\n';
        end
      end
    end
  end
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Convert ATI data from Campbell Station deployments
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if flags.ATIFlag
    for m=1:2
      % set directories for where data live
      if m==1
        inputDir = [baseDir,'Lattice_SMAST_Station1/ATI/raw/'];
        outputDir = [baseDir,'Lattice_SMAST_Station1/ATI/processed/'];
      elseif m==2
        inputDir = [baseDir,'Lattice_CBC_Station2/ATI/raw/'];
        outputDir = [baseDir,'Lattice_CBC_Station2/ATI/processed/'];
      end
  
      % make list of files to convert
      srchKey = '*.dat';
      postFixLen = length(srchKey)-1;
      FList=dir([inputDir,srchKey]);
  
      % loop through list and convert files to .mat format
      for n = 1:length(FList)
        dataDate = get_File_Date(strip_char(FList(n).name),'Lattice',{'SMAST';'ATI'}); % Doesn't matter what station
        fileDate = datetime(FList(n).date);
        filePath = [outputDir,FList(n).name(1:end-postFixLen),'.mat'];
        fileProcessed = isfile(filePath);        
        if flags.reprocessAll || flags.processAll && (~fileProcessed || dir(filePath).date < fileDate) || ...
            (flags.reprocessSome && (dataDate >=startDate && dataDate <=endDate )) || ...
            ((dataDate >= startDate && dataDate <= endDate) && ~fileProcessed)
          disp([' Converting ATI file ',num2str(n),' of ',num2str(length(FList))]);
          try
            ATI_raw2mat(FList(n).name,inputDir,outputDir);
          catch ME
	          warning(['ATI: ',FList(n).name,', ',ME.message])
	          failedList = failedList + 'ATI: ' + FList(n).name + ', ' + ME.message + '\n';
          end
        end
      end
    end
  end
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Convert DataQ data from Campbell Station deployments
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if flags.DataQFlag
    for m=1:2
      % set directories for where data live
      if m==1
        inputDir = [baseDir,'Lattice_SMAST_Station1/DataQ/raw/'];
        outputDir = [baseDir,'Lattice_SMAST_Station1/DataQ/processed/'];
      elseif m==2
        inputDir = [baseDir,'Lattice_CBC_Station2/DataQ/raw/'];
        outputDir = [baseDir,'Lattice_CBC_Station2/DataQ/processed/'];
      end
  
      % make list of files to convert
      srchKey = '*.csv';
      postFixLen = length(srchKey)-1;
      FList=dir([inputDir,srchKey]);
  
      % loop through list and convert files to .mat format
      for n = 1:length(FList)
                % Remove extra characters if present
        if contains(FList(n).name,'_1.csv') || contains(FList(n).name,' (1).csv') || contains(FList(n).name,'_2.csv')
          fname=strrep(FList(n).name,'_1.csv','.csv');
          fname=strrep(fname,' (1).csv','.csv');
          fname=strrep(fname,'_2.csv','.csv');
        else
          fname=FList(n).name;
        end
  
        dataDate = get_File_Date(strip_char(FList(n).name),'Lattice',{'SMAST';'DataQ'}); % Doesn't matter what station
        fileDate = datetime(FList(n).date);
        filePath = [outputDir,FList(n).name(1:end-postFixLen),'.mat'];
        fileProcessed = isfile(filePath);
        if flags.reprocessAll || flags.processAll && (~fileProcessed || dir(filePath).date < fileDate) || ...
            (flags.reprocessSome && (dataDate >=startDate && dataDate <=endDate )) || ...
            ((dataDate >= startDate && dataDate <= endDate) && ~fileProcessed)
          disp([' Converting DataQ file ',num2str(n),' of ',num2str(length(FList))]);
          try
            DataQ_csv2mat(FList(n).name,inputDir,outputDir);
          catch ME
            warning(['File failed to convert: ',FList(n).name,', ',ME.message])
            failedList = failedList + 'DataQ: ' + FList(n).name + ', ' + ME.message + '\n';
          end
        end
      end
    end
  end
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Convert MZA DELTA data 
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % if flags.DELTAFlag
  %   % Input filenames for reading
  %   inputDir=[baseDir,'MZA_DELTA/raw/'];
  %   outputDir=[baseDir,'MZA_DELTA/processed/'];
  % 
  %   % function to get file date from file name - same as in get_MWBL_data.m
  %   date_of_data = @(fnm) datetime(fnm(end-17:end-8),'InputFormat','yyyy-MM-dd');
  % 
  %   % loop through data collection years, identifying list of files for that year
  %   for m = 1:2
  %     if m==1		% 2021 file list
  %       FList = dir([inputDir,'*/Results/*Log.txt']);
  %     else		% 2022 file list
  %       FList = dir([inputDir,'SMAST_DELTA_2022/*Log.txt']);
  %     end
  % 
  %     % loop through both lists and convert files to .mat format
  %     for n = 1:length(FList)
  %       dataDate = date_of_data(strip_char(FList(n).name));
  %       filePath = [outputDir,FList(n).name(1:end-4),'.mat'];
  %       fileProcessed = isfile(filePath);
  %       if flags.reprocessAll || flags.processAll && (~fileProcessed || dir(filePath).date < fileDate) || ...
  %           (flags.reprocessSome && (dataDate >=startDate && dataDate <=endDate )) || ...
  %           ((dataDate >= startDate && dataDate <= endDate) && ~fileProcessed)
  %             disp([' Converting MZA DELTA file ',num2str(n),' of ',num2str(length(FList))]);
	%         try
	%           MZA_DELTA_csv2mat(FList(n).name,[FList(n).folder,'/'],outputDir);
  %         catch ME
	%           warning(['MZA Delta: ',FList(n).name,', ',ME.message])
	%           failedList = failedList + 'MZA Delta: ' + FList(n).name + ', ' + ME.message + '\n';
	%         end
  %       end
  %     end
  %   end
  % end
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Convert Ecotech nephelometer data
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if flags.EcotechFlag
    % Input filenames for reading
    inputDir=[baseDir,'Ecotech_M9003/raw/'];
    outputDir=[baseDir,'Ecotech_M9003/processed/'];

    % Retrieve file information
    srchKey = '*.csv';
    postFixLen = length(srchKey)-1;
    FList=dir([inputDir,srchKey]);

    % loop through list and convert files to .mat format
    for n = 1:length(FList)
      dataDate = get_File_Date(strip_char(FList(n).name),'Ecotech_M9003',[]);
      fileDate = datetime(FList(n).date);
      filePath = [outputDir,FList(n).name(1:end-postFixLen),'.mat'];
      fileProcessed = isfile(filePath);
      if flags.reprocessAll || flags.processAll && (~fileProcessed || dir(filePath).date < fileDate) || ...
          (flags.reprocessSome && (dataDate >=startDate && dataDate <=endDate )) || ...
          ((dataDate >= startDate && dataDate <= endDate) && ~fileProcessed)
        disp([' Converting Ecotech M9003 file ',num2str(n),' of ',num2str(length(FList))]);
        try
          Ecotech_csv2mat(FList(n).name,inputDir,outputDir);
        catch ME
          warning(['Echotech: ',FList(n).name,', ',ME.message])
          failedList = failedList + 'Echotech: ' + FList(n).name + ', ' + ME.message + '\n';
        end
      end
    end
  end
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Convert EPA PM2.5 .json files 
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if flags.EPA_PM25Flag
    % Input filenames for reading
    inputDir=[baseDir,'EPA_PM25/raw/'];
    outputDir=[baseDir,'EPA_PM25/processed/'];
    
    % Retrieve file information
    srchKey = '*.json';
    postFixLen = length(srchKey)-1;
    FList=dir([inputDir,srchKey]);

    % loop through list and convert files to .mat format
    for n = 1:length(FList)
      dataDate = get_File_Date(strip_char(FList(n).name),'EPA_PM25',[]);
      fileDate = datetime(FList(n).date);
      filePath = [outputDir,FList(n).name(1:end-postFixLen),'.mat'];
      fileProcessed = isfile(filePath);
      if flags.reprocessAll || flags.processAll && (~fileProcessed || dir(filePath).date < fileDate) || ...
          (flags.reprocessSome && (dataDate >=startDate && dataDate <=endDate )) || ...
          ((dataDate >= startDate && dataDate <= endDate) && ~fileProcessed)
        disp([' Converting EPA PM2.5 file ',num2str(n),' of ',num2str(length(FList))]);
        try
          EPA_PM25_json2mat(FList(n).name,inputDir,outputDir);
        catch ME
	        warning(['EPA: ',FList(n).name,', ',ME.message])
	        failedList = failedList + 'EPA: ' + FList(n).name + ', ' + ME.message + '\n';
        end
      end
    end
  end
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Convert Gill data from Campbell Station deployments
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if flags.GillFlag
    % set directories for where data live
    inputDir = [baseDir,'Lattice_SMAST_Station1/Gill/raw/'];
    outputDir = [baseDir,'Lattice_SMAST_Station1/Gill/processed/'];
  
    % make list of files to convert
    srchKey = '*.dat';
    postFixLen = length(srchKey)-1;
    FList=dir([inputDir,srchKey]);

    % loop through list and convert files to .mat format
    for n = 1:length(FList)
      dataDate = get_File_Date(strip_char(FList(n).name),'Lattice',{'SMAST';'Gill'});
      fileDate = datetime(FList(n).date);
      filePath = [outputDir,FList(n).name(1:end-postFixLen),'.mat'];
      fileProcessed = isfile(filePath);
      if flags.reprocessAll || flags.processAll && (~fileProcessed || dir(filePath).date < fileDate) || ...
          (flags.reprocessSome && (dataDate >=startDate && dataDate <=endDate )) || ...
          ((dataDate >= startDate && dataDate <= endDate) && ~fileProcessed)
        disp([' Converting Gill file ',num2str(n),' of ',num2str(length(FList))]);
        try
          Gill_csv2mat(FList(n).name,inputDir,outputDir);
        catch ME
	        warning(['File failed to convert: ',FList(n).name,', ',ME.message])
	        failedList = failedList + 'DataQ: ' + FList(n).name + ', ' + ME.message + '\n';
        end
      end
    end
  end
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Convert data for NB Airport, downloaded from NOAA
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if flags.NBAirportFlag
    % set directories for where data live
    inputDir = [baseDir,'NBAirport/raw/'];
    outputDir = [baseDir,'NBAirport/processed/'];
    
    % make list of files to convert
    srchKey = '*.csv';
    postFixLen = length(srchKey)-1;
    FList=dir([inputDir,srchKey]);

    % loop through list and convert files to .mat format
    for n = 1:length(FList)
      dataDate = get_File_Date(strip_char(FList(n).name),'NBAirport',[]);
      fileDate = datetime(FList(n).date);
      filePath = [outputDir,FList(n).name(1:end-postFixLen),'.mat'];
      fileProcessed = isfile(filePath);
      if flags.reprocessAll || flags.processAll && (~fileProcessed || dir(filePath).date < fileDate) || ...
          (flags.reprocessSome && (dataDate >=startDate && dataDate <=endDate )) || ...
          ((dataDate >= startDate && dataDate <= endDate) && ~fileProcessed)
        disp([' Converting NB Airport file ',num2str(n),' of ',num2str(length(FList))]);
        try
          NBAirport_csv2mat(FList(n).name,inputDir,outputDir);
        catch ME
	        warning(['NBAirport: ',FList(n).name,', ',ME.message])
          failedList = failedList + 'NBAirport: ' + FList(n).name + ', ' + ME.message + '\n';
        end
      end
    end
  end
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Convert NOAA .csv files 
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % if flags.NOAAFlag
  %   % Input filenames for reading
  %   inputDir=[baseDir,'NOAA_WaterT/raw/'];
  %   outputDir=[baseDir,'NOAA_WaterT/processed/'];
  % 
  %   % Retrieve file information
  %   srchKey = '*.csv';
  %   postFixLen = length(srchKey)-1;
  %   FList=dir([inputDir,srchKey]);
  % 
  %   % loop through list and convert files to .mat format
  %   for n = 1:length(FList)
  %     dataDate = get_File_Date(strip_char(FList(n).name),'NOAA',[]);
  %     fileDate = datetime(FList(n).date);
  %     filePath = [outputDir,FList(n).name(1:end-postFixLen),'.mat'];
  %     fileProcessed = isfile(filePath);
  %     if flags.reprocessAll || flags.processAll && (~fileProcessed || dir(filePath).date < fileDate) || ...
  %         (flags.reprocessSome && (dataDate >=startDate && dataDate <=endDate )) || ...
  %         ((dataDate >= startDate && dataDate <= endDate) && ~fileProcessed)
  %       disp([' Converting NOAA WaterT file ',num2str(n),' of ',num2str(length(FList))]);
  %       try
  %         NOAA_csv2mat(FList(n).name,inputDir,outputDir);
  %       catch ME
	%         warning(['File failed to convert: ',FList(n).name,', ',ME.message])
	%         failedList = failedList + 'NOAA WaterT : ' + FList(n).name + ', ' +ME.message + '\n';
  %       end
  %     end
  %   end
  % end
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Convert Onset HOBO tide / water temperature data
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if flags.OnsetHOBOFlag
    % Input filenames for reading
    inputDir=[baseDir,'OnsetHOBO/raw/'];
    outputDir=[baseDir,'OnsetHOBO/processed/'];
    
    % Retrieve file information
    srchKey = '*.csv';
    postFixLen = length(srchKey)-1;
    FList=dir([inputDir,srchKey]);

    % loop through list and convert files to .mat format
    for n = 1:length(FList)
      dataDate = get_File_Date(strip_char(FList(n).name),'OnsetHOBO',[]);
      fileDate = datetime(FList(n).date);
      filePath = [outputDir,FList(n).name(1:end-postFixLen),'.mat'];
      fileProcessed = isfile(filePath);
      if flags.reprocessAll || flags.processAll && (~fileProcessed || dir(filePath).date < fileDate) || ...
          (flags.reprocessSome && (dataDate >=startDate && dataDate <=endDate )) || ...
          ((dataDate >= startDate && dataDate <= endDate) && ~fileProcessed)
        disp([' Converting Onset HOBO file ',num2str(n),' of ',num2str(length(FList))]);
        try
          OnsetHOBO_csv2mat(FList(n).name,inputDir,outputDir);
        catch ME
          warning(['HOBO: ',FList(n).name,', ',ME.message])
          failedList = failedList + 'HOBO: ' + FList(n).name + ', ' + ME.message + '\n';
        end
      end
    end
  end
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Convert PortLog data
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if flags.RainwisePortLogFlag
    % set directories for where data live
    inputDir = [baseDir,'RainwisePortLog/raw/'];
    outputDir = [baseDir,'RainwisePortLog/processed/'];
    
    % Original PortLog Formatting

    % make list of files to convert
    srchKey = '*.txt';
    postFixLen = length(srchKey)-1;
    FList=dir([inputDir,srchKey]);

    % loop through list and convert files to .mat format
    for n = 1:length(FList)
      dataDate = get_File_Date(strip_char(FList(n).name),'RainwisePortLog',[]);
      fileDate = datetime(FList(n).date);
      filePath = [outputDir,FList(n).name(1:end-postFixLen),'.mat'];
      fileProcessed = isfile(filePath);
      if flags.reprocessAll || flags.processAll && (~fileProcessed || dir(filePath).date < fileDate) || ...
          (flags.reprocessSome && (dataDate >=startDate && dataDate <=endDate )) || ...
          ((dataDate >= startDate && dataDate <= endDate) && ~fileProcessed)
        disp([' Converting Portlog file ',num2str(n),' of ',num2str(length(FList))]);
        try
          Portlog_csv2mat(FList(n).name,inputDir,outputDir);
        catch ME
          warning(['File failed to convert: ',FList(n).name,', ',ME.message])
          failedList = failedList + 'Portlog: ' + FList(n).name + ', ' + ME.message + '\n';
        end
      end
    end

    % MKIII Formatting
    % make list of files to convert
    srchKey = '*.csv';
    postFixLen = length(srchKey)-1;
    FList=dir([inputDir,srchKey]);

    % loop through list and convert files to .mat format
    for n = 1:length(FList)
      dataDate = get_File_Date(strip_char(FList(n).name),'RainwisePortLog',[]);
      fileDate = datetime(FList(n).date);
      filePath = [outputDir,FList(n).name(1:end-postFixLen),'.mat'];
      fileProcessed = isfile(filePath);
      if flags.reprocessAll || flags.processAll && (~fileProcessed || dir(filePath).date < fileDate) || ...
          (flags.reprocessSome && (dataDate >=startDate && dataDate <=endDate )) || ...
          ((dataDate >= startDate && dataDate <= endDate) && ~fileProcessed)
        disp([' Converting MKIII file ',num2str(n),' of ',num2str(length(FList))]);
        try
          MKIII_csv2mat(FList(n).name,inputDir,outputDir);
        catch ME
          warning(['File failed to convert: ',FList(n).name,', ',ME.message])
          failedList = failedList + 'Portlog: ' + FList(n).name + ', ' + ME.message + '\n';
        end
      end
    end
  end
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Convert K&Z Scintillometer data 
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if flags.ScintFlag
    % Input filenames for reading
    inputDir=[baseDir,'KZScintillometer/raw/'];
    outputDir=[baseDir,'KZScintillometer/processed/'];
    
    % Retrieve file information
    srchKey = '*.log'; % All Scint files are now .log
    postFixLen = length(srchKey)-1;
    FList=dir([inputDir,srchKey]);

    % loop through list and convert files to .mat format
    for n = 1:length(FList)
      dataDate = get_File_Date(strip_char(FList(n).name),'KZScintillometer',[]);
      fileDate = datetime(FList(n).date);
      filePath = [outputDir,FList(n).name(1:end-postFixLen),'.mat'];
      fileProcessed = isfile(filePath);
      if flags.reprocessAll || flags.processAll && (~fileProcessed || dir(filePath).date < fileDate) || ...
          (flags.reprocessSome && (dataDate >=startDate && dataDate <=endDate )) || ...
          ((dataDate >= startDate && dataDate <= endDate) && ~fileProcessed)
        disp([' Converting K&Z Scintillometer file ',num2str(n),' of ',num2str(length(FList))]);
        try
          KZScint_csv2mat(FList(n).name,inputDir,outputDir);
        catch ME
          warning(['Scintillometer: ',FList(n).name,', ',ME.message])
          failedList = failedList + 'Scintillometer: ' + FList(n).name + ', ' + ME.message + '\n';
        end
      end
    end
  end
  % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Convert DPL data from SMAST pier and CBC towers
  % Last beacuse this takes a LONG time
  % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if flags.DPLFlag
    for m=1:2
      % set directories for where data live
      if m==1
        site = 'SMAST';
        inputDir = [baseDir,'DPL_SMAST/raw/'];
        outputDir = [baseDir,'DPL_SMAST/processed/'];
      elseif m==2
        site = 'CBC';
        inputDir = [baseDir,'DPL_CBC/raw/'];
        outputDir = [baseDir,'DPL_CBC/processed/'];
      end
  
      % make list of files to convert
      srchKey = '*.txt';
      postFixLen = length(srchKey)-1;
      FList=dir([inputDir,srchKey]);
      srchKey = '*24hrs*.mat';
      FList_24hrs=dir([outputDir,srchKey]);
  
      % loop through list and convert files to .mat format
      for n = 1:length(FList)
        fname = strip_char(FList(n).name);
        dataDate = get_File_Date(strip_char(FList(n).name),'DPL','SMAST'); % doesn't matter which site
        fileDate = datetime(FList(n).date);
  
        output_file = fname(1:end-postFixLen);

        filePath = [outputDir,output_file,'.mat'];
        fileProcessed = isfile(filePath);
        if isempty([FList_24hrs.name]) % Check if any 24hr files are present
          if flags.reprocessAll || flags.processAll && (~fileProcessed || dir(filePath).date < fileDate) || ...
              (flags.reprocessSome && (dataDate >=startDate && dataDate <=endDate )) || ...
              ((dataDate >= startDate && dataDate <= endDate) && ~fileProcessed)
            disp([' Converting DPL file ',num2str(n),' of ',num2str(length(FList)),' -- ',site,': ',FList(n).name]);
            try
              DPL_raw2mat(FList(n).name,inputDir,outputDir);
            catch ME
              warning(['DPL: ',FList(n).name,', ',ME.message])
              failedList = failedList + 'DPL: ' + FList(n).name + ', ' + ME.message + '\n';
            end
          end
        elseif ~contains([FList_24hrs.name],fname(end-20:end-13)) % Extract days that have already been converted and check for them to avoid reprocessing child files
          if flags.reprocessAll || flags.processAll && (~fileProcessed || dir(filePath).date < fileDate) || ...
              (flags.reprocessSome && (dataDate >=startDate && dataDate <=endDate )) || ...
              ((dataDate >= startDate && dataDate <= endDate) && ~fileProcessed)
            disp([' Converting DPL file ',num2str(n),' of ',num2str(length(FList)),' -- ',site,': ',FList(n).name]);
            try
              DPL_raw2mat(FList(n).name,inputDir,outputDir);
            catch ME
              warning(['DPL: ',FList(n).name,', ',ME.message])
              failedList = failedList + 'DPL: ' + FList(n).name + ', ' + ME.message + '\n';
            end
          end
        end
      end
    end
    % Compile 24hr chunks of data into a single .mat file
    if flags.processAll || flags.reprocessAll
      compile2daily(startDate,endDate,1,0) % Compile all files
    else
      compile2daily(startDate,endDate,0,0)
    end
  end
end

function fname = strip_char(filename)
  % Remove extra characters if present
  if contains(filename,'_1.')  || contains(filename,'_2.') || contains(filename,' (1).') || contains(filename,' (2).')
    fname=strrep(filename,'_1.','.');
    fname=strrep(fname,'_2.','.');
    fname=strrep(fname,' (1).','.');
    fname=strrep(fname,' (2).','.');
  else
    fname=filename;
  end
end

function S = CatStructFields(S, T)
  for j = 1:numel(T)
    S = cat(1,S,T(j));
  end
end
