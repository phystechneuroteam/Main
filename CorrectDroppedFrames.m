function CorrectDroppedFrames(dropped, path, filename)
%Inserts linear interpolated frames on positions which are listed in dropped into movie 

if  nargin < 3 || isempty(filename) || isempty(path)
     [filename, path] = uigetfile('*.tif','Select TIFF movie', 'D:\Projects\CA1_5\recording_20160808_130246-001.tif');
end

%path = 'E:\CA_1\CA1_11\';
%filename = 'recording_20160929_180649_part2_100frames.tif';
%dropped = 10:110;


full_file_name = sprintf('%s%s', path, filename);
outputfile = sprintf('%s%s_aft.tif', path, filename);

n = size(dropped);
number_of_dropped = n(2);
n = size(imfinfo(full_file_name));
n_orig = n(1);

h = waitbar(0, sprintf('Processing frame %d of %d', 0,  n_orig + number_of_dropped)); 

imwrite(imread(full_file_name, 1), outputfile);

read = 1;
written = 1;
i = 1;

while i <= number_of_dropped
    while written < dropped(i)-1 && read < n_orig
        waitbar(written/(n_orig + number_of_dropped), h, sprintf('Processing frame %d of %d', written, n_orig + number_of_dropped));
        imwrite(imread(full_file_name, read + 1), outputfile, 'WriteMode', 'append');
        read = read + 1;
        written = written + 1;
    end

    l_of_dr = 1;
    while i + l_of_dr <= number_of_dropped && dropped(i+l_of_dr) == dropped(i+l_of_dr-1) + 1 
        l_of_dr = l_of_dr + 1;
    end

    for j = 1:l_of_dr 
        if read < n_orig
            first = double(imread(sprintf('%s%s', path, filename), read));
            last = double(imread(sprintf('%s%s', path, filename), read+1));
            new_frame = uint16(fix(first*double(1-j/(l_of_dr+1)) + last*double(j/(l_of_dr+1))));
            imwrite(new_frame, outputfile, 'WriteMode', 'append');
            written = written+1;
        elseif read == n_orig
            imwrite(imread(full_file_name, read), outputfile, 'WriteMode', 'append');
            written = written+1;
        end
    end
    i = i + l_of_dr;
end

while read < n_orig
        waitbar(written/(n_orig + number_of_dropped), h, sprintf('Processing frame %d of %d', written, n_orig + number_of_dropped));
        imwrite(imread(full_file_name, read + 1), outputfile, 'WriteMode', 'append');
        read = read + 1;
        written = written + 1;
end

delete(h);