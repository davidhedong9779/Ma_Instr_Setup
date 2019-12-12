%% Connect to the afg3022C using visa-usb connection 2019.11.19
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
%% FUNCG: Reset the function generator
 fprintf(VisaObjFunCG, '*RST');
 fprintf(VisaObjFunCG, '*CLS'); 
 
%% FUNCG: Define siganl
T_signal=0.8E-2; %s
N_signal=10000; %points
fc=4500; %Hz %%Input signal frequency
%bw=.3; % for gaussian puls

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
%plot(waveform); 
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
fprintf(VisaObjFunCG, 'SOURCE1:VOLTAGE:AMPLITUDE 1');
fprintf(VisaObjFunCG, 'SOURCE1:VOLTAGE:OFFSET 0.00');
fprintf(VisaObjFunCG, ':OUTP1 ON');
fprintf(VisaObjFunCG, 'TRIGger:SEQuence:IMMediate');
%%
fclose(VisaObjFunCG);
clear VisaObjFunCG;