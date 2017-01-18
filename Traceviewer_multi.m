%Reads traces from csv files and plot them on the same figure, coloring them
%using "colornum" routine; user can define offset between traces at the
%Y-axis (in %DF/F) and parameters of periodical gray shadings on the plot at the X
%axis

[filename0, path] = uigetfile('*.csv','Select CSV files with traces:', 'MultiSelect', 'on');
numfiles0 = size(filename0);

if ischar(filename0)
    filename{1} = sprintf('%s',filename0);
    numfiles = 1;
elseif iscell(filename0)
    numfiles = numfiles0(2);
    for f = 1:numfiles
        filename{f} = sprintf('%s',filename0{f});
    end
end
  
prompt = {'Offset between traces (1 = maximum):', 'Normalization value (0 - absolute maximum)', 'Line width, px', 'Redraw figure (0/1 -no/yes)', 'Spike depicting mode (0/1 - do not draw/load .csv)'}; 
default_data = {'0.7','0','1','0','1'};
options.Resize='on';
dlg_data = inputdlg(prompt, 'Parameters', 1, default_data, options);

offset = str2double(dlg_data{1});
absmax = str2double(dlg_data{2});
line_width = str2double(dlg_data{3});
redraw = str2num(dlg_data{4});
sp_mode= str2num(dlg_data{5});

if sp_mode
    [filename2, path2] = uigetfile('*.csv','Select CSV file with traces:', sprintf('%sspikes_%s',path,filename{1}));
    SPIKES = readtable(sprintf('%s%s',path2,filename2));
end

if redraw
    figure;
end

if ~absmax
    for f = 1:numfiles
        T = readtable(sprintf('%s%s',path,filename{f}));
        dim = size(T);
       
        maxim = max(max(T{1:dim(1),2:dim(2)}));
        minim = min(min(T{1:dim(1),2:dim(2)}));
        absmax = max(max(abs(maxim), abs(minim)), absmax);
    end
end


%main plots drawing
for f = 1:numfiles
    w = waitbar(0, sprintf('Plotting trace %d of %d of file %s', 1,  dim(2)-1, filename{f}));
    
    T = readtable(sprintf('%s%s',path,filename{f}));
    dim = size(T);
    X = T{1:dim(1),1};
    
    hold on;
    for i = 2:dim(2)
        waitbar((i-1)/(dim(2)-1), w, sprintf('Processing cell %d of %d', i-1,  dim(2)-1));
        plot(X, T{1:dim(1),i}/absmax + offset*(i-2), 'Color', colornum(i-1), 'LineWidth', line_width);
    end
    delete(w);
end

%spikes drawing
w = waitbar(0, sprintf('Drawing spikes: trace %d of %d', 1,  dim(2)-1));
if sp_mode ~= 0
    for i = 2:dim(2)
        waitbar((i-1)/(dim(2)-1), w, sprintf('Processing cell %d of %d', i-1,  dim(2)-1));
        for j = 1:dim(1)
            if SPIKES {j,i}
                sp_ampl = SPIKES {j,i}/absmax;
                patch([X(j)-0.3, X(j), X(j)+0.3, X(j)], [offset*(i-1.8) + sp_ampl, offset*(i-1.65) + sp_ampl, offset*(i-1.8) + sp_ampl, offset*(i-1.95) + sp_ampl], colornum(i-1), 'EdgeColor', 'none');
            end
        end
    end
end
delete(w);

