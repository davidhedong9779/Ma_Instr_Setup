%Acoustic Scanning Code
%Oscilloscope, Signal Generator, and Translation Stage Control

% 1) Use with 32 bit Matlab
% 2) always have "driver" and "data" subfolders: including
% AgilentInfiniiVision.mdd and tek_afg3000.mdd
% 3) have galil tools installed
% 4) have ArbExpress (signal generator software installed), and include C:\Program Files (x86)\Tektronix\ArbExpress\Tools\Matlab
%in matlab path
% 5) If having problem with creating objects, use 'tmtool'. Note this is
% also a way of investigating the properties and functions of the driver
% files


clc;
clear all;
close all;

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


%% Setup Clock for File Saving
cl=clock;
clockroot=['_' num2str(1E3*cl(2)) '_' num2str(1E3*cl(3)) '_' num2str(1E3*cl(1)) '_' num2str(1E3*cl(4)) 'h_' num2str(1E3*cl(5)) 'm_' num2str(1E3*cl(6)) 's'];


%% Connect to Oscilloscope
fDrvr=[dir '\driver\AgilentInfiniiVision.mdd'];
visaRscName='USB0::2391::5981::MY50340316::0::INSTR';
stDev = createStDevFromRscName(visaRscName);
scopeObj = scopeObject(fDrvr, stDev);
scopeObj.connect();
[model, manufacturer] = scopeObj.getModel()


%% Initialize and set properties
scopeObj.devicereset(); % can insert a funcion into "scopeObject.m" like this, or can use scopeObj.devSource.

%setup open and close visa object to turn on precision mode
visaObj = visa('agilent','USB0::2391::5981::MY50340316::0::INSTR');
visaObj.InputBufferSize = 100000;
visaObj.Timeout = 10;
visaObj.ByteOrder = 'littleEndian';
fopen(visaObj);
fprintf(visaObj,':SYSTem:PRECision 1');
fprintf(visaObj,':TRIGger:SWEep NORMal');
%end precision mode setup

%set channel 1 object properties - note: can use ex. get(hChanObj,'Coupling')
hChanObj = scopeObj.devSource.Channel(1);
set(hChanObj,'Coupling','Agilent546XXVerticalCouplingDC');
set(hChanObj,'InputImpedance',1E6); %must be 50 or 1E6 ohms
set(hChanObj,'Offset',0);
set(hChanObj,'ProbeAttenuation',1);
set(hChanObj,'Range',Osc_Ch1_range); %Vpp
set(hChanObj, 'Invert', Ch1_invert);

%set channel 2 object properties - note: can use ex. get(hChanObj,'Coupling')
hChanObj2 = scopeObj.devSource.Channel(2);
set(hChanObj2, 'Enabled', 'on');
set(hChanObj2,'Coupling','Agilent546XXVerticalCouplingDC');
set(hChanObj2,'InputImpedance',1E6); %must be 50 or 1E6 ohms
set(hChanObj2,'Offset',0);
set(hChanObj2,'ProbeAttenuation',1);
set(hChanObj2,'Range',Osc_Ch2_range); %Vpp
set(hChanObj2, 'Invert', Ch2_invert);

%set trigger properties
hTriggerObj = scopeObj.devSource.Trigger(1);
set(hTriggerObj,'Coupling','Agilent546XXTriggerCouplingDC');
% set(hTriggerObj,'Continuous','off');
% set(hTriggerObj,'Source','UserChannel1');
set(hTriggerObj,'TriggerType','Agilent546XXTriggerEdge');
fprintf(visaObj,':TRIGger:SOURce EXTernal');

set(hTriggerObj,'Level',Osc_trigger_level);

%set acquisition properties
hAcqObj = scopeObj.devSource.Acquisition(1);
set(hAcqObj,'AcquisitionType','Agilent546XXAcquisitionTypeNormal');
set(hAcqObj,'TimePerRecord',Osc_T);
set(hAcqObj,'StartTime',-1*Osc_pretriggerT);
set(hAcqObj,'NumberOfPointsMin',Osc_N_min);


%% Connect to arbitrary waveform generator object / Signal generator
s=NewSession('USB0::1689::839::C036587::0','usb');
[status,idn]=query(s, '*idn?');


%% Connect to Signal Generator
interfaceObj = instrfind('Type', 'visa-usb', 'RsrcName', 'USB0::1689::839::C036587::0', 'Tag', '');
if isempty(interfaceObj)
    %     interfaceObj = visa('tek', 'USB0::1689::839::C036587::0');
    interfaceObj = visa('tek', 'USB0::1689::839::C036587::0');
else
    fclose(interfaceObj);
    interfaceObj = interfaceObj(1);
end

deviceObj = icdevice([dir '\driver\tek_afg3000.mdd'], interfaceObj);
connect(deviceObj);
disp('go')


%% Setup signal generator
% devicereset(deviceObj);
% set(deviceObj.Burstmode(1), 'Enabled', 'on');
% set(deviceObj.Burstmode(1), 'Cycles', 1.0);
% set(deviceObj.Waveform(1), 'Shape', 'EMemory');
% set(deviceObj.Voltage(1), 'Amplitude', sig_voltage);
% set(deviceObj, 'TriggerSource', 'external');
% status=Write(s,'Output1:State On');

dt_signal=T_signal/N_signal; %s
Fs_signal=1/dt_signal %Hz
f_signalgenerator=1/T_signal %Hz

%set(deviceObj.Frequency(1), 'Frequency', f_signalgenerator);

t1=[0:dt_signal:T_signal-dt_signal];
t2=[0:dt_signal:1/fc*8];
ccc=size(t2,2);
ddd=size(t1,2);
% DEFINE SIGNAL
Data=zeros(size(t1,2));
Data1=1/2*sin(2*pi*fc*t2);
Data(ddd-ccc+1:ddd)=Data1(1:ccc);
figure;
plot(t1,Data)
%Data = gauspuls(t-t(end)/2,fc,bw);

%TransferWfm(s, 'example.wfm', Data, N_signal);


%% Connect to Motion Controller
g = actxserver('galil'); %set the variable g to the GalilTools COM wrapper
response = g.libraryVersion; %Retrieve the GalilTools library versions
disp(response); %display GalilTools library version
g.address = ''; %Open connections dialog box
response = g.command(strcat(char(18), char(22))); %Send ^R^V to query controller

disp(strcat('Connected to: ', response)); %print response
response = g.command('MG_BN'); %Send MG_BN command to query controller for serial number
disp(strcat('Serial Number: ', response)); %print response

stepperrev=51200;
inchperrev=.062;
in2m=.0254;
stepperm=1/(in2m*inchperrev/stepperrev);


%% Main Loop: Get data and plot
FsOsc = get(hAcqObj,'SampleRate');
FsMHzOsc = [num2str(FsOsc/1E6) ' MHz']

%% Return motion controller to initial position

for i=1:P1
        for j=1:P2
        i
        j
        % set for single acquisition - waiting for trigger
        fprintf(visaObj,':SINGle');
        
        pause(delay)
        
        % trigger signal generator
        invoke(deviceObj,'trigger');
        pause(0.5)

        % gather data
        [dataVals, x0, dx] = invoke(scopeObj.devSource.Measurement(hChanObj.HwIndex), 'FetchWaveform', 1);
        [dataVals2, x0, dx] = invoke(scopeObj.devSource.Measurement(hChanObj2.HwIndex), 'FetchWaveform', 1);

        timeVals = x0:dx:x0+(length(dataVals)-1)*dx;
        timeVals2=timeVals;
        % dataVals2=zeros(length(timeVals),1);
        
        %plot data
        %figure;
        %plot(timeVals,dataVals,timeVals2,dataVals2);
        
        %save data
        %save([datafolder '\' filenameroot '_i=' num2str(i) '_j=' num2str(j) clockroot '.mat']...
        %   , 'timeVals', 'dataVals', 'dataVals2');
        save([datafolder '\' filenameroot '_i=' num2str(i) '_j=' num2str(j) '.mat']...
            , 'timeVals', 'dataVals', 'dataVals2');
        
        dt=timeVals(2)-timeVals(1);
        Fs=1/dt;
        
        %Move
        if j<P2
            g.command('DP 0,0');
            if mod(i,2)==1
                g.command(['PAA=(1)*' num2str(-1*stepsize*stepperm)]); %+1 positive y (toward the curtain)
            else
                g.command(['PAA=(1)*' num2str(stepsize*stepperm)]); %+1 positive y (toward the curtain)
            end
            g.command('BGAB');
            g.command('AMAB')
        else
            if i<P1
                g.command('DP 0,0');
                g.command(['PAB=(1)*' num2str(-1*stepsize*stepperm)]); %+1 = negative y (toward the doors)
                g.command('BGAB');
                g.command('AMAB')
                
            end
        end
        pause(0.5)
    end
end


%% Return motion controller to initial position
g.command('DP 0,0');
g.command(['PAB=(1)*' num2str(1*(P1-1)*stepsize*stepperm)]); %+1 positive y (toward the doors)
g.command(['PAA=(1)*' num2str(1*(P2-1)*stepsize*stepperm)]); %+1 = negative x (toward the curtain)
g.command('BGAB');
g.command('AMAB')

%% Disconnect Devices
% Disconnect and close second oscilloscope object
fclose(visaObj);
delete(visaObj);
clear visaObj;

% Disconnect oscilloscope
scopeObj.disconnect();
scopeObj.delete();

% Close Arbitrary Waveform Generation Connection
CloseSession(s);
% Disconnect signal generator
disconnect(deviceObj);
delete([deviceObj interfaceObj]);

% Close motion controller object
delete(g);


%% Save all settings
save([datafolder '\' filenameroot '_main' clockroot '.mat']);
% saveas(hfig,[datafolder '\' filenameroot clockroot '.fig'])
% saveas(hfig,[datafolder '\' filenameroot clockroot '.png'])
