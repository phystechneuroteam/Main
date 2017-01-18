function Del = Delete_cells_by_vvp(height,width,path,del_list,del_list_length,num_dir)

    %Display current merged image
     merged = zeros(height, width, 3, 'double');
             
     for n_filter = 1:del_list_length
          filter = del_list(:,:,1,n_filter);
          color = colornum(mod(n_filter, 10)+1);
          for c = 1:3
              merged(:,:,c) = merged(:,:,c) + filter.*color(c);
          end
     end
     max_im = max(max(max(merged)));
     imshow(merged./max_im);
         
%Get mouse clics
        [y, x] = ginput;
        
        for i = 1:length(x)
            files = dir(sprintf('%s\\refined%d\\*.tif', path, num_dir));
            number_of_filters = length(files);
            for n_filter = 1:number_of_filters
                filter = double(imread(sprintf('%s\\refined%d\\%s', path,num_dir, files(n_filter).name)));
                if filter(round(x(i)),round(y(i))) ~= 0
                     delete(sprintf('%s\\refined%d\\%s', path,num_dir, files(n_filter).name));
                end
             end
        end
end

        
