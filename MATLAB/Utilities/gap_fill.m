function [t_new,f_new] = gap_fill(t,f,varargin);
% function [t_new,f_new] = gap_fill(t,f,varargin);
%
% This function examines a data series, f(t), for any gaps in what is otherwise 
% regularly spaced data, and fills those time gaps with the mean of the series.
% The premise is that we have what should have been regularly sampled data,
% but that it has data gaps, and that we want to fill these data gaps before
% performing spectral analysis, or other analyses that assume regular data 
% spacing.
%
% Usage:
%   [t_new,f_new] = gap_fill(t, f, max_gap [1000], method ['mean','interp']);
%   where max_gap and method are optional inputs
%
% Inputs:
%   t, f		- assumed time (independent variable) 
%			  and f(t) (dependent variable)
%   max_gap 		- optional (default 1000), max number of points to interpolate
% 			  over before giving error
%   method		- string variable indicating 'mean' or 'interp' for mean value 
%			  or linear interpolation
%
% Outputs: 
%   t_new, f_new	- new t and f(t), but with t padded for any time gaps
%			  (jumps in time), and f(t) filled with mean(f) during
% 			  gap periods
%
% Notes: 	- t should be monotonic and contain no NaNs (okay if f(t) has NaNs)
% 		- filling gaps with the mean is identidical to de-meaning and 
%		  then filling with zeros
% 		- for data that are almost, but not quite regularly sampled, 
% 		  the median sample interval is used to fill gaps
%
% Example:
%   t = [0:100];
%   f = sin(2*pi/100*t);
%   t(40:50) = [];
%   f(40:50) = [];
%   plot(t,f,'bo-')
%   hold on
%
%   [t_new,f_new]=gap_fill(t,f,1000,'mean');
%   plot(t_new,f_new,'rs')
%   [t_new,f_new]=gap_fill(t,f,1000,'interp');
%   plot(t_new,f_new,'g^')
%
% Written by Miles A. Sundermeyer, 3/9/2023

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Preliminaries
% Check/set variable (optional) inputs
max_gap = 1000;			% max number of sample points to allow in gap
method = 'mean';

if length(varargin)==1
  max_gap = varargin{1};
elseif length(varargin)==2
  max_gap = varargin{1};
  method = varargin{2};
end

% put data in column format, remembering previous state
[m,n] = size(t);

if m>n			% data already in column format, [m x 1] array
  flipcols = 0;
else
  t = t';
  f = f';
  flipcols = 1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find mean sample interval of data
sample_int = median(diff(t));	

% Find mean of data
f_mean = mean(f,'omitnan');

% find indicies of original time series where sample interval is greater than
% some fraction of the median, say the median +/- 10 percent
err = 0.10;		% error tolerance when looking for gaps
			% same tolerance is used as warning in case gaps are uneven in time

% get indices of time gaps
gap_ind = find(diff(t) >= (1+err)*sample_int);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Loop through the indicies identified as gaps, and fill with regularly spaced time intervals
for n=1:length(gap_ind)
  % find out the gap size
  gap_size = diff(t(gap_ind(n)+[0 1]));			% gap size (time units)

  if gap_size/sample_int > max_gap			% gap is bigger than allowed number of pts
    error(['Gap size greater than ',num2str(max_gap),' points detected!'])
  else							% fill this gap
    % find how many points it will take to fill this gap
    npts = round((gap_size - sample_int)/sample_int);	% number of points needed to fill gap

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % create times at regular intervals, starting from 1 sample interval following last data point
    % and 1 sample interval before next in gap
    % Note, in linspace call below, intentionally include end points to make sure data are evenly 
    % spaced across entire interval
    gap_start = t(gap_ind(n));
    gap_end = t(gap_ind(n)+1);
    t_gap = [linspace(gap_start,gap_end,npts+2)]';	

    % now drop first and last points as these are already represented
    t_gap([1 npts+2]) = [];		

    % check to make sure new sample interval is consistent with existing
    if length(t_gap)>=2
      this_sample_int = diff(t_gap(1:2));			% interpolated sample interval
      if (this_sample_int > (1+err)*sample_int) | (this_sample_int < (1-err)*sample_int)
        warning(['**** New sample interval differs from old by more than ',num2str(100*err),'% ****'])
      end
    end

    % Insert these new times into the time variable
    t = [t(1:gap_ind(n)); t_gap; t(gap_ind(n)+1:end)];

    % and the dependent variable
    if strcmp(method,'mean')
      f_gap = f_mean*ones(size(t_gap));
    elseif strcmp(method,'interp')
      f_gap = interp1([gap_start gap_end],[f(gap_ind(n)) f(gap_ind(n)+1)],t_gap);
    end
    f = [f(1:gap_ind(n)); f_gap; f(gap_ind(n)+1:end)];

    % add npts to remainder of gap_ind array so we keep track of new index locations
    gap_ind(n+1:end) = gap_ind(n+1:end) + npts;

    % Report to command line what we did
    disp(strcat('  Gap filled: gap start: ',datestr(t(gap_ind(n))),', gap size:',string(gap_size)));
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
t_new = t;
f_new = f;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If appropriate, flip data back to row format
if flipcols
  t_new = t_new';
  f_new = f_new';
end    
