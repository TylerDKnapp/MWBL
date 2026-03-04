function [x,y] = comp2cart(theta, rho)
    theta = 90 - theta;
    theta_rad = deg2rad(theta);
    [x,y] = pol2cart(theta_rad,rho);
end