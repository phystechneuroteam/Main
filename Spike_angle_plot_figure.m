%function spike_plot_circle(path1, filename1, path2, filename2, in_rad, ext_rad, bord_wid, lab_dist, sect, ang_start, ref_time, turn_bord)
%Draws spatial maps of neuronal spiking
%filename1, path1 - .csv file with videotracking;
%filename2, path2 - .csv file with spikes of neurons
%ref_time - time (in seconds) of NVista (i.e. SPIKES) start relative to videotracking

%if nargin < 2 || isempty(path1) || isempty(filename1)
%    [filename1, path1] = uigetfile('*.csv','Select .csv file with angles:');
%end
%if nargin < 4 || isempty(path2) || isempty(filename2)
%    [filename2, path2] = uigetfile('*.csv','Select .csv file with spikes:');
%end

%if nargin < 12 || isempty (in_rad) || isempty (ext_rad) || isempty (bord_wid) || isempty(lab_dist) || isempty(sect) || isempty (ang_start) || isempty (ref_time) || isempty (turn_bord)
%    prompt = {'Inner circle radius, px:', 'External circle radius, px', 'Border thickness, px (0 - no borders)', 'Distance from ext_rad to text labels (0 - no labels)', 'Number of sectors', 'Angle between horizntal plane and neraest sectors', 'Reference time', 'Rotate borders 90 deg (0/1-no/yes)'}; 
%    default_data = {'100','120','5','15','40','8.36', '83.917', '0'};
%    options.Resize='on';
%    dlg_data = inputdlg(prompt, 'Parameters', 1, default_data, options);
%    ang_start = str2double(dlg_data{6});

path1 =  'J:\CA_1\CA1_6_20160817\';   
filename1 = 'CA1_6_20160817_angles_01.csv';
path2 =  'J:\CA_1\CA1_6_20160817\old_csv\';   
filename2 = 'spikes_df_recording_20160817_143813.tif_corrected.tif_neuropil_30.csv_conc.csv';

ang_start = 8.36;
ref_time = 83.917;
n_sect = 40;
turn_b = 0;
sp_width = 8; %width of spike marker in seconds
sp_height = 5; %height of spike marker in degrees
res_x = 5; %resolution at x axis (pixels per degree)
res_y = 0.1; %resolution at y axis (pixels per frame)


VT = readtable(sprintf('%s%s',path1,filename1));
TIME_VT = VT{1:height(VT),1};
ANG_VT = VT{1:height(VT),2};

%vt time quantum
dt_vt = (TIME_VT(height(VT)) - TIME_VT(1))/height(VT);
%ref_time with respect to movie_time
ref_time = ref_time - TIME_VT(1) + dt_vt;

SPIKES = readtable(sprintf('%s%s',path2,filename2));
n_cells = width(SPIKES) - 1;
n_frames = height(SPIKES);
TIME = SPIKES{1:n_frames,1};
fps = n_frames/(TIME(n_frames)- TIME(1));
ANG = zeros(n_frames,1,'double'); %final array of angles 
D_ANG = zeros(n_frames,1,'double'); %array of angular velocity 
DD_ANG = zeros(n_frames,1,'double'); %array of angular acceleration 
n_ypoints = fix(n_frames*res_y - 0.00001)  + 1; 
n_xpoints = fix(360*res_x - 0.00001) + 1;
IM = zeros(n_ypoints, n_xpoints, 3);

if isdir(sprintf('%s%s_spike_plots', path2, filename1))
    rmdir(sprintf('%s%s_spike_plots', path2, filename1), 's');
end
[s, ~, ~] = mkdir(path2,sprintf('%s_spike_plots', filename1));
while ~s
   [s, ~, ~] = mkdir(path2,sprintf('%s_spike_plots', filename1));
end


w = waitbar(0, sprintf('Processing frame %d of %d', 0,  n_frames));

for i = 1:n_frames
    
    waitbar(i/n_frames, w, sprintf('Processing frame %d of %d', i,  n_frames));
    
    y = fix(i*res_y - 0.00001) + 1;
    %Drawing background
    for x = 1:n_xpoints
        IM(y,x,:) = 0.5 + mod(fix((x*4/360)/res_x) + turn_b, 2)*0.2;
        if rem((x*n_sect/360)/res_x, 1)  < 0.001
            IM(y,x,:) = 0;
        end
    end
     
    %number of frame in VT corresponding to i in SPIKES
    t1 = fix((TIME(i) + ref_time)/dt_vt);
    %linear approximation combined with rescaling
    angle = ANG_VT(t1) + (ANG_VT(t1+1) - ANG_VT(t1))*(TIME(i) + ref_time - t1*dt_vt)/dt_vt - ang_start;
    if angle < 0
        ANG(i) = angle + 360;
    else
        ANG(i) = angle;
    end
    if i > 1
        D_ANG(i) = (ANG(i) - ANG(i-1))*fps;
        DD_ANG(i) = (D_ANG(i) - D_ANG(i-1))*fps;
    end
    
    if D_ANG(i) >= 0 && D_ANG(i)/fps < 350
        IM(y,fix(ANG(i)*res_x)+1, 2) = 1;
    end
    if D_ANG(i) <= 0 && D_ANG(i)/fps > -350
        IM(y,fix(ANG(i)*res_x)+1, 3) = 1;
    end
end   
    


    h = figure;
    imshow(IM);
    %saveas(h, sprintf('%s%s_spike_plots\\%s_spike_figure_plot_%d.tif', path2, filename1, filename2, 1), 'tif');
    imwrite(IM, sprintf('%s%s_spike_plots\\%s_spike_figure_plot_%d.tif', path2, filename1, filename2, 1));
    
