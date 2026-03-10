%% Aristotle University of Thessaloniki (AUTh) ECE
%% Danai Zacharioudaki AEM: 9418 Email: zachardd@ece.auth.gr

close all
clear
clc

% Starting point
x_init = 3.8;
x = x_init;
y_init = 0.5;
y = y_init;
u = 0.05;
angle = [0 +45 -45];
theta = angle(3);  %change to examine different scenarios: '1'=0, '2'=+45, '3'=-45

% Desired Position
x_d = 10;
y_d = 3.2;

x_array = [];
y_array = [];

%fuzzy 
sys = readfis('Car_Control_fis_withRules');   % reading the .fis file 


while true
    % stop if out of map
    if x > 10 || x < 0 || y > 4 || y < 0
        break
    end
     %check if over last obstacle
     if (abs(y - 3.2) < 0.1) && (x>7)
        next_x = x + u;
        if (next_x>=10)
           x=10;
           x_array = cat(2, x_array, x);
           y_array = cat(2, y_array, y);
           break;
       else
           x = next_x;
       end
        y = y + 0;
    else
       [dH, dV] = calculate_relative_position(x, y);
       dTheta = evalfis(sys, [dV dH theta]);
       
       %calculate new position
       theta = theta + dTheta;
       theta = wrapTo180(theta); 
       next_x = x + u * cosd(theta);
       if (next_x>=10)
           x=10;
           x_array = cat(2, x_array, x);
           y_array = cat(2, y_array, y);
           break;
       else
           x = next_x;
       end
       y = y + u * sind(theta);
     end
       
    %Printing values for inspection
    fprintf('x = %.2f, y = %.2f | dV = %.2f, dH = %.2f | theta = %.2f\n', ...
        x, y, dV, dH, theta);
    % Store the current position in the arrays
    x_array = cat(2, x_array, x);
    y_array = cat(2, y_array, y);

end

% Error calculation
x_e = x_array(end) - x_d;
y_e = y_array(end) - y_d;
fprintf("Initial Angle for this test run: %d\n", angle(3));  %change to examine different scenarios
fprintf("error on the x-axis: %d\n", x_e);
fprintf("error on the y-axis: %d\n", y_e);
fprintf("------------------------------------------------\n");

% Plot Route 
figure
arr = [5 0; 5 1; 6 1; 6 2; 7 2; 7 3; 10 3];

plot(arr(:, 1), arr(:, 2), 'LineWidth', 1);
polygon = [arr; 10 0];
fill(polygon(:, 1), polygon(:, 2), [.9 .9 .9], 'LineWidth', 1);
hold on
x_array = x_array.';
y_array = y_array.';
plot(x_array, y_array, 'b-.');
hold on 
plot(x_init, y_init, 'b.', 'MarkerSize', 22);
hold on 
plot(x_array(end), y_array(end), 'b*', 'MarkerSize', 7);
hold on
plot(x_d, y_d, 'r.', 'MarkerSize', 22);
xlim([0 11]);
ylim([0 4]);
title(sprintf("Cruise Control (Initial Angle = %d)", angle(3)), 'Interpreter', 'latex'); %change angle to examine different scenarios
legend('Obstacles', 'Controlled Route', 'Start', 'Ending', 'Desired finish');


fprintf("Cruise Control terminated at position (x,y): (%.2f, %.2f)\n'", x, y);