%% Aristotle University of Thessaloniki (AUTh) ECE
%% Danai Zacharioudaki AEM: 9418 Email: zachardd@ece.auth.gr

%fis = readfis('Car_Control_fis.fis');


fuzzyRules = [
"If dV is S and dH is S and theta is N then dTheta is P"
"If dV is S and dH is S and theta is ZE then dTheta is P"
"If dV is S and dH is S and theta is P then dTheta is P"
"If dV is S and dH is M and theta is N then dTheta is P"
"If dV is S and dH is M and theta is ZE then dTheta is P"
"If dV is S and dH is M and theta is P then dTheta is P"
"If dV is S and dH is L and theta is N then dTheta is P"
"If dV is S and dH is L and theta is ZE then dTheta is P"
"If dV is S and dH is L and theta is P then dTheta is P"
"If dV is M and dH is S and theta is N then dTheta is P"
"If dV is M and dH is S and theta is ZE then dTheta is P"
"If dV is M and dH is S and theta is P then dTheta is P"
"If dV is M and dH is M and theta is N then dTheta is P"
"If dV is M and dH is M and theta is ZE then dTheta is ZE"
"If dV is M and dH is M and theta is P then dTheta is ZE"
"If dV is M and dH is L and theta is N then dTheta is P"
"If dV is M and dH is L and theta is ZE then dTheta is ZE"
"If dV is M and dH is L and theta is P then dTheta is N"
"If dV is L and dH is S and theta is N then dTheta is P"
"If dV is L and dH is S and theta is ZE then dTheta is P"
"If dV is L and dH is S and theta is P then dTheta is P"
"If dV is L and dH is M and theta is N then dTheta is P"
"If dV is L and dH is M and theta is ZE then dTheta is N"
"If dV is L and dH is M and theta is P then dTheta is ZE"
"If dV is L and dH is L and theta is N then dTheta is P"
"If dV is L and dH is L and theta is ZE then dTheta is N"
"If dV is L and dH is L and theta is P then dTheta is N"
];


%fis = addRule(fis, fuzzyRules);

%writefis(fis,'Car_Control_fis_withRules');  
fis_rules_final = readfis('Car_Control_fis_withRules');
rules = showrule(fis_rules_final);
disp(rules);


