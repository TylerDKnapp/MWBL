% plot_timeseries_main.m - Matlab script to plot time series from MWBL sensors
% Syntax: plot_timeseries_main
%
% Inputs:
%    1) Folder locations with MWBL data files
%
% Outputs:
%    output - figures
%   
% Other m-files required: None
%
% MAT-files required: Sensor data files converted to *.mat format
%
% Author: Steven E. Lohrenz
% School for Marine Science and Technology, University of Massachusetts Dartmouth
% email address: slohrenz@umassd.edu
% Website: http://www.umassd.edu/smast/
% Revised by Steven Lohrenz: 1 July 2022 - added functionality to save a
%   subset of data
% Revised by Steven Lohrenz: 8 July 2022 - added DPL plotting routine
% Revised by Steven Lohrenz: 22 July 2022 - modified graph X-axis limit 
% Revised by Eric Le-Zabarsky: 8 Semptember 2022 - added an elseif to the delta_date for the latest deployment
% Revised by Steven Lohrenz:  12/26/2022 - removed time correction for DPL as it is now part of csv2mat script
% Revised by Steven Lohrenz:  03/25/2023 - updated KZ Scintillometer plotting script
% Revised by Steven Lohrenz:  04/16/2023 - corrected some variable indexing issues

%% ------------- BEGIN CODE --------------%% 

Verson = 'plot_timeseries_main, V2.0, 04/16/2023';

clc
clearvars

inpath_pref='/usr2/MWBL/Data/';
%inpath_pref='C:\Users\ezabarsky\OneDrive - University of Massachusetts Dartmouth\MWBL\Data\';
%Set initial and end dates for file processing

init_date='11-03-2024 16:00:00';  %'10-27-2022 00:00:00'; '10/05/2022';
end_date='11-04-2024 13:59:00';   %'12-31-2022 23:59:00'; '10/18/2022';
dt_format='MM-dd-uuuu HH:mm:ss';

%To override limits for plotting
date_override=0;
override_dt_format='MM-dd-uuuu HH:mm:ss';
override_init_date = char(datetime(init_date,'InputFormat',override_dt_format),...
    'MM-dd-uuuu HH:mm:ss');
override_end_date = '11-07-2024 13:59:00';

%Specify which datasets to plot (true or false, 0 or 1)
Portlog=0;
DataQ=0;
ATI=0;
Gill=0;
KZ_Scint=0;
Delta=0;
DPL=1;

%Option to save truncated data files
Portlog_save=0;
DataQ_save=0;
ATI_save=0;
Gill_save=0;
%KZ_Scint_save=0;
%Delta_save=0;
DPL_save=0;

fig_count=0;

%% Plot Portlog

if Portlog
    %Input filenames for reading
    inpath=[inpath_pref,'RainwisePortLog\processed\'];
    outpath=[inpath_pref,'RainwisePortlog\plots\'];
    
    %Retrieve file information
    FList=dir([inpath,'\*.mat']);
    
    [filen,~]=size(FList);
    
    %Loop through file list for processing
    for ifile=1:filen
        file_name=FList(ifile).name;
    
        %Check for data range and get serial number
        if contains(file_name,'SMAST')
            indx1=strfind(FList(n).name,'Data_');
            Portlog_date=FList(n).name(indx1+5:indx1+12);
            %Portlog_date=file_name(26:33);
            indx2=strfind(FList(n).name,'SMAST_');
            SerialNo=FList(n).name(indx2+6:indx2+6);
        elseif contains(file_name,'CBC')
            indx1=strfind(FList(n).name,'Data_');
            Portlog_date=FList(n).name(indx1+5:indx1+12);
            %Portlog_date=file_name(26:33);
            indx2=strfind(FList(n).name,'CBC_');
            SerialNo=FList(n).name(indx2+4:indx2+6);
        else
            indx1=strfind(FList(n).name,'Data_');
            Portlog_date=FList(n).name(indx1+5:indx1+12);
            %Portlog_date=file_name(26:33);
            indx2=strfind(FList(n).name,'Portlog_');
            SerialNo=FList(n).name(indx+8:indx+6);
        end    

        portlog_datenum=datenum(Portlog_date,'yyyymmdd');
    
        if portlog_datenum >= datenum(init_date) && portlog_datenum <= datenum(end_date)
            %Read data file
            disp(['Reading Portlog_',SerialNo,'_',datestr(portlog_datenum)]);
            
            switch SerialNo
                case '13448'
                if ~exist('port_dat_13448','var')
                    %Load data
                    port_dat_13448=load([inpath,file_name]);
                else
                    %Load data and append to existing structure
                    port_dat_app=load([inpath,file_name]);
                    port_dat_13448=[port_dat_13448,port_dat_app];
                end

                case '13449'
                if ~exist('port_dat_13449','var')
                    %Load data
                    port_dat_13449=load([inpath,file_name]);
                else
                    %Load data and append to existing structure
                    port_dat_app=load([inpath,file_name]);
                    port_dat_13449=[port_dat_13449,port_dat_app];
                end
            end
        end
    end

    %Concatenate structures

    if exist('port_dat_13448','var') 
        fld=fieldnames(port_dat_13448); %Get fieldnames from structure
        all_dat_13448 = struct;  %final structure
        for field = 1:length(fld)
           fname = fld{field};
           all_dat_13448.(fname) = vertcat(port_dat_13448.(fname));
        end
        clear 'port_dat_13448'
    end    
    
    if exist('port_dat_13449','var')
        fld=fieldnames(port_dat_13449); %Get fieldnames from structure
        all_dat_13449 = struct;  %final structure
        for field = 1:length(fld)
           fname = fld{field};
           all_dat_13449.(fname) = vertcat(port_dat_13449.(fname));
        end
        clear 'port_dat_13449'
    end    

    %% Plot Portlog
    
    disp('Plotting figure...');

    %Override X-axis limits
    if date_override
        init_date_old=init_date;
        init_date=override_init_date;
        end_date_old=end_date;
        end_date=override_end_date;
        dt_format=override_dt_format;
    end

    %Set X-axis limits
    xlimits=[datetime(init_date,"InputFormat",dt_format),datetime(end_date,"InputFormat",dt_format)];

    %Increment figure counter
    fig_count=fig_count+1;

    %Initialize parameters
    fts=12;
    fportlog=figure(fig_count);
    scrsz = get(groot,'ScreenSize');
    set(fportlog,'Position',[scrsz(4).*.1 scrsz(3).*.1 scrsz(3).*.55 scrsz(4).*.65])
    set(0,'DefaultFigureVisible','on');  %Suppresses figure visibility during processing - set to on if desired    tmax=30;
    tmin=0;
    tmax=30;    
    wspd_max=11;
    wspd_min=0;

    %**************************************************************************
    % PLOT Parameters
    tiledlayout(4,1)
    nexttile
        hold on; box on; grid on; set(gca,'FontSize',fts);  
        hleg=[];
        if exist('all_dat_13448','var')
            hp2=plot(all_dat_13448.date_time , all_dat_13448.T_Air , '*k');
            hleg=[hleg,hp2];
        end
        
        if exist('all_dat_13449','var')
            hp1=plot(all_dat_13449.date_time, all_dat_13449.T_Air , '.b');
            hleg=[hleg,hp1];
        end
        set(gca,'Xlim',xlimits);
        %set(gca,'Ylim',[tmin,tmax]);
        xlabel(''); ylabel('TEMP AIR [C]');
        if length(hleg)>1
            legend(hleg,'13448','13449');
        end
        title('Portlog');
    
        %Set X-axis limits
        set(gca,'Xlim',datetime({init_date,end_date},'InputFormat',dt_format));
    
        %Format x-axis labels
        xtick=get(gca,'Xtick');
        xticklab=datestr(xtick,"mm/dd HH:MM");
        set(gca,'XtickLabel',xticklab);

    nexttile
        hleg2=[];
        hleg_lab={};
        hold on; box on; grid on; set(gca,'FontSize',fts); 
        if exist('all_dat_13448','var')
            hws1=plot(all_dat_13448.date_time , all_dat_13448.WindSpd, '*k');
            hleg2=[hleg2,hws1];
            hleg_lab=cat(2,hleg_lab,'WindSpd\_13448');
        end
        
        if exist('all_dat_13449','var')
            hws2=plot(all_dat_13449.date_time , all_dat_13449.WindSpd, '.b');
            hleg2=[hleg2,hws2];
            hleg_lab=cat(2,hleg_lab,'WindSpd\_13449');
        end
    
        %Set X-axis limits
        set(gca,'Xlim',datetime({init_date,end_date},'InputFormat',dt_format));
    
        set(gca,'Ylim',[wspd_min,wspd_max]);
        xlabel(''); ylabel('WIND SPEED  [m/s]');
        set(gca,'XtickLabel',xticklab);
        axpos=get(gca,'Position');
     
        %Plot max windspeed
        if exist('all_dat_13448','var')
            hwsmax1=plot(gca,all_dat_13448.date_time , all_dat_13448.WS_Max,'+k','MarkerSize',3);
            hleg2=[hleg2,hwsmax1];
            hleg_lab=cat(2,hleg_lab,'WindGust\_13448');
        end
    
        if exist('all_dat_13449','var')
            hwsmax2=plot(gca,all_dat_13449.date_time, all_dat_13449.WS_Max,'+b','MarkerSize',3);
            hleg2=[hleg2,hwsmax2];
            hleg_lab=cat(2,hleg_lab,'WindGust\_13449');
        end
    
        %Set axis limits
        set(gca,'Xlim',datetime({init_date,end_date},'InputFormat',dt_format));
        %set(gca,'Ylim',[wspd_min,wspd_max]);
    
        legend(hleg2,hleg_lab);
        hold on
        
    nexttile
        hold on; box on; grid on; set(gca,'FontSize',fts); 
        if exist('all_dat_13448','var')
            plot(all_dat_13448.date_time , all_dat_13448.WindDir, '*k');
        end
        
        if exist('all_dat_13449','var')
            plot(all_dat_13449.date_time , all_dat_13449.WindDir, '.b');
        end
    
        %Set X-axis limits
        set(gca,'Xlim',datetime({init_date,end_date},'InputFormat',dt_format));
    
        xlabel('DATE/TIME'); ylabel('WIND DIR (deg)');
        set(gca,'XtickLabel',xticklab);

nexttile
        hold on; box on; grid on; set(gca,'FontSize',fts);
        if exist('all_dat_13448','var')
            plot(all_dat_13448.date_time , all_dat_13448.Baro, '*k');
        end
        if exist('all_dat_13449','var')
            plot(all_dat_13449.date_time , all_dat_13449.Baro, '.b');
        end
    
        %Set X-axis limits
        set(gca,'Xlim',datetime({init_date,end_date},'InputFormat',dt_format));
    
        xlabel(''); ylabel('PRESS  [hPa]');
        set(gca,'XtickLabel',xticklab);
        
%     nexttile
%         hold on; box on; grid on; set(gca,'FontSize',fts); 
%         if exist('all_dat_13448','var')
%             plot(all_dat_13448.date_time , all_dat_13448.Rain, '*k');
%         end
%         
%         if exist('all_dat_13449','var')
%             plot(all_dat_13449.date_time , all_dat_13449.Rain, '.b');
%         end
%     
%         %Set X-axis limits
%         set(gca,'Xlim',datetime({init_date,end_date},'InputFormat',dt_format));
%     
%         xlabel('DATE/TIME'); ylabel('PRECIP [mm]');
%         set(gca,'XtickLabel',xticklab);
  
    %####################

    %Reformat date strings for output filename
    init_date_str=datestr(init_date,'yyyymmdd');
    end_date_str=datestr(end_date,'yyyymmdd');

    print(gcf,[outpath,'Portlog_time_series_',init_date_str,'-',end_date_str,'.tif'],'-dtiff','-r300')

    if Portlog_save && exist('all_dat_13448','var')
        portlog_fields=fieldnames(all_dat_13448);
        save_index=all_dat_13448.date_time>=datetime(init_date,"InputFormat",dt_format) & ...
            all_dat_13448.date_time<=datetime(end_date,"InputFormat",dt_format);
        for isen=5:length(portlog_fields)  %Skip attribute fields
            all_dat_13448.(portlog_fields{isen})=all_dat_13448.(portlog_fields{isen})(save_index);
        end
        save([outpath,'Portlog_13448_time_series_',init_date_str,'-',end_date_str,'.mat'],'all_dat_13448');
    end

    if Portlog_save && exist('all_dat_13449','var')
        portlog_fields=fieldnames(all_dat_13449);
        save_index=all_dat_13449.date_time>=datetime(init_date,"InputFormat",dt_format) & ...
            all_dat_13449.date_time<=datetime(end_date,"InputFormat",dt_format);
        for isen=5:length(portlog_fields)  %Skip attribute fields
            all_dat_13449.(portlog_fields{isen})=all_dat_13449.(portlog_fields{isen})(save_index);
        end
        save([outpath,'Portlog_13449_time_series_',init_date_str,'-',end_date_str,'.mat'],'all_dat_13449');
    end

%     clearvars -except 'init_date' 'end_date' 'init_date_str' 'end_date_str' 'xlimits' ...
%         'ATI' 'Delta' 'KZ_Scint' 'Portlog' 'Gill'  'DataQ' 'fig_count' 'inpath_pref' ...
%         'date_override' 'override_init_date' 'override_end_date'  'DataQ_save' ...
%         'ATI_save' 'Gill_save' 'DPL' 'DPL_save' 'dt_format' 'override_dt_format' %Clears variables from workspace

end

%% Plot ATI

if ATI
    %Input filenames for reading
    inpath=[inpath_pref,'SMAST_Station1\ATI\processed\'];
    outpath=[inpath_pref,'SMAST_Station1\ATI\plots\'];
    
    %Retrieve file information
    FList=dir([inpath,'\*.mat']);
    
    [filen,~]=size(FList);
    
    for ifile=1:filen
        file_name=FList(ifile).name;
        
        %Check for data range
        ATI_date=file_name(26:35);
        
        ATI_datenum=datenum(ATI_date,'yyyy-mm-dd');
    
        if ATI_datenum >= datenum(init_date) && ATI_datenum <= datenum(end_date)
            disp(['Reading ATI_',datestr(ATI_datenum)]);
            if ~exist('ATI_dat','var')
                %Load data
                ATI_dat=load([inpath,file_name]);
            else
                %Load data and append to existing structure
                ATI_dat_app=load([inpath,file_name]);
                ATI_dat=[ATI_dat,ATI_dat_app];
            end
        end
    end

    %Concatenate structures

    ati_fld=fieldnames(ATI_dat); %Get fieldnames from structure
    all_dat_ati = struct;  %final structure
    for ifld = 1:length(ati_fld)
       fname = ati_fld{ifld};
       all_dat_ati.(fname) = vertcat(ATI_dat.(fname));
    end

    %Remove NaT points
    good_indx=~isnat(all_dat_ati.date_time);
    var_indx=find(ismember(ati_fld,{'date_time','u','v','w','T_Air'}));  %Find fields matching variable names
    for ifld = 1:length(var_indx)
       fname = ati_fld{var_indx(ifld)};
       all_dat_ati.(fname) = all_dat_ati.(fname)(good_indx);
    end
    
    %Sort ascending by date_time
    [new_dt,sort_indx]=sort(all_dat_ati.date_time);
    for ifld = 1:length(var_indx)
       fname = ati_fld{var_indx(ifld)};
       all_dat_ati.(fname) = all_dat_ati.(fname)(sort_indx);
    end
 
    all_dat_ati.WindSpd=sqrt(all_dat_ati.u.^2+all_dat_ati.v.^2);
    all_dat_ati.WindSpd_smooth=smoothdata(all_dat_ati.WindSpd,'movmean',minutes(10),'SamplePoints',all_dat_ati.date_time);  %Moving average smoothing with window equivalent to 1 min
    all_dat_ati.T_Air_smooth=smoothdata(all_dat_ati.T_Air,'movmean',minutes(10),'SamplePoints',all_dat_ati.date_time);  %Moving average smoothing with window equivalent to 1 min
    all_dat_ati.u_smooth=smoothdata(all_dat_ati.u,'movmean',minutes(10),'SamplePoints',all_dat_ati.date_time);
    all_dat_ati.v_smooth=smoothdata(all_dat_ati.v,'movmean',minutes(10),'SamplePoints',all_dat_ati.date_time);
    [theta_WD,rho_corr]=cart2pol(all_dat_ati.u,all_dat_ati.v);
    all_dat_ati.WindDir=wrapTo360(rad2deg(pi()./2 - theta_WD)-180);
    all_dat_ati.WindDir_smooth=smoothdata(all_dat_ati.WindDir,'movmean',minutes(10),'SamplePoints',all_dat_ati.date_time);

    clear {'ATI_dat','ATI_dat_app','ATI_date','ATI_datenum'};

    %% Plot ATI

    %Override X-axis limits
    if date_override
        init_date_old=init_date;
        init_date=override_init_date;
        end_date_old=end_date;
        end_date=override_end_date;
        dt_format=override_dt_format;
    end

    %Get indices for desired time range
    dataindx=find(all_dat_ati.date_time>=datetime(init_date,'InputFormat',dt_format) & ...
            all_dat_ati.date_time<=datetime(end_date,'InputFormat',dt_format));
    
    %Set X-axis limits
    xlimits=[datenum(init_date),datenum(end_date)];

    %Increment figure counter
    fig_count=fig_count+1;

    %Initialize parameters
    fts=12;
    point_color=[0.6,0.6,0.6];
    fati=figure(fig_count);
    scrsz = get(groot,'ScreenSize');
    set(fati,'Position',[scrsz(4).*.1 scrsz(3).*.1 scrsz(3).*.55 scrsz(4).*.65])
    set(0,'DefaultFigureVisible','on');  %Suppresses figure visibility during processing - set to on if desired    tmax=30;
    tmax=23;
    tmin=21;
    wspd_max=6;
    wspd_min=0;
    
    %**************************************************************************
    % PLOT Parameters
    tiledlayout(3,1)
    nexttile
        hold on; box on; grid on; set(gca,'FontSize',fts);  
        plot(all_dat_ati.date_time, all_dat_ati.T_Air,'.','Color',point_color);
        set(gca,'Xlim',datetime({init_date,end_date},'InputFormat',dt_format));
        %set(gca,'Ylim',[tmin,tmax]);
        hold on
        plot(all_dat_ati.date_time, all_dat_ati.T_Air_smooth, '-b','LineWidth',2);
        xlabel(''); ylabel('TEMP  AIR  [C]');
        legend('Unfiltered','10 min avg')
        title('ATI');
    
        %Set X-axis limits
        set(gca,'Xlim',datetime({init_date,end_date},'InputFormat',dt_format));
    
        %Format axis labels
        xtick=get(gca,'Xtick');
        xticklab=datestr(xtick,"mm/dd HH:MM");
        set(gca,'XtickLabel',xticklab);

    nexttile
        hold on; box on; grid on; set(gca,'FontSize',fts); 
        plot(all_dat_ati.date_time, all_dat_ati.WindSpd, '.','Color',point_color);
        hold on
        set(gca,'Xlim',datetime({init_date,end_date},'InputFormat',dt_format),'Xtick',xtick);
        set(gca,'Ylim',[wspd_min,wspd_max]);
        plot(all_dat_ati.date_time, all_dat_ati.WindSpd_smooth, '-b','LineWidth',2);
        xlabel('DATE/TIME'); ylabel('WIND SPEED  [m/s]');
        
        %Set X-axis limits
        set(gca,'Xlim',datetime({init_date,end_date},'InputFormat',dt_format));
    
        set(gca,'XtickLabel',xticklab);
     
        %####################
    
        %Reformat date strings for output filename
        init_date_str=datestr(init_date,'yyyymmdd');
        end_date_str=datestr(end_date,'yyyymmdd');

    nexttile
        hold on; box on; grid on; set(gca,'FontSize',fts); 
        plot(all_dat_ati.date_time, all_dat_ati.WindDir, '.','Color',point_color);
        hold on
        set(gca,'Xlim',datetime({init_date,end_date},'InputFormat',dt_format),'Xtick',xtick);
        set(gca,'Ylim',[0,370]);
        plot(all_dat_ati.date_time, all_dat_ati.WindDir_smooth, '-b','LineWidth',2);
        hpl=plot(all_dat_13449.date_time , all_dat_13449.WindDir, 'om');
        xlabel('DATE/TIME'); ylabel('WIND DIR  [deg]');
        
        %Set X-axis limits
        set(gca,'Xlim',datetime({init_date,end_date},'InputFormat',dt_format));
        set(gca,'XtickLabel',xticklab);
        legend(hpl,'SMAST Portlog');
     
        %####################
    
        %Reformat date strings for output filename
        init_date_str=datestr(init_date,'yyyymmdd');
        end_date_str=datestr(end_date,'yyyymmdd');

    %outpath='C:\Users\slohrenz\Documents\Steve\DATA\NUWC\DPLProcessing\';
    
    print(gcf,[outpath,'ATI_time_series_',init_date_str,'-',end_date_str,'.tif'],'-dtiff','-r300');
        
    if ATI_save
        save_index=all_dat_ati.date_time>=datetime(init_date,'InputFormat',dt_format) & ...
            all_dat_ati.date_time<=datetime(end_date,'InputFormat',dt_format);
        ati_fld_new=fieldnames(all_dat_ati);
        for isen=4:length(ati_fld_new)  %Skip attribute fields
            all_dat_ati.(ati_fld_new{isen})=all_dat_ati.(ati_fld_new{isen})(save_index);
        end
        save([outpath,'ATI_time_series_',init_date_str,'-',end_date_str,'.mat'],'all_dat_ati');
    end

    clearvars -except 'init_date' 'end_date' 'init_date_str' 'end_date_str' 'xlimits' ...
        'ATI' 'Delta' 'KZ_Scint' 'Portlog' 'Gill'  'DataQ' 'fig_count' 'inpath_pref' ...
        'date_override' 'override_init_date' 'override_end_date'  'DataQ_save' ...
        'ATI_save' 'Gill_save' 'DPL' 'DPL_save' 'dt_format' 'override_dt_format' % Clears variables from workspace
  
end

%% Plot Gill

if Gill
    %Input filenames for reading
    inpath=[inpath_pref,'SMAST_Station1\Gill\processed\'];
    outpath=[inpath_pref,'SMAST_Station1\Gill\plots\'];
    
    %Retrieve file information
    FList=dir([inpath,'\*.mat']);
    
    [filen,~]=size(FList);
    
    for ifile=1:filen
        file_name=FList(ifile).name;
        
        %Check for data range
        Gill_date=file_name(21:30);
        
        Gill_datenum=datenum(Gill_date,'yyyy-mm-dd');
    
        if Gill_datenum >= datenum(init_date) && Gill_datenum <= datenum(end_date)
            disp(['Reading Gill_',datestr(Gill_datenum)]);
            if ~exist('Gill_dat','var')
                %Load data
                Gill_dat=load([inpath,file_name]);
                %Gill_dat=matfile([inpath,file_name]);  %Create link to data file
            else
                %Load data and append to existing structure
                Gill_dat_app=load([inpath,file_name]);
                Gill_dat=[Gill_dat,Gill_dat_app];
            end
        end
    end

    %Concatenate structures

    gill_fld=fieldnames(Gill_dat); %Get fieldnames from structure
    all_dat_gill = struct;  %final structure
    for field = 1:length(gill_fld) %Skip universal variables
       fname = gill_fld{field};
       all_dat_gill.(fname) = vertcat(Gill_dat.(fname));
    end

    %Remove NaT points
    good_indx=~isnat(all_dat_gill.date_time);
    for isen = 4:length(gill_fld)
       fname = gill_fld{isen};
       all_dat_gill.(fname) = all_dat_gill.(fname)(good_indx);
    end
    
    %Sort ascending by date_time
    [all_dat_gill.date_time,sort_indx]=sort(all_dat_gill.date_time);
    for isen = 5:length(gill_fld)
       fname = gill_fld{isen};
       all_dat_gill.(fname) = all_dat_gill.(fname)(sort_indx);
    end

    all_dat_gill.WindSpd=sqrt(all_dat_gill.u.^2+all_dat_gill.v.^2);
    all_dat_gill.WindSpd_smooth=smoothdata(all_dat_gill.WindSpd,'movmean',minutes(1),'SamplePoints',all_dat_gill.date_time);  %Moving average smoothing with window equivalent to 1 min
    all_dat_gill.T_Air=all_dat_gill.T_Air-273.15;
    all_dat_gill.T_Air_smooth=smoothdata(all_dat_gill.T_Air,'movmean',minutes(1),'SamplePoints',all_dat_gill.date_time);
    all_dat_gill.u_smooth=smoothdata(all_dat_gill.u,'movmean',minutes(10),'SamplePoints',all_dat_gill.date_time);
    all_dat_gill.v_smooth=smoothdata(all_dat_gill.v,'movmean',minutes(10),'SamplePoints',all_dat_gill.date_time);
    

    clear {'Gill_dat','Gill_date','Gill_datenum','gill_fld'};


    %% Plot Gill

    %Override X-axis limits
    if date_override
        init_date_old=init_date;
        init_date=override_init_date;
        end_date_old=end_date;
        end_date=override_end_date;
        dt_format=override_dt_format;
    end

    %Increment figure counter
    fig_count=fig_count+1;

    %Initialize parameters
    fts=12;
    point_color=[0.6,0.6,0.6];
    fgill=figure(fig_count);
    scrsz = get(groot,'ScreenSize');
    set(fgill,'Position',[scrsz(4).*.1 scrsz(3).*.1 scrsz(3).*.55 scrsz(4).*.65])
    set(0,'DefaultFigureVisible','on');  %Suppresses figure visibility during processing - set to on if desired    tmax=30;
    tmax=30;
    tmin=21;
    wspd_max=11;
    wspd_min=0;

    %**************************************************************************
    % PLOT Parameters
    tiledlayout(2,1)
    nexttile
    hold on; box on; grid on; set(gca,'FontSize',fts);  
    plot(all_dat_gill.date_time, all_dat_gill.T_Air, '.','Color',point_color);
    hold on
    plot(all_dat_gill.date_time, all_dat_gill.T_Air_smooth, '-b','LineWidth',2);
 
    %Set axis limits
    set(gca,'Xlim',datetime({init_date,end_date},'InputFormat',dt_format));
    %set(gca,'Ylim',[tmin,tmax]);
    
    xlabel(''); ylabel('TEMP  AIR  [C]');
    legend('Unfiltered','1 min avg')
    title('Gill');

    %Format x-axis labels
    xtick=get(gca,'Xtick');
    xticklab=datestr(xtick,"mm/dd HH:MM");
    set(gca,'XtickLabel',xticklab);

    nexttile
    hold on; box on; grid on; set(gca,'FontSize',fts); 
    plot(all_dat_gill.date_time, all_dat_gill.WindSpd, '.','Color',point_color);
    hold on
    plot(all_dat_gill.date_time, all_dat_gill.WindSpd_smooth, '-b','LineWidth',2);
    
    %Set axis limits
    set(gca,'Xlim',datetime({init_date,end_date},'InputFormat',dt_format));
    set(gca,'Ylim',[wspd_min,wspd_max]);

    xlabel('DATE/TIME'); ylabel('WIND SPEED  [m/s]');
    set(gca,'XtickLabel',xticklab);
 
    %####################

    init_date_str=datestr(init_date,'yyyymmdd');
    end_date_str=datestr(end_date,'yyyymmdd');

    print(gcf,[outpath,'Gill_time_series_',init_date_str,'-',end_date_str,'.tif'],'-dtiff','-r300');
        
    if Gill_save
        save_index=find(all_dat_gill.date_time>=datetime(init_date,'InputFormat',dt_format) & ...
            all_dat_gill.date_time<=datetime(end_date,'InputFormat',dt_format));

        % To allow for easier visualization of the large Gill dataset, this
        % only saves every ten data points

        save_index_dwnsamp=save_index(1:10:end);
        %Get Gill structure fieldnames
        gill_fld_new=fieldnames(all_dat_gill);
        for isen=4:length(gill_fld_new)
            all_dat_gill.(gill_fld_new{isen})=all_dat_gill.(gill_fld_new{isen})(save_index_dwnsamp);
        end
        save([outpath,'Gill_time_series_',init_date_str,'-',end_date_str,'.mat'],'all_dat_gill');
        %save([outpath,'Gill_time_series_',init_date_str,'-',end_date_str,'.mat'],'all_dat_gill',...
        %    '-v7.3','-nocompression');  %-v7.3 is required for large file save (takes a long time)
    end

    clearvars -except 'init_date' 'end_date' 'init_date_str' 'end_date_str' 'xlimits' ...
        'ATI' 'Delta' 'KZ_Scint' 'Portlog' 'Gill'  'DataQ' 'fig_count' 'inpath_pref'...
        'date_override' 'override_init_date' 'override_end_date'  'DataQ_save' ...
        'ATI_save' 'Gill_save' 'DPL' 'DPL_save' 'dt_format' 'override_dt_format' %Clears variables from workspace

end

%% Plot KZ_Scint
% 
if KZ_Scint
    %Input filenames for reading
    inpath=[inpath_pref,'KZScintillometer\processed\'];
    outpath=[inpath_pref,'KZScintillometer\plots\'];
    
    %Retrieve file information
    FList=dir([inpath,'\*.mat']);
    
    [filen,~]=size(FList);
    
    for ifile=1:filen
        file_name=FList(ifile).name;
        
        %Check for data range
        KZ_Scint_date=file_name(1:8);
        
        KZ_Scint_file_date_time=datetime(KZ_Scint_date,'InputFormat','yyyyMMdd');
    
        if KZ_Scint_file_date_time >= datetime(init_date) && KZ_Scint_file_date_time <= datetime(end_date)
            disp(['Reading KZ_Scint_',datestr(KZ_Scint_file_date_time)]);
            if ~exist('KZ_Scint_dat','var')
                %Load data
                KZ_Scint_dat=load([inpath,file_name]);
            else
                %Load data and append to existing structure
                KZ_Scint_dat_app=load([inpath,file_name]);
                KZ_Scint_dat=[KZ_Scint_dat,KZ_Scint_dat_app];
            end
        end
    end

    %WindSpd_smooth=smoothdata(WindSpd,'movmean',1800);  %Moving average smoothing with window equivalent to 1 min

    disp('Plotting figure...');
    
    %Override X-axis limits
    if date_override
        init_date_old=init_date;
        init_date=override_init_date;
        end_date_old=end_date;
        end_date=override_end_date;
    end

    %Set X-axis limits
    xlimits=[datetime(init_date),datetime(end_date)];

    %Increment figure counter
    fig_count=fig_count+1;

    %Initialize parameters
    fts=16;
    point_color=[0.6,0.6,0.6];
    figure(fig_count);
    clf
    tmax=30;
    tmin=0;
    wspd_max=40;
    wspd_min=0;

    %**************************************************************************
    % PLOT Parameters
    %tiledlayout(2,1)
    %nexttile
    hold on; box on; grid off; set(gca,'FontSize',fts,'Linewidth',1.5);
    %plot(datetime,KZ_Scint_dat.Cn2,KZ_Scint_dat.Cn2Sig,'bo');
    for np=1:length(KZ_Scint_dat)
        kz1=plot(KZ_Scint_dat(np).date_time,KZ_Scint_dat(np).Cn2-KZ_Scint_dat(np).Cn2Sig,'m--');
        kz2=plot(KZ_Scint_dat(np).date_time,KZ_Scint_dat(np).Cn2+KZ_Scint_dat(np).Cn2Sig,'m--');
        kz3=plot(KZ_Scint_dat(np).date_time,smoothdata(KZ_Scint_dat(np).Cn2,'movmean',minutes(1),'SamplePoints',KZ_Scint_dat(np).date_time),'b-','LineWidth',2);
    end
    set(gca,'Xlim',xlimits,'YScale','log','YLim',[10^-17,10^-12],'FontWeight','bold');
    %set(gca,'Ylim',[tmin,tmax]);
    xlabel('Date (UTC)'); ylabel('C_n^{2} (m^{-2/3})');
    legend([kz3,kz1],'C_n^2 (1 min avg)','+/- 1 SD');
    title('Kipp and Zonen Scintillometer');

    %Format x-axis labels
    %time_incr=1; %Set ticks every four hours
    %xtick=xlimits(1)+time_incr;
    xtick=get(gca,'XTick');
    set(gca,'Xtick',xtick);
    xticklab=datestr(xtick,"mmm dd");
    set(gca,'XtickLabel',xticklab);

    %####################

    print(gcf,[outpath,'KZ_Scint_time_series_',datestr(init_date_old),'-',datestr(end_date_old),'.tif'],'-dtiff','-r300')

    clearvars -except 'init_date' 'end_date' 'init_date_str' 'end_date_str' 'xlimits' ...
    'ATI' 'Delta' 'KZ_Scint' 'Portlog' 'Gill'  'DataQ' 'fig_count' 'inpath_pref' ...
    'date_override' 'override_init_date' 'override_end_date'  'DataQ_save' ...
    'ATI_save' 'Gill_save' 'DPL' 'DPL_save' 'dt_format' 'override_dt_format' %Clears variables from workspace

end

%% Plot Delta
% 
if Delta
    %Input filenames for reading
    inpath=[inpath_pref,'MZA_DELTA\processed\'];
    outpath=[inpath_pref,'MZA_DELTA\plots\'];
    
    %Retrieve file information
    FList=dir([inpath,'\*.mat']);
    FL = FList(1:140); %%%%%% TESTER list
    [filen,~]=size(FList);
    
    for ifile=1:filen
        file_name=FList(ifile).name;
        
        %Check for date range
        if contains(file_name,'SMAST-')
            Delta_date=file_name(7:16);
        elseif contains(file_name,'UMass')
            Delta_date=file_name(13:22);
        elseif contains(file_name, 'SMAST DELTA 2022')
            Delta_date=file_name(18:27);
        elseif contains(file_name,'AFIT-')
            Delta_date=file_name(6:15);
        end
        
        Delta_datenum=datenum(Delta_date,'yyyy-mm-dd');
    
        if Delta_datenum >= datenum(init_date) && Delta_datenum <= datenum(end_date)
            disp(['Reading Delta_',datestr(Delta_datenum)]);
            if ~exist('Delta_dat','var')
                %Load data
                Delta_dat=load([inpath,file_name]);
            else
                %Load data and append to existing structure
                Delta_dat_app=load([inpath,file_name]);
                Delta_dat=[Delta_dat,Delta_dat_app];
            end
        end
    end

    %WindSpd_smooth=smoothdata(WindSpd,'movmean',1800);  %Moving average smoothing with window equivalent to 1 min

    disp('Plotting figure...');
    
    %Override X-axis limits
    if date_override
        init_date_old=init_date;
        init_date=override_init_date;
        end_date_old=end_date;
        end_date=override_end_date;
    end

    %Set X-axis limits
    xlimits=[datenum(init_date),datenum(end_date)];

    %Increment figure counter
    fig_count=fig_count+1;

    %Initialize parameters
    fts=12;
    point_color=[0.6,0.6,0.6];
    figure(fig_count);
    clf
    tmax=30;
    tmin=0;
    wspd_max=40;
    wspd_min=0;

    %**************************************************************************
    % PLOT Parameters
    %tiledlayout(2,1)
    %nexttile
    hold on; box on; grid on; set(gca,'FontSize',fts);
    for np=1:length(Delta_dat)
        kz1=plot(Delta_dat(np).date_time+Delta_dat(np).Time,Delta_dat(np).Cn2_Mean,'m.');
    end
    xlimDelta=datetime(xlimits,'ConvertFrom','datenum');
    set(gca,'Xlim',xlimDelta,'YScale','log','YLim',[10^-16,10^-13]);
    %set(gca,'Ylim',[tmin,tmax]);
    xlabel('DATE/TIME'); ylabel('C_n^{2} mean (m^{-2/3})');
    legend('C_n^2 mean (1 min avg)');
    title('MZA Delta');

    %Format x-axis labels
    xtick=get(gca,'XTick');
    set(gca,'Xtick',xtick);
    xticklab=datestr(xtick,"mm/dd HH:MM");
    set(gca,'XtickLabel',xticklab);

    %####################

    print(gcf,[outpath,'Delta_time_series_',init_date_str,'-',end_date_str,'.tif'],'-dtiff','-r300')

    clearvars -except 'init_date' 'end_date' 'init_date_str' 'end_date_str' 'xlimits' ...
    'ATI' 'Delta' 'KZ_Scint' 'Portlog' 'Gill'  'DataQ' 'fig_count' 'inpath_pref'  ...
        'date_override' 'override_init_date' 'override_end_date'  'DataQ_save' ...
        'ATI_save' 'Gill_save' 'DPL' 'DPL_save'  %Clears variables from workspace

end

%% Plot DataQ
% 
if DataQ
    %Input filenames for reading
    inpath=[inpath_pref,'SMAST_Station1\DataQ\processed\'];
    outpath=[inpath_pref,'SMAST_Station1\DataQ\plots\'];
    
    %Retrieve file information
    FList=dir([inpath,'\*.mat']);
    
    [filen,~]=size(FList);
    
    for ifile=1:filen
        file_name=FList(ifile).name;
        
        %Check for date index by searching for 202 string pattern
        date_indx=strfind(file_name,'202');
        DataQ_date=file_name(date_indx:date_indx+9);
        DataQ_datenum=datenum(DataQ_date,'yyyy-mm-dd');
    
        if DataQ_datenum >= datenum(init_date) && DataQ_datenum <= datenum(end_date)
            disp(['Reading DataQ_',datestr(DataQ_datenum)]);
            if ~exist('DataQ_dat','var')
                %Load data
                DataQ_dat=load([inpath,file_name]);
            else
                %Load data and append to existing structure
                DataQ_dat_app=load([inpath,file_name]);
                DataQ_dat=[DataQ_dat,DataQ_dat_app];
            end
        end
    end

    %Concatenate structures

    dataq_fld=fieldnames(DataQ_dat); %Get fieldnames from structure
    all_dat_dataq = struct;  %final structure
    for field = 3:length(dataq_fld) %Skip universal variables
       fname = dataq_fld{field};
       all_dat_dataq.(fname) = vertcat(DataQ_dat.(fname));
    end

    disp('Plotting figure...');

    %Override X-axis limits
    if date_override
        init_date_old=init_date;
        init_date=override_init_date;
        end_date_old=end_date;
        end_date=override_end_date;
        dt_format=override_dt_format;
    end

    %Set X-axis limits
    xlimits=[datenum(init_date),datenum(end_date)];

    %Filter recent Pyr data
    bad_pyr_index=find(all_dat_dataq.date_time<datetime('05/05/2022 20:00:00',InputFormat='MM/dd/yyyy HH:mm:SS') & ...
        all_dat_dataq.date_time>datetime('12/31/2021 00:00:00',InputFormat='MM/dd/yyyy HH:mm:SS'));
    all_dat_dataq.Pyr(bad_pyr_index)=NaN;
    
    %Increment figure counter
    fig_count=fig_count+1;


    %Initialize parameters
    fts=11;
    point_color=[0.6,0.6,0.6];
    fdataq=figure(fig_count);
    scrsz = get(groot,'ScreenSize');
    set(fdataq,'Position',[scrsz(4).*.1 scrsz(3).*.1 scrsz(3).*.55 scrsz(4).*.65])
    set(0,'DefaultFigureVisible','on');  %Suppresses figure visibility during processing - set to on if desired    tmax=30;
    clf

    tmax=30;
    tmin=5;
    baro_max=1040;
    baro_min=1001;
    hum_max=100;
    hum_min=10;
    pyr_max=2000;
    pyr_min=-200;

    %**************************************************************************
    % PLOT Parameters
    tiledlayout(4,1)
    nexttile
    hold on; box on; grid on; set(gca,'FontSize',fts);
    hdq1=plot(all_dat_dataq.date_time,all_dat_dataq.T_Air_upr,'m.');
    hold on
    hdq2=plot(all_dat_dataq.date_time,all_dat_dataq.T_Air_lwr,'c-');
    set(gca,'Xlim',datetime({init_date,end_date},'InputFormat',dt_format));
    %set(gca,'YScale','linear','YLim',[tmin,tmax]);
    xlabel(''); ylabel('Air Temperature');
    legend([hdq1,hdq2],'T\_air (upper)','T\_air (lower)');
    title('DataQ');

   %Format x-axis labels
    xtick=get(gca,'XTick');
    xticklab=datestr(xtick,"mm/dd HH:MM");
    set(gca,'XtickLabel',xticklab);

    %####################

    nexttile
    hold on; box on; grid on; set(gca,'FontSize',fts); 
    for np=1:length(DataQ_dat)
        hdq3=plot(all_dat_dataq.date_time,all_dat_dataq.Baro,'k+');
        if np==1
            hold on
        end
    end
    set(gca,'Xlim',datetime({init_date,end_date},'InputFormat',dt_format),'Xtick',xtick);
    %set(gca,'Ylim',[baro_min,baro_max]);
    xlabel(''); ylabel('Pressure [mb]');

    %Format x-axis labels
    xtick=get(gca,'XTick');
    xticklab=datestr(xtick,"mm/dd HH:MM");
    set(gca,'XtickLabel',xticklab);
 
    %####################

    nexttile
    hold on; box on; grid on; set(gca,'FontSize',fts);
    for np=1:length(DataQ_dat)
        hdq4=plot(all_dat_dataq.date_time,all_dat_dataq.RelHumid_upr,'m.');
        if np==1
            hold on
        end
        hdq5=plot(all_dat_dataq.date_time,all_dat_dataq.RelHumid_lwr,'c-');
    end
    set(gca,'Xlim',datetime({init_date,end_date},'InputFormat',dt_format)); ...
    %set(gca,'YScale','linear','YLim',[hum_min,hum_max]);
    xlabel(''); ylabel('Relative Humidity (%)');
    legend([hdq4,hdq5],'RH (upper)','RH (lower)');

    %Format x-axis labels
    xtick=get(gca,'XTick');
    xticklab=datestr(xtick,"mm/dd HH:MM");
    set(gca,'XtickLabel',xticklab);
 
    %####################

    nexttile
    hold on; box on; grid on; set(gca,'FontSize',fts);
    for np=1:length(DataQ_dat)
        hdq6=plot(all_dat_dataq.date_time,all_dat_dataq.NetRad,'m.');
        if np==1
            hold on
        end
        hdq7=plot(all_dat_dataq.date_time,all_dat_dataq.Pyr,'c-');
    end
    set(gca,'Xlim',datetime({init_date,end_date},'InputFormat',dt_format),'YScale','linear','YLim',[pyr_min,pyr_max]);
    xlabel('DATE/TIME'); ylabel('Solar Irradiance (W/m2)');
    legend([hdq6,hdq7],'NetRad','Pyr');

   %Format x-axis labels
    xtick=get(gca,'XTick');
    xticklab=datestr(xtick,"mm/dd HH:MM");
    set(gca,'XtickLabel',xticklab);
 
    %####################
    init_date_str=datestr(init_date,'yyyymmdd');
    end_date_str=datestr(end_date,'yyyymmdd');

    print(gcf,[outpath,'DataQ_time_series_',init_date_str,'-',end_date_str,'.tif'],'-dtiff','-r300');
        
    if DataQ_save
        dataq_fld=fieldnames(all_dat_dataq);
        save_index=all_dat_dataq.date_time>=datetime(init_date,'InputFormat',dt_format) & ...
            all_dat_dataq.date_time<=datetime(end_date,'InputFormat',dt_format);
        for isen=2:length(dataq_fld)
            all_dat_dataq.(dataq_fld{isen})=all_dat_dataq.(dataq_fld{isen})(save_index);
        end
        save([outpath,'DataQ_time_series_',init_date_str,'-',end_date_str,'.mat'],'all_dat_dataq');
    end

    clearvars -except 'init_date' 'end_date' 'init_date_str' 'end_date_str' 'xlimits' ...
    'ATI' 'Delta' 'KZ_Scint' 'Portlog' 'Gill'  'DataQ' 'fig_count' 'inpath_pref'  ...
    'date_override' 'override_init_date' 'override_end_date'  'DataQ_save' ...
        'ATI_save' 'Gill_save' 'DPL' 'DPL_save' 'dt_format' 'override_dt_format' %Clears variables from workspace

end
 
 %% Plot DPL
 
 if DPL
     %Input filenames for reading
     inpath=[inpath_pref,'DPL_SMAST/processed/'];
     outpath=[inpath_pref,'DPL_SMAST/plots/'];
     
     %Retrieve file information
     FList=dir([inpath,'*.mat']);
     
     [filen,~]=size(FList);
     
     for ifile=1:filen
         file_name=FList(ifile).name;
         
         %Check for data range
         %Find initial index for date string
 
         if strcmp(file_name(1:4),'Data')
             DPL_date=file_name(12:28);
         elseif strcmp(file_name(1:4),'File')
             DPL_date=file_name(6:22);
         elseif strcmp(file_name(1:3),'DPL')
             DPL_date=file_name(18:34);
         end
 
         DPL_datetime=datetime(DPL_date,'InputFormat','yy-MM-dd-HH-mm-ss');
     
         if DPL_datetime >= datetime(init_date,'InputFormat',dt_format) &&...
                 DPL_datetime < datetime(end_date,'InputFormat',dt_format)
             disp(['Reading DPL_SMAST_210911_',DPL_date,'.mat']);
             %Check 
 
             if ~exist('DPL_dat','var')
                 %Load data
                 DPL_dat=load([inpath,file_name]);
             else
                 %Load data and append to existing structure
                 DPL_dat_app=load([inpath,file_name]);
                 DPL_dat=[DPL_dat,DPL_dat_app];
             end
         end
     end
 
     %Concatenate structures
 
     [~,mm]=size(DPL_dat);
     dpl_fld=fieldnames(DPL_dat); %Get fieldnames from structure
     var_indx=find(contains(dpl_fld,{'H1','H2','H3','H4','H5'}));  %Get indices for desired variables (exclude attributes)
     dt_indx=find(contains(dpl_fld,{'H1','H2','H3','H4','H5','date_time'}));  %Get indices for desired variables (exclude attributes)
     plt_indx = find(contains(dpl_fld,{'H1','H2','H3','H4','H5'}));  %Get indices for plot variables 

     all_dat_dpl = struct;  %final structure for sensor data
     for ifile=1:mm
         numfld=length(dpl_fld);
         if ifile==1
             all_dat_dpl.date_time = DPL_dat(ifile).date_time;
         else
             all_dat_dpl.date_time = [all_dat_dpl.date_time;...
                 DPL_dat(ifile).date_time];
         end

         for isen = 1:5  %Exclude attribute fields  
             variables=DPL_dat(ifile).variables;
             numvar=length(variables);
             fname = char(dpl_fld(plt_indx(isen)));
             % if strcmp(fname,'date_time')
                 % if ifile==1
                 %     all_dat_dpl.(variables{1}) = DPL_dat(ifile).(variables{1});
                 % else
                 %     all_dat_dpl.(variables{1}) = [all_dat_dpl.(variables{1});...
                 %         DPL_dat(ifile).(variables{1})];
                 % end
             %DP else
             for iv=1:numvar
                 if ifile==1 
                     if isempty(DPL_dat(ifile).(fname).(variables{iv})) 
                         all_dat_dpl.([fname,'_',variables{iv}])=nan(length(DPL_dat(ifile).date_time),1);
                     else
                         all_dat_dpl.([fname,'_',variables{iv}]) = DPL_dat(ifile).(fname).(variables{iv});
                     end
                 else
                     if isempty(DPL_dat(ifile).(fname).(variables{iv}))
                         all_dat_dpl.([fname,'_',variables{iv}])=[all_dat_dpl.([fname,'_',variables{iv}]);...
                             nan(length(DPL_dat(ifile).date_time),1)];
                     else
                         all_dat_dpl.([fname,'_',variables{iv}]) = [all_dat_dpl.([fname,'_',variables{iv}]);...
                             DPL_dat(ifile).(fname).(variables{iv})];
                     end
                 end 
             end
         end
     end
 
 
     all_fld=fieldnames(all_dat_dpl);
 
     %Remove NaT points and duplicate times and sort by time
     [~,good_indx,~]=unique(all_dat_dpl.date_time);
     bad_indx=isnat(all_dat_dpl.date_time(good_indx));

     
     for isen = 1:length(all_fld) 
        fname = all_fld{isen};
        all_dat_dpl.(fname) = all_dat_dpl.(fname)(good_indx(~bad_indx));
     end
     
     %{
     [all_dat_dpl.date_time,sort_indx]=sort(all_dat_dpl.date_time);
     for ifield = 1:length(all_fld)
        fname = all_fld{ifield};
        all_dat_dpl.(fname) = all_dat_dpl.(fname)(sort_indx);
     end
     %}
 
     %COMMENTED OUT - NOW PART OF CSV2MAT SCRIPT
     %Get time correction data (THIS WORKS ONLY FOR PERIOD 09/08/22 to 10/20/22)
     %{
     time_table=readtable([inpath,'..\DPL_time_offset_calculation.xlsx'],'Sheet','Sheet2');
     time_table=table2array(time_table);
 
     %Do time correction
     dpl_time_interp=interp1(time_table(:,2),time_table(:,1),all_dat_dpl.date_time);
     all_dat_dpl.date_time=dpl_time_interp;
     %}
 
     %ALTERNATE METHODS - NOT AS ACCURATE
     %days_duration=days(all_dat_dpl.date_time-datetime('09/08/2022 16:40:30','InputFormat','MM/dd/uuuu HH:mm:ss'));
     %time_offset=6.364E-05.*days_duration.^2+2.052E-02.*(days_duration);  %Based on time series of offsets from 09/08/22 to 10/20/22
     %time_offset=(0.00006799.*days_duration + 0.02046).*days_duration;  %Based on time series of offsets from 09/08/22 to 10/20/22
     %all_dat_dpl.date_time_corr=all_dat_dpl.date_time+days(time_offset);
 
     numsens=5;  %Number of sensors to include in plot
     for sensn=1:numsens
         u=all_dat_dpl.(['H',num2str(sensn),'_u']);
         v=all_dat_dpl.(['H',num2str(sensn),'_v']);
         T_Air=all_dat_dpl.(['H',num2str(sensn),'_T_Air']);  
         RelHumid=all_dat_dpl.(['H',num2str(sensn),'_RelHumid']);  
         %if length(u)>length(v)
             u=u(1:length(v),:);
         %end
         field_str=['WindSpd_H',num2str(sensn)];
         all_dat_dpl.(field_str)=sqrt(u.^2 + v.^2);
         field_str=['WindSpd_smooth_H',num2str(sensn)];
         all_dat_dpl.(field_str)=smoothdata(all_dat_dpl.(['WindSpd_H',num2str(sensn)]),...
             'movmean',minutes(1),'SamplePoints',all_dat_dpl.date_time);
         field_str=['T_Air_smooth_H',num2str(sensn)];
         all_dat_dpl.(field_str)=smoothdata(T_Air,...
             'movmean',minutes(1),'SamplePoints',all_dat_dpl.date_time); 
         field_str=['RelHumid_smooth_H',num2str(sensn)];
         all_dat_dpl.(field_str)=smoothdata(RelHumid,...
             'movmean',minutes(1),'SamplePoints',all_dat_dpl.date_time);   %Moving average smoothing with window equivalent to 1 min
     end
 
     %clear {'DPL_dat','DPL_dat_app','DPL_date','DPL_datenum'};
 
     % Plot DPL
 
     %Override X-axis limits
     if date_override
         init_date_old=init_date;
         init_date=override_init_date;
         end_date_old=end_date;
         end_date=override_end_date;
         dt_format=override_dt_format;
    end
 
     %Get indices for desired time range
     dataindx=find(all_dat_dpl.date_time>=datetime(init_date,'InputFormat',dt_format) & ...
             all_dat_dpl.date_time<=datetime(end_date,'InputFormat',dt_format));
     
     %Set X-axis limits
     xlimits=[datetime(init_date,'InputFormat',dt_format),datetime(end_date,'InputFormat',dt_format)];
 
     %Increment figure counter
     fig_count=fig_count+1;
 
     %Initialize parameters
     fts=4;
     %point_color=[0.6,0.6,0.6];
     fdpl=figure(fig_count);
     scrsz = get(groot,'ScreenSize');
     set(fdpl,'Position',[scrsz(4).*.1 scrsz(3).*.1 scrsz(3).*.55 scrsz(4).*.65])
     set(0,'DefaultFigureVisible','on');  %Suppresses figure visibility during processing - set to on if desired    tmax=30;
     tmax=30;
     tmin=5;
     wspd_max=10;
     wspd_min=-10;
     numsens=5;
     mrk_sz = 1;

     %**************************************************************************
     % PLOT Parameters
     tiledlayout(3,1)
     nexttile
     hold on; box on; grid on; set(gca,'FontSize',fts);
     map = get(gca,'ColorOrder');   %Set same color order
     %{
     for sn=1:numsens
         field_str=['S',num2str(sn),'_T_Air'];
         plot(all_dat_dpl.date_time(dataindx), all_dat_dpl.(field_str)(dataindx),...
             'o','MarkerSize',3,'Linewidth',1);
     end
     %}
     hold on
     for sn=1:numsens
         field_str=['H',num2str(sn),'_T_Air'];
         plot(all_dat_dpl.date_time(dataindx), all_dat_dpl.(field_str)(dataindx),'o','MarkerSize',mrk_sz,'Linewidth',1);
     end
     set(gca,'Xlim',[datetime(init_date,'InputFormat',dt_format), ...
         datetime(end_date,'InputFormat',dt_format)]);
     set(gca,'Ylim',[tmin,tmax]);
     xlabel(''); ylabel('TEMP AIR [C]');
     legend({'H1','H2','H3','H4','H5'});
     title('DPL (1-min avg)');
 
     %Format x-axis labels
     xtick=get(gca,'Xtick');
     xticklab=datestr(xtick,"mm/dd HH:MM");
     set(gca,'XtickLabel',xticklab);
 
     nexttile
     hold on; box on; grid on; set(gca,'FontSize',fts);
     map = get(gca,'ColorOrder');   %Set same color order
     %{
     for sn=1:numsens
         field_str=['S',num2str(sn),'_RelHumid'];
         plot(all_dat_dpl.date_time(dataindx), all_dat_dpl.(field_str)(dataindx),'o','MarkerSize',3mrk_sz,'Linewidth',1);
     end
     %}
     hold on
     for sn=1:numsens
         field_str=['RelHumid_smooth_H',num2str(sn)];
         plot(all_dat_dpl.date_time(dataindx), all_dat_dpl.(field_str)(dataindx),'o','MarkerSize',mrk_sz,'Linewidth',1);
     end
     set(gca,'Xlim',datetime({init_date,end_date},'InputFormat',dt_format));
     %set(gca,'Ylim',[tmin,tmax]);
     
     xlabel(''); ylabel('REL HUMIDITY [%]');
 
     %Format x-axis labels
     set(gca,'XtickLabel',xticklab);
 
     nexttile
     hold on; box on; grid on; set(gca,'FontSize',fts); 
 
     for sn=1:numsens
         field_str=['H',num2str(sn),'_WindSpd'];
         plot(all_dat_dpl.date_time(dataindx), all_dat_dpl.(field_str)(dataindx),'o','MarkerSize',mrk_sz,'Linewidth',1);
     end
     
     % for sn=1:numsens
     %     field_str=['H',num2str(sn),'_w'];
     %     plot(all_dat_dpl.date_time(dataindx), all_dat_dpl.(field_str)(dataindx),...
     %         'o','MarkerSize',2,'Linewidth',1);
     % end
     set(gca,'Xlim',datetime({init_date,end_date},'InputFormat',dt_format)); %,'Xtick',xtick);
     set(gca,'Ylim',[wspd_min,wspd_max]);
     xlabel('DATE/TIME'); ylabel('WIND SPEED(w component)[m/s]');
     set(gca,'XtickLabel',xticklab);
  
     %####################
 
     %Reformat date strings for output filename
     init_date_str=datestr(init_date,'yyyymmdd');
     end_date_str=datestr(end_date,'yyyymmdd');
 
     % outpath='C:\Users\slohrenz\Documents\Steve\DATA\NUWC\DPLProcessing\';

     % print(gcf,[outpath,'DPL_time_series_',init_date_str,'-',end_date_str,'.tif'],'-dtiff','-r300');
         
     
     if DPL_save
       all_dpl=struct;
       dpl_fld_new=fieldnames(all_dat_dpl);
       for isen=1:length(dpl_fld_new)  %Skip attribute fields
           all_dpl.(dpl_fld_new{isen})=all_dat_dpl.(dpl_fld_new{isen})(dataindx);
       end
       save([outpath,'DPL_time_series_',init_date_str,'-',end_date_str,'.mat'],'all_dpl');
     end
 
     init_date=init_date_old;
     end_date=end_date_old;
 
     clearvars -except 'init_date' 'end_date' 'init_date_str' 'end_date_str' 'xlimits' ...
         'ATI' 'Delta' 'KZ_Scint' 'Portlog' 'Gill'  'DataQ' 'fig_count' 'inpath_pref' ...
         'date_override' 'override_init_date' 'override_end_date'  'DataQ_save' ...
         'ATI_save' 'Gill_save' 'DPL' 'DPL_save' 'dt_format' 'override_dt_format' 'all_dat_dpl' %Clears variables from workspace
     
 end

disp('Completed');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%------------- END OF CODE --------------
%


