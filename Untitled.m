%fname = {'CA1_6_20161116_121433_neuropil_60.csv', 'CA1_12_20161110_113448_neuropil_60.csv','CA1_13_20161110_121122_neuropil_60.csv', 'CA1_15_20161110_123813_neuropil_60.csv', 'GCaMP6s.csv'};
fname = {'GCaMP6f.csv', 'YTNC.csv', 'GCaMP6s.csv'};
path = 'C:\YTNC_GC_csv\1_1_Neuropil_60\';

for i = 1:length(fname)
    [spikes(i), mampl(i), dampl(i), msnr(i), dsnr(i), mtoff(i), dtoff(i), mtrise(i), dtrise(i)] = SpikeStatSolo_new(20, 400, path, strcat('stat_', fname{i}), path, strcat('statfit_', fname{i}));
end
