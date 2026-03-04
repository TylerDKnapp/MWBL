%% Create a linear interpolation between two points with a desired number of points
function points = interpLocal(p1,p2,numPoints)
  if p1 == p2
    points = ones(1,numPoints)*p1;
  else
    itr = (p2-p1)/(numPoints+1);
    points = p1:itr:p2;
    points = points(2:(end-1));
  end
end