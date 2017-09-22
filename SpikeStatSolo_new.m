function [spikes, mampl, dampl,msnr, dsnr, mtoff, dtoff, mtrise, dtrise] = SpikeStatSolo_new(fps, t_noise, path, filename, path_fit, filename_fit)
%Returns statistics from .csv file with solo spikes;

if nargin < 6 || isempty (filename) || isempty(path)
    [filename, path] = uigetfile('*.csv','Select CSV file with solo spikes:');
    [filename_fit, path_fit] = uigetfile('*.csv','Select CSV file with solo fits:');
end

T = readtable(strcat(path,filename));
T_fit = readtable(strcat(path_fit,filename_fit));
dim = size(T_fit);

%spikes = dim(2)-2;
ampl = zeros(dim(2)-1, 1, 'double');
tau_off = zeros(dim(2)-1, 1, 'double');
tau_rise = zeros(dim(2)-1, 1, 'double');
snr = zeros(dim(2)-1, 1, 'double');

h = waitbar(0, sprintf('Processing spike %d of %d', 0,  dim(2)-1)); 

for i = 1:dim(2)-1
    waitbar(i/(dim(2)-1), h, sprintf('Processing spike %d of %d', i,  dim(2)-1));
    
    bckg = T_fit{1,i+1};

    [ampl(i), nampl] = max(T_fit{1:dim(1)-1,i+1});
    ampl(i) = ampl(i) - bckg;
    
    for j = nampl:dim(1)-1
        if T_fit{j,i+1} <= ampl(i)/2 + bckg
            break;
        end
        tau_off(i) = tau_off(i) + 1/fps;
    end 
    for j = 1:nampl
        if T_fit{nampl-j+1,i+1} <= ampl(i)/2 + bckg
            break;
        end
        tau_rise(i) = tau_rise(i) + 1/fps;
    end
    noize = T{dim(1)+1,i+1};
    snr(i) = ampl(i)/noize;
end

mampl = mean(ampl);
dampl = std(ampl);
msnr = mean(snr);
dsnr = std(snr);
mtoff = mean(tau_off);
dtoff = std(tau_off);
mtrise = mean(tau_rise);
dtrise = std(tau_rise);
spikes = dim(2)-1;

delete (h);
end