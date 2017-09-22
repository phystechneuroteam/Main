function GetFirstFrame(path, filename)
%saves first frame of given multipage .tif file
if nargin <2
    [filename, path] = uigetfile('*.tif','Select multipage .tif file','I:\tralivali.tif');
end

frame = imread(strcat(path, filename), 1);

imwrite(frame, strcat(path, filename(1:10),'_firstframe.tif'));

end
