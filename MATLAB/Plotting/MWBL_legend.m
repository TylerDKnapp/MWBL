function MWBL_legend(cset,Sensors,SensorList)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function MWBL_legend(cset,Sensors,SensorList)
%
% Function to set legend colors according to cset color scheme and draw legend 
% based on SensorList and master list of Sensors
%
% Written by Miles A. Sundermeyer, 9/22/2023
% Modified by Tyler Knapp, 01/24/2025 - Adding individual variables for Apogee sensors 3238/3239
% Modified by Tyler Knapp, 02/21/2025 - Fixed typo in "KZSintilometer" to "KZScintilometer". Restores legend title
% Modified by Tyler Knapp, 09/24/2025 - Adding seperate DataQ variables

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate empty line objects for all the different colors in cset variable
Lset.PortLog_SMAST = plot([NaT NaT],[nan nan],'-','color',cset.PortLog_SMAST);
hold on
Lset.PortLog_CBC = plot([NaT NaT],[nan nan],'-','color',cset.PortLog_CBC);

Lset.Gill_SMAST = plot([NaT NaT],[nan nan],'-','color',cset.Gill_SMAST);
Lset.ATI_SMAST = plot([NaT NaT],[nan nan],'-','color',cset.ATI_SMAST);
Lset.DataQ_SMAST = plot([NaT NaT],[nan nan],'-','color',cset.DataQ_SMAST);
Lset.Young_SMAST = plot([NaT NaT],[nan nan],'-','color',cset.Young_SMAST);
Lset.HMP60_SMAST_Upr = plot([NaT NaT],[nan nan],'-','color',cset.HMP60_SMAST_Upr);
Lset.HMP60_SMAST_Lwr = plot([NaT NaT],[nan nan],'-','color',cset.HMP60_SMAST_Lwr);
Lset.Pyrano_SMAST = plot([NaT NaT],[nan nan],'-','color',cset.Pyrano_SMAST);
Lset.NetRad_SMAST = plot([NaT NaT],[nan nan],'-','color',cset.NetRad_SMAST);

Lset.ATI_CBC = plot([NaT NaT],[nan nan],'-','color',cset.ATI_CBC);
Lset.DataQ_CBC = plot([NaT NaT],[nan nan],'-','color',cset.DataQ_CBC);
Lset.Young_CBC = plot([NaT NaT],[nan nan],'-','color',cset.Young_CBC);
Lset.HMP60_CBC = plot([NaT NaT],[nan nan],'-','color',cset.HMP60_CBC);
Lset.Pyrano_CBC = plot([NaT NaT],[nan nan],'-','color',cset.Pyrano_CBC);
Lset.NetRad_CBC = plot([NaT NaT],[nan nan],'-','color',cset.NetRad_CBC);

Lset.DPL_SMAST1 = plot([NaT NaT],[nan nan],'-','color',cset.DPL_SMAST{1});
Lset.DPL_SMAST2 = plot([NaT NaT],[nan nan],'-','color',cset.DPL_SMAST{2});
Lset.DPL_SMAST3 = plot([NaT NaT],[nan nan],'-','color',cset.DPL_SMAST{3});
Lset.DPL_SMAST4 = plot([NaT NaT],[nan nan],'-','color',cset.DPL_SMAST{4});
Lset.DPL_SMAST5 = plot([NaT NaT],[nan nan],'-','color',cset.DPL_SMAST{5});

Lset.DPL_CBC1 = plot([NaT NaT],[nan nan],'-','color',cset.DPL_CBC{1});
Lset.DPL_CBC2 = plot([NaT NaT],[nan nan],'-','color',cset.DPL_CBC{2});
Lset.DPL_CBC3 = plot([NaT NaT],[nan nan],'-','color',cset.DPL_CBC{3});
Lset.DPL_CBC4 = plot([NaT NaT],[nan nan],'-','color',cset.DPL_CBC{4});
% Lset.DPL_CBC5 = plot([NaT NaT],[nan nan],'-','color',cset.DPL_CBC{5});

Lset.HOBO_SMAST = plot([NaT NaT],[nan nan],'-','color',cset.HOBO_SMAST);
Lset.HOBO_CBC = plot([NaT NaT],[nan nan],'-','color',cset.HOBO_CBC);

Lset.KZScintillometer = plot([NaT NaT],[nan nan],'-','color',cset.KZScintillometer);

Lset.NBA = plot([NaT NaT],[nan nan],'-','color',cset.NBAirport);

Lset.Ecotech_M9003 = plot([NaT NaT],[nan nan],'-','color',cset.Ecotech_M9003);
Lset.Ambilabs_2WIN = plot([NaT NaT],[nan nan],'-','color',cset.Ambilabs_2WIN);
Lset.Apogee_3238 = plot([NaT NaT],[nan nan],'-','color',cset.Apogee_3238);
Lset.Apogee_3239 = plot([NaT NaT],[nan nan],'-','color',cset.Apogee_3239);
Lset.AQMesh_2451070 = plot([NaT NaT],[nan nan],'-','color',cset.AQMesh_2451070);
Lset.AQMesh_2451071 = plot([NaT NaT],[nan nan],'-','color',cset.AQMesh_2451071);
Lset.EPA_PM25 = plot([NaT NaT],[nan nan],'-','color',cset.EPA_PM25);
Lset.NOAA_WaterT = plot([NaT NaT],[nan nan],'-','color',cset.NOAA_WaterT);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Build legend arguments to go with just the sensors we set to load and plot
% Loop through SensorList and build legend arguments
LList = [];		% array of Lset line object handles to use for legend line types
LLabels = {};		% cell array of character arrays to use for legend labels

% Do the following the long way just to be sure we have everything in the order intended
% Probably a better way to do this, but I don't feel like thinking / spending time on it
for n=1:length(SensorList)
  if SensorList(n) > 0
    if strcmp(Sensors.name(SensorList(n)),'PortLog_SMAST')
      LList(length(LList)+1) = Lset.PortLog_SMAST;
      LLabels(length(LLabels)+1) = Sensors.name(SensorList(n)); 
    elseif strcmp(Sensors.name(SensorList(n)),'PortLog_CBC')
      LList(length(LList)+1) = Lset.PortLog_CBC;
      LLabels(length(LLabels)+1) = Sensors.name(SensorList(n));
    elseif strcmp(Sensors.name(SensorList(n)),'ATI_SMAST')
      LList(length(LList)+1) = Lset.ATI_SMAST;
      LLabels(length(LLabels)+1) = Sensors.name(SensorList(n));
    elseif strcmp(Sensors.name(SensorList(n)),'Gill_SMAST')
      LList(length(LList)+1) = Lset.Gill_SMAST;
      LLabels(length(LLabels)+1) = Sensors.name(SensorList(n));
    elseif strcmp(Sensors.name(SensorList(n)),'DataQ_SMAST')
      LList(length(LList)+1) = Lset.DataQ_SMAST;
      LLabels(length(LLabels)+1) = Sensors.name(SensorList(n));
    elseif strcmp(Sensors.name(SensorList(n)),'ATI_CBC')
      LList(length(LList)+1) = Lset.ATI_CBC;
      LLabels(length(LLabels)+1) = Sensors.name(SensorList(n));
    elseif strcmp(Sensors.name(SensorList(n)),'HMP60_SMAST_Upr')
      LList(length(LList)+1) = Lset.HMP60_SMAST_Upr;
      LLabels(length(LLabels)+1) = Sensors.name(SensorList(n));
    elseif strcmp(Sensors.name(SensorList(n)),'HMP60_SMAST_Lwr')
      LList(length(LList)+1) = Lset.HMP60_SMAST_Lwr;
      LLabels(length(LLabels)+1) = Sensors.name(SensorList(n));
    elseif strcmp(Sensors.name(SensorList(n)),'Young_SMAST')
      LList(length(LList)+1) = Lset.Young_SMAST;
      LLabels(length(LLabels)+1) = Sensors.name(SensorList(n));
    elseif strcmp(Sensors.name(SensorList(n)),'Pyrano_SMAST')
      LList(length(LList)+1) = Lset.Pyrano_SMAST;
      LLabels(length(LLabels)+1) = Sensors.name(SensorList(n));
    elseif strcmp(Sensors.name(SensorList(n)),'NetRad_SMAST')
      LList(length(LList)+1) = Lset.NetRad_SMAST;
      LLabels(length(LLabels)+1) = Sensors.name(SensorList(n));
    elseif strcmp(Sensors.name(SensorList(n)),'DataQ_CBC')
      LList(length(LList)+1) = Lset.DataQ_CBC;
      LLabels(length(LLabels)+1) = Sensors.name(SensorList(n));
    elseif strcmp(Sensors.name(SensorList(n)),'HMP60_CBC')
      LList(length(LList)+1) = Lset.HMP60_CBC;
      LLabels(length(LLabels)+1) = Sensors.name(SensorList(n));
    elseif strcmp(Sensors.name(SensorList(n)),'Young_CBC')
      LList(length(LList)+1) = Lset.Young_CBC;
      LLabels(length(LLabels)+1) = Sensors.name(SensorList(n));
    elseif strcmp(Sensors.name(SensorList(n)),'Pyrano_CBC')
      LList(length(LList)+1) = Lset.Pyrano_CBC;
      LLabels(length(LLabels)+1) = Sensors.name(SensorList(n));
    elseif strcmp(Sensors.name(SensorList(n)),'NetRad_CBC')
      LList(length(LList)+1) = Lset.NetRad_CBC;
      LLabels(length(LLabels)+1) = Sensors.name(SensorList(n));
    elseif strcmp(Sensors.name(SensorList(n)),'DPL_SMAST')
      LList(length(LList)+1) = Lset.DPL_SMAST1;
      LList(length(LList)+1) = Lset.DPL_SMAST2;
      LList(length(LList)+1) = Lset.DPL_SMAST3;
      LList(length(LList)+1) = Lset.DPL_SMAST4;
      LList(length(LList)+1) = Lset.DPL_SMAST5;
  
      LLabels{length(LLabels)+1} = [Sensors.name{SensorList(n)},' H1'];
      LLabels{length(LLabels)+1} = [Sensors.name{SensorList(n)},' H2'];
      LLabels{length(LLabels)+1} = [Sensors.name{SensorList(n)},' H3'];
      LLabels{length(LLabels)+1} = [Sensors.name{SensorList(n)},' H4'];
      LLabels{length(LLabels)+1} = [Sensors.name{SensorList(n)},' H5'];
    elseif strcmp(Sensors.name(SensorList(n)),'DPL_CBC')
      LList(length(LList)+1) = Lset.DPL_CBC1;
      LList(length(LList)+1) = Lset.DPL_CBC2;
      LList(length(LList)+1) = Lset.DPL_CBC3;
      LList(length(LList)+1) = Lset.DPL_CBC4;
      % LList(length(LList)+1) = Lset.DPL_CBC5;
  
      LLabels{length(LLabels)+1} = [Sensors.name{SensorList(n)},' H1'];
      LLabels{length(LLabels)+1} = [Sensors.name{SensorList(n)},' H2'];
      LLabels{length(LLabels)+1} = [Sensors.name{SensorList(n)},' H3'];
      LLabels{length(LLabels)+1} = [Sensors.name{SensorList(n)},' H4'];
      % LLabels{length(LLabels)+1} = [Sensors.name{SensorList(n)},' H5'];
    elseif strcmp(Sensors.name(SensorList(n)),'HOBO_SMAST')
      LList(length(LList)+1) = Lset.HOBO_SMAST;
      LLabels(length(LLabels)+1) = Sensors.name(SensorList(n));
    elseif strcmp(Sensors.name(SensorList(n)),'HOBO_CBC')
      LList(length(LList)+1) = Lset.HOBO_CBC;
      LLabels(length(LLabels)+1) = Sensors.name(SensorList(n));
    elseif strcmp(Sensors.name(SensorList(n)),'KZScintillometer')
      LList(length(LList)+1) = Lset.KZScintillometer;
      LLabels(length(LLabels)+1) = Sensors.name(SensorList(n));
    elseif strcmp(Sensors.name(SensorList(n)),'NBAirport')
      LList(length(LList)+1) = Lset.NBA;
      LLabels(length(LLabels)+1) = Sensors.name(SensorList(n));
    elseif strcmp(Sensors.name(SensorList(n)),'Ambilabs_2WIN')
      LList(length(LList)+1) = Lset.Ambilabs_2WIN;
      LLabels(length(LLabels)+1) = Sensors.name(SensorList(n));
    elseif strcmp(Sensors.name(SensorList(n)),'Ecotech_M9003')
      LList(length(LList)+1) = Lset.Ecotech_M9003;
      LLabels(length(LLabels)+1) = Sensors.name(SensorList(n));
    elseif strcmp(Sensors.name(SensorList(n)),'Apogee_3238')
      LList(length(LList)+1) = Lset.Apogee_3238;
      LLabels(length(LLabels)+1) = Sensors.name(SensorList(n));
    elseif strcmp(Sensors.name(SensorList(n)),'Apogee_3239')
      LList(length(LList)+1) = Lset.Apogee_3239;
      LLabels(length(LLabels)+1) = Sensors.name(SensorList(n));
    elseif strcmp(Sensors.name(SensorList(n)),'AQMesh_2451070')
      LList(length(LList)+1) = Lset.AQMesh_2451070;
      LLabels(length(LLabels)+1) = Sensors.name(SensorList(n));
    elseif strcmp(Sensors.name(SensorList(n)),'AQMesh_2451071')
      LList(length(LList)+1) = Lset.AQMesh_2451071;
      LLabels(length(LLabels)+1) = Sensors.name(SensorList(n));
    elseif strcmp(Sensors.name(SensorList(n)),'EPA_PM25')
      LList(length(LList)+1) = Lset.EPA_PM25;
      LLabels(length(LLabels)+1) = Sensors.name(SensorList(n));
    elseif strcmp(Sensors.name(SensorList(n)),'NOAA_WaterT')
      LList(length(LList)+1) = Lset.NOAA_WaterT;
      LLabels(length(LLabels)+1) = {'NOAA Fall River'};
    end
  end
end % End n loop


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Draw the legend (replacing underscores with spaces in legend labels)
legend(LList,strrep(LLabels,'_',' '),'AutoUpdate','off','Orientation','Vertical','Location','NorthEast','NumColumns',2)
