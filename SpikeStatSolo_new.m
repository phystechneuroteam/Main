function [spikes, mampl, dampl,msnr, dsnr, mtoff, dtoff, mtrise, dtrise] = SpikeStatSolo_new(fps, n_rand, path, filename, path_fit, filename_fit)
%Returns statistics from .csv file with solo spikes;
%n_rand - number of randomly selected spikes; if 0 - all spikes are taken

if nargin < 6 || isempty (filename) || isempty(path)
    [filename, path] = uigetfile('*.csv','Select CSV file with solo spikes:');
    [filename_fit, path_fit] = uigetfile('*.csv','Select CSV file with solo fits:');
end

T = readtable(strcat(path,filename));
T_fit = readtable(strcat(path_fit,filename_fit));
dim = size(T_fit);
X = T{1:dim(1),1};
AV = zeros(dim(1), 1);

ampl = zeros(dim(2)-1, 1, 'double');
tau_off = zeros(dim(2)-1, 1, 'double');
tau_rise = zeros(dim(2)-1, 1, 'double');
snr = zeros(dim(2)-1, 1, 'double');

if n_rand
    p = randperm(n_rand);
else
    p = 1:dim(2)-1;
    n_rand = dim(2)-1;
end

h = waitbar(0, sprintf('Processing spike %d of %d', 0,  dim(2)-1)); 
figure, hold on;

for i = 1:n_rand
    waitbar(i/n_rand, h, sprintf('Processing spike %d of %d', i,  n_rand));
    
    bckg = T_fit{2,p(i)+1};

    [ampl(i), nampl] = max(T_fit{1:dim(1)-1,p(i)+1});
    ampl(i) = ampl(i) - bckg;
    
    for j = nampl:dim(1)-1
        if T_fit{j,p(i)+1} <= ampl(i)/2 + bckg
            break;
        end
        tau_off(i) = tau_off(i) + 1/fps;
    end 
    for j = 1:nampl
        if T_fit{nampl-j+1,p(i)+1} <= ampl(i)/2 + bckg
            break;
        end
        tau_rise(i) = tau_rise(i) + 1/fps;
    end
    noize = T{dim(1)+1,p(i)+1};
    snr(i) = ampl(i)/noize;
    
    plot(X, T{1:dim(1),p(i)+1}, 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
    AV = AV + T{1:dim(1),p(i)+1};
end

mampl = mean(ampl);
dampl = std(ampl);
msnr = mean(snr);
dsnr = std(snr);
mtoff = mean(tau_off);
dtoff = std(tau_off);
mtrise = mean(tau_rise);
dtrise = std(tau_rise);
spikes = n_rand;

AV = AV./spikes;
plot(X, AV, 'Color', [0 1 1], 'LineWidth', 3);

delete (h);
end