 %% OSC_TESTING Code for communicating with an instrument.
%
%   This is the machine generated representation of an instrument control
%   session. The instrument control session comprises all the steps you are
%   likely to take when communicating with your instrument. These steps are:
%   
%       1. Instrument Connection
%       2. Instrument Configuration and Control
%       3. Disconnect and Clean Up
% 
%   To run the instrument control session, type the name of the file,
%   osc_testing, at the MATLAB command prompt.
% 
%   The file, OSC_TESTING.M must be on your MATLAB PATH. For additional information 
%   on setting your MATLAB PATH, type 'help addpath' at the MATLAB command 
%   prompt.
% 
%   Example:
%       osc_testing;
% 
%   See also SERIAL, GPIB, TCPIP, UDP, VISA, BLUETOOTH, I2C, SPI.
% 
%   Creation time: 08-Nov-2019 13:34:22

%% Major Settings
%General
dir = 'D:\Chu\Acousic Exp\v1';
datafolder='data';
%filenameroot='direction_grating_0210_double_angle100'%facing the second door;
filenameroot='direction_grating_0406_empty_angle75-3'%facing the second door;

%previous 56/150
%Major Oscilloscope Setings
Osc_Ch1_range=8; %Vpp - Channel 1 range
Osc_Ch2_range=8; %Vpp - Channel 2 range
Osc_trigger_level=2; %Vpp - Trigger Level
Osc_T=1.0E-2; %s - total time
Osc_pretriggerT=-.3E-2; %s - pre trigger time
Osc_N_min=10E3; %mininum number of sampling points
Ch1_invert='off'; %'on'=inverted, 'off'=normal
Ch2_invert='on'; %'on'=inverted, 'off'=normal

%Major Function Generator Settings
sig_voltage=2.0; %Vpp
T_signal=0.8E-2; %s
N_signal=10000; %points
fc=4500; %Hz %%Input signal frequency
bw=.3; % for gaussian puls

%Scanning Grid
%P1=1; % (note: right now setup for odd numbers)
%P1=41;
P1=41;
P2=1;

%P1=3;
%P2=2;
stepsize=0.005; %m
delay=2; %s



%% Instrument Connection

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

%% Setup open and close visa object to turn on precision mode

% Set properity
visaObj.InputBufferSize = 100000;
visaObj.Timeout = 10;
visaObj.ByteOrder = 'littleEndian';

% Connect to instrument object, obj1.
fopen(visaObj);

%% Sending Signal to Osc

% Turn on precision mode
%fprintf(visaObj,'');
%fprintf(visaObj,'*RST');
%fprintf(visaObj,':SYSTem:PRECision 1');
fprintf(visaObj,':SYSTem:LOCK on');
fprintf(visaObj,':TRIGger:SWEep NORMal');

% Channel 1
fprintf(visaObj,':CHANnel1:DISPlay 1');
fprintf(visaObj,':CHANnel1:COUPling DC');
fprintf(visaObj,':CHANnel1:IMPedance ONEMeg');
fprintf(visaObj,':CHANnel1:OFFSet 0 V');
fprintf(visaObj,':CHANnel1:PROBe X1');
fprintf(visaObj,':CHANnel1:RANGe ' + Osc_Ch1_range);
fprintf(visaObj,':CHANnel1:INVert ' + Ch1_invert);

% Channel 2
fprintf(visaObj,':CHANnel2:DISPlay 1');
fprintf(visaObj,':CHANnel2:COUPling DC');
fprintf(visaObj,':CHANnel2:IMPedance ONEMeg');
fprintf(visaObj,':CHANnel2:OFFSet 0 V');
fprintf(visaObj,':CHANnel2:PROBe X1');
fprintf(visaObj,':CHANnel2:RANGe ' + Osc_Ch1_range);
fprintf(visaObj,':CHANnel2:INVert ' + Ch1_invert);

%Trigger
fprintf(visaObj,':TRIGger:MODE EDGE');
fprintf(visaObj,':TRIGger:EDGE:SOURce EXT');
fprintf(visaObj,':TRIGger:EDGE:COUPling DC');
fprintf(visaObj,':TRIGger[:EDGE]:LEVel ' + Osc_trigger_level);

%set acquisition properties
fprintf(visaObj,':ACQuire:TYPE NORMal');
fprintf(visaObj,':TRIGger:MODE EDGE');
fprintf(visaObj,':TRIGger:MODE EDGE');
fprintf(visaObj,':TRIGger:MODE EDGE');
set(hAcqObj,'AcquisitionType','Agilent546XXAcquisitionTypeNormal');
set(hAcqObj,'TimePerRecord',Osc_T);
set(hAcqObj,'StartTime',-1*Osc_pretriggerT);
set(hAcqObj,'NumberOfPointsMin',Osc_N_min);

%% Save
fprintf(visaObj,':WAVeform:POINts:MODE RAW');
fprintf(visaObj,':WAVeform:SOURce CHANnel1');
fprintf(visaObj,':WAVeform:FORMat BYTE'); %page1620


%% Disconnect and Clean Up

fprintf(visaObj,':SYSTem:LOCK off');

% Disconnect from instrument object, obj1.
fclose(visaObj);

% The following code has been automatically generated to ensure that any
% object manipulated in TMTOOL has been properly disposed when executed
% as part of a function or script.

% Clean up all objects.
delete(visaObj);
clear visaObj;

