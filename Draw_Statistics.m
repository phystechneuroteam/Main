function numspikes = Draw_Statistics (redraw)

%Reads traces from csv files and plot them on the same figure, coloring them
%using "colornum" routine; user can define offset between traces at the
%Y-axis (in %DF/F) and parameters of periodical gray shadings on the plot at the X
%axis

[filename, path] = uigetfile('*.csv','Select CSV file with traces:', 'C:\YTNC_GC_csv\df_recording_20160915_130942_corrected.tif_neuropil_40.csv_medlowpassed_5.000000e-01_60.csv');

if nargin < 1
    redraw = 0;
end

T = readtable(sprintf('%s%s',path,filename));
dim = size(T);
X = T{1:dim(1),1};
AV = zeros(dim(1), 1);

maxim = max(max(T{1:dim(1),2:dim(2)}));
minim = min(min(T{1:dim(1),2:dim(2)}));
absmax = max(abs(maxim), abs(minim));


if redraw
    figure;
end

%main plots drawing
w = waitbar(0, sprintf('Plotting trace %d of %d', 1,  dim(2)-1));
hold on;
for i = 2:dim(2)
    waitbar((i-1)/(dim(2)-1), w, sprintf('Processing spike %d of %d', i-1,  dim(2)-1));
    plot(X, T{1:dim(1),i}/absmax, 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
    AV = AV + T{1:dim(1),i};
end
delete(w);
numspikes = dim(2) - 1;
AV = AV./numspikes;
plot(X, AV/absmax, 'Color', [0 1 1], 'LineWidth', 2);
end
