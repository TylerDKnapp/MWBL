%% Process data function, removes erronious spikes in data
function dataOut = remove_spikes(dataIn,rateLimit)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Remove spikes in sensor temperature
  % Note: will not catch case if second index of data is also bad.
  try % Try to convert from table to array
    dataIn = table2array(dataIn);
    inputIsTable = true;
  catch % If above threw an error assume dataIn is already an array
    inputIsTable = false;
  end
  dataOut = dataIn;
  dxIndx = find(diff(dataIn)>rateLimit);
  if ~isempty(dxIndx)
    for i = 1:length(dxIndx)-1
      j = dxIndx(i)+1;
      itrDt = abs(dataOut(j-1,1) - dataOut(j,1));
      itrDt_N1 = abs(dataOut(j-1,1) - dataOut(j+1,1)); % Check dt with next value to see if it is a single error
  
      if ((itrDt > rateLimit) && (itrDt_N1 <= rateLimit))
        % if data is bad, average previous and next time steps
        dataOut(j,1) = (dataOut(j-1,1) + dataOut(j+1,1))/2;
      elseif ((itrDt > rateLimit) && (itrDt_N1 > rateLimit))
        itr = j+1;
        itrPrevGood = j - 1;
        
        while (abs(dataOut(j-1,1) - dataOut(itr,1)) > rateLimit)
          itr = itr + 1;
          itrNextGood = itr;
          if (itr >= length(dataOut(:,1)))
            itrNextGood = itrPrevGood; % Erronious data goes until end of file, make data equal to the last good point of data
            break
          end
        end
  
        tmp_interp = interpLocal(dataOut(j-1,1), dataOut(itrNextGood,1), length(j:itr-1));
        dataOut(j:itr-1,1) = tmp_interp;
      end
    end
  end
  % Convert back to table, if dataIn was in table format
  if inputIsTable
    dataOut = array2table(dataOut);
  end
end