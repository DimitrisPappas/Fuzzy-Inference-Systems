% Δημήτρης Παππάς
% ΑΕΜ: 8391     
% ΗΜΜΥ ΑΠΘ 
% Regression part 2 - Optimal TSK model
clear all;

%% Διαβάζω τα δεδομένα
% 81 χαρακτηριστικά και 1 αποτέλεσμα
data = load('superconduct.csv');
features = data(:,1:81);
results = data(:,82);

%% Optimal parameters
numFeatures = 14;
numRules = 9;
radius = 0.4;

%% Αρχικοποίηση Τιμών
k =5;
counter = 0;
% Σφάλματα κάθε επανάληψης k fold
rmse = zeros(k,1);
nmse = zeros(k,1);
ndei = zeros(k,1);
r2 = zeros(k,1);

%% Υπολογίζω τα σημαντικότερα features
[ranks,weights] = relieff(features,results,10); 

%% Υλοποίηση Βέλτιστου Μοντέλου
% cv partition k-fold cross validation
kfold = cvpartition(results, 'KFold', 5);
% loop for 5 folds
for fold = 1:kfold.NumTestSets
    % iteration index
    training_id = kfold.training(fold);
    testing_id = kfold.test(fold);
    
    % Επιλέγω τα σημαντικότερα features
    Dtrn = data(training_id, ranks(1:numFeatures));
    Dval = data(testing_id, ranks(1:numFeatures));
            
    Dtrn = [Dtrn data(training_id, end)];
    Dval = [Dval data(testing_id, end)];

    % TSK Subtractive Clustering
    fis = genfis2(Dtrn(:,1:numFeatures), Dtrn(:,end), radius);

    % Training with anfis
    EpochNumber = 100;
    opt_an = anfisOptions('InitialFIS',fis,'EpochNumber',EpochNumber);
    opt_an.ValidationData = Dval;
    opt_an.OptimizationMethod = 1;      % hybrid
    [trainedFis, trainError, stepSize, chkFis, chkError] = anfis(Dtrn, opt_an);

    % Predictions
    predictions = evalfis(trainedFis, Dval(:,1:end-1));

    % Errors
    [rmse(fold) nmse(fold) ndei(fold) r2(fold)] = calculate(Dval(:,end), predictions);

    % Αυξάνω τον δείκτη της επανάληψης
    counter = counter + 1;
    fprintf("Είμαι στην επανάληψη %d\n",counter);
end

% Μέσος όρος Σφαλμάτων
RMSE = sum(rmse(:))/k;
NMSE = sum(nmse(:))/k;
NDEI = sum(ndei(:))/k;
R2 = sum(r2(:))/k;

%% Plots
% Plot mf BEFORE training για την 5η επανάληψη (fold = 5)
figure(1)
subplot(2,2,1)
plotmf(fis,'input',1)
title('Membership Functions Before Training for input 1');
subplot(2,2,2)
plotmf(fis,'input',5)
title('Membership Functions Before Training for input 5');
subplot(2,2,3)
plotmf(fis,'input',10)
title('Membership Functions Before Training for input 10');
subplot(2,2,4)
plotmf(fis,'input',14)
title('Membership Functions Before Training for input 14');

% Plot mf AFTER training
figure (2)
subplot(2,2,1)
plotmf(chkFis, 'input', 1)
title('Membership Functions After Training for input 1');
subplot(2,2,2)
plotmf(chkFis, 'input', 5)
title('Membership Functions After Training for input 5');
subplot(2,2,3)
plotmf(chkFis, 'input', 10)
title('Membership Functions After Training for input 10');
subplot(2,2,4)
plotmf(chkFis, 'input', 14)
title('Membership Functions After Training for input 14');

% Τιμές Πρόβλεψης Μοντέλου
figure(3);
scatter([1:length(predictions)],predictions)
grid on
xlabel('data')
ylabel('Predicted Values')
title('Τιμές Πρόβλεψης Μοντέλου')

% Πραγματικές Τιμές
figure(4)
scatter([1:length(Dval(:,end))], Dval(:,end)) 
grid on
xlabel('data')
ylabel('Real Values')
title('Πραγματικές Τιμές')

% Prediction Error 
prediction_error = Dval(:,end) - predictions;
figure(5)
plot(prediction_error)
grid on
xlabel('data')
ylabel('Prediction Error')
title("Σφάλμα Πρόβλεψης")

% Learning Curve
figure(6)
grid on
plot([trainError chkError])
xlabel('samples')
ylabel('Error');
legend('Training Error','Validation Error')
title("Learning Curve");

fprintf('[RMSE NMSE NDEI R2] = [%d %d %d %d]\n',RMSE,NMSE,NDEI,R2);
fprintf('Number of Rules = %d\n',length(trainedFis.Rules));





