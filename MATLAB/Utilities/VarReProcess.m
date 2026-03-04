% Resave processed files with a new variable name, this is super unoptimal, might as well par-reprocess
clear

fileDir = '/usr2/MWBL/Data/Lattice_SMAST_Station1/Gill/processed/';
fileList = dir([fileDir,'*.mat']);
variables = {'date_time'; 'status_addr'; 'status_data'; 'u'; 'v'; 'w'; 'T_Sonic'; 'checksum';'WindSpd';'WindDir'};
units = {'Matlab formatted datetime (UTC)';'status addr';'status';'m/s';'m/s';'m/s';'deg C';'checksum';'m/s';'degrees'};

for i = 1:length(fileList)
  output_file = fileList(i).name;
  inputFile = open([fileDir,fileList(i).name]);
  % Changing T_Air to T_Sonic
  try % If this errors out T_Air is already missing
    T_Sonic = inputFile.T_Air;
    inputFile.T_Sonic = T_Sonic;
    inputFile = rmfield(inputFile,'T_Air');
    % Saving
    [date_time,WindSpd,WindDir,T_Sonic,u,v,w,status_addr,elevation,status_data,checksum,Version] = seperateVarsGill(inputFile);
    save([fileDir,output_file],'variables','elevation','units','Version');
    for n = 1:length(variables)
      save([fileDir,output_file],variables{n},'-append');
    end
  end
end

fileDir = '/usr2/MWBL/Data/Lattice_SMAST_Station1/ATI/processed/';
fileList = dir([fileDir,'*.mat']);
variables = {'date_time'; 'u'; 'v'; 'w'; 'T_Sonic'; 'Cs'; 'x'; 'y'; 'z'; 'Pitch'; 'Roll'; 'Tu' ; 'Tv'; 'Tw'; 'a'; 'WindSpd';'WindDir'};
units = {'Matlab formatted datetime (UTC)';'m/s';'m/s';'m/s';'deg C'; 'm/s';'g';'g';'g';'degrees';'degrees';'deg C' ; 'deg C'; 'deg C'; '[]'; 'm/s';'degrees'};
parfor i = 1:length(fileList)
  output_file = fileList(i).name;
  inputFile = open([fileDir,fileList(i).name]);
  % Changing T_Air to T_Sonic
  T_Sonic = inputFile.T_Air;
  inputFile.T_Sonic = T_Sonic;
  inputFile = rmfield(inputFile,'T_Air');
  % Saving
  [date_time,WindSpd,WindDir,T_Sonic,u,v,w,Cs,elevation,x,y,z,Pitch,Roll,Tu,Tv,Tw,a,Version] = seperateVarsATI(inputFile);
  save([fileDir,output_file],'variables','elevation','units','Version','-fromstruct');
  for n = 1:length(variables)
    save([fileDir,output_file],variables{n},'-append','-fromstruct');
  end
end

fileDir = '/usr2/MWBL/Data/Lattice_CBC_Station2/ATI/processed/';
fileList = dir([fileDir,'*.mat']);
variables = {'date_time'; 'u'; 'v'; 'w'; 'T_Sonic'; 'Cs'; 'x'; 'y'; 'z'; 'Pitch'; 'Roll'; 'Tu' ; 'Tv'; 'Tw'; 'a'; 'WindSpd';'WindDir'};
units = {'Matlab formatted datetime (UTC)';'m/s';'m/s';'m/s';'deg C'; 'm/s';'g';'g';'g';'degrees';'degrees';'deg C' ; 'deg C'; 'deg C'; '[]'; 'm/s';'degrees'};
parfor i = 1:length(fileList)
  output_file = fileList(i).name;
  inputFile = open([fileDir,fileList(i).name]);
  % Changing T_Air to T_Sonic
  T_Sonic = inputFile.T_Air;
  inputFile.T_Sonic = T_Sonic;
  inputFile = rmfield(inputFile,'T_Air');
  % Saving
  [date_time,WindSpd,WindDir,T_Sonic,u,v,w,Cs,elevation,x,y,z,Pitch,Roll,Tu,Tv,Tw,a,Version] = seperateVarsATI(inputFile);
  save([fileDir,output_file],'variables','elevation','units','Version','-fromstruct');
  for n = 1:length(variables)
    save([fileDir,output_file],variables{n},'-append','-fromstruct');
  end
end

fileDir = '/usr2/MWBL/Data/DPL_SMAST/processed/';
fileList = dir([fileDir,'*.mat']);
variables = {'date_time';'u';'v'; 'w'; 'T_Sonic'; 'RelHumid'; 'Cs'; 'x'; 'y'; 'z'; 'Pitch'; 'Roll'; 'Tu' ; 'Tv'; 'Tw'; 'a';'WindSpd';'WindDir'};
units = {'m/s';'m/s';'m/s';'deg C';'%';'m/s';'g';'g';'g';'degrees';'degrees';'deg C' ; 'deg C'; 'deg C'; '[]';'m/s';'degrees from N'};
parfor i = 1:length(fileList)
  output_file = fileList(i).name;
  inputFile = open([fileDir,fileList(i).name]);
  % Changing T_Air to T_Sonic
  for j = 1:5
    T_Sonic = inputFile.(['H',num2str(j)]).T_Air;
    inputFile.(['H',num2str(j)]).T_Sonic = T_Sonic;
    inputFile.(['H',num2str(j)]) = rmfield(inputFile.(['H',num2str(j)]),'T_Air');
  end
  % Saving
  [date_time,H1,H2,H3,H4,H5,variables,units,elevation,Version,DPL_station,SerialNo] = seperateVarsDPL(inputFile);
  save([fileDir,output_file],'data_time','variables','elevation','units','Version','-fromstruct');
  for n = 1:5
    save([fileDir,output_file],['H',num2str(n)],'-append','-fromstruct');
  end
end



function [date_time,WindSpd,WindDir,T_Sonic,u,v,w,status_addr,elevation,status_data,checksum,Version] = seperateVarsGill(data)
  status_addr = data.status_addr;
  status_data = data.status_data;
  checksum = data.checksum;
  date_time = data.date_time;
  T_Sonic = data.T_Sonic;
  WindSpd = data.WindSpd;
  WindDir = data.WindDir;
  u = data.u;
  v = data.v;
  w = data.w;
  elevation = data.elevation;
  Version = data.Version;
end

function [date_time,WindSpd,WindDir,T_Sonic,u,v,w,Cs,elevation,x,y,z,Pitch,Roll,Tu,Tv,Tw,a,Version] = seperateVarsATI(data)
  Cs = data.Cs;
  x = data.x;
  y = data.y;
  z = data.z;
  Pitch = data.Pitch;
  Roll = data.Roll;
  Tu = data.Tu;
  Tv = data.Tv;
  Tw = data.Tu;
  a = data.a;
  date_time = data.date_time;
  T_Sonic = data.T_Sonic;
  WindSpd = data.WindSpd;
  WindDir = data.WindDir;
  u = data.u;
  v = data.v;
  w = data.w;
  elevation = data.elevation;
  Version = data.Version;
end

function [date_time,H1,H2,H3,H4,H5,variables,units,elevation,Version,DPL_station,SerialNo] = seperateVarsDPL(data)
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