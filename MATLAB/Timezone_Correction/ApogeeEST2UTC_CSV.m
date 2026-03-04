%% ApogeeEST2UTC_CSV.m
% Created by Tyler Knapp, 03/07/2025
%%
clear
serialNumArray = [3238 3239];
for serialNum = serialNumArray(1):serialNumArray(end,1)
  clearvars file_date
  file_path = ['/usr2/MWBL/Data/Apogee/raw/*',num2str(serialNum),'*.csv'];
  % log_path = '/usr2/MWBL/Data/Apogee/ApogeeEST2UTC_CSV.log';
  % log = fopen(log_path,'w');
  % fprintf(log,"=~=~=~=~=~=~=~=~=~=~=~=~ ApogeeEST2UTC_CSV: %s =~=~=~=~=~=~=~=~=~=~=~=~\n",datetime('now'));
  start_date = datetime(2024,01,01);
  end_date = datetime(2025,03,01);
  
  filedate = @(fnm) datetime(fnm(end-11:end-4),'InputFormat','yyyyMMdd');
  file_list = dir(file_path);			% this is list of all files for this sensor

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % get dates for all these files
  for n=1:length(file_list)
    file_date(n) = filedate(file_list(n).name);
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % sort these by date, just to be sure
  [file_date,sortind] = sort(file_date,'descend');
  file_list = file_list(sortind);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Get index of file dates in the range we need, plus one more before and after
  % First try to get file dates within date range of interest
  fileind = find(file_date>=start_date & file_date<=end_date);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % strip file list to just the ones we want
  file_list = file_list(fileind);
  file_date = file_date(fileind);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Loop through files and data to fix erronious data
  for i = 1:length(file_list)
    filename = [file_list(i).folder,'/',file_list(i).name];
    data = readtable(filename, "Delimiter",",");
    data.Properties.VariableNames{1} = 'date_time';
    data = table2struct(data);
    if i == 1 % first
      % First itration always prompt user, this is the baseline
      fprintf("File: %s\nStartHr: %s\nEndHr: %s\n", ...
      file_list(i).name,data.date_time(1,1),data.date_time(end,1))
    elseif i == length(file_list) % last
      filename_im1 = [file_list(i-1).folder,'/',file_list(i-1).name];
      data_im1 = readtable(filename_im1, "Delimiter",",");
      data_im1.Properties.VariableNames{1} = 'date_time';
      data_im1 = table2struct(data_im1);
      if hours(data_im1.date_time(1,1) - data.date_time(end,1)) > 0
        % If time difference is significant prompt user
        fprintf("File: %s\nStart: %s\nEndHr-PrevStartHr: %s - %s\n", ...
        file_list(i).name,data.date_time(1,1),data.date_time(end,1),data_im1.date_time(1,1))
      elseif hours(data_im1.date_time(1,1) - data.date_time(end,1)) < 0
        error("negative time difference in start - end times in files:\n%s\nStart: %s\nEnd: %s\n%s\nStart: %s\nEnd: %s" ...
          ,file_list(i-1).name,data_im1.date_time(1,1),data_im1.date_time(end,1),file_list(i).name,data.date_time(1,1),data.date_time(end,1))
      else
        fprintf("File: %s\nStart: %s\nEndHr-PrevStartHr: %s - %s\n", ...
        file_list(i).name,data.date_time(1,1),data.date_time(end,1),data_im1.date_time(1,1))
        continue % Skip to next iteration
      end
    else
      filename_im1 = [file_list(i-1).folder,'/',file_list(i-1).name];
      data_im1 = readtable(filename_im1, "Delimiter",",");
      data_im1.Properties.VariableNames{1} = 'date_time';
      data_im1 = table2struct(data_im1);
      filename_im1 = [file_list(i+1).folder,'/',file_list(i+1).name];
      data_ip1 = readtable(filename_im1, "Delimiter",",");
      data_ip1.Properties.VariableNames{1} = 'date_time';
      data_ip1 = table2struct(data_ip1);
      if hours(data_im1.date_time(1,1) - data.date_time(end,1)) > 0
        % If time difference is significant prompt user
        fprintf("File: %s\nStart-NextEnd: %s - %s\nEnd-PrevStart: %s - %s\n", ...
        file_list(i).name,data.date_time(1,1),data_ip1.date_time(end,1),data.date_time(end,1),data_im1.date_time(1,1))
      elseif hours(data_im1.date_time(1,1) - data.date_time(end,1)) < 0
        error("negative time difference in start - end times in files:\n%s\nStart: %s\nEnd: %s\n%s\nStart: %s\nEnd: %s" ...
          ,file_list(i-1).name,data_im1.date_time(1,1),data_im1.date_time(end,1),file_list(i).name,data.date_time(1,1),data.date_time(end,1))
      else
        fprintf("File: %s\nStart: %s\nEndHr-PrevStartHr: %s - %s\n", ...
        file_list(i).name,data.date_time(1,1),data.date_time(end,1),data_im1.date_time(1,1))
        continue % Skip to next iteration
      end
    end % End if
  
    while true
      % Send user message to change from EST/EDT
      check = input("Type 'y' to adjust to UTC(+5hrs) or 'n' to continue\n","s");
      % Check user input from terminal
      if check == "y"
        fprintf("Converting end from %s to %s\nPress any key to continue", ...
          data.date_time(end,1),data.date_time(end,1)+hours(5))
        pause
        % Add 5hrs to all date_time
        data.date_time = data.date_time + hours(5);
        fprintf(log,"Converting:%s to UTC (+5hrs)\n",filename);
        % Save new file
        disp("Saving new file as: " + filename)
        data = struct2table(data);
        writetable(data,filename)
        break
      elseif check == "n"
        % if user inputs n skip to next iteration
        break
      else
        fprintf("WARNING - Cmd: '%s' not found try again.\n",check)
      end
    end % End while
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  end % End for file_list
end % End for SN

%% table2struct: Convert table to struct with values equal to each column of table
function x1 = table2struct(x0)
  for i = 1:size(x0,2)
    if i == 1
      try
        x1.(x0.Properties.VariableNames{i}) = datetime(table2array(x0(:,i)),"Format","MM/dd/yyyy HH:mm");
      catch
        x1.(x0.Properties.VariableNames{i}) = datetime(datestr(table2array(x0(:,i))),"Format","MMM dd yyyy HH:mm:ss");
      end
    else
      x1.(x0.Properties.VariableNames{i}) = table2array(x0(:,i));
    end
  end
end