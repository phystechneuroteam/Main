function CsvCombiner_ang (step, path, filename)
%Combines given .csv files (should be listed as {'filename1', filename2',
%filename3',..} into one .csv file
if nargin < 3 || isempty (path) || isempty (filename)
    [filename, path] = uigetfile('*.csv','Select CSV files to concatenate:', 'MultiSelect', 'on');
end
if nargin < 1
    step = 0.05;
end

numfiles = size(filename);
numstr = 0;
for f = 1:numfiles(2)
    T = readtable(sprintf('%s%s',path,filename{f}));
    dim = size(T);
    numstr = numstr + dim(1);
end

TNEW = zeros(numstr + 1, dim(2));
TNEW(2:numstr+1, 1) = (1:numstr).*step;
m = 2;
h = waitbar(0, sprintf('Processing file %d of %d', 0,  numfiles(2))); 

for f = 1:numfiles(2)
    waitbar(f/numfiles(2), h, sprintf('Processing file %d of %d', f,  numfiles(2)));
    T = readtable(sprintf('%s%s',path,filename{f}));
    dim = size(T);
    if f ==1 
        ang = 18;
    else
        ang = 10;
    end
    TNEW(m:m+dim(1)-1,2:dim(2)) = T{1:dim(1),2:dim(2)} - ang;
    m = m + dim(1);
end

csvwrite(sprintf('%s%s_conc.csv',path,filename{1}), TNEW);
delete(h);