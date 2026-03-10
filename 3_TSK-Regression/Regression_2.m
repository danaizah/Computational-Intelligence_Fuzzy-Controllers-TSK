% Aristotle University of Thessaloniki (AUTh) ECE
% Danai Zacharioudaki AEM: 9418 Email: zachardd@ece.auth.gr

format compact
clear 
clc

% Data loading from .csv file
dataset = load('superconduct.csv');

%Data split
preproc=1;
[Dtrn,Dval,Dtst]=split_scale(dataset,preproc);

dataset_target = dataset(:, end);
TargetDtrn = Dtrn(:, end);
TargetDval = Dval(:, end);
TargetDtst = Dtst(:, end);

%----Grid Search----

num_features = [5 8 10 12 15];

cluster_radius = [0.2 0.4 0.5 0.6 0.8];

%Local variables

num_folds = 5;
cluster_method = 'SubtractiveClustering';
grid_MSE = zeros(length(num_features), length(cluster_radius));
grid_num_rules = zeros(length(num_features), length(cluster_radius));


%Feature selection: Relief algorithm
num_nearest_neighbors = 10;
[ranking_indexes, importanceWeights] = relieff(dataset(:, 1:end-1), dataset_target, num_nearest_neighbors, 'method', 'regression');

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

        CV = cvpartition(size(temp_trn, 1), 'KFold', num_folds);
        CV_MSE = zeros(1, num_folds);
        
        for k = 1:num_folds
            CV_Dtrn = temp_trn(training(CV, k), :);
            CV_TargetDtrn = CV_Dtrn(:, end);
            CV_val = temp_trn(test(CV, k), :);
            % Subtractive clustering for IF-THEN rules creation
            fisOptions = genfisOptions('SubtractiveClustering', 'ClusterInfluenceRange', j);
            initial_fis = genfis(CV_Dtrn(:, 1:end-1), CV_TargetDtrn, fisOptions);
            % Check if valid rules
            if (size(initial_fis.Rules, 2) < 2)
                fprintf("Number of rules less than 2...\n");

                continue;
            end

            % FIS Options
            ANFISoptions = anfisOptions;
            ANFISoptions.InitialFIS = initial_fis;
            ANFISoptions.ValidationData = CV_val;  
            ANFISoptions.EpochNumber = 100;
            % Train of model
            [~, ~, ~, fis, ~] = anfis(CV_Dtrn, ANFISoptions);



            % Calculate the trained model's output
            y = evalfis(fis, temp_tst(:, 1:end-1));

            % Save the Mean Squared Error
            CV_MSE(:, k) = mse(y, TargetDtst);
            local_MSE(jIdx) = mean(CV_MSE);
            local_rules(jIdx) = size(fis.Rules, 2);
        end

        % save an MSE for every pair of feature number & cluster radius
        grid_MSE(iIdx, :) = local_MSE;
        grid_num_rules(iIdx, :) = local_rules;
      
    end
end

save('regression_grid_search');

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


% === Visualization ===

load('regression_grid_search');

%MSE - Number of rules
figure;
scatter(grid_num_rules(:), grid_MSE(:), 80, repelem(num_features, numel(cluster_radius))', 'filled');
xlabel('Number of Fuzzy Rules');
ylabel('Mean Squared Error');
title('MSE vs Number of Rules');
colorbar;
colormap turbo;
grid on;
saveas(gcf,['.\figures\Part2' 'MSE_Rules_plot.png'])

%MSE - Number of features & Cluster radius
figure;
[X, Y] = meshgrid(num_features, cluster_radius); 
scatter3(X(:), Y(:), grid_MSE(:), 80, grid_MSE(:), 'filled');
xlabel('Number of Features');
ylabel('Cluster Radius');
zlabel('Mean Squared Error');
title('3D Scatter: MSE vs Number of Features and Cluster Radius');
colorbar;
colormap turbo;
grid on;
view(45, 30); % adjust viewing angle
saveas(gcf,['.\figures\Part2' 'MSE_Scatter.png'])

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

% Build initial FIS using subtractive clustering
fisOptions = genfisOptions('SubtractiveClustering', 'ClusterInfluenceRange', bestClusterRadius);
initial_fis = genfis(final_trn(:,1:end-1), final_trn(:,end), fisOptions);

% Train ANFIS
anfisOpts = anfisOptions('InitialFIS', initial_fis, 'ValidationData', final_val, 'EpochNumber', 100);
[trained_fis, trainError, stepSize, chkFis, chkError] = anfis(final_trn, anfisOpts);

%Plot of predicted vs actual values
y_pred = evalfis(chkFis, final_tst(:,1:end-1));
y_true = final_tst(:,end);

figure;
plot(y_true, y_pred, 'o');
hold on;
plot([min(y_true) max(y_true)], [min(y_true) max(y_true)], 'r--');
xlabel('Actual Values');
ylabel('Predicted Values');
title('Predicted vs Actual Output');
grid on;
saveas(gcf, '.\figures\Part2\predicted_vs_actual_values.png');

%Plot of Prediction Error
prediction_error = y_pred - y_true;

figure;
plot(prediction_error, 'LineWidth', 1.2);
grid on;
xlabel('Sample Index', 'Interpreter', 'latex');
ylabel('Prediction Error', 'Interpreter', 'latex');
title('{Prediction Error}', 'Interpreter', 'latex');

yline(0, 'r--', 'LineWidth', 1.0);

saveas(gcf, '.\figures\Part2\prediction_error_plot.png');

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
%%
%Show fuzzy membership functions for first 4 input variables

%Before then After Training 

for i = 1:4

    figure;
    [x, mf] = plotmf(initial_fis, 'input', i);
    plot(x, mf, 'LineWidth', 1.5);
    grid on;

    xlabel(sprintf('Input %d', i), 'Interpreter', 'latex');
    ylabel('Degree of Membership', 'Interpreter', 'latex');
    title(sprintf('Membership Functions  Input %d (Before Training)', i), 'Interpreter', 'none');

    % Extract membership function names
    mfNames = string({initial_fis.Inputs(i).MembershipFunctions.Name});
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

%%
%Metrics calculation

RMSE = sqrt(mean((y_true - y_pred).^2));
NMSE = mean((y_true - y_pred).^2) / var(y_true);
NDEI = RMSE / std(y_true);
R2 = 1 - sum((y_true - y_pred).^2) / sum((y_true - mean(y_true)).^2);

resultsTable = table(RMSE, NMSE, NDEI, R2)


