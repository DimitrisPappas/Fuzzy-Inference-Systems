function[x y] = car_trojectory(x0,y0,theta0,car_control)
% (x,y) η τελική θέση του οχήματος
x = x0;
y = y0;
theta = theta0;

% Ταχύτητα οχήματος
v = 0.05;                   % 0.05 m/sec

% Υπολογίζω την τροχιά του οχήματος
flag = 1;                   % "1" = το όχημα ΔΕΝ έφτασε στην επιθυμητή θέση, "0" = το όχημα έφτασε στην επιθυμητή θέση
i = 1;
while (flag)
    % Υπολογίζω τις αποστάσεις dV (κάθετη) και dH (οριζόντια) από το εμπόδιο
    dV = vertical_distance(x(i),y(i));
    dH = horizontal_distance(x(i),y(i));

    % Κανονικοποιούμε στο διάστημα [0,1]
    dV = min(dV,1);
    dV = max(dV,0);
    dH = min(dH,1);
    dH = max(dH,0);

    % Υπολογίζουμε τη μεταβολή της γωνίας dθ με την βοήθεια της Βάσης
    % Κανόνων του Fuzzy συστήματος
    dtheta = evalfis(car_control,[dV dH theta]);
    % Προσθέτω τη μεταβολή της γωνίας για να βρω την νέα γωνία (κατεύθυνση)
    % του οχήματος
    theta = theta + dtheta;
    % Η γωνία θ έχει πεδίο ορισμού το [-180,180]
    if (theta>180)
        theta = theta - 360;
    elseif (theta<-180)
        theta = theta + 360;
    end

    % Υπολογίζουμε τη νέα θέση (x,y) του οχήματος
    i = i + 1;
    x(i) = x(i-1) + v*cosd(theta);              % Θεωρώ dt=1 sec
    y(i) = y(i-1) + v*sind(theta);
    
    % Ελέγχουμε αν το όχημα έφτασε στην επιθυμητή θέση
    flag = check(x(i),y(i),i);
end
end
