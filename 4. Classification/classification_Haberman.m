% Δημήτρης Παππάς
% ΑΕΜ: 8391     
% ΗΜΜΥ ΑΠΘ 
% Classification part 1 - TSK Models
clear all;

%% Διαβάζω τα δεδομένα
% inputs
% age = Age of patient at time of operation (numerical) 
% year = Patient's year of operation (year - 1900, numerical) 
% nodes = Number of positive axillary nodes detected (numerical) 

% output
% survival = Survival status (class attribute)
% 1 = the patient survived 5 years or longer
% 2 = the patient died within 5 year

% data
D = load('haberman.data');
age = D(:,1);
year = D(:,2);
nodes = D(:,3);
survival = D(:,4);

%% Χωρίζω τα δεσομένα σε training, evaluation, check
% Dtrn = training data - 60% των data
% Dval = evaluation data - 20% των data
% Dchk = check data - 20% των data

numData = 306;
Dtrn = [age(1:fix(numData*0.6)), year(1:fix(numData*0.6)), nodes(1:fix(numData*0.6)), survival(1:fix(numData*0.6))];
Dval = [age(fix(numData*0.6)+1:fix(numData*0.8)), year(fix(numData*0.6)+1:fix(numData*0.8)), nodes(fix(numData*0.6)+1:fix(numData*0.8)), survival(fix(numData*0.6)+1:fix(numData*0.8))];
Dchk = [age(fix(numData*0.8)+1:end), year(fix(numData*0.8)+1:end), nodes(fix(numData*0.8)+1:end), survival(fix(numData*0.8)+1:end)];

%% Αρχικοποίηση Τιμών
% Αλλάζω τον αριθμό των κανόνων μέσω της ακτίνας των Clusters. Επιλέγω δύο ακραίες τιμές σύμφωνα με την εκφώνηση
% Μοντέλο 1 & 3 radius = 0.1 -- Μοντέλο 2 & 4 radius = 0.9
radius = [0.1 0.9];     

% Τα δύο πρώτα μοντέλα 1 & 2 κάνουν "class dependent" clustering
EM_dependent = zeros(2,2,2);        % Error Matrix
OA_dependent = zeros(2,1);          % Overall Accuracy
PA_dependent = zeros(2,2);          % Producer's Accuracy
UA_dependent = zeros(2,2);          % User's Accuracy
K_dependent = zeros(2,1);           % Εκτίμηση Πραγματικής Στατιστικής Παραμέτρου
Rules_dependent = zeros(2,1);       % Αριθμός Κανόνων Μοντέλου Εκπαίδευσης

% Τα δύο επόμενα μοντέλα 3 & 4 κάνουν "class independent" clustering
EM_independent = zeros(2,2,2);      % Error Matrix
OA_independent = zeros(2,1);        % Overall Accuracy
PA_independent = zeros(2,2);        % Producer's Accuracy
UA_independent = zeros(2,2);        % User's Accuracy
K_independent = zeros(2,1);         % Εκτίμηση Πραγματικής Στατιστικής Παραμέτρου
Rules_independent = zeros(2,1);     % Αριθμός Κανόνων Μοντέλου Εκπαίδευσης

numRules = 0;                       % Αριθμός Κανόνων
counter = 0;                        % Μετριτής Επαναλήψεων 

% Ανάθεση τιμής στο όνομα της mf
nameMF = strings(1000,1);
nameMF_out = strings(1000,1);
for i = 1:1000
    nameMF(i) = "mf" + i;
    nameMF_out(i) = "mfOut" + i;
end

% Ανάθεση τιμής στο όνομα των inputs
nameInput = {'Age', 'Year', 'Nodes'};
% Έχουμε 2 classes: survival = {1,2}

%% Clustering
% Τρέχω δύο επαναλήψεις για κάθε τιμή της ακτίνας, ένα μοντέλο "Class
% Dependent" και ένα μοντέλο "Class Independent"
% "Subtractive Clustering" διαμέριση χώρου
for r=1:2 
    %% "Class Dependent"  --  Clustering per Class
    [centers1, sigma1] = subclust(Dtrn(Dtrn(:,end) == 1,:), radius(r));
    [centers2, sigma2] = subclust(Dtrn(Dtrn(:,end) == 2,:), radius(r));
    numRules = size(centers1,1) + size(centers2,1);


    % Build new FIS 
    class_fis = newfis('Classification_FIS', 'sugeno');
    
    % Add Input Variables
    for i=1:size(Dtrn,2)-1          % number of features
        class_fis = addvar(class_fis, 'input', nameInput{i}, [0 1]);
    end
    
    % Add Output Variable
    class_fis = addvar(class_fis, 'output', 'Survival', [0 1]);
    
    % Add Input Membership Functions
    for i=1:size(Dtrn,2)-1          % number of features
        for j=1:size(centers1,1)    % number of centers for each feature
            counter = counter + 1;
            class_fis = addmf(class_fis, 'input', i, nameMF(counter), 'gaussmf', [sigma1(i) centers1(j,i)]);
        end
        for j=1:size(centers2,1)    % number of centers for each feature
            counter = counter + 1;
            class_fis = addmf(class_fis, 'input', i, nameMF(counter), 'gaussmf', [sigma2(i) centers2(j,i)]);
        end
    end
    counter = 0;        % reset counter
    
    % Add Output Membership Functions
    out = [zeros(1, size(centers1,1)) ones(1, size(centers2,1))];
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

    % ANFIS Training
    EpochNumber = 100;
    opt_an = anfisOptions('InitialFIS', class_fis, 'EpochNumber', EpochNumber);
    opt_an.ValidationData = Dval;
    opt_an.OptimizationMethod = 1;      % hybrid
    [class_model, trainError, stepSize, chkFIS, chkError] = anfis(Dtrn, opt_an);

    % ANFIS Evaluation
    prediction = evalfis(class_model, Dchk(:,1:end-1));
    prediction = round(prediction);     % Στρογγυπολποιώ στην κοντινότερη integer τιμή
    % Περιορίζω το σύνολο τιμών στο {1,2}, γιατί η round μπορεί να δώσει {0,1,2,3}
    for i=1:size(prediction,1)
        if prediction(i) <= 1 ; prediction(i) = 1 ; end
        if prediction(i) >= 2 ; prediction(i) = 2 ; end
    end
    prediction_error = Dchk(:,end) - prediction;

    % Υπολογίζω τον Error Matrix 
    errMatrix = zeros(2,2);
    errMessage = "Confusion Matrix -- Class Dependent με ακτίνα " + radius(r)
    errMatrix = confusionmat(Dchk(:,end), prediction)       %  Επιστρέφει τον confusion matrix μεταξύ των Πραγματικών Τιμών και των Προβλεπόμενων Τιμών 
    
    % Υπολογίζω Accuracy
    TP = errMatrix(1,1);    % True Positive
    FP = errMatrix(2,1);    % False Positive
    TN = errMatrix(2,2);    % True Negative
    FN = errMatrix(1,2);    % False Negative
    
    % Overall Accuracy
    OA = (TP + TN) / (TP + FP + TN + FN);

    % Producer's Accuracy
    PA1 = TP / (TP + FN);       % Σωστές Προβλέψεις / Σύνολο γραμμής
    PA2 = TN / (TN + FP);

    % User's Accuracy
    UA1 = TP / (TP + FP);       % Σωστές Προβλέψεις / Σύνολο στήλης
    UA2 = TN / (TN + FN);

    % K
    N = size(Dchk,1);
    K = (N*(TP + TN) - ((TP + FP)*(TP + FN) + (FN + TN)*(FP + TN)))/(N^2 - ((TP + FP)*(TP + FN) + (FN + TN)*(FP + TN)));

    % Αποθηκεύω τις μετρήσεις των δύο ακτινών [0.1 0.9] για το "Dependent" μοντέλο
    OA_dependent(r) = OA;
    PA_dependent(r,1) = PA1;
    PA_dependent(r,2) = PA2;
    UA_dependent(r,1) = UA1;
    UA_dependent(r,2) = UA2;
    K_dependent(r) = K;
    EM_dependent(:,:,r) = errMatrix;
    Rules_dependent(r) = size(class_model.Rules,2);

    % Plots Class Dependent
    if r == 1
        % Plot Learning Curve
        figure(2)
        plot([trainError chkError],'LineWidth',2)
        grid on
        legend('Training Error','Checking Error')
        xlabel('EpochNumber')
        ylabel('Error')
        title("Learning Curve - Class Dependent με radius = " + radius(r))

        % Plot Prediction Error  
        figure(3)
        scatter([1:length(prediction_error)],prediction_error)
        grid on
        xlabel('data')
        ylabel('Prediction Error')
        title("Prediction Error - Class Dependent με radius = " + radius(r))

        % Plot Membership Functions
        for i = 1:size(Dtrn,2)-1        % number of features
            figure(3+i)
            plotmf(chkFIS,'input',i)
            title("Model Class Dependent " + r + " με feature " + i + " και ακρίνα " + radius(r))
        end
    else
        % Plot Learning Curve
        figure(7)
        plot([trainError chkError],'LineWidth',2)
        grid on
        legend('Training Error','Checking Error')
        xlabel('EpochNumber')
        ylabel('Error')
        title("Learning Curve - Class Dependent με radius = " + radius(r))

        % Plot Prediction Error  
        figure(8)
        scatter([1:length(prediction_error)],prediction_error)
        grid on
        xlabel('data')
        ylabel('Prediction Error')
        title("Prediction Error - Class Dependent με radius = " + radius(r))

        % Plot Membership Functions
        for i = 1:size(Dtrn,2)-1        % number of features
            figure(8+i)
            plotmf(chkFIS,'input',i)
            title("Model Class Dependent " + r + " με feature " + i + " και ακρίνα " + radius(r))
        end
    end

    %% "Class Independet" 
    % genfis μοντέλο με Sugeno fis και Subtractive Clustering
    fis2 = genfis2(Dtrn(:,1:end-1), Dtrn(:,end), radius(r));
    
    % anfis training
    EpochNumber = 100;
    opt_an = anfisOptions('InitialFIS',fis2,'EpochNumber',EpochNumber);
    opt_an.ValidationData = Dval;
    opt_an.OptimizationMethod = 1;      % hybrid
    [fis2_model, trainError2, stepSize2, chkFIS2, chkError2] = anfis(Dtrn, opt_an);
    
    % ANFIS Evaluation
    prediction2 = evalfis(fis2_model, Dchk(:,1:end-1));
    prediction2 = round(prediction2);     % Στρογγυπολποιώ στην κοντινότερη integer τιμή
    % Περιορίζω το σύνολο τιμών στο {1,2}, γιατί η round μπορεί να δώσει {0,1,2,3}
    for i=1:size(prediction2,1)
        if prediction2(i) <= 1 ; prediction2(i) = 1 ; end
        if prediction2(i) >= 2 ; prediction2(i) = 2 ; end
    end
    prediction_error2 = Dchk(:,end) - prediction2;

    % Υπολογίζω τον Error Matrix 
    errMatrix = zeros(2,2);
    errMessage = "Confusion Matrix -- Class Independent με ακτίνα " + radius(r)
    errMatrix = confusionmat(Dchk(:,end), prediction2)       %  Επιστρέφει τον confusion matrix μεταξύ των Πραγματικών Τιμών και των Προβλεπόμενων Τιμών 
    
    % Υπολογίζω Accuracy
    TP = errMatrix(1,1);    % True Positive
    FP = errMatrix(2,1);    % False Positive
    TN = errMatrix(2,2);    % True Negative
    FN = errMatrix(1,2);    % False Negative
    
    % Overall Accuracy
    OA = (TP + TN) / (TP + FP + TN + FN);

    % Producer's Accuracy
    PA1 = TP / (TP + FN);       % Σωστές Προβλέψεις / Σύνολο γραμμής
    PA2 = TN / (TN + FP);

    % User's Accuracy
    UA1 = TP / (TP + FP);       % Σωστές Προβλέψεις / Σύνολο στήλης
    UA2 = TN / (TN + FN);

    % K
    N = size(Dchk,1);
    K = (N*(TP + TN) - ((TP + FP)*(TP + FN) + (FN + TN)*(FP + TN)))/(N^2 - ((TP + FP)*(TP + FN) + (FN + TN)*(FP + TN)));

    % Αποθηκεύω τις μετρήσεις των δύο ακτινών [0.1 0.9] για το "Independent" μοντέλο
    OA_independent(r) = OA;
    PA_independent(r,1) = PA1;
    PA_independent(r,2) = PA2;
    UA_independent(r,1) = UA1;
    UA_independent(r,2) = UA2;
    K_independent(r) = K;
    EM_independent(:,:,r) = errMatrix;
    Rules_independent(r) = size(fis2_model.Rules,2);

    % Plots Class Independent
    if r == 1
        figure(12)
        plot([trainError2 chkError2],'LineWidth',2)
        grid on
        legend('Training Error','Checking Error')
        xlabel('number of Epochs')
        ylabel('Error')
        title("Learning Curve - Class Independent με radius = " + radius(r))

        % Plot Prediction Error  
        figure(13)
        scatter([1:length(prediction_error2)],prediction_error2)
        grid on
        xlabel('data')
        ylabel('Prediction Error')
        title("Prediction Error - Class Independent με radius = " + radius(r))

        % Plot Membership Functions
        for i = 1:size(Dtrn,2)-1        % number of features
            figure(13+i)
            plotmf(chkFIS2,'input',i)
            title("Model Class Independent " + r + " με feature " + i + " και ακρίνα " + radius(r))
        end
    else
        figure(17)
        plot([trainError2 chkError2],'LineWidth',2)
        grid on
        legend('Training Error','Checking Error')
        xlabel('number of Epochs')
        ylabel('Error')
        title("Learning Curve - Class Independent με radius = " + radius(r))

        % Plot Prediction Error  
        figure(18)
        scatter([1:length(prediction_error2)],prediction_error2)
        grid on
        xlabel('data')
        ylabel('Prediction Error')
        title("Prediction Error - Class Independent με radius = " + radius(r))

        % Plot Membership Functions
        for i = 1:size(Dtrn,2)-1        % number of features
            figure(18+i)
            plotmf(chkFIS2,'input',i)
            title("Model Class Independent " + r + " με feature " + i + " και ακρίνα " + radius(r))
        end
    end
end

%% Plot Πίνακες και Accuracy
% Class Dependent
OA_message = "Overall Accuracy -- Class Dependent"
OA_dependent
PA_message = "Producer's Accuracy -- Class Dependent"
PA_dependent
UA_message = "User's Accuracy -- Class Dependent"
UA_dependent
K_message = "Εκτίμηση Πραγματικής Στατιστικής Παραμέτρου K -- Class Dependent"
K_dependent
EM_message = "Error Matrix -- Class Dependent"
EM_dependent
Rules_message = "Number of Rules -- Class Dependent"
Rules_dependent

% Class Independent
OA_message = "Overall Accuracy -- Class Independent"
OA_independent
PA_message = "Producer's Accuracy -- Class Independent"
PA_independent
UA_message = "User's Accuracy -- Class Independent"
UA_independent
K_message = "Εκτίμηση Πραγματικής Στατιστικής Παραμέτρου K -- Class Independent"
K_independent
EM_message = "Error Matrix -- Class Independent"
EM_independent
Rules_message = "Number of Rules -- Class Independent"
Rules_independent




%% Plot inputs & output
figure(1)
subplot(2,2,1)
plot(age)
title('age')
subplot(2,2,2)
plot(year)
title('year in 20th century')
subplot(2,2,3)
plot(nodes)
title('nodes')
subplot(2,2,4)
plot(survival)
title('survival')





