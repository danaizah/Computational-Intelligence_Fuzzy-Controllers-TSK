%% Aristotle University of Thessaloniki (AUTh) ECE
%% Danai Zacharioudaki AEM: 9418 Email: zachardd@ece.auth.gr


format compact
clear 
clc

%% Data loading 
data=load('haberman.data');
inputNames = { ...
    'Age', ...
    'Year of Operation', ...
    'Number of Positive Axillary Nodes'};

%Data split
preproc=1;

[Dtrn,Dval,Dtst]=stratified_sampling_split_scale(data,preproc);

TargetDtrn = Dtrn(:, end);
TargetDval = Dval(:, end);
TargetDtst = Dtst(:, end);


%Model Initialization 
model_names = {'TSK_model_1','TSK_model_2','TSK_model_3','TSK_model_4',};

%Class-independent models

cluster_radius(1) = 0.1;
FISoptions(1) = genfisOptions('SubtractiveClustering');
FISoptions(1).ClusterInfluenceRange = cluster_radius(1);
initialFIS(1) = genfis(Dtrn(:, 1:end-1), TargetDtrn, FISoptions(1));

cluster_radius(2) = 0.9;
FISoptions(2) = genfisOptions('SubtractiveClustering');
FISoptions(2).ClusterInfluenceRange = cluster_radius(2);
initialFIS(2) = genfis(Dtrn(:, 1:end-1), TargetDtrn, FISoptions(2));

%Class-dependent models

cluster_radius(3) = 0.1;
FISoptions(3) = genfisOptions('SubtractiveClustering');
initialFIS(3) = sugfis;

cluster_radius(4) = 0.9;
FISoptions(4) = genfisOptions('SubtractiveClustering');
initialFIS(4) = sugfis;

outputMembershipFunctionType = 'constant' ; % Singleton
numOfModels = length(model_names);


% Classification Metrics initialization

OA = zeros(2,1);
PA = zeros(2,2);
UA = zeros(2,2);
Kappa = zeros(2,1);
error_matrix = zeros(2,2,2);

% Classification Metrics Function
function [OA, PA, UA, Kappa] = classificationMetrics(confMat)
    % confMat: confusion matrix (k x k)
    N = sum(confMat(:));          % total samples
    diagVals = diag(confMat);     % correct predictions per class
    rowSum = sum(confMat, 2); % actual totals
    colSum = sum(confMat, 1); % predicted totals
    % Overall Accuracy 
    OA = sum(diagVals) / N;

    % Producer's Accuracy 
    % (how well true samples are correctly recognized)
    PA = diagVals ./ rowSum;

    % User's Accuracy
    % (how reliable the predicted labels are)
    UA = diagVals' ./ colSum;

    % Cohen's Kappa 
    Kappa = (N * sum(diagVals) - sum(rowSum .* colSum')) / ...
            (N^2 - sum(rowSum .* colSum'));
end





%% Train models

ANFISoptions = anfisOptions;
ANFISoptions.ValidationData = Dval;
ANFISoptions.EpochNumber = 100;

 
trainingTime = zeros(1, numOfModels);

%CLASS-INDEPENDENT ONLY
for i = 1:(numOfModels-2)

    ANFISoptions.InitialFIS = initialFIS(i);
    tic;
    [~, trainError(:, i), ~, validationFIS(i), validationError(:, i)] = anfis(Dtrn, ANFISoptions);
    trainingTime(i) = toc;

    fprintf('Model %d training time: %.2f seconds\n', i, trainingTime(i));

    % Membership functions 
    for j = 1:size(Dtrn, 2) - 1
        figure;
        plotmf(validationFIS(i), 'input', j);
        xlabel(inputNames{j}, 'Interpreter', 'latex');
        ylabel('Degree of Membership', 'Interpreter', 'latex')
        title(['Input: ' inputNames{j}], 'Interpreter', 'latex');
        subtitle(['TSK\_model\_' num2str(i)], 'Interpreter','latex');
        %saveas(gcf,['.\figures\Part1'  '\TSK_model_' num2str(i) '_input_' num2str(j) '.png'])
    end

 % Learning curve 
    figure;
    plot([trainError(:, i) validationError(:, i)]);
    grid on;
    xlabel('Num of iterations', 'Interpreter', 'latex'); 
    ylabel('Error', 'Interpreter', 'latex');
    legend('Training Error', 'Validation Error', 'Interpreter', 'latex');
    title('\textbf{Learning Curve}', 'Interpreter','latex');
    subtitle(['TSK\_model\_' num2str(i)], 'Interpreter','latex');
    %saveas(gcf,['.\figures\Part1'   '\TSK_model_' num2str(i) '_Learning_Curve.png'])
   

    y_pred(:, i) = evalfis(validationFIS(i), Dtst(:, 1:end-1));
    y_pred(:, i) = round(y_pred(:, i));
    y_pred(:, i) = min(max(1, y_pred(:, i)), 2);

    % Error matrix 
    error_matrix = confusionmat(TargetDtst, y_pred(:, i));
    figure;
    cm = confusionchart(error_matrix);
    cm.Title = ['Error matrix of TSK\_model\_' num2str(i)];
    %saveas(gcf,['.\figures\Part1' '\TSK_model_' num2str(i) '_ErrorMatrix.png'])

    % Metrics calculation  
    [OA(i), PA(:, i), UA(:, i), Kappa(i)] = classificationMetrics(error_matrix);

    num_model_rules(i) = size(validationFIS(i).Rules, 2);
end

%CLASS-DEPENDENT ONLY
for i = (numOfModels-1):numOfModels

    % Clustering Per Class
    cluster_1_input_data = Dtrn(TargetDtrn == 1, :);
    [cluster_centers1, sigma1] = subclust(cluster_1_input_data, cluster_radius(i));
    num_cluster_centers1 = size(cluster_centers1, 1);
    cluster_2_input_data = Dtrn(TargetDtrn == 2, :);
    [cluster_centers2, sigma2] = subclust(cluster_2_input_data, cluster_radius(i));
    num_cluster_centers2 = size(cluster_centers2, 1);

    num_rules = num_cluster_centers1 + num_cluster_centers2;

    for j = 1:size(Dtrn, 2) - 1
        % Add Input
        initialFIS(i) = addInput(initialFIS(i), [0,1], 'Name', sprintf("in%d", j));

        % Add MF
        for k=1:size(cluster_centers1, 1)    
            initialFIS(i) = addMF(initialFIS(i), sprintf("in%d", j), 'gaussmf', [sigma1(j) cluster_centers1(k, j)]);
        end
        for k=1:size(cluster_centers2, 1)
            initialFIS(i) = addMF(initialFIS(i), sprintf("in%d", j), 'gaussmf', [sigma2(j) cluster_centers2(k, j)]);
        end
    end

    % Add Output
    initialFIS(i) = addOutput(initialFIS(i), [0, 1], 'Name', 'out1');

    % Add MF
    params = [zeros(1, size(cluster_centers1, 1)) ones(1, size(cluster_centers2, 1))];
    for j = 1:num_rules
        initialFIS(i) = addMF(initialFIS(i), 'out1', outputMembershipFunctionType, params(j));
    end

    % Add FIS RuleBase
    rules_list = zeros(num_rules, size(Dtrn, 2));
    for j = 1:size(rules_list, 1)
        rules_list(j, :) = j;
    end
    rules_list = [rules_list ones(num_rules, 2)];
    initialFIS(i) = addrule(initialFIS(i), rules_list);

    %Training
    ANFISoptions.InitialFIS = initialFIS(i);

    % Train model
    [~, trainError(:, i), ~, validationFIS(i), validationError(:, i)] = anfis(Dtrn, ANFISoptions);

    % Membership functions 
    for j = 1:size(Dtrn, 2) - 1
        figure;
        plotmf(validationFIS(i), 'input', j);
        xlabel(inputNames{j}, 'Interpreter', 'latex');
        ylabel('Degree of Membership', 'Interpreter', 'latex')
        title(['Input: ' inputNames{j}], 'Interpreter', 'latex');
        subtitle(['TSK\_model\_' num2str(i)], 'Interpreter','latex');
        %saveas(gcf,['.\figures\Part1'  '\TSK_model_' num2str(i) '_input_' num2str(j) '.png'])
    end

    % Learning curve 
    figure;
    plot([trainError(:, i) validationError(:, i)]);
    grid on;
    xlabel('Num of iterations', 'Interpreter', 'latex'); 
    ylabel('Error', 'Interpreter', 'latex');
    legend('Training Error', 'Validation Error', 'Interpreter', 'latex');
    title('\textbf{Learning Curve}', 'Interpreter','latex');
    subtitle(['TSK\_model\_' num2str(i)], 'Interpreter','latex');
    %saveas(gcf,['.\figures\Part1' '\TSK_model_' num2str(i) '_Learning_Curve.png'])
   

    y_pred(:, i) = evalfis(validationFIS(i), Dtst(:, 1:end-1));
    y_pred(:, i) = round(y_pred(:, i));
    y_pred(:, i) = min(max(1, y_pred(:, i)), 2);

    % Error matrix 
    error_matrix = confusionmat(TargetDtst, y_pred(:, i));
    figure;
    cm = confusionchart(error_matrix);
    cm.Title = ['Error matrix of TSK\_model\_' num2str(i)];
    %saveas(gcf,['.\figures\Part1' '\TSK_model_' num2str(i) '_ErrorMatrix.png'])

     % Metrics calculation  
    [OA(i), PA(:, i), UA(:, i), Kappa(i)] = classificationMetrics(error_matrix);

    num_model_rules(i) = size(validationFIS(i).Rules, 2);

end

%% Metrics Results 

T = table;
T.Model = model_names';                           
T.("Overall Accuracy") = OA;                       
T.("Producer Accuracy (Class 1)") = PA(1, :)';     
T.("Producer Accuracy (Class 2)") = PA(2, :)';     
T.("User Accuracy (Class 1)") = UA(1, :)';         
T.("User Accuracy (Class 2)") = UA(2, :)';         
T.("K̂") = Kappa;                                  

disp(T)

for d = 1:length(num_model_rules)
    fprintf('Model %d has %d rules.\n', d, num_model_rules(d));
end




