% For plotting recently collected data from Aerosol sensors:
%
% EPA_PM25, Ecotech Nephelometer, Ambilabs AQMesh pods
%
% Written by Miles A. Sundermeyer, 1/7/2024
% Last modified by Miles A. Sundermeyer, 8/13/2024; unified start and end time rather than individual times per variable

%close all

if(1)
  set(0,'DefaultAxesFontName','Times');
  set(0,'DefaultAxesFontSize',12);
  set(0,'DefaultAxesFontWeight','bold');
  set(0,'DefaultAxesLineWidth',1.5);
  set(0,'DefaultLineLineWidth',1.5);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set period to load and plot
%starttime = datetime(2025,01,01);
starttime = datetime(2023,12,23);
endtime = datetime(2025,10,01);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load some data
% EPA_PM25_Narr = get_MWBL_data(starttime,endtime,'EPA_PM25','Narragansett');
% EPA_PM25_Fall = get_MWBL_data(starttime,endtime,'EPA_PM25','FallRiver');

AQMesh0 = get_MWBL_data(starttime,endtime,'AQMesh','2451070');
AQMesh1 = get_MWBL_data(starttime,endtime,'AQMesh','2451071');

% Ecotech_M9003 = get_MWBL_data(starttime,endtime,'Ecotech_M9003',[]);
Ambilabs_2WIN = get_MWBL_data(starttime,endtime,'Ambilabs_2WIN',[]);

Apogee0 = get_MWBL_data(starttime,endtime,'Apogee','3238');
Apogee1 = get_MWBL_data(starttime,endtime,'Apogee','3239');

Portlog_SMAST = get_MWBL_data(starttime,endtime,'RainwisePortLog','SMAST');
% Portlog_CBC = get_MWBL_data(starttime,endtime,'RainwisePortlog','CBC');
NBAirport = get_MWBL_data(starttime,endtime,'NBAirport',[]);
OnsetHOBO_SMAST = get_MWBL_data(starttime,endtime,'OnsetHOBO','SMAST');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure(1)
clf
%subplot(2,1,1)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
yyaxis right
set(gca,'YColor','k')
% plot(Ecotech_M9003.date_time,Ecotech_M9003.sigma_sp,'LineStyle','-','Color','k')	% scattering coefficient (cm^-1)
hold on
% plot(Ambilabs_2WIN.date_time,Ambilabs_2WIN.sigma_sp,'LineStyle','-','Color','b')
plot(Ambilabs_2WIN.date_time,Ambilabs_2WIN.PM25,'LineStyle','-','Color','b')

ylim([0 120])
%ylim([1e0 1e3])
%set(gca,'yscale','log')

ylabel('Scattering Coefficient (cm^{-1})')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
yyaxis left
set(gca,'YColor','k')
%plot(EPA_PM25_Narr.date_time,EPA_PM25_Narr.PM25,'LineStyle','-','Color','b')
%plot(EPA_PM25_Fall.date_time,EPA_PM25_Fall.PM25,'LineStyle','-','Color','g')

plot(AQMesh0.date_time,AQMesh0.PM1Scaled,'Marker','none','LineStyle','-','Color','b')
plot(AQMesh1.date_time,AQMesh1.PM1Scaled,'Marker','none','LineStyle','-','Color','c')

plot(AQMesh0.date_time,AQMesh0.PM25Scaled,'Marker','none','LineStyle','-','Color','r')
plot(AQMesh1.date_time,AQMesh1.PM25Scaled,'Marker','none','LineStyle','-','Color','m')

plot(AQMesh0.date_time,AQMesh0.PM4Scaled,'Marker','none','LineStyle','-','Color',0.7*[1 0 0])
plot(AQMesh1.date_time,AQMesh1.PM4Scaled,'Marker','none','LineStyle','-','Color',0.7*[0 1 0])

plot(AQMesh0.date_time,AQMesh0.PM10Scaled,'Marker','none','LineStyle','-','Color',0.7*[0 0 1])
plot(AQMesh1.date_time,AQMesh1.PM10Scaled,'Marker','none','LineStyle','-','Color',0.7*[1 1 0])

ylim([0 60])
xlabel('Time (UTC)')
ylabel('Particle Concentration (\mug/m^3)')

legend('Ecotech M9003 2.5\mum', 'Ambilabs 2WIN', 'AQMesh-0 1\mum', 'AQMesh-1 1\mum', 'AQMesh-0 2.5\mum', 'AQMesh-1 2.5\mum', 'AQMesh-0 4\mum', 'AQMesh-1 4\mum', 'AQMesh-0 10\mum', 'AQMesh-1 10\mum','AutoUpdate','off','Location','NorthEast','NumColumns',2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure(2)
clf
%subplot(2,1,1)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
yyaxis left
set(gca,'YColor','k')
plot(AQMesh0.date_time,AQMesh0.COScaled,'Marker','none','LineStyle','-','Color','b')
hold on
plot(AQMesh1.date_time,AQMesh1.COScaled,'Marker','none','LineStyle','-','Color','c')

plot(AQMesh0.date_time,AQMesh0.CO2Scaled,'Marker','none','LineStyle','-','Color','r')
plot(AQMesh1.date_time,AQMesh1.CO2Scaled,'Marker','none','LineStyle','-','Color','m')

if(1)		% WARNING - THIS IS TO TEMPORARILY FILL A GAP WHERE ONE SHOULD NOT EXIST FOR APRIL 2025
  thisind0 = find(AQMesh0.date_time>=datetime(2025,03,01) & AQMesh0.date_time<=datetime(2025,04,01));
  thisind1 = find(AQMesh1.date_time>=datetime(2025,03,01) & AQMesh1.date_time<=datetime(2025,04,01));
  plot(AQMesh0.date_time(thisind0)+days(30),AQMesh0.COScaled(thisind0),'Marker','none','LineStyle','-','Color','b')
  hold on
  plot(AQMesh1.date_time(thisind1)+days(30),AQMesh1.COScaled(thisind1),'Marker','none','LineStyle','-','Color','c')

  plot(AQMesh0.date_time(thisind0)+days(30),AQMesh0.CO2Scaled(thisind0),'Marker','none','LineStyle','-','Color','r')
  plot(AQMesh1.date_time(thisind1)+days(30),AQMesh1.CO2Scaled(thisind1),'Marker','none','LineStyle','-','Color','m')
end

ylim([0 1150])
ylim([200 1300])
ylabel('Gas Concentration (CO, CO2, \mug/m^3)')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
yyaxis right
set(gca,'YColor','k')

plot(AQMesh0.date_time,AQMesh0.NOScaled,'Marker','none','LineStyle','-','Color',0.7*[1 0 0])
plot(AQMesh1.date_time,AQMesh1.NOScaled,'Marker','none','LineStyle','-','Color',0.7*[0 1 0])

plot(AQMesh0.date_time,AQMesh0.NO2Scaled,'Marker','none','LineStyle','-','Color',0.7*[0 0 1])
plot(AQMesh1.date_time,AQMesh1.NO2Scaled,'Marker','none','LineStyle','-','Color',0.7*[1 1 0])

plot(AQMesh0.date_time,AQMesh0.NOxScaled,'Marker','none','LineStyle','-','Color',0.7*[0 1 1])
plot(AQMesh1.date_time,AQMesh1.NOxScaled,'Marker','none','LineStyle','-','Color',0.7*[1 0 1])

plot(AQMesh0.date_time,AQMesh0.O3Scaled,'Marker','none','LineStyle','-','Color',0.4*[1 0 0])
plot(AQMesh1.date_time,AQMesh1.O3Scaled,'Marker','none','LineStyle','-','Color',0.4*[0 1 0])

plot(AQMesh0.date_time,AQMesh0.SO2Scaled,'Marker','none','LineStyle','-','Color',0.4*[0 0 1])
plot(AQMesh1.date_time,AQMesh1.SO2Scaled,'Marker','none','LineStyle','-','Color',0.4*[1 1 0])

if(1)		% WARNING - THIS IS TO TEMPORARILY FILL A GAP WHERE ONE SHOULD NOT EXIST FOR APRIL 2025
  plot(AQMesh0.date_time(thisind0)+days(30),AQMesh0.NOScaled(thisind0),'Marker','none','LineStyle','-','Color',0.7*[1 0 0])
  plot(AQMesh1.date_time(thisind1)+days(30),AQMesh1.NOScaled(thisind1),'Marker','none','LineStyle','-','Color',0.7*[0 1 0])
  
  plot(AQMesh0.date_time(thisind0)+days(30),AQMesh0.NO2Scaled(thisind0),'Marker','none','LineStyle','-','Color',0.7*[0 0 1])
  plot(AQMesh1.date_time(thisind1)+days(30),AQMesh1.NO2Scaled(thisind1),'Marker','none','LineStyle','-','Color',0.7*[1 1 0])
  
  plot(AQMesh0.date_time(thisind0)+days(30),AQMesh0.NOxScaled(thisind0),'Marker','none','LineStyle','-','Color',0.7*[0 1 1])
  plot(AQMesh1.date_time(thisind1)+days(30),AQMesh1.NOxScaled(thisind1),'Marker','none','LineStyle','-','Color',0.7*[1 0 1])
  
  plot(AQMesh0.date_time(thisind0)+days(30),AQMesh0.O3Scaled(thisind0),'Marker','none','LineStyle','-','Color',0.4*[1 0 0])
  plot(AQMesh1.date_time(thisind1)+days(30),AQMesh1.O3Scaled(thisind1),'Marker','none','LineStyle','-','Color',0.4*[0 1 0])
  
  plot(AQMesh0.date_time(thisind0)+days(30),AQMesh0.SO2Scaled(thisind0),'Marker','none','LineStyle','-','Color',0.4*[0 0 1])
  plot(AQMesh1.date_time(thisind1)+days(30),AQMesh1.SO2Scaled(thisind1),'Marker','none','LineStyle','-','Color',0.4*[1 1 0])

end

ylim([0 120])

xlabel('Time (UTC)')
ylabel('Gas Concentration (NO_x, O_3, SO_2, \mug/m^3)')

legend('AQMesh-0 CO', 'AQMesh-1 CO', 'AQMesh-0 CO_2', 'AQMesh-1 CO_2', 'AQMesh-0 NO', 'AQMesh-1 NO', 'AQMesh-0 NO2', 'AQMesh-1 NO2','AQMesh-0 NO_x','AQMesh-1 NO_x','AQMesh-0 O_3','AQMesh-1 O_3','AQMesh-0 SO_2','AQMesh-1 SO_2','AutoUpdate','off','Location','NorthEast','NumColumns',4);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure(3)
clf
%subplot(2,1,1)

plot(Portlog_SMAST.date_time,Portlog_SMAST.T_Air,'Marker','none','LineStyle','-','Color','k')
hold on

plot(Apogee0.date_time,Apogee0.T_Sensor,'Marker','none','LineStyle','-','Color','r')
plot(Apogee1.date_time,Apogee1.T_Sensor,'Marker','none','LineStyle','-','Color','m')

plot(OnsetHOBO_SMAST.date_time,OnsetHOBO_SMAST.T_Water,'Marker','none','LineStyle','-','Color','b')

plot(Apogee0.date_time,Apogee0.T_Water,'Marker','none','LineStyle','-','Color','c')
plot(Apogee1.date_time,Apogee1.T_Water,'Marker','none','LineStyle','-','Color','g')

xlabel('Time (UTC)')
ylim([-10 30])
ylabel('Air and Water Temperature (^oC)')

legend('RainWise Portlog T_{air}', 'Apogee-0 T_{air}', 'Apogee-1 T_{air}', 'OnsetHOBO T_{water}', 'Apogee-0 T_{water}', 'Apogee-1 T_{water}', 'AutoUpdate','off','Location','SouthEast','NumColumns',2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for n=1:3
  figure(n)

  %set(gcf,'position',[n*20*[1 -1]+[500 350] 1120 700])
  set(gcf,'position',[n*20*[1 -1]+[500 350] 1270 270])

  %xlim([datetime(2024,03,01,00,00,00), datetime(2024,05,06)])
  xlim([starttime endtime])
  print('-djpeg',['plot_aerosol_2025_',num2str(n)])
end


if(0)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  figure(2)
  clf
  %subplot(2,1,1)

  plot(Portlog_SMAST.date_time,Portlog_SMAST.RelHumid,'b')
  hold on
  plot(Portlog_CBC.date_time,Portlog_CBC.RelHumid,'c')
  plot(NBAirport.date_time,NBAirport.RelHumid,'k')

  xlim([datetime(2024,03,01,00,00,00), datetime(2024,05,06)])

  plot(Portlog_SMAST.date_time,Portlog_SMAST.Precip,'b')
  hold on
  plot(Portlog_CBC.date_time,Portlog_CBC.Precip,'c')
  plot(NBAirport.date_time,NBAirport.Precip,'k')
end


