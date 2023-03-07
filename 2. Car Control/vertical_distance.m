function[dis] = vertical_distance(x,y)
% Υπολογίζουμε την κάθετη απόσταση dV του οχήματος από το εμπόδιο
if (x<5)
    dis = y;
elseif (x>=5 && x<6)
    dis = y - 1;                % Αφαιρώ "1" από το y γιατί το εμπόδιο φτάνει μέχρι το boundary = 1
elseif (x>=6 && y<7)
    dis = y - 2;                % Αφαιρώ "2" από το y γιατί το εμπόδιο φτάνει μέχρι το boundary = 2
else 
    dis = y - 3;                % Αφαιρώ "3" από το y γιατί το εμπόδιο φτάνει μέχρι το boundary = 3
end
end
