function SeparateFilters(path, filename)
%Crops all overlapping filters in 'path' directory, i.e. makes them separate
%Separated filers are written in subfolder 'separated'

if nargin < 2
    [filename, path] = uigetfile('*.tif','Select TIFF image','K:\CA1\CA1_7\filters_500\CA1_7_refined1\filter_1.tif');
end

%Subfolder creation
if isdir(sprintf('%s\\separated', path))
    rmdir(sprintf('%s\\separated', path), 's');
end
[s, ~, ~] = mkdir(path,'separated');
while ~s
   [s, ~, ~] = mkdir(path,'separated');
end
%File reading
files = dir(sprintf('%s\\*.tif',path));
number_of_filters = length(files);

%Initialization
info = imfinfo(sprintf('%s%s', path, filename));
width = info.Width;
height = info.Height;
merged = zeros(height, width,'double');

h_wtb = waitbar(1/number_of_filters, sprintf('Separating filter %d of %d', 0,  number_of_filters)); 

for n_filter = 1:number_of_filters
    
    h_wtb = waitbar(n_filter/number_of_filters, h_wtb, sprintf('Separating filter %d of %d', n_filter,  number_of_filters)); 
    
    filter = double(imread(sprintf('%s%s', path, files(n_filter).name)));
    max_im = max(max(filter));
    filter = filter./max_im;
    
    %define roi borders
    feats = regionprops(logical(filter), 'Extrema');
    Ext = feats(1).Extrema;
    minh = max(fix(Ext(1,2)), 1);
    maxh = min(fix(Ext(5,2))+1, height);
    minw = max(fix(Ext(7,1)), 1);
    maxw = min(fix(Ext(3,1))+1, width);
    
    %remove overlapping parts
    for h = minh:maxh
        for w = minw:maxw
            if filter(h,w) && merged(h,w)
                if merged(h,w) > filter(h,w)
                    filter(h,w) = 0;
                else
                    merged(h,w) = 0;
                end
            end
        end
    end
    
    %border cropping
    d_filter = bwdist(~filter);
    for h = minh:maxh
        for w = minw:maxw
            if d_filter(h,w) < 1.5
                filter(h,w) = 0;
            end
            %adding cropped filter to merged
            if filter(h,w) 
                merged(h,w) = filter(h,w);
            end
        end
    end
end

%Separating merged into filters, num should be equal to initial n_filters
[L, num] = bwlabel(merged);
for i = 1:num
    h_wtb = waitbar(i/num, h_wtb, sprintf('Writing filter %d of %d', i,  num)); 
    IM = L == i;
    filter = double(IM).*merged;
    maxim = max(max(filter));
    imwrite(filter./maxim, sprintf('%s\\separated\\filter_%d.tif',path,i)); 
end
figure, imshow(merged);    
delete(h_wtb);
end