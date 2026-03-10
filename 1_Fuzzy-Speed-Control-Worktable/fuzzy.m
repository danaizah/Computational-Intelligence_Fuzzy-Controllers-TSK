%% Aristotle University of Thessaloniki (AUTh) ECE
%% Danai Zacharioudaki AEM: 9418 Email: zachardd@ece.auth.gr

% Fuzzy Controller

%% Creation of the Fuzzy Inference System

fis = mamfis('Name', 'MamdaniFIS', 'AndMethod', 'min', 'OrMethod', 'max', 'ImplicationMethod', 'prod', 'AggregationMethod', 'max', 'DefuzzificationMethod', 'centroid');

% Create folder for saving figures if it does not exist
if ~exist('figures','dir')
    mkdir figures;
end

% Set inputs
fis = addInput(fis, [-1 1], 'Name', 'E'); % error E 
fis = addInput(fis, [-1 1], 'Name', 'dE'); % change of error dE

% Set outputs
fis = addOutput(fis, [-1 1], 'Name', 'dU'); % change of control input dU

%% Setup of the fuzzy partitions (linguistic terms) for each input and output variable

% The error (E) as input variable
fis = addMF(fis, 'E', 'trimf', [-1 -1 -0.666666], 'Name', 'NL'); % NL
fis = addMF(fis, 'E', 'trimf', [-1 -0.666666 -0.333333], 'Name', 'NM'); % NM
fis = addMF(fis, 'E', 'trimf', [-0.666666 -0.333333 0], 'Name', 'NS'); % NS
fis = addMF(fis, 'E', 'trimf', [-0.333333 0 0.333333], 'Name', 'ZR'); % ZR
fis = addMF(fis, 'E', 'trimf', [0 0.333333 0.666666], 'Name', 'PS'); % PS
fis = addMF(fis, 'E', 'trimf', [0.333333 0.666666 1], 'Name', 'PM'); % PM
fis = addMF(fis, 'E', 'trimf', [0.666666 1 1], 'Name', 'PL'); % PL

% Plot membership functions for Error (E)
fig1 = figure;
plotmf(fis,'input',1);
title('Membership Functions of Input: Error (E)');
xlabel('Error (E)');
ylabel('Membership grade \mu');
grid on;
saveas(fig1, fullfile('figures','mf_error.png'));

% The derivative error (DE) as input variable
fis = addMF(fis, 'dE', 'trimf', [-1 -1 -0.666666], 'Name', 'NL'); % NL
fis = addMF(fis, 'dE', 'trimf', [-1 -0.666666 -0.333333], 'Name', 'NM'); % NM
fis = addMF(fis, 'dE', 'trimf', [-0.666666 -0.333333 0], 'Name', 'NS'); % NS
fis = addMF(fis, 'dE', 'trimf', [-0.333333 0 0.333333], 'Name', 'ZR'); % ZR
fis = addMF(fis, 'dE', 'trimf', [0 0.333333 0.666666], 'Name', 'PS'); % PS
fis = addMF(fis, 'dE', 'trimf', [0.333333 0.666666 1], 'Name', 'PM'); % PM
fis = addMF(fis, 'dE', 'trimf', [0.666666 1 1], 'Name', 'PL'); % PL

% Plot membership functions for Derivative of Error (DE)
fig2 = figure;
plotmf(fis,'input',2);
title('Membership Functions of Input: Derivative of Error (DE)');
xlabel('Derivative of Error (DE)');
ylabel('Membership grade \mu');
grid on;
saveas(fig2, fullfile('figures','mf_derror.png'));

% The derivative control signal (DU) as output variable 
% Set oral variables for dU
fis = addMF(fis, 'dU', 'trimf', [-1 -1 -0.75], 'Name', 'NV'); % NV
fis = addMF(fis, 'dU', 'trimf', [-1 -0.75 -0.5], 'Name', 'NL'); % NL
fis = addMF(fis, 'dU', 'trimf', [-0.75 -0.5 -0.25], 'Name', 'NM'); % NM
fis = addMF(fis, 'dU', 'trimf', [-0.5 -0.25 0], 'Name', 'NS'); % NS
fis = addMF(fis, 'dU', 'trimf', [-0.25 0 0.25], 'Name', 'ZR'); % ZR
fis = addMF(fis, 'dU', 'trimf', [0 0.25 0.5], 'Name', 'PS'); % PS
fis = addMF(fis, 'dU', 'trimf', [0.25 0.5 0.75], 'Name', 'PM'); % PM
fis = addMF(fis, 'dU', 'trimf', [0.5 0.75 1], 'Name', 'PL'); % PL
fis = addMF(fis, 'dU', 'trimf', [0.75 1 1], 'Name', 'PV'); % PV

% Plot membership functions for Output Variable (DU)
fig3 = figure;
plotmf(fis,'output',1);
title('Membership Functions of Output: Derivative Control Signal (DU)');
xlabel('DU');
ylabel('Membership grade \mu');
grid on;
saveas(fig3, fullfile('figures','mf_output_DU.png'));

% Fuzzy rules: 
fuzzyRules = [...
 
 "If E is NL and dE is NL then dU is NV"
    "If E is NL and dE is NM then dU is NV"
    "If E is NL and dE is NS then dU is NV"
    "If E is NL and dE is ZR then dU is NL"
    "If E is NL and dE is PS then dU is NM"
    "If E is NL and dE is PM then dU is NS"
    "If E is NL and dE is PL then dU is ZR"
    "If E is NM and dE is NL then dU is NV"
    "If E is NM and dE is NM then dU is NV"
    "If E is NM and dE is NS then dU is NL"
    "If E is NM and dE is ZR then dU is NM"
    "If E is NM and dE is PS then dU is NS"
    "If E is NM and dE is PM then dU is ZR"
    "If E is NM and dE is PL then dU is PS"
    "If E is NS and dE is NL then dU is NV"
    "If E is NS and dE is NM then dU is NL"
    "If E is NS and dE is NS then dU is NM"
    "If E is NS and dE is ZR then dU is NS"
    "If E is NS and dE is PS then dU is ZR"
    "If E is NS and dE is PM then dU is PS"
    "If E is NS and dE is PL then dU is PM"
    "If E is ZR and dE is NL then dU is NL"
    "If E is ZR and dE is NM then dU is NM"
    "If E is ZR and dE is NS then dU is NS"
    "If E is ZR and dE is ZR then dU is ZR"
    "If E is ZR and dE is PS then dU is PS"
    "If E is ZR and dE is PM then dU is PM"
    "If E is ZR and dE is PL then dU is PL"
    "If E is PS and dE is NL then dU is NM"
    "If E is PS and dE is NM then dU is NS"
    "If E is PS and dE is NS then dU is ZR"
    "If E is PS and dE is ZR then dU is PS"
    "If E is PS and dE is PS then dU is PM"
    "If E is PS and dE is PM then dU is PL"
    "If E is PS and dE is PL then dU is PV"
    "If E is PM and dE is NL then dU is NS"
    "If E is PM and dE is NM then dU is ZR"
    "If E is PM and dE is NS then dU is PS"
    "If E is PM and dE is ZR then dU is PM"
    "If E is PM and dE is PS then dU is PL"
    "If E is PM and dE is PM then dU is PV"
    "If E is PM and dE is PL then dU is PV"
    "If E is PL and dE is NL then dU is ZR"
    "If E is PL and dE is NM then dU is PS"
    "If E is PL and dE is NS then dU is PM"
    "If E is PL and dE is ZR then dU is PL"
    "If E is PL and dE is PS then dU is PV"
    "If E is PL and dE is PM then dU is PV"
    "If E is PL and dE is PL then dU is PV"
];


%% Import the rule table into the fis
fis = addRule(fis,fuzzyRules);

% Write the fis object into a .fis file
writeFIS(fis,'Trapezi_ergasias_24_MyFIS');
Trapezi_ergasias_24_MyFIS = readfis('Trapezi_ergasias_24_MyFIS.fis');
save('Trapezi_ergasias_24_MyFIS','Trapezi_ergasias_24_MyFIS')

%% Graphical presentation of rules with Rule Viewer 
ruleview(fis);

%% Creation of the 3D output graph
fig4 = figure;
gensurf(fis);   
title('Output Surface of the FIS as a Function of the Inputs','Interpreter','latex','FontWeight','bold');

% Axis labels
xlabel('Error (E)','Interpreter','latex','FontWeight','bold');
ylabel('Derivative of Error (DE)','Interpreter','latex','FontWeight','bold');
zlabel('Control Signal (DU)','Interpreter','latex','FontWeight','bold');
grid on;
saveas(fig4, fullfile('figures','fuzzy_surface.png'));

%Rules visualization
% Get rules from FIS
rules = fis.Rules;

% Count fuzzy sets
numE  = length(fis.Inputs(1).MembershipFunctions);   % sets for Error
numDE = length(fis.Inputs(2).MembershipFunctions);   % sets for dError
numDU = length(fis.Outputs(1).MembershipFunctions);  % sets for DU

% Initialize rule matrix
ruleMatrix = nan(numDE, numE);

% Fill rule matrix: rows = DE, columns = E
for i = 1:length(rules)
    inE  = rules(i).Antecedent(1);  % fuzzy set index for Error
    inDE = rules(i).Antecedent(2);  % fuzzy set index for dError
    outDU = rules(i).Consequent(1); % fuzzy set index for DU
    ruleMatrix(inDE, inE) = outDU;
end

% Create heatmap
fig5 = figure;
imagesc(ruleMatrix);
colormap(jet(numDU));
colorbar('Ticks',1:numDU,'TickLabels',{fis.Outputs(1).MembershipFunctions.Name});
set(gca,'XTick',1:numE,'XTickLabel',{fis.Inputs(1).MembershipFunctions.Name});
set(gca,'YTick',1:numDE,'YTickLabel',{fis.Inputs(2).MembershipFunctions.Name});
xlabel('Error (E)');
ylabel('Change of Error (dE)');
title('Fuzzy Rule Base Visualization');
saveas(fig5, fullfile('figures','fuzzy_rules_heatmap.png'));

%% Evaluation

input_values = [0.333333, -0.666666]; % Example inputs [E, dE]

% Evaluate FIS
output = evalfis(fis, input_values);

% Display the output
disp(['Output for E = ' num2str(input_values(1)) ' and dE = ' num2str(input_values(2)) ': dU = ' num2str(output)]);


