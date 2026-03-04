% get_File_Path.m:
% Reads dataStream and returns path of desired sensor's processed files.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   'dataStream'
%     'subdataStream'

%   'Ambilabs_2WIN'
%   'Apogee'
%     '3238'
%     '3239'
%   'AQMesh'
%     '2451070'
%     '2451071'
%   'DPL
%     'SMAST'
%     'CBC'
%     'TestRack'
%   'Ecotech_M9003'
%   'EPA_PM25'
%     'FallRiver'
%     'Narragansett'
%   'Lattice'        NOTE: Pass in as: get_File_Date(fileName, 'Lattice', {'SMAST';'ATI'})
%     'SMAST'
%       'ATI'
%       'DataQ'
%       'EnclosureTemp'
%       'Gill'
%       'Young'
%       'NetRadiometer'
%       'Pyranometer'
%       'HMP60_Upr'
%       'HMP60_Lwr'
%     'CBC'
%       'ATI'
%       'DataQ'
%       'EnclosureTemp'
%       'Young'
%       'NetRadiometer'
%       'Pyranometer'
%       'HMP60'
%   'KZScintillometer'
%   'MZA_DELTA'
%   'NBAirport'
%   'NOAA_WaterT'
%   'OnsetHOBO'
%     '21265947' (SMAST)
%     '21265946' (CBC)
%   'RainwiseMKIII'
%   'RainwisePortLog'
%     '13448' - deployed at SMAST prior to 9/21/2021, then moved to CBC
%     '13449'
%     'W3425' - MKII

% Note, pass-in [] for substream if not needed for a particular data set.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created by Tyler Knapp, 09/09/2025
% Modified by Tyler Knapp, 09/23/2025 - Added Young, NetRadiometer, Pyranometer, and HMP60 subdataStream(s)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function filePath = get_File_Path(filePathBase, dataStream, subdataStream)
  switch dataStream
  case 'Ambilabs_2WIN'
    filePath = strcat(filePathBase,dataStream,'/processed/','*.mat');
  case 'Apogee'
    if isempty(subdataStream)
      filePath = strcat(filePathBase,dataStream,'/processed/','*.mat');
    else
      filePath = strcat(filePathBase,dataStream,'/processed/*',subdataStream,'*.mat');
    end
  case 'AQMesh'
    if isempty(subdataStream)
      filePath = strcat(filePathBase,dataStream,'/processed/','*.mat');
    else
      filePath = strcat(filePathBase,dataStream,'/processed/*',subdataStream,'*.mat');
    end
  case 'DPL'
    filePath = strcat(filePathBase,'DPL_',subdataStream,'/processed/','*.mat');
  case 'Ecotech_M9003'
    filePath = strcat(filePathBase,dataStream,'/processed/','*.mat');
  case 'EPA_PM25'
    if isempty(subdataStream)
      filePath = strcat(filePathBase,dataStream,'/processed/','*.mat');
    else
      filePath = strcat(filePathBase,dataStream,'/processed/*',subdataStream,'*.mat');
    end
  case 'KZScintillometer'
    filePath = strcat(filePathBase,dataStream,'/processed/','*.mat');
  case 'Lattice'
    switch subdataStream{1}
    case 'SMAST'
      switch subdataStream{2}
      case 'ATI'
        filePath = strcat(filePathBase,'Lattice_SMAST_Station1/',subdataStream{2},'/processed/','*.mat');
      case 'Gill'
        filePath = strcat(filePathBase,'Lattice_SMAST_Station1/',subdataStream{2},'/processed/','*.mat');
      case 'DataQ'
        filePath = strcat(filePathBase,'Lattice_SMAST_Station1/',subdataStream{2},'/processed/','*.mat');
      case 'Young'
        filePath = strcat(filePathBase,'Lattice_SMAST_Station1/DataQ/processed/','*.mat');
      case 'NetRadiometer'
        filePath = strcat(filePathBase,'Lattice_SMAST_Station1/DataQ/processed/','*.mat');
      case 'Pyranometer'
        filePath = strcat(filePathBase,'Lattice_SMAST_Station1/DataQ/processed/','*.mat');
      case 'HMP60_Upr'
        filePath = strcat(filePathBase,'Lattice_SMAST_Station1/DataQ/processed/','*.mat');
      case 'HMP60_Lwr'
        filePath = strcat(filePathBase,'Lattice_SMAST_Station1/DataQ/processed/','*.mat');
      end
    case 'CBC'
      switch subdataStream{2}
      case 'ATI'
        filePath = strcat(filePathBase,'Lattice_CBC_Station2/',subdataStream{2},'/processed/','*.mat');
      case 'DataQ'
        filePath = strcat(filePathBase,'Lattice_CBC_Station2/',subdataStream{2},'/processed/','*.mat');
      case 'Young'
        filePath = strcat(filePathBase,'Lattice_CBC_Station2/DataQ/processed/','*.mat');
      case 'NetRadiometer'
        filePath = strcat(filePathBase,'Lattice_CBC_Station2/DataQ/processed/','*.mat');
      case 'Pyranometer'
        filePath = strcat(filePathBase,'Lattice_CBC_Station2/DataQ/processed/','*.mat');
      case 'HMP60'
        filePath = strcat(filePathBase,'Lattice_CBC_Station2/DataQ/processed/','*.mat');
      end
    end
  case 'NBAirport'
    filePath = strcat(filePathBase,'NBAirport/processed/','*.mat');
  case 'NOAA_WaterT'
    filePath = strcat(filePathBase,'NOAA_WaterT/processed/','*.mat');
  case 'OnsetHOBO'
    if isempty(subdataStream)
      filePath = strcat(filePathBase,dataStream,'/processed/','*.mat');
    else
      switch subdataStream
      case 'SMAST'
        filePath = strcat(filePathBase,'OnsetHOBO_SMAST','/processed/','*.mat');
      case 'CBC'
        filePath = strcat(filePathBase,'OnsetHOBO_CBC','/processed/','*.mat');
      end
    end
  case 'RainwisePortLog'
    if isempty(subdataStream)
      % Case to return all portlog filess
      filePath = strcat(filePathBase,dataStream,'/processed/','*.mat');
    else
      % Will work with SN
      filePath = strcat(filePathBase,dataStream,'/processed/*',subdataStream,'*.mat');
    end
  % case 'MZA_DELTA'  			% Currently not checked
  %   % known prefixes to file names are: 'SMAST DELTA 2022', 'AFIT', and 'UMass Delta'
  %   filedate = @(fnm) datetime(fnm(end-17:end-8),'InputFormat','yyyy-MM-dd');
  %   file_path = strcat(filePathBase,dataStream,'/processed','/*Log.mat');
  end
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if exist("filePath","var")
    return
  else
    error("Error: In get_File_Path.m - Sensor: %s - %s not found", dataStream, subdataStream)
  end
end