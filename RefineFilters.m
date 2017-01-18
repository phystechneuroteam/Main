function m = RefineFilters(path, ssigm, ssquare, bsquare, scirc, bcirc, overlap)
%Refines filters in the given folder (should be of the same size). Overlapping 
%more than on [overl] ratio filters, and filters with square and circularity which exceed  
%the limits will be discarded. Ssigm - parameter of
%pre-filtering, bsquare, ssquare - limits of square (e.g. non-zero pixels),
%circ - lowest circularity.
%Returns number of proper filters which are written into folder ../refined.

%Defining missing arguments
if nargin < 1 
    [filename, path] = uigetfile('*.tif','Select TIFF image','C:\Current\Fedor1s-1\image0000.tif');
end
if nargin < 7 || isempty (ssigm) || isempty (ssquare) || isempty (bsquare) || isempty(scirc) || isempty(bcirc) || isempty (overlap)
    prompt = {'Small sigma (0 - adaptive, -1 - skip):', 'Smallest filter square, px', 'Biggest filter square, px', 'Minimal circularity for smallest filter(1.0 for circle)', 'Minimal circularity for bigest filter', 'Maximal overlapping ratio'}; 
    default_data = {'0','64','1300','0.9','0.7','0.2'};
    options.Resize='on';
    dlg_data = inputdlg(prompt, 'Parameters', 1, default_data, options);

    ssigm = str2double(dlg_data{1});
    ssquare = str2num(dlg_data{2});
    bsquare = str2num(dlg_data{3});
    scirc = str2num(dlg_data{4});
    bcirc = str2num(dlg_data{5});
    overlap = str2double(dlg_data{6});
end

%Creating folder for writing filters into it, if such folder exist, it will
%be deleted and created again
if isdir(sprintf('%s\\refined', path))
    rmdir(sprintf('%s\\refined', path), 's');
end
[s, ~, ~] = mkdir(path,'refined');
while ~s
   [s, ~, ~] = mkdir(path,'refined');
end

%Getting files
files = dir(sprintf('%s\\*.tif',path));
n_files = length(files);

%Sorting files by their square
for f = 1:n_files 
    IM = double(imread(sprintf('%s%s', path, files(f).name)));
    files_sq(f) = setfield(files(f), 'square', nnz(IM)); 
end
FILES = struct2table(files_sq);
FILES = sortrows(FILES, 'square');
files_sq = table2struct(FILES);

%Creating waitbar
h = waitbar(1/n_files, sprintf('Writing filter %d of %d', 0,  n_files)); 
m = 0; %number of refined filters

info = imfinfo(sprintf('%s%s', path, files_sq(1).name));
width = info.Width;
height = info.Height;
SUM_IM = zeros(height, width, 'double');

for f = 1:n_files
    h = waitbar(f/n_files, h, sprintf('Processing filter %d of %d', f,  n_files));
    %Reading image
    IM = double(imread(sprintf('%s%s', path, files_sq(f).name)));
    sq = nnz(IM);
    
    if sq > bsquare || circularity(IM) < (bcirc - scirc)*(sq-ssquare)/(bsquare-ssquare) + scirc
        continue
    end

    %Shading correction, smoothing and segmenting filter into parts
    if ssigm == -1
        L = bwlabel(IM);
    else
        %Estimate of cell size
        bsigm = max(max(bwdist(~IM)))*2;
        if ~ssigm
            ssigm = bsigm/5;
        end
        BG = single(IM) - conv2(single(IM), single(gaussian2d(1000,bsigm)), 'same'); %shading correction
        SG = conv2(BG, single(gaussian2d(1000,ssigm)), 'same'); %smoothing
        WS = watershed(1 - Norm(SG));
        L = bwlabel(DrawWS(IM, WS));
    end
    n_segments = max(max(L));

    %Writing properly sized filters

    for n = 1:n_segments
        BG = L == n;
        SG = double(BG).*IM;
        maxim = max(max(SG));
        if nnz(SG) < ssquare || overlap_is(SUM_IM, SG, overlap)
            continue
        end
        m = m + 1;
        SUM_IM = SUM_IM + SG;
        imwrite(SG./maxim, sprintf('%s\\refined\\filter_%d.tif',path,m));
    end
end
delete(h);
end


