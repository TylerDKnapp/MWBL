% MWBL_data_csv2mat.m
% Syntax: MWBL_data_csv2mat
%
% Marine Wave Boundary Layer Analysis
% Script for cycling through raw output data from MWBL sensors and converting to .mat format.
%
% Inputs:
%   none (run as script, not function)
%
% Outputs:
%    output - '*.mat' files with variables, units, time, and date in individual files
%   
% Directory paths (absolute or relative) for various raw MWBL data files are specified below.
%
% Additional .m-files required to run this script: 
%  1) Portlog_csv2mat.m
%  2) DataQ_csv2mat.m
%  3) ATI_csv2mat.m
%  4) Gill_csv2mat.m
%  5) NBAirport_csv2mat
%  6) KZScint_csv2mat.m
%  7) MZA_DELTA_csv2mat.m
%  8) DPL_csv2mat.m
%  9) Ecotech_csv2mat.m
%  10) Apogee_csv2mat.m
%  11) AQMesh_csv2mat.m
%  12) Ambilabs_2WIN_csv2mat.m
% Additional .mat-files required to run this script:
%   none
%
% Author: Steven E. Lohrenz, Ph.D., biological oceanography
% School for Marine Science and Technology, University of Massachusetts Dartmouth
% email address: slohrenz@umassd.edu
% Website: http://www.umassd.edu/smast/
% Revised by Steve Lohrenz, 26 Oct 2021
% Revised by Miles A. Sundermeyer, 10/31/2021
% Last revision by Steven Lohrenz, 03/08/2022
% Revised by Miles A. Sundermeyer, 03/12/2022
% Revised by Steven Lohrenz, 05/01/2022 - switched to table versions of Gill and ATI conversion scripts
% Revised by Steven Lohrenz, 09/02/2022 - added conversion script for DPL 
% Revised by Miles A. Sundermeyer, 09/25/2022 - added Onset HOBO and adjusted DELTA and DPL paths
% Miles A. Sundermeyer, 09/25/2022 - added Onset HOBO and adjusted DELTA and DPL paths
% Steven Lohrenz, 10/21/2022 - added time and date selection option to process subset of DPL files within a given date range
% Steven Lohrenz, 12/28/2022 - added time and date selection option to process subset of ATI files within a given date range
% Kayhan Ulgen, 03/07/2023 - added reprocesssomeFlag and reprocessallFlag availibilty for all sensors.
% Revised by Steven Lohrenz, 05/11/2023 - cleaned up function naming
% Revised by Steven Lohrenz, 05/29/23 - modified Portlog script to allow processing of files from a selected date range
% Revised by Miles A. Sundermeyer, 6/9/2023 - modified to reflect new DPL folder names, new username function, backslashes to slashes in filenames
% Revised by Miles A. Sundermeyer, 6/12/23 - added failed file list via 'try:catch' to enable automated processing
% Revised by Miles A. Sundermeyer, 6/14/23 - Adjusted FList for Scintillometer data to list .txt and .log files%
% Revised by Steven Lohrenz, 7/21/2023 - Modified file date reading for sensors to account for different filename formats
% Revised by Kayhan Ulgen, 12/20/2023 - Added the Ecotech and EPA_PM25 conversion script.
% Revised by Kayhan Ulgen, 1/4/2024 - Added Apogee IR Sensor conversion script
% Revised by Miles A. Sundermeyer, 1/6/2024 - Added AQMesh script; added file identifyer info under DPL conversion section
% Revised by Kayhan Ulgen, 2/15/2024 - Added Ambilabs conversion script.
% Revised by Steven Lohrenz, 8/29/2024 - Added options for selecting sensors by commenting out lines
% Revised by Miles A. Sundermeyer, 11/2/2024 included try/catch error reporting for all sensors, corrected some for/end loops,
%		eliminated redundancy in conditional reprocesssomeFlag, reprocessallFlag and standard convert
% Revised by Tyler Knapp, 12/31/24 - Changed DPL check for files already processed to use the same scheme as DPL_csv2mat
% Revised by Tyler Knapp, 01/07/2025 - Adjusted reprocessing checks to account for longer file extension (.json & .xlsx)
% Revised by Tyler Knapp, 05/01/2025 - Now uses universal raw2mat function, sorted sensors A-Z
% Revised by Tyler Knapp, 06/24/2025 - Added 'processAll' flag to process any and all non-processed files
% Revised bu Tyler Knapp, 06/24/2025 - Added RainwsieMKIII dataStream
% ------------- BEGIN CODE --------------%% 
clear
Version = 'MWBL_data_csv2mat, 06/24/2025';
disp([Version, ' is running']);
baseDir = '/usr2/MWBL/Data/';
% baseDir = '/mnt/MWBL/Data/';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
flags.reprocessAll = 0; % reprocess all files: 1 = yes, 0 = no(only files not processed)  
flags.reprocessSome = 0; % reprocess files for given date range below
flags.processAll = 1; % process all files that haven't been processed yet

dt_format='MM-dd-yyyy HH:mm:ss';
startDate = datetime('08-01-2021 00:00:00','InputFormat',dt_format);	% e.g., '12-31-2022 23:59:00';
endDate = datetime('09-27-2025 00:00:00','InputFormat',dt_format);	% e.g., '12-31-2022 23:59:00';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set which data sets to run (0 = do not run, 1 = run)
flags.ApogeeFlag  = 1;
flags.AmbilabsFlag = 1;
flags.AQMeshFlag = 1;
flags.ATIFlag = 1;
flags.DataQFlag = 1;
flags.DELTAFlag = 1;
flags.DPLFlag = 1;
flags.EcotechFlag = 1;
flags.EPA_PM25Flag = 1;
flags.GillFlag = 1;
flags.NBAirportFlag = 1;
flags.NOAAFlag = 1;
flags.OnsetHOBOFlag = 1;
flags.RainwisePortLogFlag = 1;
flags.ScintFlag = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Comment out below to include in processing
% flags.ApogeeFlag  = 0;
% flags.AmbilabsFlag = 0;
% flags.AQMeshFlag = 0;
flags.ATIFlag = 0;
flags.DataQFlag = 0;
flags.DELTAFlag = 0;
flags.DPLFlag = 0;
% flags.EcotechFlag = 0;
flags.EPA_PM25Flag = 0;
flags.GillFlag = 0;
% flags.NBAirportFlag = 0;
flags.NOAAFlag = 0;
% flags.OnsetHOBOFlag = 0;
flags.RainwisePortLogFlag = 0;
flags.ScintFlag = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
failedList = raw2mat(startDate, endDate, flags);

if failedList == ""
  disp('All Matlab files converted!');
else
  disp('Done converting files, but the following files failed to convert:')
  disp(failedList');
  save([baseDir,'failedList.mat'],'failedList');
end

%------------- END OF CODE --------------%
