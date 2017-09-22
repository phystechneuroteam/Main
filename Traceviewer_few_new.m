function Traceviewer_few_new(numbers, path, filename, sp_mode)
%Reads traces from csv files and plot them on the same figure, coloring them
%using "colornum" routine; user can define offset between traces at the
%Y-axis (in %DF/F) and parameters of periodical gray shadings on the plot at the X
%axis

T = readtable(strcat(path, filename));
if sp_mode
    SPIKES = readtable(strcat(path,'spikes_',filename));
end
dim = size(T);
X = T{1:dim(1),1};
n = length(numbers);

maxim = max(max(T{1:dim(1),2:dim(2)}));
minim = min(min(T{1:dim(1),2:dim(2)}));
offset = 0.7;

figure; hold on;
for i = 1:n
    plot(X, (T{1:dim(1),numbers(i)+1}-minim)/(maxim-minim) + offset*(i-1), 'Color', colornum(i), 'LineWidth', 2);
    if sp_mode
       for j = 1:dim(1)
            if SPIKES {j,numbers(i)+1}
                patch([X(j)-1, X(j), X(j)+1, X(j)], [offset*(i+0.1), offset*i, offset*(i+0.1), offset*(i+0.2)], colornum(i), 'EdgeColor', 'none');
            end
        end
     end
end

