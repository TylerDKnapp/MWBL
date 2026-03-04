function [cset, sHt] = MWBL_plot_const()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                          % Baseline Heights %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Per RTK GPS measurements, the deck of the SMAST pier @ location of tower is 2.86 m (NAVD88)
  % Mean high water (MHW) is 0.78 m, and mean low water (MLW) is -0.30 m (NAVD88).
  SMAST_Pier = 2.84;    % (m NAVD88) SMAST pier, average of landward end, seaward end, tower (TDK 01/16/2025)
  CBC_Jetty = 2.30;		      % (m NAVD88) Concrete of CBC jetty next to MWBL tower/HOBO (TDK 09/24/2025)
  CBC_Lattice_Base = 1.55;  % (m NAVD88) CBC lattice west base plate (TDK 09/24/2025)
  CBC_Lattice_Plat = 4.21;  % (m NAVD88) Top of scint. platform on CBC lattice (TDK 09/24/2025)
  MHW = 0.78;		            % (m NAVD88) per pier As-Built plans, dated 4/9/2007
  MLW = -0.30;		          % (m NAVD88) per pier As-Built plans, dated 4/9/2007
  SeaLevel_offset_SMAST = SMAST_Pier - (MHW+MLW)/2;		% add this to sensorAQMesh_2451071 heights to get height above MSL
  SeaLevel_offset_CBC_Jetty = CBC_Jetty - (MHW+MLW)/2;		% add this to sensor heights to get height above MSL
  SeaLevel_offset_CBC_Lattice_Base = CBC_Lattice_Base - (MHW+MLW)/2;		% add this to sensor heights to get height above MSL
  SeaLevel_offset_CBC_Lattice_Plat = CBC_Lattice_Plat - (MHW+MLW)/2;		% add this to sensor heights to get height above MSL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % set colors for plotting different height sensors
  nColors = 25;
  ColorSet = jet(nColors);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                           % Sensor Heights %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % For wind velocity sensors, interpolate colors onto sensor heights
  scaleHt = 12;		% (m NAVD88)
  % Set sensor heights for each of the sensors
  % SMAST Lattice
  sHt.Gill_SMAST = SeaLevel_offset_SMAST - 0.84; % (m) TDK 09/26/2025
  sHt.ATI_SMAST = SeaLevel_offset_SMAST + 2.56; % (m) TDK 09/26/2025
  sHt.Young_SMAST = SeaLevel_offset_SMAST + 0.82;	% (m) TDK 09/26/2025
  sHt.HMP60_SMAST_Upr = SeaLevel_offset_SMAST + 2.76; % (m) TDK 09/26/2025
  sHt.HMP60_SMAST_Lwr = SeaLevel_offset_SMAST - 0.16; % (m) TDK 09/26/2025
  sHt.NedRad_SMAST = SeaLevel_offset_SMAST + 2.74; % (m) TDK 09/26/2025
  sHt.Pyr_SMAST = SeaLevel_offset_SMAST + 2.92; % (m) TDK 09/26/2025
  % CBC Lattice
  sHt.ATI_CBC = SeaLevel_offset_CBC_Lattice_Plat + 0.575; % (m) TDK 09/24/2025
  sHt.Young_CBC = SeaLevel_offset_CBC_Lattice_Base + 1.00; % (m) TDK 09/24/2025
  sHt.HMP60_CBC = SeaLevel_offset_CBC_Lattice_Plat + 0.575; % (m) TDK 09/24/2025
  sHt.NedRad_CBC = SeaLevel_offset_CBC_Lattice_Plat + 0.51; % (m) TDK 09/24/2025
  sHt.Pyr_CBC = SeaLevel_offset_CBC_Lattice_Plat + 1.10; % (m) TDK 09/24/2025
  % SMAST Tower
  sHt.DPL_SMAST1 = SeaLevel_offset_SMAST + 2.03;
  sHt.DPL_SMAST2 = SeaLevel_offset_SMAST + 3.78;
  sHt.DPL_SMAST3 = SeaLevel_offset_SMAST + 5.54;
  sHt.DPL_SMAST4 = SeaLevel_offset_SMAST + 7.29;
  sHt.DPL_SMAST5 = SeaLevel_offset_SMAST + 9.04;
  % CBC Tower
  sHt.DPL_CBC1 = SeaLevel_offset_CBC_Jetty + 3.73; % TDK 07/2025
  sHt.DPL_CBC2 = SeaLevel_offset_CBC_Jetty + 5.49;
  sHt.DPL_CBC3 = SeaLevel_offset_CBC_Jetty + 7.24;
  sHt.DPL_CBC4 = SeaLevel_offset_CBC_Jetty + 8.99;
  % sHt.DPL_CBC5 = SeaLevel_offset_CBC_Jetty + 9.04; % Only 4 sensors on CBC Tower
  % Test Rack aligned to SMAST Tower Heights
  sHt.DPL_SMAST_TESTRACK1 = SeaLevel_offset_SMAST + 2.03;
  sHt.DPL_SMAST_TESTRACK2 = SeaLevel_offset_SMAST + 3.78;
  sHt.DPL_SMAST_TESTRACK3 = SeaLevel_offset_SMAST + 5.54;
  sHt.DPL_SMAST_TESTRACK4 = SeaLevel_offset_SMAST + 7.29;
  sHt.DPL_SMAST_TESTRACK5 = SeaLevel_offset_SMAST + 9.04;
  % PortLog(s)
  sHt.PortLog_SMAST = 4.99; % (m) TDK 09/26/2025
  sHt.PortLog_CBC = SeaLevel_offset_CBC_Jetty + 1.6;	% this just a wild guess, assuming same as SMAST (?)
  % HOBO(s)
  sHt.HOBO_SMAST = 3.70; % (m) TDK 09/26/2025
  sHt.HOBO_CBC = 2.29; % (m) TDK 09/24/2025
  % AQMesh(s)
  sHt.AQMesh_2451070 = 3.59; % (m) TDK 09/26/2025
  sHt.AQMesh_2451071 = 3.60 + 1; % Add 1 to offset colors
  % Scintillometer
  sHt.KZS = SeaLevel_offset_SMAST + 4.0;		% this just a wild guess
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                           % Sensor Colors %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Set line colors based on sensor heights if sensor measures wind speed
  % SMAST Lattice
  cset.Gill_SMAST = ColorSet(ceil(sHt.Gill_SMAST/scaleHt*nColors),:);
  cset.ATI_SMAST = ColorSet(ceil(sHt.ATI_SMAST/scaleHt*nColors),:);
  cset.Young_SMAST = [1 0 0]; %ColorSet(ceil(sHt.Young_SMAST/scaleHt*nColors),:);
  cset.HMP60_SMAST_Upr = ColorSet(ceil(sHt.HMP60_SMAST_Upr/scaleHt*nColors),:);
  cset.HMP60_SMAST_Lwr = ColorSet(ceil(sHt.HMP60_SMAST_Lwr/scaleHt*nColors),:);
  cset.Pyrano_SMAST = [0.5 0 0.5];
  cset.NetRad_SMAST = [1 0 1];
  % CBC Lattice
  cset.ATI_CBC = ColorSet(ceil(sHt.ATI_CBC/scaleHt*nColors),:);
  cset.Young_CBC = [0 0 1]; %ColorSet(ceil(sHt.Young_CBC/scaleHt*nColors),:);
  cset.HMP60_CBC = ColorSet(ceil(sHt.HMP60_CBC/scaleHt*nColors),:);
  cset.Pyrano_CBC = [0 0.5 0.5];
  cset.NetRad_CBC = [0 1 1];
  % SMAST Tower
  cset.DPL_SMAST{1} = ColorSet(ceil(sHt.DPL_SMAST1/scaleHt*nColors),:);
  cset.DPL_SMAST{2} = ColorSet(ceil(sHt.DPL_SMAST2/scaleHt*nColors),:);
  cset.DPL_SMAST{3} = ColorSet(ceil(sHt.DPL_SMAST3/scaleHt*nColors),:);
  cset.DPL_SMAST{4} = ColorSet(ceil(sHt.DPL_SMAST4/scaleHt*nColors),:);
  cset.DPL_SMAST{5} = ColorSet(ceil(sHt.DPL_SMAST5/scaleHt*nColors),:);
  % CBC Tower
  cset.DPL_CBC{1} = ColorSet(ceil(sHt.DPL_SMAST1/scaleHt*nColors),:);
  cset.DPL_CBC{2} = ColorSet(ceil(sHt.DPL_SMAST2/scaleHt*nColors),:);
  cset.DPL_CBC{3} = ColorSet(ceil(sHt.DPL_SMAST3/scaleHt*nColors),:);
  cset.DPL_CBC{4} = ColorSet(ceil(sHt.DPL_SMAST4/scaleHt*nColors),:);
  % cset.DPL_CBC{5} = ColorSet(ceil(sHt.DPL_SMAST5/scaleHt*nColors),:);
  % Test Rack aligned to SMAST Tower Colors
  cset.DPL_SMAST_TESTRACK{1} = ColorSet(ceil(sHt.DPL_SMAST1/scaleHt*nColors),:);
  cset.DPL_SMAST_TESTRACK{2} = ColorSet(ceil(sHt.DPL_SMAST2/scaleHt*nColors),:);
  cset.DPL_SMAST_TESTRACK{3} = ColorSet(ceil(sHt.DPL_SMAST3/scaleHt*nColors),:);
  cset.DPL_SMAST_TESTRACK{4} = ColorSet(ceil(sHt.DPL_SMAST4/scaleHt*nColors),:);
  cset.DPL_SMAST_TESTRACK{5} = ColorSet(ceil(sHt.DPL_SMAST5/scaleHt*nColors),:);
  % PortLog(s)
  cset.PortLog_SMAST = [0 0.5 0]; %ColorSet(ceil(sHt.PortLog_SMAST/scaleHt*nColors),:);
  cset.PortLog_CBC = ColorSet(ceil(sHt.PortLog_CBC/scaleHt*nColors),:);
  % HOBO(s)
  cset.HOBO_SMAST = [0 0 1]; % ColorSet(ceil(sHt.HOBO_SMAST/scaleHt*nColors),:);
  cset.HOBO_CBC = [1 0 1]; % ColorSet(ceil(sHt.HOBO_CBC/scaleHt*nColors),:);
  % DataQ(s)
  cset.DataQ_SMAST = [1 0 0.5];
  cset.DataQ_CBC = [1 0.5 0.5];
  % Nephlometer(s)
  cset.Ecotech_M9003 = [1 0 1];
  cset.Ambilabs_2WIN = [1 0.75 0]; % ColorSet(ceil(sHt.Ambilabs_2WIN/scaleHt*nColors),:);
  % Apogee(s)
  cset.Apogee_3238 = [1 0 0];
  cset.Apogee_3239 = [0 1 0];
  % AQMesh(s)
  cset.AQMesh_2451070 = [0 0.75 0.5]; ColorSet(ceil(sHt.AQMesh_2451070/scaleHt*nColors),:);
  cset.AQMesh_2451071 = [0 0.75 1]; ColorSet(ceil(sHt.AQMesh_2451071/scaleHt*nColors),:);
  % Baseline data, make black
  cset.KZScintillometer = [0 0 0];
  cset.NBAirport = [0 0 0];
  cset.EPA_PM25 = [0 0 0];
  cset.NOAA_WaterT = [0 0 0];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end