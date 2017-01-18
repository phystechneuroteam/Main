function PerformPcaIca(path, filename, temp_bin, pc_num, ic_num)
%performs PCA/ICA analysis of one movie, optionally bins it temporally.

    if  nargin < 2 || isempty(filename) || isempty(path)
        [filename, path] = uigetfile('*.tif','Select TIFF movie', 'MultiSelect', 'on');
    end
    if nargin <5 || isempty(temp_bin) || isempty(pc_num) || isempty(ic_num)
        prompt = {'Temporal binning factor', 'Number of PCs', 'Number of ICs'}; 
        default_data = {'1','150','100'};
        options.Resize='on';
        dlg_data = inputdlg(prompt, 'Parameters', 1, default_data, options);

        temp_bin = str2num(dlg_data{1});
        pc_num = str2num(dlg_data{2});
        ic_num = str2num(dlg_data{3});
    end
%analysis performing

    mosaic.initialize();
    movie = mosaic.loadMovieTiff(sprintf('%s%s', path, filename));
    movie = mosaic.normalizeMovie(movie);
    mosaic.saveMovieTiff(movie, sprintf('%sdf_%s',path, filename), 'largeMovieOption','BigTIFF');
    
    if temp_bin > 1 
        movie = mosaic.resampleMovie(movie, 'spatialReduction',1,'temporalReduction', temp_bin);
        mosaic.saveMovieTiff(movie, sprintf('%sdf_bb%d_%s',path, temp_bin, filename));
    end
    
    icGroups = mosaic.pcaIca(movie, 'numPCs', pc_num, 'numICs', ic_num, 'unmix', 'both');
    mosaic.saveOneObject(icGroups, sprintf('%sicGroups_%s.mat',path, filename));
    mosaic.terminate();

end

