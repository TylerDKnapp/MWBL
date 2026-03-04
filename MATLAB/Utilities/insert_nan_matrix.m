% Written by Tyler D. Knapp and Miles A. Sundermeyer 06/05/2025
function data = insert_nan_matrix(data,dataStream,max_cont_time)

  vars = fieldnames(data);
  len_data = length(data.date_time);

  if ~isempty(data.date_time)
    dt = minutes(diff(data.date_time));
    NanInsInd = find(dt>=max_cont_time); % find indicies of time gaps > max_cont_time
    len_nan = length(NanInsInd);

    if len_nan > 0
      data_tmp = zeros(len_data + len_nan,1); % make time array to account for NaN indicies 
      data_tmp(NanInsInd + (1:len_nan).') = nan; % assign NaN's where needed
      NotNanInd = find(~isnan(data_tmp)); % get indices of new array that are not Nan

      if contains(dataStream, 'DPL')
        %%% Special Formatting for DPL Data %%%
        datetime_tmp = datetime(zeros(len_data + len_nan,1),'ConvertFrom','posixtime'); % make new time array to account for NaN indicies
        datetime_tmp(NanInsInd + (1:size(NanInsInd,1)).') = NaT; % assign NaT's where needed
        datetime_tmp(NotNanInd) = data.date_time; % assign original date_times to the non-nan indices
        data.date_time = datetime_tmp;
        for sensorItr = 1:5
          len_data = length(data.(['H',num2str(sensorItr)]).date_time);
          if ~isempty(data.(['H',num2str(sensorItr)]).date_time)
            dt = minutes(diff(data.(['H',num2str(sensorItr)]).date_time));
            NanInsInd = find(dt>=max_cont_time); % find indicies of time gaps > max_cont_time
            len_nan = length(NanInsInd);
              
            data_tmp = zeros(len_data + len_nan,1); % make time array to account for NaN indicies 
            data_tmp(NanInsInd + (1:len_nan).') = nan; % assign NaN's where needed
            NotNanInd = find(~isnan(data_tmp)); % get indices of new array that are not Nan
            if len_nan > 0
              datetime_tmp = datetime(zeros(len_data + len_nan,1),'ConvertFrom','posixtime'); % make new time array to account for NaN indicies
              datetime_tmp(NanInsInd + (1:size(NanInsInd,1)).') = NaT; % assign NaT's where needed
              datetime_tmp(NotNanInd) = data.(['H',num2str(sensorItr)]).date_time; % assign original date_times to the non-nan indices
              data.(['H',num2str(sensorItr)]).date_time = datetime_tmp;
  
              vars = fieldnames(data.(['H',num2str(sensorItr)]));
              for j = 1:length(vars)
                if ~isempty(data.(['H',num2str(sensorItr)]).(vars{j})) && ~(class(data.(['H',num2str(sensorItr)]).(vars{j})) == "datetime")
                  data_tmp(NotNanInd) = data.(['H',num2str(sensorItr)]).(vars{j}); % assign original data to the non-nan indices
                  data.(['H',num2str(sensorItr)]).(vars{j}) = data_tmp;
                end
              end
              
            end
          end
        end

      else
        %%% Default Formatting %%%
        for j = 1:length(vars)
          if ~contains(vars{j}, 'variable') && ~contains(vars{j}, 'unit')
            if class(data.(vars{j})) == "datetime"
              datetime_tmp = datetime(zeros(size(data.(vars{j}),1) + size(NanInsInd,1),1),'ConvertFrom','posixtime'); % make new time array to account for NaN indicies
              datetime_tmp(NanInsInd + (1:size(NanInsInd,1)).') = NaT; % assign NaT's where needed
              datetime_tmp(NotNanInd) = data.(vars{j}); % assign original date_times to the non-nan indices
              data.(vars{j}) = datetime_tmp;
            elseif length(data.(vars{j})) == len_data
              data_tmp(NotNanInd) = data.(vars{j}); % assign original data to the non-nan indices
              data.(vars{j}) = data_tmp;
            end
          end
        end

      end
    end
  end

end