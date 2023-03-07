function[flag] = check(x,y,i)
% flag:     "1" =   το όχημα ΔΕΝ έφτασε ακόμη στην επιθυμητή θέση, 
%           "0" =   το όχημα έφτασε στην επιθυμητή θέση 
%                   ή τράκαρε στο εμπόδιο
%                   ή έκανε πολλές επαναλήψεις και δεν έφτασε ποτέ
flag = 1;
if (y>=0 && y<1)
    if (x>5)
        flag = 0;
    end
elseif (y>=1 && y<2)
    if (x>6)
        flag = 0;
    end
elseif (y>=2 && y<3)
    if (x>7)
        flag =0;
    end
elseif (y>3)
    if (x>10)
        flag = 0;
    end
end

if (i>10^6)
    flag = 0;
    message = "Η επανάληψη δεν ολοκληρώθηκε ποτέ"
end
end