%% Aristotle University of Thessaloniki (AUTh) ECE
%% Danai Zacharioudaki AEM: 9418 Email: zachardd@ece.auth.gr


% Create folder for saving figures if it does not exist
figDir = fullfile(pwd,'figures');
if ~exist(figDir, 'dir')
    mkdir(figDir);
end


% Open Loop transfer function for the system
s = tf('s');
Ka = 1; 
c = 0.125;
openLoopSystem = 25*(s+c)/(s*(s+0.1)*(s+10));


% Root Locus (initial)
figure;
rlocus(openLoopSystem);
title('Open-Loop Root Locus (initial)');
xlabel('Real Axis'); ylabel('Imaginary Axis'); grid on;
saveas(gcf, fullfile('figures','rootlocus_initial.png'));

% Closed Loop Transfer Function (feedback = -1)
closedLoopSystem = feedback(openLoopSystem, 1, -1);
beforeSystem = closedLoopSystem;
figure;
step(closedLoopSystem);
title('Closed-Loop Step Response (before tuning)');
xlabel('Time (sec)'); ylabel('Amplitude'); grid on;
saveas(gcf, fullfile('figures','step_before_tuning.png'));

% Transfer Functions for System and Controller
Gp = 25/((s+0.1)*(s+10));
Gc = Ka*(s+c)/s;

%% Tune the system (only once, then comment out)
%controlSystemDesigner(Gp,Gc) ;

%% Load the controller model after tuning
LinearPI = load('ControlSystemDesignerSession.mat') ; 

% Extract the tuned value of proportional gain Kp and zero c from the session data
Kp = LinearPI.ControlSystemDesignerSession.DesignerData.Architecture.TunedBlocks(2).ZPKGain ; 
c = LinearPI.ControlSystemDesignerSession.DesignerData.Architecture.TunedBlocks(2).PZGroup(1).Zero;

% Update the Controller transfer function based on tuned values
Gc = Kp*(s-c)/s;

openLoopSystem = Gp*Gc;
closedLoopSystem = feedback(openLoopSystem,1,-1);
afterSystem = closedLoopSystem;


% Step response metrics
S = stepinfo(closedLoopSystem);
fprintf('Step Response Results\n');
fprintf('Rise time (sec): %f\n', S.RiseTime);
fprintf('Overshoot (%%): %f\n', S.Overshoot);

if S.Overshoot < 8 && S.RiseTime < 0.6
    disp("Requirements are met.");
else
    disp("Requirements are not met");
end


% Ki and Kp calculation
Ki = (-c)*Kp ; 
fprintf("\nKp = %g \t Ki = %g\n", Kp, Ki);

%% Root locus plot after tuning
figure;
rlocus(openLoopSystem);
title('Open-Loop Root Locus (after tuning)');
xlabel('Real Axis'); ylabel('Imaginary Axis'); grid on;
saveas(gcf, fullfile('figures','rootlocus_after_tuning.png'));

% Step response after tuning
figure;
stepplot(closedLoopSystem);
grid on;
title('Closed-Loop Step Response (after tuning)');
xlabel('Time (sec)'); ylabel('Amplitude'); grid on;
saveas(gcf, fullfile('figures','step_after_tuning.png'));

% Suppose you have beforeSystem and afterSystem already defined
% (closed-loop transfer functions before and after tuning)

figure;
hold on;

% Plot both step responses
[y1,t1] = step(beforeSystem, 2);   % simulate up to 2 sec
[y2,t2] = step(afterSystem, 2);

plot(t1, y1, 'b', 'LineWidth', 1.5);
plot(t2, y2, 'r--', 'LineWidth', 1.5);

grid on;
legend('Before tuning','After tuning','Location','Southeast');
title('Closed-Loop Step Response: Before vs After Tuning');
xlabel('Time (sec)');
ylabel('Amplitude');

% Same axes for both
xlim([0 2]);
ylim([0 1.2]);

% Get step info
info_before = stepinfo(beforeSystem);
info_after  = stepinfo(afterSystem);

% Annotate rise time and overshoot
text(1.2,0.3, sprintf('Before: Rise=%.2fs, OS=%.2f%%', ...
    info_before.RiseTime, info_before.Overshoot), 'Color','b');

text(1.2,0.2, sprintf('After:  Rise=%.2fs, OS=%.2f%%', ...
    info_after.RiseTime, info_after.Overshoot), 'Color','r');


feedback(openLoopSystem, 1, -1)



