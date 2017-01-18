function NeuropilCorrectMouse(varargin)

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
%manual movie selection
if ~isfield(P, 'Path') ||~isfield(P, 'Concatenated')
    [filename, P.Path] = uigetfile('*.tif','Select concatenated movie', 'MultiSelect', 'on');
    if iscell(filename) %if user selected more than one file
        P.Concatenated = filename;
    elseif ischar(filename) %if user selected one file
        P.Concatenated{1} = filename;
    end
end
%manual filter selection
if ~isfield(P, 'Refined')
    [~, P.Refined] = uigetfile('*.tif','Select any file in folder with refined filters');
end

%Manual parameter selection
if ~isfield(P,'Neur_rad') || ~isfield(P,'Neur_coeff') || ~isfield(P,'Neur_df') || ~isfield(P,'Fps')
    prompt = {'Neuropil radius, px', 'Neuropil subtraction coefficient', 'Perform df/f (0/1 - no/yes)', 'Movie frame rate, fps'}; 
    default_data = {'30','1','1','20'};
    options.Resize='on';
    data = inputdlg(prompt, 'Parameters', 1, default_data, options);
    P = ParamFromCell({'Neur_rad','Neur_coeff', 'Neur_df', 'Fps'}, data, P);
else
    data = {sprintf('%d',P.Neur_rad), sprintf('%d',P.Neur_coeff), sprintf('%d',P.Neur_df), sprintf('%d',P.Fps)};
end

%------------------------WRITING PARAMETERS TO FILE------------------------

%If there is still no parameter file, create it
if ~isfield(P, 'ParamFile')
    P.ParamFile = sprintf('%s%s_Params.csv',P.Path, P.Concatenated{1}(1:length(P.Concatenated{1})-4));
end
%Write path, filenames and other parameters in ParamFile
all_files = sprintf('%s', P.Concatenated{1});
for i = 2:length(P.Concatenated)
    all_files = strcat(all_files,sprintf(';%s', P.Concatenated{i})); 
end
Param2File({'Path','Concatenated','Refined'}, {P.Path, all_files, P.Refined}, P.ParamFile);
Param2File({'Neur_rad','Neur_coeff', 'Neur_df', 'Fps'}, data, P.ParamFile);

%----------------------------MAIN BLOCK------------------------------------
for n_conc = 1:length(P.Concatenated)
    info = imfinfo(sprintf('%s%s',P.Path,P.Concatenated{n_conc}));
    width = info.Width;
    height = info.Height;
    length1 = size(info);
    num_frames = length1(1);

    %filters reading
    files = dir(sprintf('%s\\*.tif',P.Refined));
    dim = size(files);
    numfiles = dim(1);

    %arrays initializing
    filters = zeros(height, width, numfiles,  'double');
    sum_filter = zeros(height, width, 'double');
    meanframe = zeros(height, width, 'double');
    centers = zeros(numfiles,3);
    TR = zeros(num_frames+1, numfiles+1);
    TR(2:num_frames+1, 1) = double((1:num_frames))/P.Fps;

    %Calculating summary filter
    for i = 1:numfiles
        filter = double(imread(sprintf('%s%s',P.Refined, files(i).name)));
        %define maximum of the filter
        [max_x, n_maxx] = max(filter);
        [~, n_maxy] = max(max_x);
        centers(i,1) = n_maxx(n_maxy);
        centers(i,2) = n_maxy;
        %sum of filter
        sq = sum(sum(filter));
        % normalize filter and calculate summary filter
        filters(:,:,i) = filter./sq;
        sum_filter = sum_filter + filters(:,:,i); 
    end
    for i = 1:numfiles
        %add neuropil to filter matrix
        n_neuropil = 0; %number of neuropil pixels
        for h = max(1, centers(i,1)-P.Neur_rad):min(height, centers(i,1)+P.Neur_rad)
            for w = max(1, centers(i,2)-P.Neur_rad):min(width, centers(i,2)+P.Neur_rad)
                if ((h-centers(i,1))^2 + (w-centers(i,2))^2)^0.5 < P.Neur_rad && sum_filter(h,w) == 0
                    filters(h,w,i) = -1; 
                    n_neuropil = n_neuropil + 1;
                end
            end
        end 
        %normalizing neuropil pixels
        for h = max(1, centers(i,1)-P.Neur_rad):min(height, centers(i,1)+P.Neur_rad)
            for w = max(1, centers(i,2)-P.Neur_rad):min(width, centers(i,2)+P.Neur_rad)
                if filters(h,w,i) == -1
                    filters(h,w,i) = -P.Neur_coeff/n_neuropil; 
                end
            end
        end
    end
   
    %Calculating mean frame
    if P.Neur_df
        h_wtb = waitbar(0, sprintf('Calculating mean frame: frame %d of %d', 0,  num_frames)); 
        for n_fr=1:num_frames
            waitbar(n_fr/num_frames, h_wtb, sprintf('Calculating mean frame: frame %d of %d', n_fr,  num_frames));
            frame = double(imread(sprintf('%s%s',P.Path,P.Concatenated{n_conc}), n_fr));
            meanframe = meanframe + frame;
        end
        meanframe = meanframe./num_frames;
        delete(h_wtb);
    end
    
    %Neuropil correction plus df/f    
    h_wtb = waitbar(0, sprintf('Processing frame %d of %d', 0,  num_frames)); 
    for n_fr=1:num_frames
        waitbar(n_fr/num_frames, h_wtb, sprintf('Processing frame %d of %d', n_fr,  num_frames));
        frame = double(imread(sprintf('%s%s',P.Path,P.Concatenated{n_conc}), n_fr));
        %df/f correction
        if P.Neur_df
            frame = (frame - meanframe)./meanframe;
        end
        %neuropil correction
        for i = 1:numfiles
            TR(n_fr+1, i+1) = TR(n_fr+1, i+1) + sum(sum(frame.*filters(:,:,i)));
        end
    end
    P.RawTraces{n_conc} = sprintf('%s_neuropil_%d.csv',P.Concatenated{n_conc}(1:length(P.Concatenated{n_conc})-4),P.Neur_rad);
    csvwrite(sprintf('%s%s',P.Path,P.RawTraces{n_conc}), TR);
    delete(h_wtb);
end

%--------------------WRITE OUTPUT FILENAMES TO PARAMFILE-------------------
all_files = sprintf('%s', P.RawTraces{1});
for i = 2:length(P.RawTraces)
    all_files = strcat(all_files,sprintf(';%s', P.RawTraces{i})); 
end
Param2File({'RawTraces'}, {all_files}, P.ParamFile);

end