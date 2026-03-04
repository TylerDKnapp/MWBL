function [ensembleTime,ensembleAvg,ensembleVar] = ensembleAverage(date_time, inputData, samplePeriod)
arguments
  % date_time = (datetime('now') + seconds(1:1000)).' % Column Array
  date_time = convertTo((datetime('now') + seconds(1:1000)).','posixtime') % Column Array
  inputData = ones(1000,1) % Column Array
  samplePeriod = 60 % Seconds
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % ensembleAverage Calculate the ensembled average
  %   
  % Inputs:
  %   date_time = array of datetime variables
  %   inputData = array of data to process
  %   samplePeriod = period of data to average across [sec]
  %
  % Outputs:
  %   ensembleTime = array of ensembled average of date_time
  %   ensembleAvg = array of ensembled average of inputData
  %   ensembleVar = array of ensembled variance of inputData
  %
  % Modified by Tyler Knapp 09/24/2025 - Added catch for datetime
  % Modified by Tyler Knapp 09/30/2025 - Converting from index based to time based, required argument changes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                           % Function Start %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if ~(class(date_time) == "double") && ~(class(date_time) == "int64")  % For days since epoch
    error("ERROR: In ensembleAverage.m - date_time must be of type double or int64. date_time is: %s",class(date_time))
  end
  timeStep = date_time(find(~isnan(date_time),1,'first'));
  endTime = date_time(find(~isnan(date_time),1,'last'));
  samplingFrequency = 1/(median(diff(date_time),'omitnan'));	% (Hz)
  endIndx = [];
  % Pre-allocate arrays
  ensembleTime = [];
  ensembleAvg = [];
  ensembleVar = [];
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
        endIndx = find(abs(date_time - timeStep) <= 1/samplingFrequency,1);
        if ~isempty(endIndx)
          ensembleTime(itr) = mean(date_time(startIndx:endIndx),'omitnan');
          ensembleAvg(itr) = mean(inputData(startIndx:endIndx),'omitnan');
          ensembleVar(itr) = var(inputData(startIndx:endIndx),'omitnan');
        else
          ensembleTime(itr) = NaN;
          ensembleAvg(itr) = NaN;
          ensembleVar(itr) = NaN;
        end
        itr = itr + 1;
      end
    end
    % Add final step
    ensembleTime(itr) = mean(date_time(startIndx:endIndx),'omitnan');
    ensembleAvg(itr) = mean(inputData(startIndx:endIndx),'omitnan');
    ensembleVar(itr) = var(inputData(startIndx:endIndx),'omitnan');
    ensembleTime = ensembleTime.';
    ensembleAvg = ensembleAvg.';
    ensembleVar = ensembleVar.';
  end
end

