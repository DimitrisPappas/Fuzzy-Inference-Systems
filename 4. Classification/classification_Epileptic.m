% Δημήτρης Παππάς
% ΑΕΜ: 8391     
% ΗΜΜΥ ΑΠΘ 
% Classification part 2 - Searching for the Optimal Parameters
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
% Ορίζω τις παραμέτρους για αριθμό σημαντικότερων features και μήκος
% ακτίνας των clusters
parameters = zeros(4,5,2);  % 4x5 features & 4x5 radius
parameters(:,:,1) = [5 5 5 5 5; 7 7 7 7 7; 9 9 9 9 9; 11 11 11 11 11];
parameters(:,:,2) = [0.2 0.4 0.6 0.8 1; 0.2 0.4 0.6 0.8 1; 0.2 0.4 0.6 0.8 1; 0.2 0.4 0.6 0.8 1];

% Πίνακες Τελικών Αποτελεσμάτων
OA = zeros(4,5);        % Overall Accuracy
rulesNumber = zeros(4,5);     % Number of Rules
features = zeros(4,5);  % Σημαντικότερα features που επιλέχτηκαν από την Relief

% Πίνακες για k-fold cross validation
OA_kfold = zeros(5,1);      % OA για κάθε k fold
rules_kfold = zeros(5,1);   % rules για κάθε k fold

k = 5;              % 5 k-fold cross validation
iteration = 0;     % αριθμός επαναλήψεων
counter = 0;        % μετριτής

% Ανάθεση τιμής στο όνομα της mf
nameMF = strings(100000,1);
nameMF_out = strings(100000,1);
for i = 1:100000
    nameMF(i) = "mf" + i;
    nameMF_out(i) = "mfOut" + i;
end

%% Σημαντικότερα features
% Επιλέγω τα σημαντικότερα features με την ενοτλή "Relief"
[ranks,weights] = relieff(D(:,1:end-1), D(:,end), 5);

%% Grid Search με Class Dependent
for f=1:4       % number of features
    for r=1:5   % number of radius
        features_kfold = parameters(f,r,1);
        radius = parameters(f,r,2);
        % CVpartition kfold
        kfold1 = cvpartition(D(:,end), 'KFold', 5, 'Stratify', true);

        for fold=1:kfold1.NumTestSets
            iteration = iteration + 1;
            messageCounter = "Είμαι στην επανάληψη " + iteration;
            iteration

            %% Διαχωρισμός Δεσομένων
            % Χωρίζω με τυχαιότητα το συνολικό dataset σε training dataset
            % 80% του συνόλου και σε testing dataset 20%
            Dtraining = D(training(kfold1,fold),:);         % Training indices for cross-validation 80%
            Dtesting = D(test(kfold1,fold),:);              % Test indices for cross-validation 20%
            
            % Χωρίζω το training cross validation dataset "Dtraining" σε
            % training 80% (του 80% του συνόλου) και σε testing 20% (του 80% του συνόλου)
            kfold2 = cvpartition(Dtraining(:,end), 'KFold', 4, 'Stratify', true);
            Dtrn = Dtraining(training(kfold2,2),:);
            Dchk = Dtraining(test(kfold2,2),:);

            % Κρατάω μόνο τα Σημαντικότερα features
            Dtrn = [Dtrn(:,ranks(1:features_kfold)) Dtrn(:,end)];
            Dchk = [Dchk(:,ranks(1:features_kfold)) Dchk(:,end)];
            Dtest = [Dtesting(:,ranks(1:features_kfold)) Dtesting(:,end)];

            
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
            % Error Matrix
            EM = zeros(5,5);
            EM_message = "Confusion Matrix -- Class Dependent -- kfold iteration  " + fold
            EM = confusionmat(Dtest(:,end), prediction)        %  Επιστρέφει τον confusion matrix μεταξύ των Πραγματικών Τιμών και των Προβλεπόμενων Τιμών 

            % Overall Accuracy
            N = size(Dtest,1);
            oa = sum(diag(EM))/N;
            OA_kfold(fold) = oa;
            rules_kfold(fold) = size(class_model.Rules,2);
            
        end
        
        %% Μέσος Όρος Overall Accuracy
        % Οι τιμές του output epidleptic = {1,2,3,4,5} είναι συμβολικές
        % τιμές. Γι' αυτό δεν έχει νόημα να υπολογίσουμε μέσο όρο σφάλματος
        % πρόβλεψης για το output. Επομένως, θα αξιολογίσω το μοντέλο με
        % βάση το μέσο ότου το OA
        OA(f,r) = sum(OA_kfold(:))/k;       % Σ(OA) για όλα τα folds / k=5 αριθμό των k-folds
        features(f,r) = features_kfold;
        rulesNumber(f,r) = sum(rules_kfold(:))/k;

    end
end

%% Plots
% Overall Accuracy - Rules
figure(1);
scatter(reshape(OA,1,[]),reshape(rulesNumber,1,[]))
grid on
xlabel("Overall Accuracy")
ylabel("Number of Rules")
title("Overall Accuracy - Number of Rules ")

% Overall Accuracy - Features
figure(2);
scatter(reshape(OA,1,[]),reshape(features,1,[]))
grid on
xlabel("Overall Accuracy")
ylabel("Number of most significant Features")
title("Overall Accuracy - Number of Features")

% Overall Accuracy - Radius
figure(3);
scatter(reshape(OA,1,[]),reshape(parameters(:,:,2),1,[]))
grid on
xlabel("Overall Accuracy")
ylabel("Radius Cluster")
title("Overall Accuracy - Radius")

% Overall Accuracy - Radius + Features
figure(4);
surf(OA(:,:),parameters(:,:,2),parameters(:,:,1))
grid on
xlabel("Overall Accuracy")
ylabel("Radius Cluster")
zlabel("Number of Features")
title("Overall Accuracy - Radius + Features")















