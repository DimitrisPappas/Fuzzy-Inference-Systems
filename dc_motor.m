% Δημήτρης Παππάς
% ΑΕΜ: 8391     
% ΗΜΜΥ ΑΠΘ 
% FLC DC motor
clear all;

% Συνάρτηση Μεταφοράς
dc_tf = tf([18.69],[1 12.064])

% Ασαφές Σύστημα
fuzzy_pi = newfis('fzpi', ...   % name of FIS system
    'mamdani', ...              % mamdani type
    'min', ...                  % το συνδετικό AND υλοποιείται με τελεστή min
    'max', ...                  % το συνδετικό OR υλοποιείται με τελεστή max
    'min', ...                  % το Implication υλοποιείται με τελεστή min
    'max', ...                  % το Aggregation υλοποιείται με τελεστή max
    'centroid');                % o Defuzzifier υλοποιείται με τεχνική centroid (COA)

%% Αρχικοποίηση input και output
fuzzy_pi = addvar(fuzzy_pi, 'input', 'e', [-1,1]);              % input #1
fuzzy_pi = addvar(fuzzy_pi, 'input', 'de', [-1,1]);             % input #2
fuzzy_pi = addvar(fuzzy_pi, 'output', 'du', [-1,1]);            % output #1

%% Συνάρτηση Συμμετοχής (Membership Function) 
% Για την είσοδο e
fuzzy_pi = addmf(fuzzy_pi, 'input', 1, 'NV', 'trimf', [-1,-1,-0.75]);   % trimf = Triangular membership function
fuzzy_pi = addmf(fuzzy_pi, 'input', 1, 'NL', 'trimf', [-1,-0.75,-0.5]);
fuzzy_pi = addmf(fuzzy_pi, 'input', 1, 'NM', 'trimf', [-0.75,-0.5,-0.25]);
fuzzy_pi = addmf(fuzzy_pi, 'input', 1, 'NS', 'trimf', [-0.5,-0.25,0]);
fuzzy_pi = addmf(fuzzy_pi, 'input', 1, 'ZR', 'trimf', [-0.25,0,0.25]);
fuzzy_pi = addmf(fuzzy_pi, 'input', 1, 'PS', 'trimf', [0,0.25,0.5]);
fuzzy_pi = addmf(fuzzy_pi, 'input', 1, 'PM', 'trimf', [0.25,0.5,0.75]);
fuzzy_pi = addmf(fuzzy_pi, 'input', 1, 'PL', 'trimf', [0.5,0.75,1]);
fuzzy_pi = addmf(fuzzy_pi, 'input', 1, 'PV', 'trimf', [0.75,1,1]);

% Για την είσοδο de
fuzzy_pi = addmf(fuzzy_pi, 'input', 2, 'NL', 'trimf', [-1,-1,-2/3]);
fuzzy_pi = addmf(fuzzy_pi, 'input', 2, 'NM', 'trimf', [-1,-2/3,-1/3]);
fuzzy_pi = addmf(fuzzy_pi, 'input', 2, 'NS', 'trimf', [-2/3,-1/3,0]);
fuzzy_pi = addmf(fuzzy_pi, 'input', 2, 'ZR', 'trimf', [-1/3,0,1/3]);
fuzzy_pi = addmf(fuzzy_pi, 'input', 2, 'PS', 'trimf', [0,1/3,2/3]);
fuzzy_pi = addmf(fuzzy_pi, 'input', 2, 'PM', 'trimf', [1/3,2/3,1]);
fuzzy_pi = addmf(fuzzy_pi, 'input', 2, 'PL', 'trimf', [2/3,1,1]);

% Για την έξοσο du
fuzzy_pi = addmf(fuzzy_pi, 'output', 1, 'NV', 'trimf', [-1,-1,-0.75]);  
fuzzy_pi = addmf(fuzzy_pi, 'output', 1, 'NL', 'trimf', [-1,-0.75,-0.5]);
fuzzy_pi = addmf(fuzzy_pi, 'output', 1, 'NM', 'trimf', [-0.75,-0.5,-0.25]);
fuzzy_pi = addmf(fuzzy_pi, 'output', 1, 'NS', 'trimf', [-0.5,-0.25,0]);
fuzzy_pi = addmf(fuzzy_pi, 'output', 1, 'ZR', 'trimf', [-0.25,0,0.25]);
fuzzy_pi = addmf(fuzzy_pi, 'output', 1, 'PS', 'trimf', [0,0.25,0.5]);
fuzzy_pi = addmf(fuzzy_pi, 'output', 1, 'PM', 'trimf', [0.25,0.5,0.75]);
fuzzy_pi = addmf(fuzzy_pi, 'output', 1, 'PL', 'trimf', [0.5,0.75,1]);
fuzzy_pi = addmf(fuzzy_pi, 'output', 1, 'PV', 'trimf', [0.75,1,1]);

%% Βάση Κανόνων του Ασαφούς Συστήματος
% NV = 1            PS = 6
% NL = 2            PM = 7
% NM = 3            PL = 8
% NS = 4            PV = 9
% ZR = 5

% Για τον υπολογισμό του du δουλεύω στο διάσημα [-4,4], θεωρώ αρχικά τα e=[-4:4] και de=[-3:3] 
% και στο τέλος προσθέτω du+5 για να επανέλθω στο διάστημα [1,9]
for i=1:9
    for j=1:7
        output_du(i,j) = (i-5) + (j-4);                         % output_du = input_e + input_de
        if output_du(i,j) > 4 ; output_du(i,j) = 4 ; end        % max value = 4
        if output_du(i,j) < -4 ; output_du(i,j) = -4 ; end      % min value = -4
    end
end
output_du = output_du + 5;

for i=1:63
    input_e(i) = floor((i-1)/7)+1;
end
input_de = repmat([1:7]', 9, 1);
du = output_du';
weight = ones(length(input_de),1);    % weight = 1     || length(input_de) = 63 = 9*7
operator = ones(length(input_de),1);  % operator = AND (AND = 1) 
rules = [input_e(:) input_de(:) du(:) weight(:) operator(:)]

fuzzy_pi = addrule(fuzzy_pi, rules);
writefis(fuzzy_pi, 'fuzzy_pi.fis');



%% Χρόνος Ανόδου και Υπερύψωση
% Σήματα του Simulink
% s= stepinfo(out.output.data,out.output.time)                    % stepinfo & overshoot
% plot(out.r.time,out.r.data,out.output.time,out.output.data)     % plot input & output
% plot(out.Va.time,out.Va.data)                                   % plot Va (FLC output)

%% Διέγερση Κανόνων
% sec δειγματοληψία
points = 1000;           
% % plot του input e
[xOut_e,yOut_e] = plotmf(fuzzy_pi,'input',1,points);
% % plot του input de
[xOut_de,yOut_de] = plotmf(fuzzy_pi,'input',2,points);
% % plot του output du
[xOut_du,yOut_du] = plotmf(fuzzy_pi,'output',1,points);
% plot(xOut_e,yOut_e)
% plot(xOut_de,yOut_de)
% plot(xOut_du,yOut_du)


e_PS = yOut_e(:,6);                                 % PS = 6 for e
de_NM = yOut_de(:,2);                               % NM = 2 for de
% eval = evalfis(fuzzy_pi,[0.25,-2/3])                % PS = 0.25 for e + NM = -2/3 for de


ruleOutputs_final = zeros([101,63]);
j=1;
final_output = zeros([points 1]);
rules_activated = 0;
for i=1:63
    % MF του κανόνα i
    e_r = yOut_e(:,rules(i,1));
    de_r= yOut_de(:,rules(i,2));
    % MF AND Input
    e_PS_AND_e_r = min(e_PS,e_r);
    de_NM_AND_de_r = min(de_NM,de_r);
    w1 = max(e_PS_AND_e_r);
    w2 = max( de_NM_AND_de_r);
    % Διέγερση Κανόνα
    if(w1 ~= 0 && w2 ~= 0 )
      w_tot = min(w1,w2);
      du_out(:,j) = w_tot*yOut_du(:,rules(i,3));
      final_output = max(final_output,du_out(:,j));
      rules_activated = [rules_activated ; i];
      j = j+1;
      figure
      % MF e του κανόνα 
      subplot(3,3,1)
      plot(xOut_de(:,1),e_r);
      title('rule e mf')
      % MF de του κανόνα
      subplot(3,3,2)
      plot(xOut_de(:,1),de_r);
      title('rule de mf')
      % Output MF
      subplot(3,3,3)
      plot(xOut_de(:,1),yOut_du(:,rules(i,3)));
      title('output mf')
      % Input e MF
      subplot(3,3,4)
      plot(xOut_de(:,1),e_PS);
      title('input e mf')
      % Input de MF
      subplot(3,3,5)
      plot(xOut_de(:,1),de_NM);
      title('input de mf')
      % Input e MF AND e rule
      subplot(3,3,7)
      plot(xOut_de(:,1), e_PS_AND_e_r);
      title('input e AND e rule')
      ylim([0 1])
      % Input de MF AND de rule
      subplot(3,3,8)
      plot(xOut_de(:,1), de_NM_AND_de_r);
      title('input de AND de rule')
      ylim([0 1])
      % Rule output
      subplot(3,3,9)
      plot(xOut_de(:,1), du_out(:,j-1));
      title('rule output')
      ylim([0 1])
      subtitle([num2str(i),'th rule activated '])
    end
end


% Τελική Έξοδος
figure
plot(xOut_de(:,1),final_output)
title('Final Output')
ylim([0 1])
rules_activated = rules_activated(2:end);
rules_activated
% gensurf(fuzzy_pi)



