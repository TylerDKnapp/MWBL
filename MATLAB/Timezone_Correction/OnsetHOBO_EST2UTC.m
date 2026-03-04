% Use to convert raw EST/EDT/UTC-8 to UTC time
% Note: The new UTC file will overwrite original file unless code is uncommented below
%%
% Tyler Knapp 01/02/2025: Created File
% Tyler Knapp 04/16/2025: Made into loop
%%
clear
filelist = dir('/usr2/MWBL/Data/OnsetHOBO/raw/*.csv');

for i = 1:length(filelist)
  filename = "/usr2/MWBL/Data/OnsetHOBO/raw/" + filelist(i).name;
  % Extract the 
  fileDatetime = datetime(datestr(strrep(filelist(i).name(10:28),'_',':')),'format','yyyy-MM-dd hh:mm:ss');
  fileDatetime = datetime(fileDatetime,'format','dd-MMM-yyyy hh:mm:ss');
  opts = detectImportOptions(filename);
  s = readtable(filename,opts);
  margin = hours(0.25); % Add margin of 15min to account for last data recorded and the time data was pulled
  filename_UTC = "";
  save = 0;
  fprintf("Checking File: %s\n",filelist(i).name)

  if opts.VariableNames(2) ==  "Date_Time_EDT_"
    if (s.Date_Time_EDT_(end) - fileDatetime < (hours(4)-margin))
      Date_Time_UTC_ = s.Date_Time_EDT_ + hours(4);
      s = removevars(s,"Date_Time_EDT_");
      % filename_UTC = strrep(filename,'Data EDT','Data UTC Standard Time');
      filename_UTC = strrep(filename,'?','');
      s = addvars(s,Date_Time_UTC_,'After','x_');
      save = 1;
    else
      warning("WARNING1: Datetime column name doesn't match datetime.")
      break
    end
  elseif opts.VariableNames(2) == "Date_Time_EST_"
    if (s.Date_Time_EST_(end) - fileDatetime < (hours(5)-margin))
      Date_Time_UTC_ = s.Date_Time_EST_ + hours(5);
      s = removevars(s,"Date_Time_EST_");
      % filename_UTC = strrep(filename,'Data EST','Data UTC Standard Time');
      filename_UTC = strrep(filename,'?','');
      s = addvars(s,Date_Time_UTC_,'After','x_');
      save = 1;
    else
      warning("WARNING2: Datetime column name doesn't match datetime.")
      break
    end
  elseif opts.VariableNames(2) == "Date_Time_UTCStandardTime_8_"
    if (s.Date_Time_UTCStandardTime_8_(end) - fileDatetime < (hours(8)-margin))
      Date_Time_UTC_ = s.Date_Time_UTCStandardTime_8_ + hours(8);
      s = removevars(s,"Date_Time_UTCStandardTime_8_");
      s = addvars(s,Date_Time_UTC_,'After','x_');
      filename_UTC = strrep(filename,'-8','');
      save = 1;
    else
      warning("WARNING3: Datetime column name doesn't match datetime.")
      break
    end
  elseif opts.VariableNames(2) ==  "Date_Time_UTC_"
    dt = s.Date_Time_UTC_(end) - fileDatetime;
    if ~(((hours(4)-margin) <= dt) && (dt <= (hours(4)+margin)))
      warning("WARNING4: Datetime column name doesn't match datetime.")
      fprintf("Filename: %s\nLastIndx: %s\ndt: %d\n",fileDatetime,s.Date_Time_UTC_(end),hours(dt))
      pause
    end
  elseif opts.VariableNames(2) ==  "Date_Time_UTCStandardTime_"
    dt = s.Date_Time_UTCStandardTime_(end) - fileDatetime;
    if ~(((hours(4)-margin) <= dt) && (dt <= (hours(4)+margin)))
      warning("WARNING5: Datetime column name doesn't match datetime.")
      fprintf("Filename: %s\nLastIndx: %s\ndt: %d\n",fileDatetime,s.Date_Time_UTCStandardTime_(end),hours(dt))
      pause
    end
  else
      warning("WARNING6: Datetime var: %s not recognized.",string(opts.VariableNames(2)))
      break
  end
  
  if save
    %%%% UNCOMMENT IF YOU DON'T WANT FILES TO BE OVERWRITTEN %%%%
    % if isfile(filename_UTC)
    %   filename_UTC = strrep(filename_UTC,'.csv','');
    %   filename_UTC = filename_UTC + "_Converted2UTC.csv";
    % end
    fprintf("Saving as: %s\n",filename_UTC)
    writetable(s,filename_UTC);
  end
end