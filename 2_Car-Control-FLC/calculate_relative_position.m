%% Aristotle University of Thessaloniki (AUTh) ECE
%% Danai Zacharioudaki AEM: 9418 Email: zachardd@ece.auth.gr


function [dH, dV] = calculate_relative_position(x, y)
 
 dH = 0;
 dV = 0;

%Analyze all possible scenarios depending on the vehicle's position 
%and the boundaries position

if (x<5) && (y<=1)
    dH = 5-x;
    dV = y;
elseif (x<5) && (y>1) && (y<=2)
    dH = 6-x;
    dV = y;
elseif (x>=5) && (x<6) && (y>1) && (y<=2)
    dH = 6-x;
    dV = y-1;
elseif (x<5) && (y>2) && (y<=3)
    dH = 7-x;
    dV = y;
elseif (x>=5) && (x<6) && (y>2) && (y<=3)
    dH = 7-x;
    dV = y-1;
elseif (x>=6) && (x<7) && (y>2) && (y<=3)
    dH = 7-x;
    dV = y-2;
elseif (x<5) && (y>3) && (y<=4) 
    dH = 50;
    dV = y;
elseif (x>=5) && (x<6) && (y>3) && (y<=4)
    dH = 50;
    dV = y-1; 
elseif (x>=6) && (x<7) && (y>3) && (y<=4)
    dH = 50;
    dV = y-2;
elseif (x>=7) && (x<=10) && (y>3) && (y<=4)
    dH = 50;
    dV = y-3;
end

%dV,dH E [0,1]
if (dV>1)
    dV=1;
end
if (dH>1)
    dH=1;

return;
  
end