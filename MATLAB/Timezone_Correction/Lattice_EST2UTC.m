%% LatticeEST2UTC_CSV.m
% Created by Tyler Knapp, 06/24/2025
%%
clear
sensorArray = ["ATI"];
% sensorArray = ["Gill"];
for i = 1:length(sensorArray)
  sensor = sensorArray(i);
  clearvars file_date
  inputDir = '/usr2/MWBL/Data/Lattice_SMAST_Station1/' + sensor(:) + '/raw/';
  backupDir = '/usr2/MWBL/Data/Lattice_SMAST_Station1/' + sensor(:) + '/backup';
  srchKey = '*.dat';
  % log_path = '/usr2/MWBL/Data/Lattice_SMAST_Station1/LatticeEST2UTC_CSV.log';
  % log = fopen(log_path,'w');
  % fprintf(log,"=~=~=~=~=~=~=~=~=~=~=~=~ LatticeEST2UTC_CSV: %s =~=~=~=~=~=~=~=~=~=~=~=~\n",datetime('now'));
  start_date = datetime(2024,07,01);
  % start_date = datetime(2025,06,22);
  end_date = datetime(2025,05,28);
  
  filedate = @(fnm) datetime(fnm(end-13:end-4),'InputFormat','yyyy-MM-dd');
  file_list = dir(inputDir+srchKey);			% this is list of all files for this sensor

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % get dates for all these files
  for n=1:length(file_list)
    try
      file_date(n) = filedate(file_list(n).name);
    end
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
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Loop through files and data to fix erronious data
  for j = 1:length(file_list)

    filename = file_list(j).name;

    fprintf('%s\n',filename)

    % Backup Original File
    fileDir = inputDir + filename;
    copyfile(fileDir,backupDir)

    data = getATIData(filename,inputDir);

    % Save new file
    disp("Saving new file as: " + fileDir)
    writelines(data,fileDir);
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  end % End for file_list
end % End for SN

function dataStr = getATIData(input_file,inputDir)
  opts = delimitedTextImportOptions('Delimiter',{'\n'});
  data = readmatrix(inputDir+input_file,opts);
  disp('   Read completed');
  dataChar = char(data);
  
  time = datetime(dataChar(:,1:26),'format', 'yyyy-MM-dd HH:mm:ss.SSSSSS');
  % if hour(time(1)) < 4
    % time = time + hours(4);
  % end

  time = time + hours(4);
  
  dt = milliseconds(diff(time));
  dataChar = char(data(dt >= 20));
  timeChar = char(time(dt >= 20));
  dataChar(:,1:26) = timeChar;
  dataStr = string(dataChar);
end