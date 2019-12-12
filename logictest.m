%% For Func Gen and Osc Combine Testing Only
clear all;
close all;
%% ALL: Major Settings
%General
dir = 'C:\Users\ASFM\Desktop\Test_Data';
datafolder='data';
%filenameroot='direction_grating_0210_double_angle100'%facing the second door;
filenameroot='direction_grating_0406_empty_angle75-3';%facing the second door;

%previous 56/150
%Major Oscilloscope Setings
Osc_Ch1_range='8'; %Vpp - Channel 1 range
Osc_Ch2_range='8'; %Vpp - Channel 2 range
Osc_trigger_level='2'; %Vpp - Trigger Level
Osc_T=1.0E-2; %s - total time
Osc_pretriggerT=-.3E-2; %s - pre trigger time
Osc_N_min=10E3; %mininum number of sampling points
Ch1_invert='off'; %'on'=inverted, 'off'=normal
Ch2_invert='on'; %'on'=inverted, 'off'=normal
Osc_Ch1_scale = '500mV';
Osc_Ch2_scale = '500mV';

%Major Function Generator Settings
sig_voltage=2.0; %Vpp
T_signal=0.8E-2; %s
N_signal=10000; %points
fc=4500; %Hz %%Input signal frequency
%bw=.3; % for gaussian puls

%Scanning Grid

%motion controler
max_v = 1000000;       %maximum velocity in unit steps/sec
A = 6299212;           %accelaration in unit steps/sec
D = 6299212;           %decelaration in unit steps/sec
step_size = 31496;     %31496 steps/mm (fixed)
neg_step_size = -31496;
distance = 5;          %in mm, the distance per every move
total_distance = 25;  %total travel distance from origin
times = total_distance / distance;
                       %how many times to move to reach the end
total_step = distance * step_size;
                       %total amount of steps to move per time


%% OSC: Connect

% Find a VISA-USB object.
visaObj = instrfind('Type', 'visa-usb', 'RsrcName', 'USB0::0x2A8D::0x1766::MY58493344::0::INSTR', 'Tag', '');

% Create the VISA-USB object if it does not exist
% otherwise use the object that was found.
if isempty(visaObj)
    visaObj = visa('KEYSIGHT', 'USB0::0x2A8D::0x1766::MY58493344::0::INSTR');
else
    fclose(visaObj);
    visaObj = visaObj(1);
end

%% FUNCG: Connect
%  Having TekVisa installed.
%  For finding the visa address, check matlab-APPS-InstrumentControlBox-VISA-USB
%  To know how to connect the afg, always check 'Session Log'
%  Inside the InstrumentControlBox-VISA-USB
VisaObjFunCG = instrfind('Type', 'visa-usb', 'RsrcName', 'USB0::0x0699::0x034A::C020435::0::INSTR', 'Tag', '');

if isempty(VisaObjFunCG)
    VisaObjFunCG = visa('KEYSIGHT', 'USB0::0x0699::0x034A::C020435::0::INSTR');
else
    fclose(VisaObjFunCG);
    VisaObjFunCG = VisaObjFunCG(1);
end
% Set buffersize before generate the waveform whlie afg connected but not open
% Cannot set buffersize when afg is open
VisaObjFunCG.OutputBufferSize = 5120000;
% Open function generator
fopen(VisaObjFunCG);


%% MOTION: Connect and Init
oldserial = instrfind('Port','COM3');
if(~isempty(oldserial))
   fclose(oldserial);
   delete(oldserial);
end   
s1 = serial('COM3','Terminator','CR');
fopen(s1);

% initialize the movement and motor
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

%% OSC: Setup open and close visa object to turn on precision mode

% Set properity
visaObj.InputBufferSize = 100000;
visaObj.Timeout = 10;
visaObj.ByteOrder = 'littleEndian';

% Connect to instrument object, obj1.
fopen(visaObj);

%% OSC: Sending Signal to Osc

% Turn on precision mode
%fprintf(visaObj,'');
fprintf(visaObj,'*CLS');
%fprintf(visaObj,':SYSTem:PRECision 1');
%fprintf(visaObj,':SYSTem:LOCK on');
fprintf(visaObj,':TRIGger:SWEep NORMal');

%Horizontal Control
fprintf(visaObj,':TIMebase:RANGe 10E-3'); %in 100ms
fprintf(visaObj,':TIMebase:DELay 0E-3'); %in sec
fprintf(visaObj,':TIMebase:REFerence CENTer');
fprintf(visaObj,':TIMEBASE:MODE MAIN');
% Channel 1
fprintf(visaObj,':CHANnel1:DISPlay 1');
fprintf(visaObj,':CHANnel1:COUPling DC');
fprintf(visaObj,':CHANnel1:IMPedance ONEMeg');
fprintf(visaObj,':CHANnel1:OFFSet 0 V');
fprintf(visaObj,':CHANnel1:PROBe X1');
fprintf(visaObj,':CHANnel1:RANGe 8');
fprintf(visaObj,':CHANnel1:INVert off');
fprintf(visaObj,':CHANnel1:SCALe 500mV');
%fprintf(visaObj,strcat(':CHANnel1:RANGe ', Osc_Ch1_range));
%fprintf(visaObj,strcat(':CHANnel1:INVert ', Ch1_invert));
%fprintf(visaObj,strcat(':CHANnel1:SCALe ', Osc_Ch1_scale));


% Channel 2
fprintf(visaObj,':CHANnel2:DISPlay 0');
fprintf(visaObj,':CHANnel2:COUPling DC');
fprintf(visaObj,':CHANnel2:IMPedance ONEMeg');
fprintf(visaObj,':CHANnel2:OFFSet 0 V');
fprintf(visaObj,':CHANnel2:PROBe X1');
fprintf(visaObj,':CHANnel2:RANGe 8');
fprintf(visaObj,':CHANnel2:INVert off');
fprintf(visaObj,':CHANnel2:SCALe 500mV');
%fprintf(visaObj,strcat(':CHANnel2:RANGe ', Osc_Ch1_range));
%fprintf(visaObj,strcat(':CHANnel2:INVert ', Ch1_invert));
%fprintf(visaObj,strcat(':CHANnel2:SCALe ', Osc_Ch2_scale));

%Trigger
fprintf(visaObj,':TRIGger:MODE EDGE');
fprintf(visaObj,':TRIGger:EDGE:SOURce CHANNEL1');
fprintf(visaObj,':TRIGger:EDGE:COUPling DC');
%fprintf(visaObj,':TRIGger[:EDGE]:LEVel 2');
fprintf(visaObj,strcat(':TRIGger[:EDGE]:LEVel ', Osc_trigger_level));

%set acquisition properties
fprintf(visaObj,':ACQuire:TYPE NORMal');
%fprintf(visaObj,':TRIGger:MODE EDGE');
%fprintf(visaObj,':TRIGger:MODE EDGE');
%fprintf(visaObj,':TRIGger:MODE EDGE');
%set(hAcqObj,'AcquisitionType','Agilent546XXAcquisitionTypeNormal');
%set(hAcqObj,'TimePerRecord',Osc_T);
%set(hAcqObj,'StartTime',-1*Osc_pretriggerT);
%set(hAcqObj,'NumberOfPointsMin',Osc_N_min);
%fprintf(visaObj,':DIGITIZE CHAN1');

fprintf(visaObj,':SINGle');


%% FUNCG: Reset the function generator
 fprintf(VisaObjFunCG, '*RST');
 fprintf(VisaObjFunCG, '*CLS'); 
 
%% FUNCG: Define siganl
% T_signal=0.8E-2; %s 
% fc=4500; %Hz %%Input signal frequency
% N_signal =10000; % set the sample rate

dt_signal=T_signal/N_signal; %s
Fs_signal=1/dt_signal; %Hz
f_signalgenerator=1/T_signal; %Hz

t1=(0:dt_signal:T_signal-dt_signal);
t2=(0:dt_signal:1/fc*8);
ccc=size(t2,2);
ddd=size(t1,2);
% DEFINE SIGNAL
Data = zeros(size(t1,2),1);
Data1=1/2*sin(2*pi*fc*t2);
Data(ddd-ccc+1:ddd)=Data1(1:ccc);
waveform = Data;
%waveform = Data;
% Plot the custom waveform to be generated
plot(waveform); 
%title('Custom waveform created in MATLAB');
%grid on;

% Normalize waveform
%waveform = waveform ./ (max(waveform)); 


%% FUNCG: Convert waveform 
%  AFG3022C is a 14 bits device
%  Convert the double values integer values between 0 and 16382
%  As required by the instrument
waveform =  round((waveform + 1.0)*8191);
waveformLength = length(waveform);
%  Encode variable 'waveform' into binary waveform data for AFG.
%  programmer manual for bit definitions.
binblock = zeros(2 * waveformLength, 1);
binblock(2:2:end) = bitand(waveform, 255);
binblock(1:2:end) = bitshift(waveform, -8);
binblock = binblock';
% Build binary block header
bytes = num2str(length(binblock));
header = ['#' num2str(length(bytes)) bytes];


%% FUNCG: Major settings for Function generator (tek afg3022C)
% Resets the contents of edit memory and define the length of signal
% Transfer the custom waveform from MATLAB to edit memory of instrument
% Set the source to EXTernal otherwise the generator will keep triggering
% Force a trigger event immediately
% For specific settings, please check the AFG3000 series programmer manual
fprintf(VisaObjFunCG, ['DATA:DEF EMEM, ' num2str(length(t1)) ';']); %1001
fwrite(VisaObjFunCG, [':TRACE EMEM, ' header binblock ';'], 'uint8');
fprintf(VisaObjFunCG, 'SOURCE1:BURst:STATe ON');
fprintf(VisaObjFunCG, 'SOURCE1:BURst:MODE TRIGgered');
fprintf(VisaObjFunCG, 'TRIGger:SEQuence:SOURce EXTernal');
fprintf(VisaObjFunCG, 'SOURCE1:BURSt:NCYCles 1.0');
fprintf(VisaObjFunCG, 'SOURCE1:FUNCTION EMEM');
fprintf(VisaObjFunCG, 'SOURCE1:FREQUENCY 125'); 
fprintf(VisaObjFunCG, 'SOURCE1:VOLTAGE:AMPLITUDE 2');
fprintf(VisaObjFunCG, 'SOURCE1:VOLTAGE:OFFSET 0.00');
fprintf(VisaObjFunCG, ':OUTP1 ON');

%% move to left
for i = 1:times
    
    fprintf(visaObj,':SINGle');
    pause(0.5)
    fprintf(VisaObjFunCG, 'TRIGger:SEQuence:IMMediate');
    pause(1);
    % OSC: Save
    fprintf(visaObj,':WAVeform:POINts:MODE RAW');
    fprintf(visaObj,':WAVeform:SOURce CHANnel1');
    %fprintf(visaObj,':WAVeform:FORMat BYTE'); %page1620
    fprintf(visaObj,':WAV:POINTS 5000');
    %fprintf(visaObj,':WAVeform:DATA?');
    %fprintf(visaObj,':WAVeform:DATA?');% Now tell the instrument to digitize channel1

    %fprintf(visaObj,':DIGITIZE CHAN1');
    % Wait till complete
    %operationComplete = str2double(query(visaObj,'*OPC?'));
    %while ~operationComplete
    %    operationComplete = str2double(query(visaObj,'*OPC?'));
    %end
    % Get the data back as a WORD (i.e., INT16), other options are ASCII and BYTE
    fprintf(visaObj,':WAVEFORM:FORMAT WORD');
    % Set the byte order on the instrument as well
    fprintf(visaObj,':WAVEFORM:BYTEORDER LSBFirst');
    % Get the preamble block
    preambleBlock = query(visaObj,':WAVEFORM:PREAMBLE?');
    % Now send commmand to read data
    fprintf(visaObj,':WAV:DATA?');
    % read back the BINBLOCK with the data in specified format and store it in
    % the waveform structure. FREAD removes the extra terminator in the buffer
    RawData = binblockread(visaObj,'uint16'); 
    fread(visaObj,1);
    % Read back the error queue on the instrument
    instrumentError = query(visaObj,':SYSTEM:ERR?');
    while ~isequal(instrumentError,['+0,"No error"' newline])
        disp(['Instrument Error1: ' instrumentError]);
        instrumentError = query(visaObj,':SYSTEM:ERR?');
    end
    % Close the VISA connection.
    %fclose(visaObj);


    % OSC: Save: Data processing: Post process the data retreived from the scope
    % Extract the X, Y data and plot it 

    % Maximum value storable in a INT16
    maxVal = 2^16; 

    %  split the preambleBlock into individual pieces of info
    preambleBlock = regexp(preambleBlock,',','split');

    % store all this information into a waveform structure for later use
    Format = str2double(preambleBlock{1});     % This should be 1, since we're specifying INT16 output
    Type = str2double(preambleBlock{2});
    Points = str2double(preambleBlock{3});
    Count = str2double(preambleBlock{4});      % This is always 1
    XIncrement = str2double(preambleBlock{5}); % in seconds
    XOrigin = str2double(preambleBlock{6});    % in seconds
    XReference = str2double(preambleBlock{7});
    YIncrement = str2double(preambleBlock{8}); % V
    YOrigin = str2double(preambleBlock{9});
    YReference = str2double(preambleBlock{10});
    VoltsPerDiv = (maxVal * YIncrement / 8);      % V
    Offset = ((maxVal/2 - YReference) * YIncrement + YOrigin);         % V
    SecPerDiv = Points * XIncrement/10 ; % seconds
    Delay = ((Points/2 - XReference) * XIncrement + XOrigin); % seconds

    % Generate X & Y Data
    XData = (XIncrement.*(1:length(RawData))) - XIncrement;
    YData = (YIncrement.*(RawData - YReference)) + YOrigin; 

    % Plot it
    plot(XData,YData);
    set(gca,'XTick',(min(XData):SecPerDiv:max(XData)))
    xlabel('Time (s)');
    ylabel('Volts (V)');
    title('Oscilloscope Data');
    grid on;

    filename = strcat(num2str(i*10),'.mat');
    save(filename,'XData','YData')
    
    
    fprintf(s1,'MR %d\n',neg_step_size); % Move the stage
    pause(2);
end


% %% move to right
% for i = 1:times
%     
%     fprintf(visaObj,':SINGle');
%     fprintf(VisaObjFunCG, 'TRIGger:SEQuence:IMMediate');
%     pause(3);
%     
% %     % OSC: Save
% %     fprintf(visaObj,':WAVeform:POINts:MODE RAW');
% %     fprintf(visaObj,':WAVeform:SOURce CHANnel1');
% %     fprintf(visaObj,':WAV:POINTS 5000');
% %     % Get the data back as a WORD (i.e., INT16), other options are ASCII and BYTE
% %     fprintf(visaObj,':WAVEFORM:FORMAT WORD');
% %     % Set the byte order on the instrument as well
% %     fprintf(visaObj,':WAVEFORM:BYTEORDER LSBFirst');
% %     % Get the preamble block
% %     preambleBlock = query(visaObj,':WAVEFORM:PREAMBLE?');
% %     
% %     fprintf(visaObj,':WAV:DATA?');
% %     % read back the BINBLOCK with the data in specified format and store it in
% %     % the waveform structure. FREAD removes the extra terminator in the buffer
% %     RawData = binblockread(visaObj,'uint16'); 
% %     fread(visaObj,1);
% %     % Read back the error queue on the instrument
% %     instrumentError = query(visaObj,':SYSTEM:ERR?');
% %     while ~isequal(instrumentError,['+0,"No error"' char(10)])
% %         disp(['Instrument Error: ' instrumentError]);
% %         instrumentError = query(visaObj,':SYSTEM:ERR?');
% %     end
% %     
% %     % Close the VISA connection.
% %     %fclose(visaObj);
% %     
% %     % OSC: Save: Data processing: Post process the data retreived from the scope
% %     % Extract the X, Y data and plot it 
% %     % Maximum value storable in a INT16
% %     maxVal = 2^16; 
% %     %  split the preambleBlock into individual pieces of info
% %     preambleBlock = regexp(preambleBlock,',','split');
% %     % store all this information into a waveform structure for later use
% %     Format = str2double(preambleBlock{1});     % This should be 1, since we're specifying INT16 output
% %     Type = str2double(preambleBlock{2});
% %     Points = str2double(preambleBlock{3});
% %     Count = str2double(preambleBlock{4});      % This is always 1
% %     XIncrement = str2double(preambleBlock{5}); % in seconds
% %     XOrigin = str2double(preambleBlock{6});    % in seconds
% %     XReference = str2double(preambleBlock{7});
% %     YIncrement = str2double(preambleBlock{8}); % V
% %     YOrigin = str2double(preambleBlock{9});
% %     YReference = str2double(preambleBlock{10});
% %     VoltsPerDiv = (maxVal * YIncrement / 8);      % V
% %     Offset = ((maxVal/2 - YReference) * YIncrement + YOrigin);         % V
% %     SecPerDiv = Points * XIncrement/10 ; % seconds
% %     Delay = ((Points/2 - XReference) * XIncrement + XOrigin); % seconds
% %     % Generate X & Y Data
% %     XData = (XIncrement.*(1:length(RawData))) - XIncrement;
% %     YData = (YIncrement.*(RawData - YReference)) + YOrigin; 
% %     % Plot it
% %     plot(XData,YData);
% %     set(gca,'XTick',(min(XData):SecPerDiv:max(XData)))
% %     xlabel('Time (s)');
% %     ylabel('Volts (V)');
% %     title('Oscilloscope Data');
% %     grid on;
% %     
% %     filename = strcat(num2str(i+times),'.mat');
% %     save(filename,'XData','YData')
%     
%     
%     fprintf(s1,'MR %d\n',step_size); % Move the stage
%  end
%% OSC: Disconnect and Clean Up

fprintf(visaObj,':SYSTem:LOCK off');

% Disconnect from instrument object, obj1.
fclose(visaObj);

% The following code has been automatically generated to ensure that any
% object manipulated in TMTOOL has been properly disposed when executed
% as part of a function or script.

% Clean up all objects.
delete(visaObj);
clear visaObj;



%% FUNCG: Clean up - close the connection and clear the object
fclose(VisaObjFunCG);
clear VisaObjFunCG;
% close and clear
fclose(s1);
delete(s1);

clear,clc,close all