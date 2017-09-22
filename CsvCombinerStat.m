function CsvCombinerStat (step, path, filename)
%Combines given .csv files (should be listed as {'filename1', filename2',
%filename3',..} into one .csv file; adds new traces of the same length.
if nargin < 3 || isempty (path) || isempty (filename)
    [filename, path] = uigetfile('*.csv','Select CSV files to concatenate:', 'MultiSelect', 'on', 'C:\YTNC_GC_csv\test_1_1');
end
if nargin < 1
    step = 0.05;
end

numfiles = size(filename);
numcol = 1;
fout = strcat(path,'comb');

for f = 1:numfiles(2)
    T = readtable(strcat(path,filename{f}));
    dim = size(T);
    numcol = numcol + dim(2) - 1;
    fout = strcat(fout,'__',filename{f}(1:14));
end

fout = strcat(fout,'.csv');


TNEW = zeros(dim(1), numcol);
TNEW(1:dim(1),1) = (1:dim(1)).*step;
m = 2;

h = waitbar(0, sprintf('Processing file %d of %d', 0,  numfiles(2))); 

for f = 1:numfiles(2)
    waitbar(f/numfiles(2), h, sprintf('Processing file %d of %d', f,  numfiles(2)));
    T = readtable(sprintf('%s%s',path,filename{f}));
    dim = size(T);
    TNEW(1:dim(1), m: m + dim(2)-2) = T{1:dim(1),2:dim(2)};
    m = m + dim(2)-1;
end

csvwrite(fout, TNEW);
delete(h);