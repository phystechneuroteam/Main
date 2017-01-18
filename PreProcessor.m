function PreProcessor(path, filename, left, top, right, bottom, sp_bin, m_start, m_end, m_corr, m_corr_crop, target_image)

%Crops movie, makes preprocessing (fixes defective pixels, and
%downsamples movie spatially by factor sp_bin) and motion correction

    if  nargin < 2 || isempty(filename) || isempty(path)
        [filename, path] = uigetfile('*.tif','Select TIFF movie', 'MultiSelect', 'on');
    end
    
    info = imfinfo(sprintf('%s%s',path, filename));
    width = info.Width;
    height = info.Height;

%data input    
    if nargin <11 || isempty(left) || isempty(top) || isempty(right) || isempty(bottom) || isempty(sp_bin) || isempty(m_corr) || isempty (m_corr_crop)
        prompt = {'Left, px:','Top, px:','Right, px:','Bottom, px:', 'Spatial binning factor (0 - skip preprocessing, 1 - preprocess)', 'Start frame (0 - skip trimming)', 'End frame','Motion correction (0/1/2 - skip/perform with default reference region/define it)', 'Crop after motion correction (0-automatically)'}; 
        default_data = {'1','1', sprintf('%d',width), sprintf('%d',height), '1', '1', length(info), '1', '20'};
        options.Resize='on';
        data = inputdlg(prompt, 'Parameters', 1, default_data, options);

        left = str2num(data{1});
        top = str2num(data{2});
        right = str2num(data{3});
        bottom = str2num(data{4});
        sp_bin = str2num(data{5});
        m_start = str2num(data{6});
        m_end = str2num(data{7});
        m_corr = str2num(data{8});
        m_corr_crop = str2num(data{9});
    end

if left < 1 || right > width || top < 1 || bottom > height || left >= right || top >= bottom 
    error('Incorrect data!');
end

%cropping and preprocessing

mosaic.initialize();

movie = mosaic.loadMovieTiff(sprintf('%s%s', path, filename));
movie = mosaic.cropMovie(movie, left, top, right, bottom);

if sp_bin
    movie = mosaic.preprocessMovie(movie, 'spatialDownsampleFactor', sp_bin);
else 
    sp_bin = 1;
end

width = (right - left + 1)/sp_bin;
height = (bottom - top + 1)/sp_bin;

if m_start
    mosaic.TrimMovie(movie, m_start, m_end);
end

if m_corr
    
    %getting target image
    if nargin < 12 || isempty(target_image)
        targ = mosaic.extractFrame(movie, 'frame', 1);
    else
        targ = mosaic.loadImage(target_image);
    end
    
    %defining contrast parameters
%   frame = targ.getData();    
  
    %reference region setting
    pointList = mosaic.List('mosaic.Point');
    pointList.add(mosaic.Point(width*0.05, height*0.3));
    pointList.add(mosaic.Point(width*0.3, height*0.05));
    pointList.add(mosaic.Point(width*0.7, height*0.05));
    pointList.add(mosaic.Point(width*0.95, height*0.3));
    pointList.add(mosaic.Point(width*0.95, height*0.7));
    pointList.add(mosaic.Point(width*0.7, height*0.95));
    pointList.add(mosaic.Point(width*0.3, height*0.95));
    pointList.add(mosaic.Point(width*0.05, height*0.7));
    roi = mosaic.PolygonRoi(pointList);
    if m_corr == 2
        roi.edit(movie);
    end
    
    %motion correction
    movie = mosaic.motionCorrectMovie(movie, 'referenceImage', targ, 'roi', roi,'subtractSpatialMean', true, 'invertImage', true, 'autoCrop', ~m_corr_crop);
    if m_corr_crop
        movie = mosaic.cropMovie(movie, m_corr_crop + 1, m_corr_crop + 1, width - m_corr_crop, height - m_corr_crop);
    end
    mosaic.saveMovieTiff(movie, sprintf('%s%s_corrected.tif', path, filename));
else
    mosaic.saveMovieTiff(movie, sprintf('%s%s_cropped.tif', path, filename));
end
    
mosaic.terminate();

end
