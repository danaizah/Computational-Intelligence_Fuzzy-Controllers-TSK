%% Aristotle University of Thessaloniki (AUTh) ECE
%% Danai Zacharioudaki AEM: 9418 Email: zachardd@ece.auth.gr

format compact
clear 
clc

%% Data loading 
data=load('airfoil_self_noise.dat');
inputNames = { ...
    'Frequency (Hz)', ...
    'Angle of attack (deg)', ...
    'Chord length (m)', ...
    'Free-stream velocity (m/s)', ...
    'Suction-side displacement thickness (m)'};

%Data split
preproc=1;

[Dtrn,Dval,Dtst]=split_scale(data,preproc);

TargetDtrn = Dtrn(:, end);
TargetDval = Dval(:, end);
TargetDtst = Dtst(:, end);

%Model Initialization 
models = cell(1,4);
models{1} = genfis1(Dtrn, 2, 'gbellmf', 'constant');

models{2} = genfis1(Dtrn, 3, 'gbellmf', 'constant');

models{3} = genfis1(Dtrn, 2, 'gbellmf', 'linear');

models{4} = genfis1(Dtrn, 3, 'gbellmf', 'linear');

numOfModels = numel(models);
model_names = {'TSK_model_1','TSK_model_2','TSK_model_3','TSK_model_4',};


%Regression Metrics
function val = R2(y_pred, y_true)
    ss_res = sum((y_true - y_pred).^2);
    ss_tot = sum((y_true - mean(y_true)).^2);
    val = 1 - ss_res / ss_tot;
end

function val = RMSE(y_pred, y_true)
    val = sqrt(mean((y_true - y_pred).^2));
end

function val = NMSE(y_pred, y_true)
    ss_res = sum((y_true - y_pred).^2);
    ss_tot = sum((y_true - mean(y_true)).^2);
    val = ss_res / ss_tot;
end

function val = NDEI(y_pred, y_true)
    val = sqrt(NMSE(y_pred, y_true));
end

metrics_n = {'MSE', 'RMSE', 'R2', 'NMSE', 'NDEI'};
metrics = nan(length(metrics_n), numOfModels);


%% Train models

ANFISoptions = anfisOptions;
ANFISoptions.ValidationData = Dval;
ANFISoptions.EpochNumber = 100;

 
trainingTime = zeros(1, numOfModels);

for i = 1:numOfModels
    
    numMFs = numel(models{i}.input(1).mf);     
    inMFType = models{i}.input(1).mf(1).type;  
    outMFType = models{i}.output.mf(1).type;   

    
    initialFIS(i) = genfis1(Dtrn, numMFs, inMFType, outMFType);

    % Train ANFIS with its own options copy
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
        saveas(gcf,['.\figures\Part1n\model_' num2str(i) '\TSK_model_' num2str(i) '_input_' num2str(j) '.png'])
    end

 % Learning curve 
    figure;
    plot([trainError(:, i) validationError(:, i)]);
    grid on;
    xlabel('Num of iterations', 'Interpreter', 'latex'); 
    ylabel('Error', 'Interpreter', 'latex');
    legend('Training Error', 'Validation Error', 'Interpreter', 'latex');
    title('\textbf{Learning Curve}', 'Interpreter','latex');
    saveas(gcf,['.\figures\Part1n\model_' num2str(i)  '\TSK_model_' num2str(i) '_Learning_Curve.png'])
   

    % Prediction Error 
    y(:, i) = evalfis(validationFIS(i), Dtst(:, 1:end-1)); 
    prediction_error(:, i) = y(:, i) - TargetDtst;
    figure;
    plot(prediction_error(:, i));
    grid on;
    xlabel('Input', 'Interpreter', 'latex'); 
    ylabel('Error', 'Interpreter', 'latex');
    title('\textbf{Prediction Error}', 'Interpreter','latex');
    saveas(gcf,['.\figures\Part1n\model_' num2str(i) '\TSK_model_' num2str(i) '_Prediction_Error.png'])

    % Metrics    
    metrics(1, i) = mean((y(:, i) - TargetDtst).^2);
    metrics(2, i) = RMSE(y(:, i), TargetDtst); 
    metrics(3, i) = R2(y(:, i), TargetDtst); 
    metrics(4, i) = NMSE(y(:, i), TargetDtst);  
    metrics(5, i) = NDEI(y(:, i), TargetDtst);

end

% Metrics Result 
disp(array2table(metrics, 'VariableNames', model_names, 'RowNames', metrics_n));













