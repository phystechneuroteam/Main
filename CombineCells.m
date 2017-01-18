function CombineCells(path, filename)
%Allows user to combie filters in 'path' folder manually; selected filters
%will be deleted and combined fiters will be written.

if nargin < 2
    [filename, path] = uigetfile('*.tif','Select TIFF image','C:\Scripts\Test\refined\filter_1.tif');
end

info = imfinfo(sprintf('%s%s', path, filename));
width = info.Width;
height = info.Height;

while 1
    %Display current merged image
     merged = zeros(height, width, 3, 'double');
        
     files = dir(sprintf('%s\\*.tif',path));
     number_of_filters = length(files);
        
     for n_filter = 1:number_of_filters
          filter = double(imread(sprintf('%s%s', path, files(n_filter).name)));
          color = colornum(mod(n_filter, 10)+1);
          for c = 1:3
              merged(:,:,c) = merged(:,:,c) + filter.*color(c);
          end
     end
     max_im = max(max(max(merged)));
     imshow(merged./max_im);
       
    % Construct a list with three options
    [choice, ok] = listdlg('PromptString','Select action:', 'SelectionMode','single','ListString',{'Combine cells','Delete cells','Watershed cells'}) ;  
    
    if ~ok
        break;
    end
    
    % Handle response   
    switch choice
       case 1                %(Combine cells)          
        %Get mouse clics
        [y, x] = ginput;   
        
        %Constructing united filter
        new_filter = zeros(height, width, 'double');
        for i = 1:length(x)
            files = dir(sprintf('%s\\*.tif',path));
            number_of_filters = length(files);
            for n_filter = 1:number_of_filters
                filter = double(imread(sprintf('%s%s', path, files(n_filter).name)));
                if filter(round(x(i)),round(y(i))) ~= 0
                     new_filter = new_filter + filter;
                     delete(sprintf('%s%s', path, files(n_filter).name));
                end
             end
        end
        max_im = max(max(new_filter));
        imwrite(new_filter./max_im, sprintf('%s\\united_%s', path, files(n_filter).name));
        
      case 2                     %('Delete cells')
        %Get mouse clics
        [y, x] = ginput;
        
        for i = 1:length(x)
            files = dir(sprintf('%s\\*.tif',path));
            number_of_filters = length(files);
            for n_filter = 1:number_of_filters
                filter = double(imread(sprintf('%s%s', path, files(n_filter).name)));
                if filter(round(x(i)),round(y(i))) ~= 0
                     delete(sprintf('%s%s', path, files(n_filter).name));
                end
             end
        end
        
      case 3                  %('Watershed cells')
        %Get mouse clics
        [y, x] = ginput;   

        for i = 1:length(x)
            files = dir(sprintf('%s\\*.tif',path));
            number_of_filters = length(files);
            for n_filter = 1:number_of_filters
                filter = double(imread(sprintf('%s%s', path, files(n_filter).name)));
                if filter(round(x(i)),round(y(i))) ~= 0
                     %Watershed performing
                     bsigm = max(max(bwdist(~filter)))*2;
                     ssigm = bsigm/8;
                     BG = single(filter) - conv2(single(filter), single(gaussian2d(1000,bsigm)), 'same'); %shading correction
                     SG = conv2(BG, single(gaussian2d(1000,ssigm)), 'same'); %smoothing
                     WS = watershed(1 - Norm(SG));
                     L = bwlabel(DrawWS(filter, WS));
                     n_segments = max(max(L));
                     
                     %writing separated filters
                     for n = 1:n_segments
                        BG = L == n;
                        SG = double(BG).*filter;
                        max_im = max(max(SG));
                        imwrite(SG./max_im, sprintf('%s\\%s_part_%d.tif', path, files(n_filter).name, n));
                     end
                     delete(sprintf('%s%s', path, files(n_filter).name));
                end
             end
        end
    end
        
end