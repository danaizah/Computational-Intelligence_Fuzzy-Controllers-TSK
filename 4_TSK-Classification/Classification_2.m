% Aristotle University of Thessaloniki (AUTh) ECE
%% Danai Zacharioudaki AEM: 9418 Email: zachardd@ece.auth.gr

format compact
clear 
clc

% Data loading from .csv file
dataset = importdata('epileptic_seizure_data.csv');

% Ensure numeric
if isstruct(dataset)
    data = dataset.data;
else
    data = dataset;
end

%Data split
preproc=1;
[Dtrn,Dval,Dtst]=stratified_sampling_split_scale(data,preproc);

dataset_target = data(:, end);
TargetDtrn = Dtrn(:, end);
TargetDval = Dval(:, end);
Dval = max(min(Dval,1),0);
TargetDtst = Dtst(:, end);
Dtst = max(min(Dtst,1),0);



%%----Grid Search----

num_features = [5 8 10 12];

cluster_radius = [0.2 0.4 0.5 0.6];

%Local variables

num_folds = 5;
grid_MSE = zeros(length(num_features), length(cluster_radius));
grid_num_rules = zeros(length(num_features), length(cluster_radius));

%Feature selection: Relief algorithm
num_nearest_neighbors = 10;
outputMembershipFunctionType = 'constant';
[ranking_indexes, importanceWeights] = relieff(Dtrn(:, 1:end-1), Dtrn(:, end), num_nearest_neighbors, 'method', 'classification');


%Copies for parallelization
num_features_list = num_features;   
cluster_radius_list = cluster_radius;

Dtrn_local = Dtrn;
Dtst_local = Dtst;
TargetDtrn_local = TargetDtrn;
TargetDtst_local = TargetDtst;
ranking_local = ranking_indexes;

%Starts a default parallel pool
if isempty(gcp('nocreate'))
    parpool; 
end

parfor iIdx = 1:length(num_features)
    i = num_features_list(iIdx);
    local_MSE = zeros(1, numel(cluster_radius_list));
    local_rules = zeros(1, numel(cluster_radius_list));
    fprintf('Processing feature set %d/%d...\n', iIdx, length(num_features));
    temp_trn = [Dtrn_local(:, ranking_local(1:i)) TargetDtrn_local];
    temp_tst = [Dtst_local(:, ranking_local(1:i)) TargetDtst_local];  
    for jIdx = 1:numel(cluster_radius_list)
        j = cluster_radius_list(jIdx);

        CV = cvpartition(temp_trn(:, end), 'KFold', num_folds, 'Stratify', true);
        CV_MSE = zeros(1, num_folds);
        rules_num = zeros(num_folds, 1);

        for k = 1:num_folds
            CV_Dtrn = temp_trn(training(CV, k), :);
            CV_TargetDtrn = CV_Dtrn(:, end);
            CV_val = temp_trn(test(CV, k), :);


            % Clustering Per Class
            cluster1_inputData = CV_Dtrn(CV_Dtrn(:, end) == 1, 1:end-1);
           
            if ~isempty(cluster1_inputData)
               [cluster_centers1, sigma1] = subclust(cluster1_inputData, j);
            else
                cluster_centers1 = [];
                sigma1 = [];
            end

            cluster2_inputData = CV_Dtrn(CV_Dtrn(:, end) == 2, 1:end-1);
            
            if ~isempty(cluster2_inputData)
                [cluster_centers2, sigma2] = subclust(cluster2_inputData, j);
           else
                cluster_centers2 = [];
                sigma2 = [];
            end

            cluster3_inputData = CV_Dtrn(CV_Dtrn(:, end) == 3, 1:end-1);
            
            if ~isempty(cluster3_inputData)
                [cluster_centers3, sigma3] = subclust(cluster3_inputData, j);
           else
                cluster_centers3 = [];
                sigma3 = [];
            end

            cluster4_inputData = CV_Dtrn(CV_Dtrn(:, end) == 4, 1:end-1);
            
            if ~isempty(cluster4_inputData)
                [cluster_centers4, sigma4] = subclust(cluster4_inputData, j);
           else
                cluster_centers4 = [];
                sigma4 = [];
           end
            
            cluster5_inputData = CV_Dtrn(CV_Dtrn(:, end) == 5, 1:end-1);
            
            if ~isempty(cluster5_inputData)
                [cluster_centers5, sigma5] = subclust(cluster5_inputData, j);
           else
                cluster_centers5 = [];
                sigma5 = [];
           end
           
           sigma_min = 1e-3;
           sigma1 = max(sigma1, sigma_min);
           sigma2 = max(sigma2, sigma_min);
           sigma3 = max(sigma3, sigma_min);
           sigma4 = max(sigma4, sigma_min);
           sigma5 = max(sigma5, sigma_min);



            % Total num of rules
            num_rules = size(cluster_centers1, 1) + size(cluster_centers2, 1) + size(cluster_centers3, 1) + size(cluster_centers4, 1) + size(cluster_centers5, 1);

            initial_fis = sugfis;

             % Input
            for n = 1:size(temp_trn, 2) - 1
                % Add Input
                initial_fis = addInput(initial_fis, [0, 1], 'Name', sprintf("in%d", n));

                % Add Iput Membership Functions
                for m = 1:size(cluster_centers1, 1)    
                    initial_fis = addMF(initial_fis, sprintf("in%d", n), 'gaussmf', [sigma1(n) cluster_centers1(m, n)]);
                end
                for m = 1:size(cluster_centers2, 1)
                    initial_fis = addMF(initial_fis, sprintf("in%d", n), 'gaussmf', [sigma2(n) cluster_centers2(m, n)]);
                end
                for m = 1:size(cluster_centers3, 1)
                    initial_fis = addMF(initial_fis, sprintf("in%d", n), 'gaussmf', [sigma3(n) cluster_centers3(m, n)]);
                end
                for m = 1:size(cluster_centers4, 1)
                    initial_fis = addMF(initial_fis, sprintf("in%d", n), 'gaussmf', [sigma4(n) cluster_centers4(m, n)]);
                end
                for m = 1:size(cluster_centers5, 1)
                    initial_fis = addMF(initial_fis, sprintf("in%d", n), 'gaussmf', [sigma5(n) cluster_centers5(m, n)]);
                end
            end

             % Output
            initial_fis = addOutput(initial_fis, [0, 1], 'Name', 'out1');

            params = [1*ones(1, size(cluster_centers1, 1)) 2*ones(1, size(cluster_centers2, 1)) 3*ones(1, size(cluster_centers3, 1)) 4*ones(1, size(cluster_centers4, 1)) 5*ones(1, size(cluster_centers5, 1))];
            for n = 1:num_rules
                initial_fis = addMF(initial_fis, 'out1', outputMembershipFunctionType, params(n));
            end

            % Extract Rulebase

            rule_list = zeros(num_rules, size(CV_Dtrn, 2));
            for n = 1:size(rule_list, 1)
                rule_list(n, :) = n;
            end
            rule_list = [rule_list ones(num_rules, 2)];
            initial_fis = addrule(initial_fis, rule_list);

            % FIS Options
            ANFISoptions = anfisOptions;
            ANFISoptions.InitialFIS = initial_fis;
            ANFISoptions.ValidationData = CV_val;
            ANFISoptions.EpochNumber = 100;
            
            % Train model
            [~, ~, ~, fis, ~] = anfis(CV_Dtrn, ANFISoptions);

            % Calculate the trained model's output
            y_pred = evalfis(fis, CV_val(:, 1:end-1));
            y_pred = round(max(min(y_pred,5),1));
           
            % Mean Squared Error
            CV_MSE(k) = mse(y_pred, CV_val(:, end));
            
           
             % Calculate the Error Matrix 
            error_matrix = confusionmat(CV_val(:, end), y_pred);

        end
        local_MSE(jIdx) = mean(CV_MSE);
        local_rules(jIdx) = length(fis.Rules);
        % save an MSE for every pair of feature number & cluster radius
        grid_MSE(iIdx, :) = local_MSE;
        grid_num_rules(iIdx, :) = local_rules;

    end
end

save('classification_grid_search');

%%
% === Find and report best hyperparameter combination ===
% Find the smallest MSE across all combinations
[minMSE, linearIndex] = min(grid_MSE(:));

% Convert linear index to matrix indices
[bestFeatureIdx, bestRadiusIdx] = ind2sub(size(grid_MSE), linearIndex);

% Get the corresponding values of features and cluster radius
bestNumOfFeatures = num_features(bestFeatureIdx);
bestClusterRadius = cluster_radius(bestRadiusIdx);
bestNumOfRules = grid_num_rules(bestFeatureIdx, bestRadiusIdx);

% Print the results
fprintf('\n=== GRID SEARCH RESULTS ===\n');
fprintf('Lowest mean MSE: %.6f\n', minMSE);
fprintf('Best number of features: %d\n', bestNumOfFeatures);
fprintf('Best cluster radius: %.2f\n', bestClusterRadius);
fprintf('Corresponding number of rules: %d\n', bestNumOfRules);
fprintf('===========================\n\n');

%% === Visualization ===

load('classification_grid_search');

%MSE - Number of rules
figure;
scatter(grid_num_rules(:), grid_MSE(:), 80, repelem(num_features, numel(cluster_radius))', 'filled');
xlabel('Number of Fuzzy Rules');
ylabel('Mean Squared Error');
title('MSE vs Number of Rules');
colorbar;
colormap turbo;
grid on;
xlim([0 60]); 
saveas(gcf,['.\figures\Part2' 'MSE_Rules_plot.png'])

%MSE - Number of features & Cluster radius

figure;
surf(num_features, cluster_radius, grid_MSE');
xlabel('Number of Features');
ylabel('Cluster Radius');
zlabel('Mean Squared Error');
title('Surface Plot: MSE vs Number of Features and Cluster Radius');
colorbar;
colormap turbo;
shading interp; 
grid on;
view(45, 30);
saveas(gcf,['.\figures\Part2' 'MSE_Surface_Plot.png'])



%---Train the optimized model---

% Select top features
final_trn = [Dtrn(:, ranking_indexes(1:bestNumOfFeatures)) TargetDtrn];
final_val = [Dval(:, ranking_indexes(1:bestNumOfFeatures)) TargetDval];
final_tst = [Dtst(:, ranking_indexes(1:bestNumOfFeatures)) TargetDtst];

%Clustering per class 

cluster1_inputData = final_trn(final_trn(:, end) == 1, 1:end-1);
cluster2_inputData = final_trn(final_trn(:, end) == 2, 1:end-1);
cluster3_inputData = final_trn(final_trn(:, end) == 3, 1:end-1);
cluster4_inputData = final_trn(final_trn(:, end) == 4, 1:end-1);
cluster5_inputData = final_trn(final_trn(:, end) == 5, 1:end-1);

sigma_min = 1e-3;   % Avoid zeros

if ~isempty(cluster1_inputData)
    [cluster_centers1, sigma1] = subclust(cluster1_inputData, bestClusterRadius);
    sigma1 = max(sigma1, 1e-3);
else
    cluster_centers1 = [];
    sigma1 = [];
end
sigma1 = max(sigma1, sigma_min);

if ~isempty(cluster2_inputData)
    [cluster_centers2, sigma2] = subclust(cluster2_inputData, bestClusterRadius);
    sigma2 = max(sigma2, 1e-3);
else
    cluster_centers2 = [];
    sigma2 = [];
end
sigma2 = max(sigma2, sigma_min);

if ~isempty(cluster3_inputData)
    [cluster_centers3, sigma3] = subclust(cluster3_inputData, bestClusterRadius);
    sigma3 = max(sigma3, 1e-3);
else
    cluster_centers3 = [];
    sigma3 = [];
end
sigma3 = max(sigma3, sigma_min);

if ~isempty(cluster4_inputData)
    [cluster_centers4, sigma4] = subclust(cluster4_inputData, bestClusterRadius);
    sigma4 = max(sigma4, 1e-3);
else
    cluster_centers4 = [];
    sigma4 = [];
end
sigma4 = max(sigma4, sigma_min);

if ~isempty(cluster5_inputData)
    [cluster_centers5, sigma5] = subclust(cluster5_inputData, bestClusterRadius);
    sigma5 = max(sigma5, 1e-3);
else
    cluster_centers5 = [];
    sigma5 = [];
end
sigma5 = max(sigma5, sigma_min);

num_rules = size(cluster_centers1,1) + size(cluster_centers2,1) + ...
            size(cluster_centers3,1) + size(cluster_centers4,1) + ...
            size(cluster_centers5,1);


% Initialize Sugeno-type fis
optimal_fis = sugfis('Name', 'Optimal_ANFIS');

for n = 1:bestNumOfFeatures
    optimal_fis = addInput(optimal_fis, [0 1], 'Name', sprintf('in%d', n));

    % Add Gaussian MFs from all classes
    for m = 1:size(cluster_centers1, 1)
        optimal_fis = addMF(optimal_fis, sprintf('in%d', n), 'gaussmf', [sigma1(n) cluster_centers1(m, n)]);
    end
    for m = 1:size(cluster_centers2, 1)
        optimal_fis = addMF(optimal_fis, sprintf('in%d', n), 'gaussmf', [sigma2(n) cluster_centers2(m, n)]);
    end
    for m = 1:size(cluster_centers3, 1)
        optimal_fis = addMF(optimal_fis, sprintf('in%d', n), 'gaussmf', [sigma3(n) cluster_centers3(m, n)]);
    end
    for m = 1:size(cluster_centers4, 1)
        optimal_fis = addMF(optimal_fis, sprintf('in%d', n), 'gaussmf', [sigma4(n) cluster_centers4(m, n)]);
    end
    for m = 1:size(cluster_centers5, 1)
        optimal_fis = addMF(optimal_fis, sprintf('in%d', n), 'gaussmf', [sigma5(n) cluster_centers5(m, n)]);
    end
end

outputMembershipFunctionType = 'constant';
params = [1*ones(1, size(cluster_centers1, 1)) ...
          2*ones(1, size(cluster_centers2, 1)) ...
          3*ones(1, size(cluster_centers3, 1)) ...
          4*ones(1, size(cluster_centers4, 1)) ...
          5*ones(1, size(cluster_centers5, 1))];

optimal_fis = addOutput(optimal_fis, [0 1], 'Name', 'out1');

for n = 1:num_rules
    optimal_fis = addMF(optimal_fis, 'out1', outputMembershipFunctionType, params(n));
end

rule_list = zeros(num_rules, bestNumOfFeatures + 1);
for n = 1:num_rules
    rule_list(n, :) = n;  % Each rule uses MF n for each input
end
rule_list = [rule_list ones(num_rules, 2)]; % [inputs outputs weight operator]
optimal_fis = addrule(optimal_fis, rule_list);


% Train ANFIS
anfisOpts = anfisOptions('InitialFIS', optimal_fis, ...
                         'ValidationData', final_val, ...
                         'EpochNumber', 100);

[trained_fis, trainError, stepSize, chkFis, chkError] = anfis(final_trn, anfisOpts);

%Plot of predicted vs actual values
y_pred = evalfis(trained_fis, final_tst(:, 1:end-1));
y_pred = round(max(min(y_pred,5),1));
y_true = final_tst(:, end);

figure;
scatter(y_true, y_pred, 40, 'filled');
hold on;
plot([min(y_true) max(y_true)], [min(y_true) max(y_true)], 'r--', 'LineWidth', 1.5);
xlabel('Actual Values');
ylabel('Predicted Values');
title('Predicted vs Actual Output');
grid on;
axis tight;
saveas(gcf, '.\figures\Part2\predicted_vs_actual_values.png');


%Plot of training and validation error curves
figure;
plot(trainError, 'b', 'LineWidth', 1.5);
hold on;
plot(chkError, 'r', 'LineWidth', 1.5);
xlabel('Epoch');
ylabel('Error (MSE)');
legend('Training Error', 'Validation Error');
title('ANFIS Training Progress');
grid on;

saveas(gcf, '.\figures\Part2\Training_curves.png');
%
%Show fuzzy membership functions for first 4 input variables

%Before then After Training 

for i = 1:4

    figure;
    [x, mf] = plotmf(optimal_fis, 'input', i);
    plot(x, mf, 'LineWidth', 1.5);
    grid on;

    xlabel(sprintf('Input %d', i), 'Interpreter', 'latex');
    ylabel('Degree of Membership', 'Interpreter', 'latex');
    title(sprintf('Membership Functions  Input %d (Before Training)', i), 'Interpreter', 'none');

    % Extract membership function names
    mfNames = string({optimal_fis.Inputs(i).MembershipFunctions.Name});
    legend(mfNames, 'Location', 'northeast', 'Interpreter', 'none');
    saveas(gcf, ['.\figures\Part2\Input' num2str(i) 'Before_MF.png']);

    figure;
    [x, mf] = plotmf(trained_fis, 'input', i);
    plot(x, mf, 'LineWidth', 1.5);
    grid on;

    xlabel(sprintf('Input %d', i), 'Interpreter', 'latex');
    ylabel('Degree of Membership', 'Interpreter', 'latex');
    title(sprintf('Membership Functions - Input %d (After Training)', i), 'Interpreter', 'none');
    legend(mfNames, 'Location', 'northeast', 'Interpreter', 'none');
    saveas(gcf, ['.\figures\Part2\Input' num2str(i) 'After_MF.png']);
end



% Error Matrix 
error_matrix = confusionmat(y_true, y_pred);
figure;
cm = confusionchart(y_true, y_pred);
cm.Title = 'Confusion Matrix of Optimal ANFIS';
cm.RowSummary = 'off';
cm.ColumnSummary = 'off';
saveas(gcf, '.\figures\Part2\ErrorMatrix.png');

%%

% === Compute classification metrics ===
[OA, PA, UA, Kappa] = classificationMetrics(error_matrix);

% Display in a readable table
numClasses = numel(PA);
classLabels = arrayfun(@(x) sprintf('Class %d', x), 1:numClasses, 'UniformOutput', false);

T = table;
T.Model = {'Optimal ANFIS'};
T.OverallAccuracy = OA;
for c = 1:numClasses
    T.(sprintf('ProducerAccuracy_%s', classLabels{c})) = PA(c);
end
for c = 1:numClasses
    T.(sprintf('UserAccuracy_%s', classLabels{c})) = UA(c);
end
T.Kappa = Kappa;

disp(T);


% Metrics calculation  
function [OA, PA, UA, Kappa] = classificationMetrics(confMat)
    N = sum(confMat(:));          
    diagVals = diag(confMat);     
    rowSum = sum(confMat, 2); 
    colSum = sum(confMat, 1); 
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


