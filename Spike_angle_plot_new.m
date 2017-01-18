function Spike_angle_plot_new(path1, filename1, path2, filename2, ang_start, n_sect, turn_b, sp_width, sp_height)
%Draws spatial maps of neuronal spiking
%filename1, path1 - .csv file with videotracking;
%filename2, path2 - .csv file with spikes of neurons
%NB!!! csv tables must be of same length and synchronized

if nargin < 2 || isempty(path1) || isempty(filename1)
    [filename1, path1] = uigetfile('*.csv','Select .csv file with angles:', 'J:\CA_1\CA1_6_20160817\CA1_6_20160817_angles_01.csv' );
end
if nargin < 4 || isempty(path2) || isempty(filename2)
    [filename2, path2] = uigetfile('*.csv','Select .csv file with spikes:', 'J:\CA_1\CA1_6_20160817\spikes_df_recording_20160817_143813.tif_corrected.tif_neuropil_30.csv_conc.csv_medlowpassed_5.000000e-01_60.csv');
end

if nargin < 9 || isempty (ang_start)|| isempty(n_sect) || isempty (turn_b) || isempty (sp_width) || isempty (sp_height)
    prompt = {'Angle between horizntal plane and neraest sectors', 'Number of sectors', 'Rotate borders 90 deg (0/1-no/yes)', 'Width of spike marker in seconds', 'Height of spike marker in degrees'};    
    default_data = {'8.36', '40', '0', '6', '4'};
    options.Resize='on';
    dlg_data = inputdlg(prompt, 'Parameters', 1, default_data, options);
    
    ang_start = str2double(dlg_data{1});
    n_sect = str2double(dlg_data{2});
    turn_b = str2double(dlg_data{3});
    sp_width = str2double(dlg_data{4});
    sp_height = str2double(dlg_data{5});
end

%Table reading and initialization
VT = readtable(sprintf('%s%s',path1,filename1));
ANG_VT = VT{1:height(VT),2};
SPIKES = readtable(sprintf('%s%s',path2,filename2));
n_cells = width(SPIKES) - 1;
n_frames = height(SPIKES);
TIME = SPIKES{1:n_frames,1};
fps = n_frames/(TIME(n_frames)- TIME(1));
ANG = zeros(n_frames,1,'double'); %final array of angles 
D_ANG = zeros(n_frames,1,'double'); %array of angular velocity 
DD_ANG = zeros(n_frames,1,'double'); %array of angular acceleration 

%output folder creating
if isdir(sprintf('%s\\%s_spike_plots', path1, filename1))
    rmdir(sprintf('%s\\%s_spike_plots', path1, filename1), 's');
end
[s, ~, ~] = mkdir(path1,sprintf('%s_spike_plots', filename1));
while ~s
   [s, ~, ~] = mkdir(path1,sprintf('%s_spike_plots', filename1));
end

for i = 1:n_frames

    %linear approximation combined with rescaling
    angle = ANG_VT(i) - ang_start;
    if angle < 0
        ANG(i) = angle + 360;
    else
        ANG(i) = angle;
    end
    if i > 1
        D_ANG(i) = (ANG(i) - ANG(i-1))*fps;
        DD_ANG(i) = (D_ANG(i) - D_ANG(i-1))*fps;
    end
end

w = waitbar(0, sprintf('Processing cell %d of %d', 1,  n_cells));

for j = 2:n_cells+1
    waitbar((j-1)/n_cells, w, sprintf('Processing cell %d of %d', j-1,  n_cells));
    %if there are no spikes in this cell, skip it
    if ~nnz(SPIKES{1:n_frames,j})
        continue;
    end    
    h = figure;
    hold on;
    %Drawing background
    for sect = 0:n_sect-1
        for i = 1:4
            x(i) = mod(fix(i/2),2)*TIME(n_frames);
            y(i) = fix(sect*360/n_sect) + mod(fix((i-1)/2),2)*360/n_sect;
        end
        color(1:3) = 0.5 + mod(fix((sect-1)*4/n_sect) + turn_b, 2)*0.2; 
    patch(x, y, color);
    end
    
    %main plot
    for i = 2:n_frames
        if D_ANG(i) >= 0 && D_ANG(i)/fps < 350
            plot(TIME(i-1:i), ANG(i-1:i), 'LineWidth', 1.5, 'Color', [0 1 0]);
        end
        if D_ANG(i) <= 0 && D_ANG(i)/fps > -350
            plot(TIME(i-1:i), ANG(i-1:i), 'LineWidth', 1.5, 'Color', [0 0 1]);
        end
        
    end
    %Drawing spikes
    for i = 1:n_frames
        if SPIKES{i,j}~=0
            for k = 1:4
                x(k) = TIME(i) + (mod(fix(k/2),2) - 0.5)*sp_width;   
                y(k) = ANG(i) + (mod(fix((k-1)/2),2) - 0.5)*sp_height;
            end
            patch(x, y, [1 0 0], 'EdgeColor', 'none');
        end
    end
    saveas(h, sprintf('%s\\%s_spike_plots\\%s_spike_plot_%d.fig', path2, filename1, filename2, j-1), 'fig');
    saveas(h, sprintf('%s\\%s_spike_plots\\%s_spike_plot_%d.tif', path2, filename1, filename2, j-1), 'tif');
    delete(h);    
end

delete(w);
