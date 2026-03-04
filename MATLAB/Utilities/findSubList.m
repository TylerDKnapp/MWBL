% SensorSubList = findSubList(Sensors,SensorList,variable_name)
% Called as a script, not a function, so as to have access to full data sets in workspace
%
% For finding which sensors have a given variable available for plotting.
% Result should be the SensorSubList of data streams that have the variable given by variable_name
% To be used with plot_baseline_sensors and MWBL_legend functions
%
% Written by Miles A. Sundermeyer, 10/25/2023
% Modified by Tyler Knapp, 09/30/2025 - Adding check for alt and alt2 variable names
% Modified by Tyler Knapp, 12/19/2025 - Adding check for empty tmp and tmp2 variables
SensorSubList = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for nnnnmmmm=1:length(SensorList)
  clear tmp tmp2
  % make a tmp copy of the data stream in question
  eval(['tmp =',Sensors.name{SensorList(nnnnmmmm)},';']);
  try
    eval(['tmp2 =',Sensors.name{SensorList(nnnnmmmm)},'_turbulenceData;']); 
  catch
    tmp2 = struct([]);
  end
  if ~isempty(tmp) || ~isempty(tmp2)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % exclude WindSpd for MZA_DELTA ONLY
    if strcmp(Sensors.name{SensorList(nnnnmmmm)},'MZA_DELTA') & strcmp(variable_name,'WindSpd')
      % Do nothing
  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % treat DPL differently - check field names, H1-H5
    elseif contains(Sensors.name{SensorList(nnnnmmmm)},'DPL')
      if isfield(tmp.H1,variable_name) || isfield(tmp.H2,variable_name) || ...
         isfield(tmp.H3,variable_name) || isfield(tmp.H4,variable_name) || ...
         isfield(tmp.H5,variable_name) || ... 
         isfield(tmp2.H1,variable_name_alt) || isfield(tmp2.H2,variable_name_alt) ||...
         isfield(tmp2.H3,variable_name_alt) || isfield(tmp2.H4,variable_name_alt) || ...
         isfield(tmp2.H5,variable_name_alt)
        SensorSubList = [SensorSubList SensorList(nnnnmmmm)];
      end
  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    else
      if isfield(tmp,variable_name) || isfield(tmp,variable_name_alt) || isfield(tmp,variable_name_alt2)|| isfield(tmp2,variable_name_alt)
        SensorSubList = [SensorSubList SensorList(nnnnmmmm)];
      end
    end
  end
end

clear tmp tmp2
