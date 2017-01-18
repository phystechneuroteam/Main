function NeuropilCorrect_fx(filename, fil_path, r_neur, neur_coeff, fps)
%Extracts trace from given filters, then substracts mean signal from circle
%of radius r_neur (in pixels), other cells are excluded.

if nargin < 5 || isempty(fps)
    fps = 20;
end
if nargin < 4 || isempty(neur_coeff)
    neur_coeff = 1.0;
end
if nargin < 3 || isempty(r_neur)
    r_neur = 30;
end

info = imfinfo(sprintf('%s',filename));
width = info.Width;
height = info.Height;
length1 = size(info);
length = length1(1);

files = dir(sprintf('%s\\*.tif',fil_path));
dim = size(files);
numfiles = dim(1);

filters = zeros(numfiles, height, width, 'double');
sum_filter = zeros(height, width, 'double');
centers = zeros(numfiles,3);
TR = zeros(length+1, numfiles+1);
TR(2:length+1, 1) = double((1:length))/fps;

for i = 1:numfiles
    frame = double(imread(sprintf('%s%s',fil_path, files(i).name)));
    [max_x, n_maxx] = max(frame);
    [max_y, n_maxy] = max(max_x);
    centers(i,1) = n_maxx(n_maxy);
    centers(i,2) = n_maxy;
    filters(i,:,:) = frame(:,:)/max_y;
    
    for x = max(1, centers(i,1)-r_neur):min(height, centers(i,1)+r_neur)
        for y = max(1, centers(i,2)-r_neur):min(width, centers(i,2)+r_neur)
            sum_filter(x,y) = double(sum_filter(x,y) + filters(i,x,y)); 
        end
    end      
end

h = waitbar(0, sprintf('Processing frame %d of %d', 0,  length)); 

for n_fr=1:length
    waitbar(n_fr/length, h, sprintf('Processing frame %d of %d', n_fr,  length));
    frame = double(imread(sprintf('%s', filename), n_fr));
    for i = 1:numfiles
        aver_neur = 0.0;
        n_neur = 0;
        n_filter = 0;
        for x = max(1, centers(i,1)-r_neur):min(height, centers(i,1)+r_neur)
            for y = max(1, centers(i,2)-r_neur):min(width, centers(i,2)+r_neur)
                if filters(i,x,y)
                    TR(n_fr+1, i+1) = TR(n_fr+1, i+1) + frame(x,y)*filters(i,x,y);
                    n_filter = n_filter + filters(i,x,y);
                elseif ((x-centers(i,1))^2 + (y-centers(i,2))^2)^0.5 < r_neur && sum_filter(x,y) == 0
                    aver_neur = aver_neur + frame(x,y);
                    n_neur = n_neur + 1;
                end
            end
        end
        aver_neur = aver_neur/n_neur;
        TR(n_fr+1, i+1) = TR(n_fr+1, i+1)/n_filter - neur_coeff*aver_neur;
    end
end

csvwrite(sprintf('%s_neuropil_%d.csv',filename,r_neur), TR);
delete(h);
end