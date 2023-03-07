% Δημήτρης Παππάς
% ΑΕΜ: 8391     
% ΗΜΜΥ ΑΠΘ 
% FLC Car Control
clear all;

%% Ασαφές Σύστημα
car_control = newfis('carcontrol', ...      % name of FIS system
    'mamdani', ...                          % mamdani type
    'min', ...                              % το συνδετικό AND υλοποιείται με τελεστή min
    'max', ...                              % το συνδετικό OR υλοποιείται με τελεστή max
    'min', ...                              % το Implication υλοποιείται με τελεστή min
    'max', ...                              % το Aggregation υλοποιείται με τελεστή max
    'centroid');                            % o Defuzzifier υλοποιείται με τεχνική centroid (COA)

%% Fuzzy Inputs
car_control = addvar(car_control, 'input', 'dV', [0,1]);                    % input #1
car_control = addvar(car_control, 'input', 'dH', [0,1]);                    % input #2
car_control = addvar(car_control, 'input', 'theta', [-180,180]);            % input #3
car_control = addvar(car_control, 'output', 'dtheta', [-130,130]);          % output #1

%% Membership Functions
% Για την είσοδο dV
car_control = addmf(car_control, 'input', 1, 'S', 'trimf', [0,0,0.5]);
car_control = addmf(car_control, 'input', 1, 'M', 'trimf', [0,0.5,1]);
car_control = addmf(car_control, 'input', 1, 'L', 'trimf', [0.5,1,1]);

% Για την είσοδο dH
car_control = addmf(car_control, 'input', 2, 'S', 'trimf', [0,0,0.5]);
car_control = addmf(car_control, 'input', 2, 'M', 'trimf', [0,0.5,1]);
car_control = addmf(car_control, 'input', 2, 'L', 'trimf', [0.5,1,1]);

% Για την είσοδο theta
car_control = addmf(car_control, 'input', 3, 'N', 'trimf', [-180,-180,0]);
car_control = addmf(car_control, 'input', 3, 'Z', 'trimf', [-180,0,180]);
car_control = addmf(car_control, 'input', 3, 'P', 'trimf', [0,180,180]);

% Για την έξοδο dtheta - Αχρικές τιμές
% car_control = addmf(car_control, 'output', 1, 'N', 'trimf', [-130,-130,0]);
% car_control = addmf(car_control, 'output', 1, 'Z', 'trimf', [-130,0,130]);
% car_control = addmf(car_control, 'output', 1, 'P', 'trimf', [0,130,130]);

% Για την έξοδο dtheta - Τελικές τιμές
car_control = addmf(car_control, 'output', 1, 'N', 'trapmf', [-130,-130,-100,0]);
car_control = addmf(car_control, 'output', 1, 'Z', 'trimf', [-90,0,90]);
car_control = addmf(car_control, 'output', 1, 'P', 'trapmf', [0,100,130,130]);

%% Rule Base
% S = 1             N = 1
% M = 2             Z = 2
% L = 3             P = 3

% Έχουμε 27 κανόνες της μορφής:
% [dV dH theta dtheta weight AND_operator]

% Αρχική Βάση Κανόνων
% Για dV = S
% car_control = addrule(car_control, [1 1 1 3 1 1]);      
% car_control = addrule(car_control, [1 1 2 3 1 1]);
% car_control = addrule(car_control, [1 1 3 2 1 1]);
% car_control = addrule(car_control, [1 2 1 3 1 1]);
% car_control = addrule(car_control, [1 2 2 3 1 1]);
% car_control = addrule(car_control, [1 2 3 2 1 1]);
% car_control = addrule(car_control, [1 3 1 3 1 1]);
% car_control = addrule(car_control, [1 3 2 2 1 1]);
% car_control = addrule(car_control, [1 3 3 1 1 1]);
% % Για dV = M
% car_control = addrule(car_control, [2 1 1 3 1 1]); 
% car_control = addrule(car_control, [2 1 2 3 1 1]); 
% car_control = addrule(car_control, [2 1 3 2 1 1]); 
% car_control = addrule(car_control, [2 2 1 3 1 1]); 
% car_control = addrule(car_control, [2 2 2 3 1 1]); 
% car_control = addrule(car_control, [2 2 3 2 1 1]); 
% car_control = addrule(car_control, [2 3 1 3 1 1]); 
% car_control = addrule(car_control, [2 3 2 2 1 1]);
% car_control = addrule(car_control, [2 3 3 1 1 1]); 
% % Για dV = L
% car_control = addrule(car_control, [3 1 1 3 1 1]); 
% car_control = addrule(car_control, [3 1 2 3 1 1]); 
% car_control = addrule(car_control, [3 1 3 2 1 1]); 
% car_control = addrule(car_control, [3 2 1 3 1 1]); 
% car_control = addrule(car_control, [3 2 2 3 1 1]);
% car_control = addrule(car_control, [3 2 3 2 1 1]); 
% car_control = addrule(car_control, [3 3 1 3 1 1]); 
% car_control = addrule(car_control, [3 3 2 2 1 1]); 
% car_control = addrule(car_control, [3 3 3 1 1 1]); 


% Τελική Βάση Κανόνων
% Βάση Κανόνων με προτεραιότητα στο Ζ, αντί στο P
car_control = addrule(car_control, [1 1 1 3 1 1]);      
car_control = addrule(car_control, [1 1 2 3 1 1]);
car_control = addrule(car_control, [1 1 3 2 1 1]);
car_control = addrule(car_control, [1 2 1 3 1 1]);
car_control = addrule(car_control, [1 2 2 2 1 1]);
car_control = addrule(car_control, [1 2 3 1 1 1]);
car_control = addrule(car_control, [1 3 1 3 1 1]);
car_control = addrule(car_control, [1 3 2 2 1 1]);
car_control = addrule(car_control, [1 3 3 1 1 1]);
% Για dV = M
car_control = addrule(car_control, [2 1 1 3 1 1]); 
car_control = addrule(car_control, [2 1 2 3 1 1]); 
car_control = addrule(car_control, [2 1 3 2 1 1]); 
car_control = addrule(car_control, [2 2 1 3 1 1]); 
car_control = addrule(car_control, [2 2 2 2 1 1]); 
car_control = addrule(car_control, [2 2 3 1 1 1]); 
car_control = addrule(car_control, [2 3 1 3 1 1]); 
car_control = addrule(car_control, [2 3 2 2 1 1]);
car_control = addrule(car_control, [2 3 3 1 1 1]); 
% Για dV = L
car_control = addrule(car_control, [3 1 1 3 1 1]); 
car_control = addrule(car_control, [3 1 2 2 1 1]); 
car_control = addrule(car_control, [3 1 3 1 1 1]); 
car_control = addrule(car_control, [3 2 1 3 1 1]); 
car_control = addrule(car_control, [3 2 2 2 1 1]);
car_control = addrule(car_control, [3 2 3 1 1 1]); 
car_control = addrule(car_control, [3 3 1 3 1 1]); 
car_control = addrule(car_control, [3 3 2 2 1 1]); 
car_control = addrule(car_control, [3 3 3 1 1 1]);

showrule(car_control)
writefis(car_control, 'car_control.fis');

%% Plots of MF
% sec δειγματοληψία
points = 1000;           
% % plot του input dV
[xOut_dV,yOut_dV] = plotmf(car_control,'input',1,points);
% % plot του input dH
[xOut_dH,yOut_dH] = plotmf(car_control,'input',2,points);
% % plot του input theta
[xOut_theta,yOut_theta] = plotmf(car_control,'input',3,points);
% % plot του output dtheta
[xOut_dtheta,yOut_dtheta] = plotmf(car_control,'output',1,points);
% plot(xOut_dV,yOut_dV)
% plot(xOut_dH,yOut_dH)
% plot(xOut_theta,yOut_theta)
% plot(xOut_dtheta,yOut_dtheta)
% gensurf(car_control)

%% Simulation
% Φτιάχνουμε τα σύνορα του εμποδίου
boundary_x = linspace(0,5,10);
boundary_y = zeros([1 , 10]);
boundary_x = [boundary_x linspace(5,6,10)];
boundary_y = [boundary_y ones([1,10])];
boundary_x = [boundary_x linspace(6,7,10)];
boundary_y = [boundary_y 2*ones([1,10])];
boundary_x = [boundary_x linspace(7,10,10)];
boundary_y = [boundary_y 3*ones([1,10])];

% Αρχικές τιμές εισόδων
x_init = 4.1;
y_init = 0.3;
theta_init = 0;             % θ = {0,-45,-90}

% Επιθυμητή θέση
x_d = 10;
y_d = 3.2;

% Υπολογίζω την τροχιά του οχήματος για θ=0
theta_init = 0;
[x1 y1] = car_trojectory(x_init,y_init,theta_init,car_control);
figure
plot(boundary_x,boundary_y)
hold on
xlabel('x')
ylabel('y')
plot(x1,y1)
hold on
plot(x_d,y_d,'r*')
title('θ=0^o')

% Υπολογίζω την τροχιά του οχήματος για θ=-45
theta_init = -45;
[x2 y2] = car_trojectory(x_init,y_init,theta_init,car_control);
figure
plot(boundary_x,boundary_y)
hold on
xlabel('x')
ylabel('y')
plot(x2,y2)
hold on
plot(x_d,y_d,'r*')
title('θ=-45^o')

% Υπολογίζω την τροχιά του οχήματος για θ=-90
theta_init = -90;
[x3 y3] = car_trojectory(x_init,y_init,theta_init,car_control);
figure
plot(boundary_x,boundary_y)
hold on
xlabel('x')
ylabel('y')
plot(x3,y3)
hold on
plot(x_d,y_d,'r*')
title('θ=-90^o')





