%%
VisaObj = instrfind('Type', 'visa-usb', 'RsrcName', 'USB0::0x0699::0x034A::C020435::0::INSTR', 'Tag', '');

if isempty(VisaObj)
    VisaObj = visa('KEYSIGHT', 'USB0::0x0699::0x034A::C020435::0::INSTR');
else
    fclose(VisaObj);
    VisaObj = VisaObj(1);
end
%when generator is connected, set buffersize before generate the waveform 
%cannot set buffersize when the generator is open
VisaObj.OutputBufferSize = 5120000;

%open function generator
fopen(VisaObj);
%%
% Reset the function generator to a know state
 fprintf(VisaObj, '*RST');
 fprintf(VisaObj, '*CLS'); 
% %%
% Define siganl
T_signal=0.8E-2; %s 
fc=4500; %Hz %%Input signal frequency
N_signal =10000; % set the sample rate

dt_signal=T_signal/N_signal; %s
Fs_signal=1/dt_signal; %Hz
f_signalgenerator=1/T_signal; %Hz


t1= (0:dt_signal:T_signal-dt_signal);
t2= (0:dt_signal:1/fc*8);

ccc=size(t2,2);
ddd=size(t1,2);

Data=zeros(size(t1,2),1);
Data1=1/2*sin(2*pi*fc*t2);
Data(ddd-ccc+1:ddd)=Data1(1:ccc);
waveform = Data;

% Plot the custom waveform to be generated
plot(waveform); 
title('Custom waveform created in MATLAB');
grid on;
%Normalize waveform
waveform = waveform ./ (max(waveform)); 

%%
% Convert the double values integer values between 0 and 16382 (as required
waveform =  round((waveform + 1.0)*8191);
waveformLength = length(waveform);

% Encode variable 'waveform' into binary waveform data for AFG.
% programmer manual for bit definitions.
binblock = zeros(2 * waveformLength, 1);
binblock(2:2:end) = bitand(waveform, 255);
binblock(1:2:end) = bitshift(waveform, -8);
binblock = binblock';
% Build binary block header
bytes = num2str(length(binblock));
header = ['#' num2str(length(bytes)) bytes];
%%
% Resets the contents of edit memory and define the length of signal
fprintf(VisaObj, ['DATA:DEF EMEM, ' num2str(length(t2)) ';']); %1001
% Transfer the custom waveform from MATLAB to edit memory of instrument
fwrite(VisaObj, [':TRACE EMEM, ' header binblock ';'], 'uint8');

fprintf(VisaObj, 'SOURCE1:BURst:STATe ON');
fprintf(VisaObj, 'SOURCE1:BURSt:NCYCles 1.0');
fprintf(VisaObj, 'SOURCE1:FUNCTION EMEM');
fprintf(VisaObj, 'SOURCE1:FREQUENCY 1'); 
fprintf(VisaObj, 'SOURCE1:VOLTAGE:AMPLITUDE 1.00');
fprintf(VisaObj, 'SOURCE1:VOLTAGE:OFFSET 0.00');
fprintf(VisaObj, 'OUTP1 On');
fprintf(VisaObj, '')
fprintf(VisaObj, 'OUTPut:TRIGger:MODE SYNC');

% Clean up - close the connection and clear the object
fclose(VisaObj);
clear VisaObj;
