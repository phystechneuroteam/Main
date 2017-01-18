function DrawContourMap(p, im_filename, fil_path, cmp)
%Draws contours of cells, which numbers are specified in p (1D array),
%cells are taken from fil_path folder, backgound is taken from
%im_filename
%cmp - colormap, 0-colornum, 1-jet, 2-summer

num = max(size(p));

%Reading data
im = imread(im_filename);
dim = size(im);
res_im = zeros(dim(1), dim(2), 'double');

%Copying image to rgb
for i = 1:dim(1)
    for j = 1:dim(2)
         for c = 1:3
              res_im(i,j,c) = im(i,j);
         end
    end
end
maxim = max(max(max(res_im)));
if ~maxim
    maxim = 1;
end
min_p = min(p);
max_p = max(p)+0.00000001;

%Getting files
files = dir(sprintf('%s\\*.tif',fil_path));

%Coloring contours
for n = 1:num
    fil = imread(sprintf('%s%s', fil_path, files(p(n)).name));
    ds = bwdist(~fil);
    if cmp == 0
        color = colornum(n);
    elseif cmp == 1
        c_map = colormap(jet);
        n_colors = length(c_map);
        color = c_map(fix((p(n)-min_p)*n_colors/(max_p-min_p)) + 1, 1:3);
    elseif cmp == 2
        c_map = colormap(summer);
        n_colors = length(c_map);
        color = c_map(fix((p(n)-min_p)*n_colors/(max_p-min_p)) + 1, 1:3);
    end
    for i = 1:dim(1)
        for j = 1:dim(2)
            if ds(i,j) >= 1 && ds(i,j) <= 2 
                for c = 1:3
                    res_im(i,j,c) = maxim*color(c);
                end
            end
        end
    end
end

%Normalization, showing and writing
res_im = res_im./maxim;
figure, imshow(res_im);
imwrite(res_im, sprintf('%s_contour_map.tif', im_filename));

end
    