function [RMSE, NMSE, NDEI, R2] = calculate(y_orig, y_eval)
% Initialization
N = size(y_orig, 1);
SSres = 0;
SStot = 0;
y_average = mean(y_orig);

% RMSE
for i=1:N
    SSres = SSres + (y_orig(i) - y_eval(i))^2;      % Σ(y-y^)
    SStot = SStot + (y_orig(i) - y_average)^2;      % Σ(y-y⎻)
end
MSE = SSres/N;
RMSE = sqrt(MSE);

% NMSE
NMSE = SSres/SStot;

% NDEI
NDEI = sqrt(NMSE);

% R2
R2 = 1 - SSres/SStot;
end

