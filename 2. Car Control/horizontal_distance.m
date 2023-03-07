function[dis] = horizontal_distance(x,y)
% Υπολογίζουμε την οριζόντια απόσταση dΗ του οχήματος από το εμπόδιο
if (y<1)
    dis = 5 - x;                % Αφαιρώ το x από το "5" γιατί το εμπόδιο φτάνει μέχρι το boundary = 5
elseif (y>=1 && y<2)
    dis = 6 - x;                % Αφαιρώ το x από το "6" γιατί το εμπόδιο φτάνει μέχρι το boundary = 6
elseif (y>=2 && y<3)
    dis = 7 - x;                % Αφαιρώ το x από το "7" γιατί το εμπόδιο φτάνει μέχρι το boundary = 7
else
    dis = inf;                  % Δεν υπάρχει εμπόδιο για y>=3
end
end
