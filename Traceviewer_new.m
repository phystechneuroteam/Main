%Reads traces from csv files and plot them on the same figure, coloring them
%using "colornum" routine; user can define offset between traces at the
%Y-axis (in %DF/F) and parameters of periodical gray shadings on the plot at the X
%axis

[filename, path] = uigetfile('*.csv','Select CSV file with traces:', 'J:\CA_1\CA1_1_20160915\df_recording_20160915_130942_corrected.tif_neuropil_40.csv_medlowpassed_5.000000e-01_60.csv');


prompt = {'Offset between traces (1 = maximum):', 'Normalization value (0 - absolute maximum)', 'Line width, px', 'Redraw figure (0/1 -no/yes)', 'Spike depicting mode (0/1/2 - do not draw/draw/load .csv)','Spike treshold, MADs','Spike half-decay time, s'}; 
default_data = {'0.7','0','2','0','2','5','0.5'};
options.Resize='on';
dlg_data = inputdlg(prompt, 'Parameters', 1, default_data, options);

offset = str2double(dlg_data{1});
absmax = str2double(dlg_data{2});
line_width = str2double(dlg_data{3});
redraw = str2num(dlg_data{4});
sp_mode= str2num(dlg_data{5});
ampl  = str2double(dlg_data{6});
tau_off_s  = str2double(dlg_data{7});


T = readtable(sprintf('%s%s',path,filename));
dim = size(T);
X = T{1:dim(1),1};

if ~absmax
    maxim = max(max(T{1:dim(1),2:dim(2)}));
    minim = min(min(T{1:dim(1),2:dim(2)}));
    absmax = max(abs(maxim), abs(minim));
end

if sp_mode == 1
    SpikeDetector_new(path, filename, ampl, tau_off_s);
    SPIKES = readtable(sprintf('%sspikes_%s',path,filename));
elseif sp_mode == 2
    [filename2, path2] = uigetfile('*.csv','Select CSV file with traces:', sprintf('%sspikes_%s',path,filename));
    SPIKES = readtable(sprintf('%s%s',path2,filename2));
end

if redraw
    figure;
end

%main plots drawing
w = waitbar(0, sprintf('Plotting trace %d of %d', 1,  dim(2)-1));
hold on;
for i = 2:dim(2)
    waitbar((i-1)/(dim(2)-1), w, sprintf('Processing cell %d of %d', i-1,  dim(2)-1));
    plot(X, T{1:dim(1),i}/absmax + offset*(i-2), 'Color', colornum(i-1), 'LineWidth', line_width);
end
delete(w);

%spikes drawing
w = waitbar(0, sprintf('Drawing spikes: trace %d of %d', 1,  dim(2)-1));
if sp_mode ~= 0
    for i = 2:dim(2)
        waitbar((i-1)/(dim(2)-1), w, sprintf('Processing cell %d of %d', i-1,  dim(2)-1));
        for j = 1:dim(1)
            if SPIKES {j,i}
                sp_ampl = SPIKES {j,i}/absmax;
                patch([X(j)-0.3, X(j), X(j)+0.3, X(j)], [offset*(i-1.8) + sp_ampl, offset*(i-1.65) + sp_ampl, offset*(i-1.8) + sp_ampl, offset*(i-1.95) + sp_ampl], colornum(i-1), 'EdgeColor', 'none');
            end
        end
    end
end
delete(w);

