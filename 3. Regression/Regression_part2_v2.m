% Δημήτρης Παππάς
% ΑΕΜ: 8391     
% ΗΜΜΥ ΑΠΘ 
% Regression part 2 - Searching for the Optimal Parameters
clear all;

%% Διαβάζω τα δεδομένα
% 81 χαρακτηριστικά και 1 αποτέλεσμα
data = load('superconduct.csv');
features = data(:,1:81);
results = data(:,82);

%% Αρχικοποίηση Τιμών
numFeatures = [5 8 11 14];                              % αριθμός τιμών των features που θα κρατήσουμε
radius_Ra = [0.2 0.4 0.6 0.8 1];                        % τιμές ακτίνας Ra
numRules = zeros(5,1);                                  % αριθμός κανόνων
k = 5;                                                  % k-fold cross validation για το grid search
error = zeros(numel(numFeatures),numel(radius_Ra));     % error για κάθε συνδιασμό (features,rules)
counter = 0;                                            % αριθμός επαναλήψεων
% Σφάλματα κάθε επανάληψης k fold
rmse = zeros(k,1);
nmse = zeros(k,1);
ndei = zeros(k,1);
r2 = zeros(k,1);
% Μέσος όρος Σφαλμάτων
RMSE = zeros(numel(numFeatures), numel(radius_Ra));
NMSE = zeros(numel(numFeatures), numel(radius_Ra));
NDEI = zeros(numel(numFeatures), numel(radius_Ra));
R2 = zeros(numel(numFeatures), numel(radius_Ra));

%% Υπολογίζω τα σημαντικότερα features
[ranks,weights] = relieff(features,results,10);         %  indices of the most important predictors - k nearest neighbors

%% Αναζητώ Βέλτιστες Παραμέτρους
for i=1:numel(numFeatures)      % 4
    for j=1:numel(radius_Ra)    % 5
        % cv partition k-fold cross validation
        kfold = cvpartition(results, 'KFold', 5);
        % loop for 5 folds
        for fold = 1:kfold.NumTestSets
            % iteration index
            training_id = kfold.training(fold);
            testing_id = kfold.test(fold);

            % Επιλέγω τα σημαντικότερα features
            Dtrn = data(training_id, ranks(1:numFeatures(i)));
            Dval = data(testing_id, ranks(1:numFeatures(i)));
            
            Dtrn = [Dtrn data(training_id, end)];
            Dval = [Dval data(testing_id, end)];

            % TSK Subtractive Clustering
            fis = genfis2(Dtrn(:,1:numFeatures(i)), Dtrn(:,end), radius_Ra(j));

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
        RMSE(i,j) = sum(rmse(:))/k;
        NMSE(i,j) = sum(nmse(:))/k;
        NDEI(i,j) = sum(ndei(:))/k;
        R2(i,j) = sum(r2(:))/k;

        % Αποθηκεύω Σφάλμα, Κανόνες, Σημαντικότερα features για Plots
        % RMSE(i,j) = sum(rmse(:))/k;               % Σφαλμα
        % numFeatures(i)                            % Αριθμός Σημαντικότερων features
        rules(i,j) = length(trainedFis.Rules);      % Κανόνες
    end
end

%% Ελάχιστο error
% Optimized Values
minimum = min(min(RMSE));
[min_i min_j] = find(RMSE == minimum);
fprintf('Optimal features number %d, optimal radius %d, optimal number of rules %d, with %d error.\n',numFeatures(min_i), radius_Ra(min_j), rules(min_i,min_j), minimum);

%% Plots
% Σφάλμα συναρτήσει των Κανόνες
figure(1);
scatter(reshape(RMSE,1,[]),reshape(rules,1,[])); 
grid on
xlabel("RMSE"); 
ylabel("Number of Rules");
title("RMSE dependent to Number of Rules ");

% Σφάλμα συναρτήσει των Κρατημένων features
nf = [numFeatures;numFeatures;numFeatures;numFeatures;numFeatures];
nf = nf';
figure(2);
scatter(reshape(RMSE,1,[]),reshape(nf,1,[])); 
grid on
xlabel("RMSE"); 
ylabel("Number of kept features (numFeatures)");
title("RMSE dependent to Number of kept features ");

% Σφάλμα συναρτήσει της Ακτίνας Ra
ra = [radius_Ra;radius_Ra;radius_Ra;radius_Ra];
figure(3);
scatter(reshape(RMSE,1,[]),reshape(ra,1,[])); 
grid on
xlabel("RMSE"); 
ylabel("Radius Cluster");
title("RMSE dependent to Radius Cluster ");


