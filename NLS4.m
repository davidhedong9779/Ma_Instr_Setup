clear,clc,close all

max_v = 1000000;       %maximum velocity in unit steps/sec
A = 6299212;           %accelaration in unit steps/sec
D = 6299212;           %decelaration in unit steps/sec
step_size = 31496;     %31496 steps/mm (fixed)
neg_step_size = -31496;
distance = 1;          %in mm, the distance per every move
total_distance = 250;  %total travel distance from origin
times = total_distance / distance;
                       %how many times to move to reach the end
total_step = distance * step_size;
                       %total amount of steps to move per time
oldserial = instrfind('Port','COM3');
if(~isempty(oldserial))
    fclose(oldserial);
    delete(oldserial);
end    
s1 = serial('COM3','Terminator','CR');
fopen(s1);
%% initialize the movement and motor
fprintf(s1,'%s\n','EM=0'); % Set echo mode so prompt is not sent
pause(0.1);
fprintf(s1,'%s\n','MS=250'); %step resolution
pause(0.1)
fprintf(s1,'%s\n','P=0'); % Set current position to zero
pause(0.1);
fprintf(s1,'%s\n','MA 10000,0,1'); %move to the right end
pause(0.1)
fprintf(s1,'%s\n','P=0'); % Set current position to zero
pause(0.1);
fprintf(s1,'A=%d\n',A); %set accelaration
pause(0.1)
fprintf(s1,'D=%d\n',D); %set decelaration
pause(0.1);
fprintf(s1,'VM=%d\n',max_v); % Set max velocity
pause(0.1);
%% move to left
for i = 1:times
    fprintf(s1,'MR -%d\n',neg_step_size); % Move the stage
    
    
    pause(3);
end
%% move back to right
for i = 1:times
    fprintf(s1,'MR %d\n',step_size); % Move the stage
    
    
    pause(3);
end
%% move back to the right to reset
fprintf(s1,'%s\n','MA 10000,0,1');
%% close and clear
fclose(s1);
delete(s1);
clear,clc,close all