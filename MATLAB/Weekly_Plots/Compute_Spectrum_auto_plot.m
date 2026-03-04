function [PowerSpectra] = Compute_Spectrum_auto_plot(data,plot_num,FigHandle,plot)
arguments
  data = []
  plot_num = 1
  FigHandle = []
  plot = 1
end
% function [PowerSpectra] = computeSpectrum(data)
%
% Marine Wave Boundary Layer Analysis
% Script for computing power spectrum from sonic anemometer data
%
% Inputs:
%   data 		- structure variable from ATI or Gill sonic, or single DPL ATI (e.g., H1)
% 
% Outputs: 
%   PowerSpectra	- structure variable contining the following fields:
%     Pxx,Pyy,Pzz,Ptt	- power spectral density of u, v, w, T
%     freqs		- array of frequencies (Hz) over which spectrum is computed
% 
% Written by Miles A. Sundermeyer, 4/15/2023
% Edited by Tyler D. Knap, 05/13/2025 - Added FigHandle
% Revised by Tyler Knapp, 09/24/2025 - Changed T_Air to T_Sonic

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Parse data, depending on what type of data file is being loaded
date_time = datenum(data.date_time);		% convert from date_time to datenum format
u = data.u;			% (m/s) u velocity
v = data.v;			% (m/s) v velocity
w = data.w;			% (m/s) w velocity
T = data.T_Sonic;			% (deg C) Sonic temperature

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Only run this if passed non-empty variables
if ~isempty(u) & ~isempty(v) & ~isempty(w) & ~isempty(T)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % check that T is in C, not K
  if median(T)>200
    warning('Temperature appears to aleardy be in Kelvin ...')
    T = T - 273.15;		% will convert back to Kelvin below
  end
  samplingFrequency = round(1/(86400 * median(diff(date_time))));	% (Hz)

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  N = length(date_time);
  if mod(N,2)==0			% even number of data
  else				% odd number of data pts, force data to have even number of pts
    date_time(end) = [];
    u(end) = [];
    N = N-1;
  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if(1) 				% Compute spectrum "by hand"
    % Do all three components of velocity
    Xn = fft(u,N);
    Pxx = Xn.*conj(Xn)/N;
    % get rid of negative freq parts of Pxx
    Pxx(N/2+2:end) = [];				% Note: N is even, so keep N/2+1 as Nyquist
    % and double power of pos freq parts
    Pxx(2:end-1) = 2*Pxx(2:end-1);			% double all but zero freq and Nyquist

    Yn = fft(v,N);
    Pyy = Yn.*conj(Yn)/N;
    % get rid of negative freq parts of Pxx
    Pyy(N/2+2:end) = [];				% Note: N is even, so keep N/2+1 as Nyquist
    % and double power of pos freq parts
    Pyy(2:end-1) = 2*Pyy(2:end-1);			% double all but zero freq and Nyquist

    Zn = fft(w,N);
    Pzz = Zn.*conj(Zn)/N;
    % get rid of negative freq parts of Pxx
    Pzz(N/2+2:end) = [];				% Note: N is even, so keep N/2+1 as Nyquist
    % and double power of pos freq parts
    Pzz(2:end-1) = 2*Pzz(2:end-1);			% double all but zero freq and Nyquist

    Tn = fft(T,N);
    PTT = Tn.*conj(Tn)/N;
    % get rid of negative freq parts of Pxx
    PTT(N/2+2:end) = [];				% Note: N is even, so keep N/2+1 as Nyquist
    % and double power of pos freq parts
    PTT(2:end-1) = 2*PTT(2:end-1);			% double all but zero freq and Nyquist

    % Make freq array from zero freq to Nyquist
    df = 1/(86400*(datenum(date_time(end)) - datenum(date_time(1))));		% (1/s)
    freqs = df*[0:N/2];
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  else				% use Matlab's pspectrum 
    [Pxx,freqs] = pspectrum(u,samplingFrequency,'power');
    [Pyy,freqs] = pspectrum(v,samplingFrequency,'power');
    [Pzz,freqs] = pspectrum(w,samplingFrequency,'power');
    [PTT,freqs] = pspectrum(T,samplingFrequency,'power');
  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  PowerSpectra.freqs = freqs;
  PowerSpectra.Pxx = Pxx;
  PowerSpectra.Pyy = Pyy;
  PowerSpectra.Pzz = Pzz;
  PowerSpectra.PTT = PTT;

  if(plot)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    figure(FigHandle(plot_num));
    clf
       
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    subplot(2,2,1)
    loglog(freqs,Pxx,'b-');

    ylabel('P_{xx} (m^2/s^2)')

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    subplot(2,2,2)
    loglog(freqs,Pyy,'b-');

    ylabel('P_{yy} (m^2/s^2)')

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    subplot(2,2,3)
    loglog(freqs,Pzz,'b-');

    ylabel('P_{zz} (m^2/s^2)')

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    subplot(2,2,4)
    loglog(freqs,PTT,'b-');

    ylabel('P_{TT} (^oC^2)')

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for n=1:4
      subplot(2,2,n)
      hold on
      xlabel('frequency (Hz)')

      grid on
      axis([1e-5 1e1 1e-10 1e6])
      ax = axis;

      plot(ax(1)*[1e3 1e5],1e1*(ax(1)*[1e3 1e5]).^(-5/3),'r-','linewidth',2)
      text(ax(1)*1e4,1e1*(ax(1)*1e4).^(-5/3),'-5/3','color','r','VerticalAlignment','base')
      data_stream = ["ATI SMAST";"Gill SMAST";"ATI CBC";"DPL SMAST";"DPL CBC"];
      sgtitle(data_stream(plot_num,:))
    end
  end
else
  PowerSpectra = struct('freqs',[],'Pxx',[],'Pyy',[],'Pzz',[],'PTT',[]);
end
