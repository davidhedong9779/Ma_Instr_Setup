% Purpose: 
% 1. Connect to a Keysight InfiniiVision oscilloscope
% 2. Calculate pre-trigger time (minimum possible arming time)
% 3. Wait for scope to arm the trigger and display the actual arming time
% 4. Wait for scope to trigger and display the time delay
% 5. Wait for acquisition to complete and display the time delay
% 6. Grab the waveform data (optional)

% Start with a clean slate by clearing all variables, figures, etc.  

clear 
clear all
clc
close
close all

% In Connection Expert, assign the scope's model number as its alias
% visa_address = 'TCPIP0::192.168.1.110::hislip0::INSTR';
visa_address = 'msox3104t';

% Set number of waveforms to acquire
numWaveforms = 1;

% Enter the timeout (s) for general I/O
scopeTimeout = 5; 

% Optionally set up the scope to use the Probe Comp signal connected to
% channel 1
resetScope = 0;

% Optionally import the waveform data
getWaveform = 1;

% Close connections to any previously connected instruments  

newobjs = instrfind; 
if ~isempty(newobjs)
    fclose(newobjs);
    delete(newobjs);
end

% 1. Connect to a Keysight InfiniiVision oscilloscope

scope = visa('agilent',visa_address);

fopen(scope); % Connect to the scope 
scope.Timeout = scopeTimeout;
scope.EOSMode = 'read&write';
clrdevice(scope); % Device Clear clears any pending operations

while resetScope
    fprintf(scope,'*rst;*cls;*opc?');
    opc = fscanf(scope,'%d');
    fprintf(scope,':chan1:scal 0.5; offs 1.25');
    fprintf(scope,':tim:scal 2.0e-4');
    fprintf(scope,':trig:sour chan1;lev 1.25');
    fprintf(scope,':stop'); % Stop acquiring to prevent unwanted triggers
    resetScope=0;
end

fprintf(scope,'*idn?'); % Get scope's ID string
idn = scanstr(scope,','); % Read response and parse into an array

fprintf(scope,'*cls;:opee 32;*sre 128;*opc?');
opc = fscanf(scope,'%d');

% 2. Calculate pre-trigger time (minimum possible arming time)
timeOnScreen = strip(query(scope,':tim:rang?'));
timebaseRef = query(scope,':tim:ref?');
timebaseDelay = query(scope,':tim:pos?');
disp(strcat('*** ',string(timeOnScreen),' seconds on screen'));

for i = 1:numWaveforms

% 3. Wait for scope to arm the trigger and display the actual arming time

fprintf(scope,':sing'); 
tic
disp('*** :SINGle sent ***');
disp('Elapsed time is 0.000000 seconds.')

scopeArmed = 0;
while ~scopeArmed
    pause(0.1);
    fprintf(scope,':AER?');
    scopeArmed = fscanf(scope,'%d');
end

disp('*** Scope is armed and waiting for trigger ***')
toc

% 4. Wait for scope to trigger and display the time delay

scopeTriggered = 0;
while ~scopeTriggered
    pause(0.1);
    fprintf(scope,':TER?');
    scopeTriggered = fscanf(scope,'%d');
end

disp('*** Scope has triggered ***')
toc

% 5. Wait for acquisition to complete and display the time delay

acquisitionComplete = 0;
while ~acquisitionComplete  % Wait for the Run bit to go low
    pause(0.1);
    fprintf(scope,':oper:cond?');
    acquisitionComplete = not(bitget(fscanf(scope,'%d'),4));
end

disp('*** Acquisition complete ***')
toc

% 6. Grab the waveform data (optional)

if getWaveform == 1
    fprintf(scope,':wav:sour chan1');
    fprintf(scope,':wav:poin:mode max');
    fprintf(scope,':wav:poin max');
%     fprintf(scope,':wav:poin 1000');
    fprintf(scope,':wav:uns 0');
    fprintf(scope,':wav:form word');
    fprintf(scope,':wav:byt lsbf');
    fprintf(scope,':wav:pre?');
    pre = scanstr(scope,',');
    fprintf(scope,':tim:rang?');
    timeRange = scanstr(scope,',','%f');
    fprintf(scope,':tim:pos?');
    timePosition = scanstr(scope,',','%f');
    fprintf(scope,':chan1:rang?');
    chRange = scanstr(scope,',','%f'); 
    fprintf(scope,':chan1:offs?');
    chOffset = scanstr(scope,',','%f');
    % Scale the plot to match the scope's display
 
    plotStartTime = timePosition - timeRange/2;
    plotEndTime = timePosition + timeRange/2;
    plotLowVoltage = chOffset - chRange/2;
    plotHighVoltage = chOffset + chRange/2;

    if iscell(pre) % The preamble contains alphanumeric values, resulting in a
                   % cell array instead of a matrix
        pre = pre(1:10); % Disregards all preamble except for first 10 values
        pre = cell2mat(pre); % Converts preamble from cell to matrix
    end

    fclose(scope); % Temporarily close scope connection to set buffer size
    scope.inputbuffersize = pre(3)*13; % Sets the buffer size to slightly 
                                       % larger than the incoming waveform data
    fopen(scope); % Reconnect to scope

    tic
    fprintf(scope,':wav:data?'); % Query instrument for waveform data
    display(['    ',':wav:data?'])
    wavin = binblockread(scope,'int16');% Reads the waveform data into an array
    fread(scope,1); % Read the termination character since binblockread does 
                    % not do this
    display([int2str(size(wavin,1)),' points read'])
    toc
    
    % _________________________________________________ 
    check_errors(scope)                      
    % _________________________________________________  

    wavData = ((wavin-pre(10))*pre(8))+pre(9); % Scales the amplitude 

    time = (0:1:(length(wavData)-1))'; % Creates time axis
    time = ((time-pre(7))*pre(5))+pre(6); % Scales times

    plot(time,wavData,'-b') %Plot waveform points
    axis([plotStartTime plotEndTime plotLowVoltage plotHighVoltage]);

    % Set plot title and axis labels

    title([idn(1),idn(2),'chan1 data',strcat(int2str(pre(3)),' points')]);
    xlabel('Time (s)') % Set axis labels
    ylabel('Voltage (V)')
end
end

% Delete objects and clear them

delete(scope);
clear scope;
clear fid  screenImage outFile


%% Functions

function check_errors(instrument)
    i = 1;
    err_queue{i} = query(instrument, ':SYSTem:ERRor?');
    while ~(strncmp(err_queue{i}, '+0,"No error"', 12))
        i = i + 1;
        err_queue{i} = query(instrument, ':SYSTem:ERRor?');
    end
    fprintf(['\nError Queue:\n' err_queue{:} '\n'])
end
