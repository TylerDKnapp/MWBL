% Function to export .mat files
% Created by Tyler Knapp, 10/07/2025
clear
startDay = '08/23/2025';
endDay = '09/10/2025';
outputDir = '/usr2/MWBL/Analysis/TKnapp/Data/';
outputFilePre = 'MWBL_';
outputFilePost = ['_',strrep(startDay,'/',''),'-',strrep(endDay,'/','')];

SensorList = [1,4:9,11:14,16,18:20,22:25,27];
Sensors.name{1} = 		  'PortLog_SMAST';    Sensors.dataStream{1} = 'RainwisePortLog';   Sensors.subdataStream{1} = 'SMAST';
Sensors.name{2} = 		  'PortLog_CBC';      Sensors.dataStream{2} = 'RainwisePortLog';   Sensors.subdataStream{2} = 'CBC';
Sensors.name{3} = 		  'ATI_SMAST';        Sensors.dataStream{3} = 'Lattice';           Sensors.subdataStream{3} = {'SMAST';'ATI'};
Sensors.name{4} = 		  'HMP60_SMAST_Upr';  Sensors.dataStream{4} = 'Lattice';           Sensors.subdataStream{4} = {'SMAST';'HMP60_Upr'};
Sensors.name{5} = 		  'Gill_SMAST';       Sensors.dataStream{5} = 'Lattice';           Sensors.subdataStream{5} = {'SMAST';'Gill'};
Sensors.name{6} = 		  'HMP60_SMAST_Lwr';  Sensors.dataStream{6} = 'Lattice';           Sensors.subdataStream{6} = {'SMAST';'HMP60_Lwr'};
Sensors.name{7} = 		  'Young_SMAST';      Sensors.dataStream{7} = 'Lattice';           Sensors.subdataStream{7} = {'SMAST';'Young'};
Sensors.name{8} = 		  'NetRad_SMAST';     Sensors.dataStream{8} = 'Lattice';           Sensors.subdataStream{8} = {'SMAST';'NetRadiometer'};
Sensors.name{9} = 		  'Pyrano_SMAST';     Sensors.dataStream{9} = 'Lattice';           Sensors.subdataStream{9} = {'SMAST';'Pyranometer'};
Sensors.name{10} = 		  'ATI_CBC';          Sensors.dataStream{10} = 'Lattice';          Sensors.subdataStream{10} = {'CBC';'ATI'};
Sensors.name{11} = 		  'HMP60_CBC';        Sensors.dataStream{11} = 'Lattice';          Sensors.subdataStream{11} = {'CBC';'HMP60'};
Sensors.name{12} = 		  'Young_CBC';        Sensors.dataStream{12} = 'Lattice';          Sensors.subdataStream{12} = {'CBC';'Young'};
Sensors.name{13} = 		  'NetRad_CBC';       Sensors.dataStream{13} = 'Lattice';          Sensors.subdataStream{13} = {'CBC';'NetRadiometer'};
Sensors.name{14} = 		  'Pyrano_CBC';       Sensors.dataStream{14} = 'Lattice';          Sensors.subdataStream{14} = {'CBC';'Pyranometer'};
Sensors.name{15} = 		  'KZScintillometer'; Sensors.dataStream{15} = 'KZScintillometer'; Sensors.subdataStream{15} = [];
Sensors.name{16} = 		  'NBAirport';        Sensors.dataStream{16} = 'NBAirport';        Sensors.subdataStream{16} = [];
Sensors.name{17} = 		  'NOAA_WaterT';      Sensors.dataStream{17} = 'NOAA_WaterT';      Sensors.subdataStream{17} = [];
Sensors.name{18} = 		  'HOBO_SMAST';       Sensors.dataStream{18} = 'OnsetHOBO';        Sensors.subdataStream{18} = '21265947';
Sensors.name{19} = 		  'HOBO_CBC';         Sensors.dataStream{19} = 'OnsetHOBO';        Sensors.subdataStream{19} = '21265946';
Sensors.name{20} = 		  'Ambilabs_2WIN';    Sensors.dataStream{20} = 'Ambilabs_2WIN';    Sensors.subdataStream{20} = [];
Sensors.name{21} = 		  'Ecotech_M9003';    Sensors.dataStream{21} = 'Ecotech_M9003';    Sensors.subdataStream{21} = [];
Sensors.name{22} = 		  'AQMesh_2451070';   Sensors.dataStream{22} = 'AQMesh';           Sensors.subdataStream{22} = '2451070';
Sensors.name{23} = 		  'AQMesh_2451071';   Sensors.dataStream{23} = 'AQMesh';           Sensors.subdataStream{23} = '2451071';
Sensors.name{24} = 		  'Apogee_3238';      Sensors.dataStream{24} = 'Apogee';           Sensors.subdataStream{24} = '3238';
Sensors.name{25} = 		  'Apogee_3239';      Sensors.dataStream{25} = 'Apogee';           Sensors.subdataStream{25} = '3239';
Sensors.name{26} = 		  'EPA_PM25';         Sensors.dataStream{26} = 'EPA_PM25';         Sensors.subdataStream{26} = [];
Sensors.name{27} = 		  'DPL_SMAST';        Sensors.dataStream{27} = 'DPL';              Sensors.subdataStream{27} = 'SMAST';
Sensors.name{28} = 		  'DPL_CBC';          Sensors.dataStream{28} = 'DPL';              Sensors.subdataStream{28} = 'CBC';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
startDate = datetime('08/23/2025','format','MM/dd/uuuu');
endDate = datetime('09/10/2025','format','MM/dd/uuuu');

for i=1:length(SensorList)
  eval(['[',Sensors.name{SensorList(i)},',errorLog] = get_MWBL_data(startDate,endDate,Sensors.dataStream{SensorList(i)},Sensors.subdataStream{SensorList(i)});']);
  fprintf('Files Compiled! Saving...')
  fileName = [outputDir,outputFilePre,Sensors.name{SensorList(i)},outputFilePost];
  save(fileName,Sensors.name{SensorList(i)},"-v7.3");
end

fprintf('/nCompleted!')