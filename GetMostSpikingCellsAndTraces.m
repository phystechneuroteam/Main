function p = GetMostSpikingCellsAndTraces(n, sp_mode, tr_path, tr_filename, backg_image, fil_path)
%Sorts traces taken from .csv file %tr_filename by decrease of number of spikes (taken from .csv file spikes_%tr_filename).
%Shows %n of them with corresponding .tif filters, taken from folder %fil_path, and layered on .tif file %bckg_image of the same size
%with filters. Images are to be saved into the folder with filters (%fil_path).

%Defining missing arguments
if nargin < 6 
    [tr_filename, tr_path] = uigetfile('*.csv','Select .csv file with traces','C:\YTNC_GC_csv\test_1_1\tralivali.csv');
    [filename0, path0] = uigetfile('*.tif','Select .tif file with background image','C:\YTNC_GC_csv\test_1_1\tralivali.tif');
    backg_image = strcat(path0, filename0);
    [~, fil_path] = uigetfile('*.tif','Select any .tif file with filter in folder with filters only','C:\YTNC_GC_csv\test_1_1\tralivali.tif');
end
if nargin <2 || isempty(n) || isempty (sp_mode)
    prompt = {'Number of output traces', 'Draw spikes (0/1 - no/yes)'}; 
    default_data = {'10', '0'};
    options.Resize='on';
    dlg_data = inputdlg(prompt, 'Parameters', 1, default_data, options);

    n = str2num(dlg_data{1});
    sp_mode = str2num(dlg_data{2});
end

%Reading, counting and sorting spikes
S = readtable(strcat(tr_path,'spikes_',tr_filename));
dim = size(S);
p = zeros(dim(2)-1, 2);

for i = 1:dim(2)-1
    p(i, 1) = i;
    p(i, 2) = nnz(S{1:dim(1),i+1});
end
p = sortrows(p,-2);
n = min(n, dim(2)-1);

DrawContourMap(p(1:n, 1), backg_image, fil_path, 0);
Traceviewer_few_new(p(1:n, 1), tr_path, tr_filename, sp_mode);

end