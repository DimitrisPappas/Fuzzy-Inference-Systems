% Δημήτρης Παππάς
% ΑΕΜ: 8391     
% ΗΜΜΥ ΑΠΘ 
% Regression part 1 - TSK Model 2
clear all;

%% Διαβάζω τα δεδομένα
% inputs
% f = frequency (Hz)
% a = angle of attack (degrees)
% ch = chord length (m)
% v = free-stream velocity (m/s)
% th = suction side displacement thickness (m)

% output
% p = scaled sound pressure level (dB)

[f a ch v th p] = textread('airfoil_self_noise.dat');
% data
d = [f a ch v th p];

%% Χωρίζω τα δεσομένα σε training, evaluation, check
% Dtrn = training data - 60% των data
% Dval = evaluation data - 20% των data
% Dchk = check data - 20% των data

data = 1503;
Dtrn = [f(1:fix(data*0.6)), a(1:fix(data*0.6)), ch(1:fix(data*0.6)), v(1:fix(data*0.6)), th(1:fix(data*0.6)), p(1:fix(data*0.6))];
Dval = [f(fix(data*0.6)+1:fix(data*0.8)), a(fix(data*0.6)+1:fix(data*0.8)), ch(fix(data*0.6)+1:fix(data*0.8)), v(fix(data*0.6)+1:fix(data*0.8)), th(fix(data*0.6)+1:fix(data*0.8)), p(fix(data*0.6)+1:fix(data*0.8))];
Dchk = [f(fix(data*0.8)+1:end), a(fix(data*0.8)+1:end), ch(fix(data*0.8)+1:end), v(fix(data*0.8)+1:end), th(fix(data*0.8)+1:end), p(fix(data*0.8)+1:end)];

%% Εκπαίδευση μοντέλου 2 - Hybrid Algorithm TSK με "3 mf" και "Singleton" output
% Αρχικό Ασαφές Σύστημα
opt_gen = genfisOptions('GridPartition','NumMembershipFunctions',3,'InputMembershipFunctionType', 'gbellmf','OutputMembershipFunctionType','constant');
fis = genfis(Dtrn(:,1:5),Dtrn(:,6),opt_gen);

% Plot membership functions BEFORE training
figure (1)
subplot(3,2,1)
plotmf(fis, 'input', 1)
title('Membership Functions Before Training for frequency');
subplot(3,2,2)
plotmf(fis, 'input', 2)
title('Membership Functions Before Training for angle');
subplot(3,2,3)
plotmf(fis, 'input', 3)
title('Membership Functions Before Training for chord');
subplot(3,2,4)
plotmf(fis, 'input', 4)
title('Membership Functions Before Training for velocity');
subplot(3,2,5)
plotmf(fis, 'input', 5)
title('Membership Functions Before Training for thickness');

% Training model 2
% The training algorithm uses a combination of the "least-squares" and "backpropagation" gradient descent methods 
% to model the training data set
opt_an = anfisOptions('InitialFIS',fis,'EpochNumber',200);
opt_an.ValidationData = Dval;
opt_an.OptimizationMethod = 1;      % 1 = hybrid method
[TSK_model_2, trainError_2, stepSize_2, chkFIS_2, chkError_2] = anfis(Dtrn, opt_an);
% showrule(chkFIS_2)

% Plot membership functions AFTER training
figure (2)
subplot(3,2,1)
plotmf(chkFIS_2, 'input', 1)
title('Membership Functions After Training for frequency');
subplot(3,2,2)
plotmf(chkFIS_2, 'input', 2)
title('Membership Functions After Training for angle');
subplot(3,2,3)
plotmf(chkFIS_2, 'input', 3)
title('Membership Functions After Training for chord');
subplot(3,2,4)
plotmf(chkFIS_2, 'input', 4)
title('Membership Functions After Training for velocity');
subplot(3,2,5)
plotmf(chkFIS_2, 'input', 5)
title('Membership Functions After Training for thickness');

%% Εκτίμηση Εξόδου & Αξιολόγηση Μοντέλου
% RMSE = Root Mean Square Error
% NMSE = Normalized Mean Square Error
% NDEI = Root of NMSE
% R2 = Coefficient of Determination

% Calculate Model 2 Evaluations             
eval_model_2 = evalfis(TSK_model_2, Dchk(:,1:5));                  % (check data, anfis output)     
% Error Metrics
[RMSE, NMSE, NDEI, R2] = calculate(Dchk(:,6), eval_model_2)     % (original output, evaluation output)

% Plot Training Error & Check Error
figure(3)
plot([trainError_2 chkError_2])
grid on
legend('training error', 'check error')
xlabel('EpochNumber')
ylabel('Root Mean Squared Error (RMSE)')
title('Training and Check Error / 3 mf & constant')

% Plot RMSE
mse = (Dchk(:,6)-eval_model_2).^2;
rmse = sqrt(mse);
figure(4)
plot(1:length(eval_model_2), rmse)          
xlabel('check data')
ylabel('Mean Square Error (MSE)')
title('MSE / 3 mf & constant output')

% Plot Prediction Error
figure(5) 
anfis_output = evalfis(TSK_model_2, d(:,1:5));         % overall data
index = 1:1503;
% Real Data vs Prediction
subplot(2,1,1)
plot([p(index) anfis_output])
legend('Real Data', 'Anfis Output');
yL = get(gca, 'YLim');
txt1 = 'Training Set';
txt2 = 'Valid Set';
txt3 = 'Checking Set';
line([901 901], yL, 'Color', 'y');
line([1202 1202], yL, 'Color', 'y');
xlabel('Samples')
title('Real Samples and ANFIS Prediction')
% Prediction Errors
subplot(2, 1, 2)
plot(p(index) - anfis_output)                   %  Real Data - Prediction Data
yL = get(gca, 'YLim');
line([901 901], yL, 'Color', 'y');
line([1202 1202], yL, 'Color', 'y');
xlabel('Samples')
title('Prediction Errors')




