function [theta,rho] = cart2comp(x,y)
    [theta_rad,rho]=cart2pol(x,y);
    theta = rad2deg(theta_rad);
    %conversion from polar to compass
    theta = 90 - theta;
end

