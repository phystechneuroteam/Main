%fname = {'GC1_1D_20170719_140737_corrected.tif_neuropil_60.csv_conc.csv', 'GC3_1D_20170719_142855_corrected.tif_neuropil_60.csv_conc.csv','YTNC2_1D_20170719_152151_corrected.tif_neuropil_60.csv_conc.csv', 'YTNC3_1D_20170719_154731_corrected.tif_neuropil_60.csv_conc.csv', 'YTNC4_1D_20170719_161019_corrected.tif_neuropil_60.csv_conc.csv', 'GCaMP6f.csv', 'YTNC.csv'};
path = 'C:\YTNC_GC_csv\test_1_1\';
fname = {'YTNC.csv'};
for i = 1:length(fname)
    [spikes(i), mampl(i), dampl(i), msnr(i), dsnr(i), mtoff(i), dtoff(i), mtrise(i), dtrise(i)] = SpikeStatSolo_new(20, 3, path, strcat('stat_', fname{i}), path, strcat('statfit_', fname{i}));
end
