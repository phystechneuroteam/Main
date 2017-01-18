function P = PcaIcaMouse(varargin)

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
if ~isfield(P, 'Path') || ~isfield(P, 'Corrected')
    [filename, P.Path] = uigetfile('*.tif','Select TIFF movies', 'MultiSelect', 'on');
    if iscell(filename) %if user selected more than one file
        P.Corrected = filename;
    elseif ischar(filename) %if user selected one file
        P.Corrected{1} = filename;
    end
end

%Manual parameter selection
if ~isfield(P,'Tbf') || ~isfield(P,'IC_num')
    prompt = {'Temporal binning factor (for PCA/ICA only)', 'Number of ICs (estimate of cell number)'}; 
    default_data = {'5','300'};
    options.Resize='on';
    data = inputdlg(prompt, 'Parameters', 1, default_data, options);
    P = ParamFromCell({'Tbf','IC_num'}, data, P);
else
    data = {sprintf('%d',P.Tbf), sprintf('%d',P.IC_num)};
end

%------------------------WRITING PARAMETERS TO FILE------------------------

%If there is still no parameter file, create it
if ~isfield(P, 'ParamFile')
    P.ParamFile = sprintf('%s%s.csv',P.Path,P.Corrected{1});
end
%Write path, filenames and other parameters in ParamFile
all_files = sprintf('%s', P.Corrected{1});
for i = 2:length(P.Corrected)
    all_files = strcat(all_files,sprintf(';%s', P.Corrected{i})); 
end
Param2File({'Path','Corrected'}, {P.Path, all_files}, P.ParamFile);
%change Param File extension to .csv after first writing to it
P.ParamFile = sprintf('%s.csv',P.ParamFile(1:length(P.ParamFile)-4));
Param2File({'Tbf','IC_num'}, data, P.ParamFile);

%------------------------OUTPUT FOLDER CREATION----------------------------

if isdir(sprintf('%s\\filters_%d', P.Path, P.IC_num))
    rmdir(sprintf('%s\\filters_%d', P.Path, P.IC_num), 's');
end
[s, ~, ~] = mkdir(P.Path, sprintf('filters_%d', P.IC_num));
while ~s
   [s, ~, ~] = mkdir(P.Path,sprintf('filters_%d', P.IC_num));
end

%------------------------MAIN BLOCK (REQUIRES MOSAIC!!!)-------------------    

mosaic.initialize();

%loading, temporal binning and concatenetion of movies
movie = mosaic.loadMovieTiff(sprintf('%s%s', P.Path, P.Corrected{1}));
if P.Tbf > 1 
    movie = mosaic.resampleMovie(movie, 'spatialReduction',1,'temporalReduction', P.Tbf);
end

for i = 2:length(P.Corrected)
    movie1 = mosaic.loadMovieTiff(sprintf('%s%s', P.Path, P.Corrected{i}));
    if P.Tbf > 1 
        movie1 = mosaic.resampleMovie(movie1, 'spatialReduction',1,'temporalReduction', P.Tbf);
    end
    movieList = mosaic.List('mosaic.Movie', {movie, movie1});
    movie = mosaic.concatenateMovies(movieList, 'gapType', 'Add fixed value between movies', 'gapTime', 0);
end
clear('movie1');
%applying DF/F to concatenated movie
movie = mosaic.normalizeMovie(movie);
mosaic.saveMovieTiff(movie, sprintf('%sdf_bb%d_whole_mouse.tif',P.Path, P.Tbf), 'largeMovieOption','BigTIFF'); 
%analysis performing
icGroups = mosaic.pcaIca(movie, 'numPCs', round(P.IC_num*1.2), 'numICs', P.IC_num, 'unmix', 'both');
%saving objects
mosaic.saveOneObject(icGroups, sprintf('%sicGroups_df_bb%d_whole_mouse_%d.mat', P.Path, P.Tbf, P.IC_num));
%writing filters
groupIt = mosaic.GroupIterator(icGroups, 'types', {'mosaic.Image'});
i =  1; %filter counter
while groupIt.hasNext()
    image = groupIt.next();
    image = mosaic.applyThresholdToImage(image, 'threshold', 0.5);
    mosaic.saveImageTiff(image, sprintf('%s\\filters_%d\\filter_%d.tif', P.Path, P.IC_num, i));
    i = i + 1;
end 
mosaic.terminate();
Param2File({'Filters'}, {sprintf('%s\\filters_%d\\', P.Path, P.IC_num)}, P.ParamFile);
end