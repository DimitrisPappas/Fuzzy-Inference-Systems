% Δημήτρης Παππάς
% ΑΕΜ: 8391     
% ΗΜΜΥ ΑΠΘ 
% Classification part 2 - Optimal TSK model
clear all;

%% Διαβάζω τα δεδομένα
% 179 μεταβητές  --  178 χαρακτηριστικά και 1 αποτέλεσμα
data = csvread('epileptic_seizure_data.csv',1,1);      % διαβάζω από το (1,1) γιατί στην πρ΄ψτη γραμμή είναι το όνομα των features
epileptic = data(:,end);       % output με 5 classes
% 1 - Recording of seizure activity 
% 2 - They recorder the EEG from the area where the tumor was located
% 3 - Yes they identify where the region of the tumor was in the brain and recording the EEG activity from the healthy brain area
% 4 - eyes closed, means when they were recording the EEG signal the patient had their eyes closed
% 5 - eyes open, means when they were recording the EEG signal of the brain the patient had their eyes open

%% Κανονικοποίηση
% Κάνω κανονικοποίηση στα 178 features
normalized_data = data(:,1:end-1);
normalized_data = normalize(normalized_data);
D = [normalized_data(:,1:end) epileptic];

%% Αρχικοποίηση Τιμών
features = 11;
radius = 0.2;
rulesNumber = 0;
k = 5;
iteration = 0;
counter = 0;
errorMatrix = zeros(5,5);       % 5 classes

% Error Matrix & Accuracy Metrics
EM = zeros(5,5,5);          % 5 classes & 5 kfold
OA = zeros(5,1);
PA = zeros(5,5);
UA = zeros(5,5);
K = zeros(5,1);

% Μέσος Όρος Μετρικών Βέλτιστου Μοντέλου
meanEM = zeros(5,5);
meanOA = 0;
meanPA1 = zeros(5,1);
meanPA2 = zeros(5,1);
meanPA3 = zeros(5,1);
meanPA4 = zeros(5,1);
meanPA5 = zeros(5,1);
meanUA1 = zeros(5,1);
meanUA2 = zeros(5,1);
meanUA3 = zeros(5,1);
meanUA4 = zeros(5,1);
meanUA5 = zeros(5,1);
meanK = 0;
meanRules = 0;

% Πίνακας Αριθμού Κανόνων για κάθε kfold
rules_kfold = zeros(5,1);

% Ανάθεση τιμής στο όνομα της mf
nameMF = strings(100000,1);
nameMF_out = strings(100000,1);
for i = 1:100000
    nameMF(i) = "mf" + i;
    nameMF_out(i) = "mfOut" + i;
end

%% Σημαντικότερα features
% Επιλέγω τα σημαντικότερα features με την ενοτλή "Relief"
[ranks,weights] = relieff(D(:,1:end-1), D(:,end), 10);

%% CVpartition για k-fold
% 80% training & 20% 
kfold1 = cvpartition(D(:,end), 'KFold', 5, 'Stratify', true);

for fold=1:kfold1.NumTestSets
    iteration = iteration + 1;
    messageIteration = "Είμαι στην επανάληψη " + iteration;

    %% Διαχωρισμός Δεσομένων
    % Χωρίζω με τυχαιότητα το συνολικό dataset σε training dataset
    % 80% του συνόλου και σε testing dataset 20%
    Dtraining = D(training(kfold1,fold),:);         % Training indices for cross-validation 80%
    Dtesting = D(test(kfold1,fold),:);              % Test indices for cross-validation 20%
            
    % Χωρίζω το training cross validation dataset "Dtraining" σε
    % training 80%  και σε testing 20% 
    kfold2 = cvpartition(Dtraining(:,end), 'KFold', 4, 'Stratify', true);
    Dtrn = Dtraining(training(kfold2,2),:);
    Dchk = Dtraining(test(kfold2,2),:);

    % Κρατάω μόνο τα Σημαντικότερα features
    Dtrn = [Dtrn(:,ranks(1:features)) Dtrn(:,end)];
    Dchk = [Dchk(:,ranks(1:features)) Dchk(:,end)];
    Dtest = [Dtesting(:,ranks(1:features)) Dtesting(:,end)];

    %% "Class Dependent"  --  Clustering per Class
    % Έχουμε 5 classes {1,2,3,4,5}
    [c1,s1]=subclust(Dtrn(Dtrn(:,end) == 1,:),radius);     % [centers,sigma]
    [c2,s2]=subclust(Dtrn(Dtrn(:,end) == 2,:),radius);
    [c3,s3]=subclust(Dtrn(Dtrn(:,end) == 3,:),radius);
    [c4,s4]=subclust(Dtrn(Dtrn(:,end) == 4,:),radius);
    [c5,s5]=subclust(Dtrn(Dtrn(:,end) == 5,:),radius);
    numRules = size(c1,1) + size(c2,1) + size(c3,1) + size(c4,1) + size(c5,1);

    %% Build FIS
    class_fis = newfis('Classification_FIS', 'sugeno');

    nameInput = {};
    for i=1:size(Dtrn,2)-1      % number of most significant features
        nameInput{i} = "in" + i;
    end

    % Add Input Variables
    for i=1:size(Dtrn,2)-1          % number of features
        class_fis = addvar(class_fis, 'input', nameInput{i}, [0 1]);
    end

    % Add Output Variable
    class_fis = addvar(class_fis, 'output', 'Epiliptic', [0 1]);
            
    % Add Input Membership Functions
    for i=1:size(Dtrn,2)-1          % number of features
        for j=1:size(c1,1)          % number of centers for each feature
            counter = counter + 1;
            class_fis = addmf(class_fis, 'input', i, nameMF(counter), 'gaussmf', [s1(i) c1(j,i)]);
        end
        for j=1:size(c2,1)          % number of centers for each feature
            counter = counter + 1;
            class_fis = addmf(class_fis, 'input', i, nameMF(counter), 'gaussmf', [s2(i) c2(j,i)]);
        end
        for j=1:size(c3,1)          % number of centers for each feature
            counter = counter + 1;
            class_fis = addmf(class_fis, 'input', i, nameMF(counter), 'gaussmf', [s3(i) c3(j,i)]);
        end
        for j=1:size(c4,1)          % number of centers for each feature
            counter = counter + 1;
            class_fis = addmf(class_fis, 'input', i, nameMF(counter), 'gaussmf', [s4(i) c4(j,i)]);
        end
        for j=1:size(c5,1)          % number of centers for each feature
            counter = counter + 1;
            class_fis = addmf(class_fis, 'input', i, nameMF(counter), 'gaussmf', [s5(i) c5(j,i)]);
        end
    end
    counter = 0;        % reset counter

    % Add Output Membership Functions
    % Χωρίζω το Πεδίο Ορισμού [0,1] σε 5 τμήματα γιατί έχουμε 5
    % κλάσεις
    out = [zeros(1,size(c1,1)) 0.25+zeros(1,size(c2,1)) 0.50+zeros(1,size(c3,1)) 0.75+zeros(1,size(c4,1)) ones(1,size(c5,1))];
    for i=1:numRules
        counter = counter + 1;
        class_fis = addmf(class_fis, 'output', 1, nameMF_out(counter), 'constant', out(i));
    end
    counter = 0;        % reset counter

    % Add Rule Base
    rules = zeros(numRules, size(Dtrn,2));
    for i=1:size(rules,1)       % number of rules
        rules(i,:) = i;         % create my Rule List
    end
    rules = [rules ones(numRules,2)]    % add weight=1 & operator=AND
    class_fis = addrule(class_fis, rules);
    showrule(class_fis)

    % Plot MF Before Training
    if fold == 5
        figure(1)
        plotmf(class_fis,'input', 1)
        title("Input 1 Before training")
        figure(2)
        plotmf(class_fis,'input', 5)
        title("Input 5 Before training")
    end

    %% ANFIS Training
    EpochNumber = 100;
    opt_an = anfisOptions('InitialFIS', class_fis, 'EpochNumber', EpochNumber);
    opt_an.ValidationData = Dchk;
    opt_an.OptimizationMethod = 1;      % hybrid
    [class_model, trainError, stepSize, chkFIS, chkError] = anfis(Dtrn, opt_an);
    
    % ANFIS Evaluation & Predictions
    prediction = evalfis(Dtest(:,1:end-1), chkFIS);
    prediction = round(prediction);
    % Περιορίζω το σύνολο τιμών στο {1,2,3,4,5}
    for i=1:size(prediction,1)
        if prediction(i) < 1 ; prediction(i) = 1 ; end
        if prediction(i) > 5 ; prediction(i) = 5 ; end
    end
    prediction_error = Dtest(:,end) - prediction;

    %% Υπολογίζω Error Matrix & Overall Accuracy
    % Υπολογίζω Error Matrix & Accuracy
    errorMatrix = confusionmat(Dtest(:,end), prediction);
    N = size(Dtest,1);
    OA_kfold = sum(diag(errorMatrix))/N;
    rules_kfold(fold) = size(class_model.Rules,2);
    
    % Error Matrix
    EM(:,:,fold) = errorMatrix;
    % Overall Accuracy
    OA(fold) = OA_kfold;
    % Producer's Accuracy
    PA(fold,1) = EM(1,1,fold)/sum(EM(1,:,fold));
    PA(fold,2) = EM(2,2,fold)/sum(EM(2,:,fold));
    PA(fold,3) = EM(3,3,fold)/sum(EM(3,:,fold));
    PA(fold,4) = EM(4,4,fold)/sum(EM(4,:,fold));
    PA(fold,5) = EM(5,5,fold)/sum(EM(5,:,fold));
    % User's Accuracy
    UA(fold,1) = EM(1,1,fold)/sum(EM(:,1,fold));
    UA(fold,2) = EM(2,2,fold)/sum(EM(:,2,fold));
    UA(fold,3) = EM(3,3,fold)/sum(EM(:,3,fold));
    UA(fold,4) = EM(4,4,fold)/sum(EM(:,4,fold));
    UA(fold,5) = EM(5,5,fold)/sum(EM(:,5,fold));
    % K
    temp = 0;
    for i = 1:5
        temp = temp + sum(EM(:,i,fold))*sum(EM(i,:,fold));
    end
    K(fold) = (N*sum(diag(EM(:,:,fold))) - temp)/(N^2 - temp);

end

%% Μέσος Όρος Error MAtrix & Accuracy
for i=1:k       % k=5 kfold
    meanEM = meanEM + EM(:,:,i);
end
% Μέσος Όρος Error Matrix
meanEM = meanEM/k;    
% Μέσος Όρος Overall Accuracy
meanOA = sum(OA)/k;     
% Μέσος Όρος Producer's Accuracy
meanPA1 = sum(PA(:,1))/k;
meanPA2 = sum(PA(:,2))/k;
meanPA3 = sum(PA(:,3))/k;
meanPA4 = sum(PA(:,4))/k;
meanPA5 = sum(PA(:,5))/k;
% Μέσος Όρος User's Accuracy
meanUA1 = sum(UA(:,1))/k;
meanUA2 = sum(UA(:,2))/k;
meanUA3 = sum(UA(:,3))/k;
meanUA4 = sum(UA(:,4))/k;
meanUA5 = sum(UA(:,5))/k;
% Μέσος Όρος K
meanK = sum(K)/k;
% Μέσος Όρος Αριθμού Κανόνων
meanRules = sum(rules_kfold)/k;

%% Plots
% Prediction Values
figure(3)
scatter([1:size(prediction,1)],prediction)
grid on
xlabel('data')
ylabel('prediction')
title('Predicted Values')

% Real Values
figure(4)
scatter([1:size(Dtest(:,end),1)],Dtest(:,end))
grid on
xlabel('data')
ylabel('real values')
title('Real Values')

% Learning Curve
figure(5)
grid on
plot([trainError chkError])
xlabel('samples')
ylabel('Error')
legend('Training Error','Validation Error')
title("Learning Curve")

% mf AFTER Training
figure(6)
plotmf(chkFIS,'input',1)
title("Input 1 After training")
figure(7)
plotmf(chkFIS,'input',5)
title("Input 5 After training")









