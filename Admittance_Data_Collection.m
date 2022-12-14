% The purpose of this script is to excite a Traveling Wave Ultrasonic Motor
% Stator with a sinusoidal frequency sweep and record the voltages from the 
% test circuit which will be used to calculated its admittance. The script
% is written to work with the Rigol DG1022 Arbitrary Wavefrom Generator and
% DS1052 or DS1104 Oscilloscope. The script creates VISA objects which 
% represent the devices and communicates with them through serial commands 
% which require a pause to prevent comunication errors. The script has the 
% scope 'auto' so the screen optimally displays the voltages. The waveform 
% generator then sweeps through the outlined sinusoidal frequencies and the 
% voltage waveforms displayed on the oscilloscope screen are recorded and 
% formatted.

% Find VISA-USB objects
DG1022 = instrfind('Type', 'visa-usb', 'RsrcName', 'USB0::0x0400::0x09C4::DG1D174002776::0::INSTR', 'Tag', '');
DS1052 = instrfind('Type', 'visa-usb', 'RsrcName', 'USB0::0x1AB1::0x0588::DS1ET171204076::0::INSTR', 'Tag', '');
DS1104 = instrfind('Type', 'visa-usb', 'RsrcName', 'USB0::0x1AB1::0x04CE::DS1ZD225201496::0::INSTR', 'Tag', '');

% Create the VISA-USB object if it does not exist, otherwise use the object
% that was found.
if isempty(DG1022)
    DG1022 = visa('NI', 'USB0::0x0400::0x09C4::DG1D174002776::0::INSTR');
else
    fclose(DG1022);
    DG1022 = DG1022(1);
end
if isempty(DS1052)
    DS1052 = visa('NI', 'USB0::0x1AB1::0x0588::DS1ET171204076::0::INSTR');
else
    fclose(DS1052);
    DS1052 = DS1052(1);
end
if isempty(DS1104)
    DS1104 = visa('NI', 'USB0::0x1AB1::0x04CE::DS1ZD225201496::0::INSTR');
else
    fclose(DS1104);
    DS1104 = DS1104(1);
end

% Set Scope Being Used
scope = DS1104;

% Set Scope Buffer Size 
if (scope == DS1052)
    buf_Size = 610;
end
if(scope == DS1104)
    buf_Size = 1212;
end

% Configure Instruments
t = 0.2;                                    % Pause Time to Prevent Communication Error
set(scope, 'InputBufferSize', buf_Size);    % Oscilloscope Input Buffer
pause(t);

% Connect to Instruments
fopen(DG1022);                      % Connect to DG1022
pause(t);
fprintf(DG1022, 'OUTP OFF');        % Turn Channel 1 Output Off
pause(t);
fprintf(DG1022, 'OUTP:CH2 OFF');    % Turn Channel 2 Off
pause(t);
fopen(scope);                       % Connect to Oscilloscope
pause(t);
fprintf(scope, ':CHAN1:DISP OFF');  % Turn Channel 1 Display Off
pause(t);
fprintf(scope, ':CHAN2:DISP OFF');  % Turn Channel 1 Display Off
pause(t);

% Sinusoidal Wave Sweep Parameters
min_F = 30000;      % Starting Frequency (Hz)
max_F = 50000;      % Ending Frequency (Hz)
step = 10;          % Step Size (Hz)
Vpp = 6;            % Wave Peak-to-Peak Voltage (V)


% Auto Scope to Display Optimum Conditions
% Sinuoidal Waves
sine_Wave = append('APPL:SIN ',num2str(max_F),',',num2str(Vpp),',0');   % Command: 'APPL:SIN f,amp,offset'
cos_Wave = append('APPL:SIN:CH2 ',num2str(max_F),',',num2str(Vpp),'0'); % Command: 'APPL:SIN f,amp,offset'

% Send Waves to Waveform Generator
fprintf(DG1022, 'VOLT:UNIT VPP');       % Set Channel 1 Voltage Unit as Vpp
pause(t);
fprintf(DG1022, 'VOLT:UNIT:CH2 VPP');   % Set Channel 2 Voltage Unit as Vpp
pause(t);
fprintf(DG1022, sine_Wave);             % Send Desired Sine Wave Command
pause(t);
fprintf(DG1022, cos_Wave);              % Send Desired Cos Wave Command
pause(t);
fprintf(DG1022, 'PHAS:CH2 90');         % Phase Shift Channel 2 to Produce Cos Wave
pause(t);
fprintf(DG1022, 'OUTP ON');             % Turn Channel 1 Output On
pause(t);
fprintf(DG1022, 'OUTP:CH2 ON');         % Turn Channel 2 Output On
pause(t);
fprintf(DG1022, 'PHAS:ALIGN');          % Align Channels so their Timing Matches
pause(t);
fprintf(scope, ':CHAN1:DISP ON');       % Turn Channel 1 Display On
pause(t);
fprintf(scope, ':CHAN2:DISP ON');       % Turn Channel 2 Display On
pause(t);
fprintf(scope, ':AUT');                 % Auto Adjust Scope Display
pause(10);                              % Larger Pause to Allow Screen to Update

% Obtain Scope Display Parameters
% DS1052 Display Parameters
if(scope == DS1052)
    time_Div = str2double(query(DS1052, ':TIM:SCAL?'));     % Time Scale (s/div)
    pause(t);
    volt_Div = str2double(query(DS1052, ':CHAN1:SCAL?'));   % Voltage Scale (v/div)
    pause(t);
    vert_Off = str2double(query(DS1052, ':CHAN1:OFFS?'));   % Vertical Offset (v)
    pause(t);
    time_Off = str2double(query(DS1052, ':TIM:OFFS?'));     % Time Offset (s)
    pause(t);
end
% DS1104 Display Parameters
if(scope == DS1104)
    fprintf(scope, ':WAV:SOUR CHAN1');                                  % Set Channel 1 as Channel to Pull Data From
    pause(t);
    fprintf(scope, ':WAV:MODE NORM');                                   % Set to Normal Mode, Reads Waveform on the Screen
    pause(t);
    preamble_CH1 = convertCharsToStrings(query(DS1104, ':WAV:PRE?'));   % Obtain Channel 1 Preamble
    pause(t);
    fprintf(scope, ':WAV:SOUR CHAN2');                                  % Set Channel 2 as Channel to Pull Data From
    pause(t);
    fprintf(scope, ':WAV:MODE NORM');                                   % Set to Normal Mode, Reads Waveform on the Screen
    pause(t);
    preamble_CH2 = convertCharsToStrings(query(DS1104, ':WAV:PRE?'));   % Obtain Channel 2 Preamble
    pause(t);
    % Extract Information from Preamble
    preamble_CH1 = split(preamble_CH1,[","]);                           % Seperate Channel 1 Preamble Contents
    x_Inc(1) = str2num(preamble_CH1(5));                                % X-Axis Increments
    x_Org(1) = str2num(preamble_CH1(6));                                % X-Axis Origin
    x_Ref(1) = str2num(preamble_CH1(7));                                % X-Axis Reference
    y_Inc_CH1(1) = str2num(preamble_CH1(8));                            % Channel 1 Y-Axis Increments
    y_Org_CH1(1) = str2num(preamble_CH1(9));                            % Channel 1 Y-Axis Origin
    y_Ref_CH1(1) = str2num(preamble_CH1(10));                           % Channel 1 Y-Axis Reference
    preamble_CH2 = split(preamble_CH2,[","]);                           % Seperate Channel 2 Preamble Contents
    y_Inc_CH2(1) = str2num(preamble_CH2(8));                            % Channel 2 Y-Axis Increments
    y_Org_CH2(1) = str2num(preamble_CH2(9));                            % Channel 2 Y-Axis Origin
    y_Ref_CH2(1) = str2num(preamble_CH2(10));                           % Channel 2 Y-Axis Reference
end

% Generate Sine Wave Command
for i = 1:((max_F-min_F)/step + 1)
    % Formulate Desired Sine Wave Command
    f = min_F + (i-1)*step;                                             % Wave Frequency (Hz)
    freq(i) = f;                                                        % Keep track of Frequency
    sine_Wave = append('APPL:SIN ',num2str(f),',',num2str(Vpp),',0');   % Sine Wave, Command: 'APPL:SIN f,amp,offset'
    cos_Wave = append('APPL:SIN:CH2 ',num2str(f),',',num2str(Vpp),'0'); % Cosine Wave, Command: 'APPL:SIN f,amp,offset'
    
    % Send Commands to DG1022 to Output Desired Wave
    fprintf(DG1022, 'OUTP OFF');            % Turn Channel 1 Output Off
    pause(t);
    fprintf(DG1022, 'OUTP:CH2 OFF');        % Turn Channel 2 Output Off
    pause(t);
    fprintf(DG1022, 'VOLT:UNIT VPP');       % Set Channel 1 Voltage Unit as Vpp
    pause(t);
    fprintf(DG1022, 'VOLT:UNIT:CH2 VPP');   % Set Channel 2 Voltage Unit as Vpp
    pause(t);
    fprintf(DG1022, sine_Wave);             % Send Desired Wave Command
    pause(t);
    fprintf(DG1022, cos_Wave);              % Send Desired Wave Command
    pause(t);
    fprintf(DG1022, 'PHAS:CH2 90');         % Turn Channel 1 Output On
    pause(t);
    fprintf(DG1022, 'OUTP ON');             % Turn Channel 1 Output On
    pause(t);
    fprintf(DG1022, 'OUTP:CH2 ON');         % Turn Channel 2 Output On                          
    pause(t)
    fprintf(DG1022, 'PHAS:ALIGN');          % Align Channels so their Timing Matches
    pause(t);
    
    % Collect Data
    if(scope == DS1052)
        fprintf(scope, ':WAV:DATA? CHAN1'); % Request Data from DS1052 Channel 1
        pause(t);
        temp = fread(DS1052);               % Read in Data as Type Double
        pause(t);
        raw_Data_CH1(:,i) =  temp(11:end);  % Delete Header 
        fprintf(scope, ':WAV:DATA? CHAN2'); % Request Data from DS1052 Channel 2
        pause(t);
        temp = fread(DS1052);               % Read in Data as Type Double
        pause(t);
        raw_Data_CH2(:,i) =  temp(11:end);  % Delete Header
    end
    if(scope == DS1104)
        fprintf(scope, ':WAV:SOUR CHAN1');  % Set Channel 1 as Channel to Pull Data From
        pause(t);
        fprintf(scope, ':WAV:MODE NORM');   % Set to Normal Mode, Reads Waveform on the Screen
        pause(t);
        fprintf(scope, ':WAV:FORM BYTE');   % Set Return Type of Data as Byte
        pause(t);
        fprintf(scope, ':WAV:DATA?');       % Request Data from Channel 1
        pause(t);
        temp = fread(scope);                % Read in Data as Type Double
        pause(t);
        raw_Data_CH1(:,i) = temp(12:end-1); % Delete Header
        fprintf(scope, ':WAV:SOUR CHAN2');  % Set Channel 2 as Channel to Pull Data From
        pause(t);
        fprintf(scope, ':WAV:MODE NORM');   % Set to Normal Mode, Reads Waveform on the Screen
        pause(t);
        fprintf(scope, ':WAV:FORM BYTE');   % Set Return Type of Data as Byte
        pause(t);
        fprintf(scope, ':WAV:DATA?');       % Request Data from Channel 2
        pause(t);
        temp = fread(scope);                % Read in Data as Type Double
        pause(t);
        raw_Data_CH2(:,i) = temp(12:end-1); % Delete Header
    end
end

% Convert Data to Voltage and Create Time Array
if(scope == DS1052)
    for i=1:length(raw_Data(1,:))
        for j = 1:length(raw_Data(:,1))
            V1(j,i) = ((240-raw_Data_CH1(j,i))*(volt_Div/25)-((vert_Off+volt_Div*4.6)));    % Calculate Voltage 1
            V2(j,i) = ((240-raw_Data_CH2(j,i))*(volt_Div/25)-((vert_Off+volt_Div*4.6)));    % Calculate Voltage 2
        end
    end
    for i = 1:length(raw_Data(:,1))
        T(i) = (i-1)*(time_Div/50)-((time_Div*6)-time_Off);                                 % Calculate Time Array
    end
end
if(scope == DS1104)
    for i=1:length(raw_Data_CH1(1,:))
        for j=1:length(raw_Data_CH1(:,1))
            V1(j,i) = (raw_Data_CH1(j,i)-y_Ref_CH1-y_Org_CH1)*y_Inc_CH1;    % Calculate Voltage 1
            V2(j,i) = (raw_Data_CH2(j,i)-y_Ref_CH2-y_Org_CH2)*y_Inc_CH2;    % Calculate Voltage 2
        end
    end
    for i = 1:length(raw_Data_CH1(:,1))
        T(i) = (i-1)*x_Inc + x_Org;                                          % Calculate Time Array
    end
end

fprintf(DG1022, 'OUTP OFF');            % Turn Channel 1 Output Off
pause(t);
fprintf(DG1022, 'OUTP:CH2 OFF');        % Turn Channel 2 Output Off
pause(t);