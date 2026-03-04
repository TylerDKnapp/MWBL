function [ensembleTime,index] = getdatetimeIndex(date_time, samplePeriod, samplingFrequency)
arguments
  date_time = convertTo((datetime('now') + seconds(1:0.05:1000)).','posixtime') % Column Array
  samplePeriod = 300 % s
  samplingFrequency = 1/20
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % getdatetimeIndex Calculate the ensembled average
  %   
  % Inputs:
  %   index = array of indexs representing the time steps desired to take average from
  %   inputData = array of data to process
  %
  % Outputs:
  %   ensembleTime = array of ensembled average of date_time
  %   index = array of indexes used to find above
  %
  % Created by Tyler Knapp 09/30/2025
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                           % Function Start %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if ~(class(date_time) == "double") && ~(class(date_time) == "int64")  % For days since epoch
    error("ERROR: In getdatetimeIndex.m - date_time must be of type double or int64. date_time is: %s",class(date_time))
  end
  timeStep = date_time(find(~isnan(date_time),1,'first'));
  endTime = date_time(find(~isnan(date_time),1,'last'));
  ensembleTime = [];
  index = [];
  endIndx = [];
  itr = 1;
  if sum(~isnan(date_time)) > 0
    % Loop through time series
    while timeStep < endTime
      if ~isempty(endIndx)
        startIndx = endIndx;
      else
        startIndx = find(abs(date_time - timeStep) <= 1/samplingFrequency,1);
      end
      timeStep = timeStep + samplePeriod; % Advance timeStep
      if ~isempty(startIndx)
        index(itr) = startIndx;
        endIndx = find(abs(date_time - timeStep) <= 1/samplingFrequency,1);
        if ~isempty(endIndx)
          ensembleTime(itr) = mean(date_time(startIndx:endIndx),'omitnan');
        else
          ensembleTime(itr) = NaN;
        end
        itr = itr + 1;
      end
    end
    % Add final index/time
    index(itr) = length(date_time);
    ensembleTime(itr-1) = mean(date_time(startIndx:end),'omitnan');
    ensembleTime = ensembleTime.';
  end
end

