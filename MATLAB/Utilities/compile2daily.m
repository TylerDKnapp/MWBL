% This script converts short interval .mat files in to daily files. 
% Intended to consolidate DPL data into larger chunks to speed up working with data
% NOTE: 
% Will not compile data if there are fewer than 24 files for a given day
% Or if there is already a file with '24hrs' in the title for a given day

% Created by Tyler Knapp 04/22/2025
% Revised by Tyler Knapp 06/26/2025 - Adding check for data variable size match. Issue in csv2mat caused time to have additional indicies.
% Revised by Tyler Knapp 09/24/2025 - Adding check for endData and removing limit on number of files for a day to be compiled

function compile2daily(startDate,endDate,all,printStatus)
arguments
  startDate = datetime("01/01/2025 00:00:00","InputFormat",'MM/dd/yyyy HH:mm:ss');
  endDate = datetime('yesterday','Format','MMMM d, yyyy HH:mm:ss'); % Not inclusive
  all = false;
  printStatus = 1;
end

  fprintf('\ncompile2daily Start...\n')
  
  if endDate >= datetime('yesterday','Format','MMMM d, yyyy HH:mm:ss')
    datetime('yesterday','Format','MMMM d, yyyy HH:mm:ss');
  end

  if all
    startDate = datetime("01/01/2020 00:00:00","InputFormat",'MM/dd/yyyy HH:mm:ss');
    endDate = datetime('yesterday','Format','MMMM d, yyyy HH:mm:ss'); % Not inclusive
  end

  % Zero out start and end times
  startDate = startDate - hours(hour(startDate)) - minutes(minute(startDate)) - seconds(second(startDate));
  endDate = endDate - hours(hour(endDate)) - minutes(minute(endDate)) - seconds(second(endDate));
  
  dataStream = ["DPL_SMAST","DPL_CBC"];
  outputDir = ["/usr2/MWBL/Data/DPL_SMAST/processed/","/usr2/MWBL/Data/DPL_CBC/processed/"];
  file_path = ["/usr2/MWBL/Data/DPL_SMAST/processed/*.mat", "/usr2/MWBL/Data/DPL_CBC/processed/*.mat"];
  
  % readMeBase = "From compile2daily.m - " + string(datetime('now')) + ": This file was compiled into ";

  filedate = @(fnm) datetime(fnm(end-20:end-4),'InputFormat','yy-MM-dd-HH-mm-ss');
  
  for numStream = 1:length(dataStream)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Get list of all files
    file_list = dir(file_path(numStream));			% this is list of all files for this sensor

    % Get dates
    for n=1:length(file_list)
      file_date(n) = filedate(file_list(n).name); % Note: You cannot preallocate datetime arrays (as of 02/2025)
    end

    % Sort these by date
    [file_date,sortind] = sort(file_date);
    file_list = file_list(sortind);

    % Remove any files outside of date range
    file_list = file_list(file_date>=startDate & file_date<endDate);
    file_date = file_date(file_date>=startDate & file_date<endDate);

    itr = 0; 
    while startDate + days(itr) < endDate
      [status, data, fileList] = getDPLdata(startDate + days(itr),startDate + days(itr+1),file_list,file_date);
      if status == 1 % Write new 24hr file
        output_file = "DPL_"+data.DPL_station+"_"+data.SerialNo+"_Data_24hrs_"+string(datetime(startDate+days(itr),"format",'yy-MM-dd-HH-mm-ss'))+".mat";
        [date_time,H1,H2,H3,H4,H5,variables,units,elevation,Version,DPL_station, SerialNo] = seperateVars(data);
        % Print Msg
        if printStatus; fprintf("Compiled: %s. Saving to: %s\n",startDate + days(itr),output_file); end
        % Save new 24hr file
        save(outputDir(numStream)+output_file,'date_time','H1','H2','H3','H4','H5','variables','units','elevation','Version','DPL_station','SerialNo');
        % readMe = readMeBase + output_file;
        for i = 1:length(fileList)
          delete(outputDir(numStream)+string(fileList(i).name))
          % save(outputDir+string(fileList(i).name),'readMe'); % Overwrite combined files with 'blank' files containing a readMe
        end
      elseif status == 2 % Overwrite old 24hr file
        output_file = "DPL_"+data.DPL_station+"_"+data.SerialNo+"_Data_24hrs_"+string(datetime(startDate+days(itr),"format",'yy-MM-dd-HH-mm-ss'))+".mat";
        [date_time,H1,H2,H3,H4,H5,variables,units,elevation,Version,DPL_station, SerialNo] = seperateVars(data);
        % Print Msg
        if printStatus; fprintf("Re-Compiled: %s. Overwritting old file and saving to: %s\n",startDate + days(itr),output_file); end
        % Save new 24hr file
        save(outputDir(numStream)+output_file,'date_time','H1','H2','H3','H4','H5','variables','units','elevation','Version','DPL_station','SerialNo');
        % readMe = readMeBase + output_file;
        for i = 1:length(fileList)
          if ~contains(fileList(i).name,'24hrs')
            delete(outputDir(numStream)+string(fileList(i).name))
          end
        end 
      elseif status == 3
        if printStatus; fprintf("Already compiled: %s\n",startDate + days(itr)); end
      else
        % If status is 0 then files have already been converted or there is less than 24 hrs of data
        if printStatus; fprintf("Failed to compile, no files: %s\n",startDate + days(itr)); end
      end
      itr = itr + 1;
    end
    clearvars file_date % Clear file_date for next sensor iteration
  end
end

function [date_time,H1,H2,H3,H4,H5,variables,units,elevation,Version,DPL_station, SerialNo] = seperateVars(data)
  date_time = data.date_time;
  H1 = data.H1;
  H2 = data.H2;
  H3 = data.H3;
  H4 = data.H4;
  H5 = data.H5;
  variables = data.variables;
  units = data.units;
  elevation = data.elevation;
  Version = data.Version;
  DPL_station = data.DPL_station;
  SerialNo = data.SerialNo;
end

function [status, data, file_list] = getDPLdata(startDate,endDate,file_list,file_date)
  status = 1;
  data = NaN;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %% File Processing
  % Get file dates within date range of interest
  file_list = file_list(file_date>=startDate & file_date<endDate);
  % file_date = file_date(file_date>=startDate & file_date<endDate);

  % End function if there are no files
  % If there is not 24 hrs of data, don't complile data
  % False positive check if there are multiple partial files, this is fine for now
  if isempty(file_list)
    status = 0;
    return
  end

  for i = 1:length(file_list)
    if contains(file_list(i).name,'24hrs') 
      file_list = file_list(logical([ones(1,i-1),0,ones(1,length(file_list)-i)]));
      if isempty(file_list)
        status = 3;
        return % Exit if files have already been compiled
      else
        status = 2; % Status 2 to mark this as an overwrite
        break % exit loop
      end
    end
  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %% Loop through list of files and concatenate data
  data = load([file_list(1).folder,'/',file_list(1).name]);
  for n = 2:length(file_list)
    thisData = load([file_list(n).folder,'/',file_list(n).name]);
    for numSens = 1:5
       for nn = 1:length(data.variables)
        % Append "thisData" to data
        data.(['H',num2str(numSens)]).(data.variables{nn}) = [data.(['H',num2str(numSens)]).(data.variables{nn}); thisData.(['H',num2str(numSens)]).(data.variables{nn})];
      end
    end
    if length(data.H1.u) ~= length(data.H1.date_time)
      warning(file_list(n).name+" - Variables are not the same length, in compile2daily.m")
      status = 1;
      return
    end
    data.date_time = [data.date_time; thisData.date_time];
  end
end