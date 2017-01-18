function Df_map_circle(path1, filename1, path2, filename2, in_rad, ext_rad, bord_wid, lab_dist, sect, ang_start, ref_time, turn_bord)
%Draws spatial maps of neuronal spiking
%filename, path - .csv file with videotracking;
%filename2, path2 - .csv file with spikes of neurons
%ref_time - time (in seconds) of NVista (i.e. SPIKES) start relative to videotracking

if nargin < 2 || isempty(path1) || isempty(filename1)
    [filename1, path1] = uigetfile('*.csv','Select .csv file with angles:');
end
if nargin < 4 || isempty(path2) || isempty(filename2)
    [filename2, path2] = uigetfile('*.csv','Select .csv file with spikes:');
end

if nargin < 12 || isempty (in_rad) || isempty (ext_rad) || isempty (bord_wid) || isempty(lab_dist) || isempty(sect) || isempty (ang_start) || isempty (ref_time) || isempty (turn_bord)
    prompt = {'Inner circle radius, px:', 'External circle radius, px', 'Border thickness, px (0 - no borders)', 'Distance from ext_rad to text labels (0 - no labels)', 'Number of sectors', 'Angle between horizntal plane and neraest sectors', 'Reference time', 'Rotate borders 90 deg (0/1-no/yes)'}; 
    default_data = {'100','120','5','15','40','8.36', '83.917', '0'};
    options.Resize='on';
    dlg_data = inputdlg(prompt, 'Parameters', 1, default_data, options);

    in_rad = str2double(dlg_data{1});
    ext_rad = str2double(dlg_data{2});
    bord_wid = str2double(dlg_data{3});
    lab_dist = str2double(dlg_data{4});
    sect = str2double(dlg_data{5});
    ang_start = str2double(dlg_data{6});
    ref_time = str2double(dlg_data{7});
    turn_bord = str2double(dlg_data{8});
end

VT = readtable(sprintf('%s%s',path1,filename1));
TIME_VT = VT{1:height(VT),1};
ANG_VT = VT{1:height(VT),2};

%time quantum
dt_vt = (TIME_VT(height(VT)) - TIME_VT(1))/height(VT);
%ref_time with respect to movie_time
ref_time = ref_time - TIME_VT(1) + dt_vt;

DFS = readtable(sprintf('%s%s',path2,filename2));
n_cells = width(DFS) - 1;
n_frames = height(DFS);
TIME = DFS{1:n_frames,1};
ANG = zeros(n_frames,1,'uint16'); %array of sectorial numbers

if isdir(sprintf('%s\\%s_df_maps', path1, filename1))
    rmdir(sprintf('%s\\%s_df_maps', path1, filename1), 's');
end
[s, ~, ~] = mkdir(path1,sprintf('%s_df_maps', filename1));
while ~s
   [s, ~, ~] = mkdir(path1,sprintf('%s_df_maps', filename1));
end

for i = 1:n_frames
    %number of frame in VT corresponding to i in SPIKES
    t1 = round((TIME(i) + ref_time)/dt_vt);
    %linear approximation combined with rescaling
    angle = ANG_VT(t1) + (ANG_VT(t1+1) - ANG_VT(t1))*(TIME(i) + ref_time - t1*dt_vt)/dt_vt - ang_start;
    if angle < 0
        ANG(i) = fix((angle + 360)*sect/360 - 0.00001) + 1;
    else
        ANG(i) = fix(angle*sect/360 - 0.00001) + 1;
    end
end

w = waitbar(0, sprintf('Processing cell %d of %d', 1,  n_cells));

OCC = zeros(sect,1); %time spent in sectors
for i = 1:n_frames
    OCC(ANG(i),1) =  OCC(ANG(i),1) + 1;
end

h_occ = figure;
DrawSectors(OCC, in_rad, ext_rad, bord_wid, lab_dist, OCC, turn_bord);
saveas(h_occ, sprintf('%s\\%s_df_maps\\%s_occupance_map.tif', path2, filename1, filename2), 'tif');

for j = 2:n_cells+1
    waitbar((j-1)/n_cells, w, sprintf('Processing cell %d of %d', j-1,  n_cells));
    DFT = zeros(sect,1, 'double'); %total df/f  in sectors
    DFR = zeros(sect,1, 'double'); %df/f rate over time in sectors
    for i = 1:n_frames
        DFT(ANG(i),1) =  DFT(ANG(i),1) + DFS{i,j};
    end
    DFR(1:sect,1) = DFT(1:sect,1)./OCC(1:sect,1);
    
    h_sp = figure;
    DrawSectors(DFR, in_rad, ext_rad, bord_wid, 0, DFT, turn_bord);
    saveas(h_sp, sprintf('%s\\%s_df_maps\\%s_df_map_%d.tif', path2, filename1, filename2, j-1), 'tif');
    delete(h_sp);    
end

delete(w);