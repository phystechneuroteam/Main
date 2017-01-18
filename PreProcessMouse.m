function P = PreProcessMouse(varargin)
%vararg = {'ParamFile','D:\Projects\CA1_13\CA1_13_sync.xls'};
%narg =2;
%---------------------READING KEYSTRING ARGUMENTS--------------------------
%Arguments extracting: arguments must be paired 'name','value'
if mod(nargin, 2)
    error('Invalid arguments');
end
for i = 1:nargin/2
    arg_names{i} = varargin{i*2 - 1};
    arg_values{i} = varargin{i*2};
end
if nargin
    P = ParamFromCell(arg_names, arg_values);
else 
    P = struct;
end

%-------------------------READING PARAM FILE-------------------------------
%if there is ParamFile argument, extract parameters from it; only missing
%parameters will be extracted
for i = 1:nargin/2
    if strcmp(arg_names{i},'ParamFile')
        P.ParamFile = arg_values{i};
        params = readtable(arg_values{i},'ReadVariableNames', false);
        P = ParamFromCell(params{:,1}, params{:,2}, P);
        break;
    end
end

%--------------------------MANUAL SELECTION--------------------------------
%if there still are missing parameters, user has to define it manually
%manual path and files selection
if ~isfield(P, 'Path') || ~isfield(P, 'Filenames')
    [filename, P.Path] = uigetfile('*.tif','Select TIFF movies', 'MultiSelect', 'on');
    if iscell(filename) %if user selected more than one file
        P.Filenames = filename;
    elseif ischar(filename) %if user selected one file
        P.Filenames{1} = filename;
    end
    
end
%Set default trim parameters; if they are already specified, 'remember' it
if isfield(P,'Trim')
    default_trim = sprintf('%d', P.Trim{1});
    for i = 2:length(P.Trim)
        default_trim = strcat(default_trim,sprintf(';%d', P.Trim{i})); 
    end
else
    default_trim = sprintf('1;%d', length(P.Filenames{1}));
    for i = 2:length(P.Filenames)
        default_trim = strcat(default_trim,sprintf(';1;%d', length(P.Filenames{i}))); 
    end
end
%Set default crop parameters; if they are already specified, 'remember' it
info = imfinfo(sprintf('%s%s',P.Path, P.Filenames{1}));
w = info.Width;
h = info.Height;
if isfield(P,'Crop')
    default_crop = sprintf('%d;%d;%d;%d',P.Crop{1},P.Crop{2},P.Crop{3},P.Crop{4});
else
    default_crop = sprintf('1;1;%d;%d',w,h);
end
%Manual parameter selection
if ~isfield(P,'Crop') || ~isfield(P,'Trim') || ~isfield(P,'Sbf') || ~isfield(P,'MC_roi') || ~isfield(P,'MC_crop')
    prompt = {'Spatial crop, px (left;top;right;bottom)', 'Temporal trim (start_frame( if 0 - skip trimming);end frame)','Spatial binning factor (0 - skip preprocessing, 1 - preprocess)','Motion correction (0/1/2 - skip/default roi/define roi)', 'Crop after motion correction (0-automatically)'}; 
    default_data = {default_crop, default_trim, '1', '1', '20'};
    options.Resize='on';
    data = inputdlg(prompt, 'Parameters', 1, default_data, options);
    P = ParamFromCell({'Crop','Trim','Sbf','MC_roi','MC_crop'}, data, P);
else
    data = {default_crop, default_trim, sprintf('%d',P.Sbf), sprintf('%d',P.MC_roi), sprintf('%d',P.MC_crop)};
end

%------------------------WRITING PARAMETERS TO FILE------------------------

%If there is still no parameter file, create it
if ~isfield(P, 'ParamFile')
    P.ParamFile = sprintf('%s%s.csv',P.Path,P.Filenames{1});
end
%Write path, filenames and other parameters in ParamFile
all_files = sprintf('%s', P.Filenames{1});
for i = 2:length(P.Filenames)
    all_files = strcat(all_files,sprintf(';%s', P.Filenames{i})); 
end
Param2File({'Path','Filenames'}, {P.Path, all_files}, P.ParamFile);
%change Param File extension to .csv after first writing to it
P.ParamFile = sprintf('%s.csv',P.ParamFile(1:length(P.ParamFile)-4));
Param2File({'Crop','Trim','Sbf','MC_roi','MC_crop'}, data, P.ParamFile);

%------------------------MAIN BLOCK (REQUIRES MOSAIC!!!)-------------------
%Additional parameters asessing
if P.Sbf
    sp_bin = P.Sbf;
else
    sp_bin = 1;
end
width = (P.Crop{3} - P.Crop{1} + 1)/sp_bin;
height = (P.Crop{4} - P.Crop{2} + 1)/sp_bin;
%Initial cropping parameters after motion correction
MCC.left = P.MC_crop;
MCC.top = P.MC_crop;
MCC.right = P.MC_crop;
MCC.bottom = P.MC_crop;

mosaic.initialize();

for i = 1:length(P.Filenames)
    
    %Loading, cropping and preprocessing
    fname = P.Filenames{i};
    movie = mosaic.loadMovieTiff(sprintf('%s%s', P.Path, fname));
    movie = mosaic.cropMovie(movie, P.Crop{1}, P.Crop{2}, P.Crop{3}, P.Crop{4});
    if P.Sbf %Sbf = 1 <=> preprocess without downsampling, Sbf = 0 <=> skip preprocessing
        movie = mosaic.preprocessMovie(movie, 'spatialDownsampleFactor', sp_bin);
    end
    
    %Trimming movie
    if i > 1              %at first iteration info already exists, see line 55
        info = imfinfo(sprintf('%s%s',P.Path, P.Filenames{i}));
    end
    if P.Trim{i*2-1} ~= 1 || P.Trim{i*2} ~= length(info) %Trim if it is needed
        movie = mosaic.trimMovie(movie, P.Trim{i*2-1}, P.Trim{i*2});
    end
    
    %Motion correction
    if P.MC_roi 
        if i==1 
            if isfield(P, 'RefFrame')   %getting target image
                targ = mosaic.loadImage(P.RefFrame);
            else                        %default target image is meanframe of first movie
                targ = mosaic.projectMovie(movie, 'projectionType', 'Mean'); 
            end
            %reference region setting
            pointList = mosaic.List('mosaic.Point'); %vertices of default octagonal roi
            pointList.add(mosaic.Point(width*0.05, height*0.3));
            pointList.add(mosaic.Point(width*0.3, height*0.05));
            pointList.add(mosaic.Point(width*0.7, height*0.05));
            pointList.add(mosaic.Point(width*0.95, height*0.3));
            pointList.add(mosaic.Point(width*0.95, height*0.7));
            pointList.add(mosaic.Point(width*0.7, height*0.95));
            pointList.add(mosaic.Point(width*0.3, height*0.95));
            pointList.add(mosaic.Point(width*0.05, height*0.7));
            roi = mosaic.PolygonRoi(pointList);
            if P.MC_roi == 2               %if user wishes to determine it manually
                roi.edit(movie);
            end
        end
        %Finally, motion correction
        [movie, motion] = mosaic.motionCorrectMovie(movie, 'referenceImage', targ, 'roi', roi,'subtractSpatialMean', true, 'invertImage', true, 'autoCrop', false);
        %Crop after MC
        if ~P.MC_crop %get parameters of auto-cropping             
            %translation motion traces of motion correction:
            list = motion.getList('types', {'mosaic.Trace'});
            trace_x = list.get(2);
            trace_y = list.get(1);
            X = trace_x.getData();
            Y = trace_y.getData();
            %get maximal
            if round(max(X))+1 > MCC.left 
                MCC.left = round(max(X))+1;
            end
            if round(max(Y))+1 > MCC.top
                MCC.top = round(max(Y))+1;
            end
            if round(abs(min(X)))+1 > MCC.right && min(X) < 0
                MCC.right = round(abs(min(X)))+1;
            end
            if round(abs(min(Y)))+1 > MCC.bottom && min(Y) < 0
                MCC.bottom = round(abs(min(Y)))+1;
            end
            mosaic.saveMovieTiff(movie, sprintf('%s%s_temp.tif', P.Path, fname(1:length(fname)-4)));
        else
            movie = mosaic.cropMovie(movie, P.MC_crop + 1, P.MC_crop + 1, width - P.MC_crop, height - P.MC_crop);
            mosaic.saveMovieTiff(movie, sprintf('%s%s_corrected.tif', P.Path, fname(1:length(fname)-4)));
        end
        
    end
end

%Final crop if default MC is chosen
if ~P.MC_crop
    for i = 1:length(P.Filenames)
        fname = P.Filenames{i};
        movie = mosaic.loadMovieTiff(sprintf('%s%s_temp.tif', P.Path, fname(1:length(fname)-4)));
        movie = mosaic.cropMovie(movie, 1 + MCC.left, 1 + MCC.top, width - MCC.right, height - MCC.bottom);
        mosaic.saveMovieTiff(movie, sprintf('%s%s_corrected.tif', P.Path, fname(1:length(fname)-4)));
        delete(sprintf('%s%s_temp.tif', P.Path, fname(1:length(fname)-4)));
    end
end

mosaic.terminate();
%------------------------------FINAL PARAMS WRITING------------------------

fname = P.Filenames{1};
all_files = sprintf('%s_corrected.tif', fname(1:length(fname)-4));
for i = 2:length(P.Filenames)
    fname = P.Filenames{i};
    all_files = strcat(all_files,sprintf(';%s_corrected.tif', fname(1:length(fname)-4))); 
end
if P.MC_crop
    fincrop = sprintf('%d;%d;%d;%d',P.MC_crop + 1, P.MC_crop + 1, width - P.MC_crop, height - P.MC_crop);
else
    fincrop = sprintf('%d;%d;%d;%d',1 + MCC.left, 1 + MCC.top, width - MCC.right, height - MCC.bottom);
end
Param2File({'MC_fincrop','Corrected'}, {fincrop, all_files}, P.ParamFile);
end    