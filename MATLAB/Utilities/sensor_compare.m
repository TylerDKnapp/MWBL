% sensor_compare.m
% Syntax: sensor_compare
%
%Script to load truncated files and compare sensor plots
%
% Inputs:
%   none (run as script, not function)
%
% Outputs:
%    output - '*.tif' plot files with sensor comparisons
%   
% Directory paths (absolute or relative) for various raw MWBL data files are specified below.
%
% Additional .mat-files required to run this script:
%    - truncated files created with plot_timeseries_main.m
%
% Author: Steven E. Lohrenz, Ph.D., biological oceanography
% School for Marine Science and Technology, University of Massachusetts Dartmouth
% email address: slohrenz@umassd.edu
% Website: http://www.umassd.edu/smast/
% Revised by Steve Lohrenz, 24 July 2022
%

% ------------- BEGIN CODE --------------%% 

Version = 'sensor_compare, V1.0, 07/24/22';

clc
clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set paths to each of the data types, raw and processed (.mat) directories
userflag = 2;			% set directory path: 0 for OneDrive, 1 for MAS, 2 for SEL
reprocessallflag = 1;		% reprocess all files: 1 = yes, 0 = no

%Set initial and end dates for file processing
init_date='11/25/2022 0:00:00';
end_date='11/26/2022 12:00:00';
dt_format='MM/dd/uuuu HH:mm:ss';

% Set which data sets to run (0 = do not run, 1 = run)
Portlogflag = 0;
DataQflag = 0;
Gillflag = 1;
ATIflag = 1;
NBAirportflag = 0;
Scintflag = 0;
DELTAflag = 0;
DPLflag = 0;

% Filenames for truncated files
portfile='Portlog_13449_time_series_20221125-20221126.mat';
dataqfile='DataQ_time_series_20221125-20221126.mat';
gillfile='Gill_time_series_20221125-20221126.mat';
atifile='ATI_time_series_20221125-20221126.mat';
dplfile='DPL_time_series_20221125-20221126.mat';

% Set baseDir to location of data
if(userflag==0)
  baseDir = 'C:\Users\sunderm\OneDrive - University of Massachusetts Dartmouth\MWBL\Data\';
elseif(userflag==1)
  baseDir = 'H:\projects\2020-05-10 MWBL NP Photonics\Data\';
elseif(userflag==2)
  baseDir ='C:\Users\slohrenz\OneDrive - UMASS Dartmouth\MWBL\Data\';
end

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load truncated data files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Portlog
if Portlogflag
    % set directories for where data live
    if(userflag==0 || userflag==1 || userflag==2)
    inputDir = [baseDir,'RainwisePortlog\plots\'];
    outputDir = [baseDir,'RainwisePortlog\plots\'];
    end
    disp('Loading Portlog file...');
    load([inputDir,portfile]);
    disp('  Loaded.');
end

%DataQ
if DataQflag
    % set directories for where data live
    if(userflag==0 || userflag==1 || userflag==2)
    inputDir = [baseDir,'SMAST_Station1\DataQ\plots\'];
    outputDir = [baseDir,'SMAST_Station1\DataQ\plots\'];
    end
    disp('Loading DataQ file...');
    load([inputDir,dataqfile]);
    disp('  Loaded.');
end

%Gill
if Gillflag
    % set directories for where data live
    if(userflag==0 || userflag==1 || userflag==2)
    inputDir = [baseDir,'SMAST_Station1\Gill\plots\'];
    outputDir = [baseDir,'SMAST_Station1\Gill\plots\'];
    end
    disp('Loading Gill file...');
    load([inputDir,gillfile]);
    disp('  Loaded.');
end

%ATI
if ATIflag
    % set directories for where data live
    if(userflag==0 || userflag==1 || userflag==2)
    inputDir = [baseDir,'SMAST_Station1\ATI\plots\'];
    outputDir = [baseDir,'SMAST_Station1\ATI\plots\'];
    end
    disp('Loading ATI file...');
    load([inputDir,atifile]);
    disp('  Loaded.');
end

%DPL
if DPLflag
    % set directories for where data live
    if(userflag==0 || userflag==1 || userflag==2)
    inputDir = [baseDir,'SMAST_DPL2\plots\'];
    outputDir = [baseDir,'SMAST_DPL2\plots\'];
    end
    disp('Loading DPL file...');
    load([inputDir,dplfile]);
    disp(  'Loaded.');

    dpl_fld=fieldnames(all_dat_dpl);

%{
    WindSpd=cell(5,1);
    WindSpd_smooth=cell(5,1);
    T_Air=cell(5,1);
    T_Air_smooth=cell(5,1);
    RelHumid=cell(5,1);
    RelHumid_smooth=cell(5,1);

    firstvarn=7;  %Index of first sensor variable (S1 U)

    for sensn=1:5
        u=all_dat_dpl.(dpl_fld{(sensn-1)*5+firstvarn});
        v=all_dat_dpl.(dpl_fld{(sensn-1)*5+firstvarn+1});
        T_Air{sensn}=all_dat_dpl.(dpl_fld{(sensn-1)*5+firstvarn+3});  
        RelHumid{sensn}=all_dat_dpl.(dpl_fld{(sensn-1)*5+firstvarn+4});  
        if length(u)>length(v)
            u=u(1:length(v),:);
        end
        WindSpd{sensn}=sqrt(u.^2 + v.^2);
        WindSpd_smooth{sensn}=smoothdata(WindSpd{sensn},'movmean',600);
        T_Air_smooth{sensn}=smoothdata(T_Air{sensn},'movmean',600); 
        RelHumid_smooth{sensn}=smoothdata(RelHumid{sensn},'movmean',600);   %Moving average smoothing with window equivalent to 1 min
    end
%}

end

%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot results
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

init_date=datetime('11/25/2022 00:00:00',"InputFormat",dt_format);
end_date=datetime('11/26/2022 23:59:00',"InputFormat",dt_format);

disp('Plotting figure...');

%Initialize parameters
fts=12;
point_color=[0.6,0.6,0.6];
hfg1=figure(1);
scrsz = get(groot,'ScreenSize');
set(hfg1,'Position',[scrsz(4).*.1 scrsz(3).*.1 scrsz(3).*.55 scrsz(4).*.65])
set(0,'DefaultFigureVisible','on');  %Suppresses figure visibility during processing - set to on if desired    tmax=30;
tmax=23;
tmin=21;
wspd_max=11;
wspd_min=0;

%Set X-axis limits
xlimits=[datetime(init_date,"InputFormat",dt_format),datetime(end_date,"InputFormat",dt_format)];

tiledlayout(4,1)
nexttile

% Plot air temperature
hold on; box on; grid on; set(gca,'FontSize',fts);  
hleg=[];
hleg_lab={};

if Portlogflag
    % PLOT Parameters
    %if exist('all_dat_13448','var')
    %    hp2=plot(all_dat_13448.date_time , all_dat_13448.T_Air , '*k');
    %    hleg=[hleg,hp2];
    %end
    
    if exist('all_dat_13449','var')
        hp=plot(all_dat_13449.date_time, all_dat_13449.T_Air , '*b');
        hleg=[hleg,hp];
        hleg_lab=cat(2,hleg_lab,'Portlog\_13449');
    end
end

if ATIflag
    hati=plot(all_dat_ati.date_time, all_dat_ati.T_Air_smooth,'+','Color','g');
    hleg=[hleg,hati];
    hleg_lab=cat(2,hleg_lab,'ATI');
end

if DataQflag
    hdq1=plot(all_dat_dataq.date_time,all_dat_dataq.T_Air_upr,'m.');
    hdq2=plot(all_dat_dataq.date_time,all_dat_dataq.T_Air_lwr,'c-');
    hleg=[hleg,hdq1,hdq2];
    hleg_lab=cat(2,hleg_lab,'DataQ\_upr');
    hleg_lab=cat(2,hleg_lab,'DataQ\_lwr');
end

if Gillflag
    hgill=plot(all_dat_gill.date_time, all_dat_gill.T_Air_smooth,'.','Color',point_color); %Add transparency to Gill data
    hleg=[hleg,hgill];
    hleg_lab=cat(2,hleg_lab,'Gill');
end

if DPLflag
    for sn=1:5
        field_str=['T_Air_smooth_S',num2str(sn)];
        hdpl=plot(all_dat_dpl.date_time, all_dat_dpl.(field_str),'o','MarkerSize',1,'Linewidth',.8);
        hleg=[hleg,hdpl];
        hleg_lab=cat(2,hleg_lab,['DPL\_S',num2str(sn)]);
    end
end

set(gca,'Xlim',xlimits);
ylabel('TEMP AIR [C]');
xlabel('DATE (UTC)');

if length(hleg)>1
    legend(hleg,hleg_lab);
end

% Plot windspeed
nexttile
hold on; box on; grid on; set(gca,'FontSize',fts); 
hleg2=[];
hleg2_lab={};

if Portlogflag
    % PLOT Parameters
    %if exist('all_dat_13448','var')
    %    hp2=plot(all_dat_13448.date_time, all_dat_13448.T_Air , '*k');
    %    hleg=[hleg,hp2];
    %end
    
    if exist('all_dat_13449','var')
        hpw=plot(all_dat_13449.date_time, all_dat_13449.WindSpd, '*b');
        hleg2=[hleg2,hpw];
        hleg2_lab=cat(2,hleg2_lab,'Portlog\_13449');
    end
end

if Gillflag
    hgillw=plot(all_dat_gill.date_time, all_dat_gill.WindSpd_smooth,'.','Color',point_color);
    hleg2=[hleg2,hgillw];
    hleg2_lab=cat(2,hleg2_lab,'Gill');
end

if ATIflag
    hatiw=plot(all_dat_ati.date_time, all_dat_ati.WindSpd_smooth,'+','Color','g');
    hleg2=[hleg2,hatiw];
    hleg2_lab=cat(2,hleg2_lab,'ATI');
end

if DPLflag
    for sn=1:5
        field_str=['WindSpd_smooth_S',num2str(sn)];
        hdplw=plot(all_dat_dpl.date_time,all_dat_dpl.(field_str),'o','MarkerSize',1,'Linewidth',0.8);
        hleg2=[hleg2,hdplw];
        hleg2_lab=cat(2,hleg2_lab,['DPL\_',num2str(sn)]);
    end
end

set(gca,'Xlim',xlimits);
ylabel('WIND SPD [M/S]');
xlabel('DATE (UTC)');

if length(hleg2)>1
    legend(hleg2,hleg2_lab);
end

nexttile
% Plot wind vector speeds
hold on; box on; grid on; set(gca,'FontSize',fts);  
hleg=[];
hleg_lab={};

if ATIflag
    hati=plot(all_dat_ati.date_time, all_dat_ati.u_smooth,'+','Color','g');
    hleg=[hleg,hati];
    hleg_lab=cat(2,hleg_lab,'ATI');
end


if Gillflag
    hgill=plot(all_dat_gill.date_time, all_dat_gill.u_smooth,'.','Color',point_color); %Add transparency to Gill data
    hleg=[hleg,hgill];
    hleg_lab=cat(2,hleg_lab,'Gill');
end

%{
if DPLflag
    for sn=1:5
        field_str=['T_Air_smooth_S',num2str(sn)];
        hdpl=plot(all_dat_dpl.date_time, all_dat_dpl.(field_str),'o','MarkerSize',1,'Linewidth',.8);
        hleg=[hleg,hdpl];
        hleg_lab=cat(2,hleg_lab,['DPL\_S',num2str(sn)]);
    end
end
%}

set(gca,'Xlim',xlimits);
ylabel('u [m/s]');
xlabel('DATE (UTC)');

if length(hleg)>1
    legend(hleg,hleg_lab);
end

nexttile
% Plot wind vector speeds
hold on; box on; grid on; set(gca,'FontSize',fts);  
hleg=[];
hleg_lab={};

if ATIflag
    hati=plot(all_dat_ati.date_time, all_dat_ati.v_smooth,'+','Color','g');
    hleg=[hleg,hati];
    hleg_lab=cat(2,hleg_lab,'ATI');
end


if Gillflag
    hgill=plot(all_dat_gill.date_time, all_dat_gill.v_smooth,'.','Color',point_color); %Add transparency to Gill data
    hleg=[hleg,hgill];
    hleg_lab=cat(2,hleg_lab,'Gill');
end

%{
if DPLflag
    for sn=1:5
        field_str=['T_Air_smooth_S',num2str(sn)];
        hdpl=plot(all_dat_dpl.date_time, all_dat_dpl.(field_str),'o','MarkerSize',1,'Linewidth',.8);
        hleg=[hleg,hdpl];
        hleg_lab=cat(2,hleg_lab,['DPL\_S',num2str(sn)]);
    end
end
%}

set(gca,'Xlim',xlimits);
ylabel('v [m/s]');
xlabel('DATE (UTC)');

if length(hleg)>1
    legend(hleg,hleg_lab);
end

%%% END OF CODE %%%

