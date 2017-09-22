function GetMeanFrame(path, filename)
%saves first frame of given multipage .tif file
if nargin <2
    [filename, path] = uigetfile('*.tif','Select multipage .tif file','I:\tralivali.tif');
end

frame = imread(strcat(path, filename), 1);
for i = 2:100
    framenew = imread(strcat(path, filename), i);
    frame = frame + framenew;
end
imwrite(round(frame./100), strcat(path, filename(1:10),'_meanframe.tif'));

end