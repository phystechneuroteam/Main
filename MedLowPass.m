function MedLowPass(filename, mode, w_time, freq)
%Applies median filter, 'w_time'- window time(s), or applies lowpass filter with cutoff 
%frequency 'freq' Hz, 'amp','ast' - passing and stopping amplitudes in dB.
%Works with .csv file.
% [w_time = 20s]
% [freq = 2Hz]
% amp = 1 dB
% ast = 60 dB
% [mode = 0/1/2 - median subtraction only/lowpasss only/both]

if nargin < 1 || isempty(filename)
    [filename0, path] = uigetfile('*.csv','Select CSV file with traces:', 'H:\CA_1\CA1_6_20160817\df_recording_20160817_143813.tif_corrected.tif_neuropil_30.csv');
    filename = sprintf('%s%s',path,filename0);
end
if nargin < 4 || isempty (mode) || isempty (w_time) || isempty (freq)
    prompt = {'Working mode (0/1 - median filter/lowpasss filter):', 'Time window for median calculation, s', 'Cutoff frequency, Hz'}; 
    default_data = {'1','2','2'};
    options.Resize='on';
    dlg_data = inputdlg(prompt, 'Parameters', 1, default_data, options);

    mode = str2num(dlg_data{1});
    w_time = str2double(dlg_data{2});
    freq = str2double(dlg_data{3});
end

amp = 1;
ast = 60;
x_shift = 1.7/freq;

T = readtable(filename);
dim = size(T);
X = T{1:dim(1),T.Properties.VariableNames{1}};
fps = round((dim(1)-1)/(X(dim(1))-X(1)));
h_wind = round(fps*w_time/2);

new_length = dim(1)-fix(x_shift*fps)-1; %length after x shift correction
x_sh = fix(x_shift*fps);

NEWT = zeros(dim(1)+1,dim(2));
NEWT(2:dim(1)+1, 1) = X(1:dim(1));


d = fdesign.lowpass('Fp,Fst,Ap,Ast', 1.8*pi*freq/fps, 2.2*pi*freq/fps, amp, ast);
Hd = design(d, 'equiripple');
h = waitbar(0, sprintf('Processing trace %d of %d', 0,  dim(2)-1)); 

for i = 2:dim(2)
    waitbar((i-1)/(dim(2)-1), h, sprintf('Processing trace %d of %d', i-1,  dim(2)-1));
    if ~mode
        for j = 1:dim(1)
            w_start = j - h_wind;
            w_end = j + h_wind;
            if w_start < 1
                w_start = 1;
            end
            if w_end > dim(1)
                w_end = dim(1);
            end
            med  = median(T{w_start:w_end,T.Properties.VariableNames{i}});
            NEWT(j,i) = med;
        end
    else
        for j = new_length+1:dim(1)
            NEWT(j+1,i) = T{j,i};
        end
        T{:,i} = filter(Hd, T{:,i});
        for j = 1:new_length
            NEWT(j+1,i) = T{j+x_sh,i};
        end 
    end
end 

csvwrite(sprintf('%s_medlowpassed.csv',filename), NEWT);
delete(h);
end