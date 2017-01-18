function crc = Circularity_by_vvp (IM)
%Returns ratio of square root of square over perimeter; normalized such
%that it equals 1.0 for circle
%optimal border 0.8
    D = bwdist(~IM);
    %borders!
    dim = size(D);
    for i = 1:dim(2)
        if IM(1, i)
            D(1, i) = 1;
        elseif IM(dim(1),i)
            D(dim(1),i) = 1;
        end
    end
    for i = 1:dim(1)
        if IM(i, 1)
            D(i, 1) = 1;
        elseif IM(i,dim(2))
            D(i,dim(2)) = 1;
        end
    end
    num_A = length(find(D==1));
    num_k = 0;
           for i = 2:dim(1)-1
               for j = 2:dim(2)-1
                   if D(i,j) == 1 && ((D(i+1,j) == 0) && (D(i, j+1) == 0))
                       num_k = num_k+1;
                   end
                       if D(i,j) == 1 && ((D(i+1,j) == 0) && (D(i, j-1) == 0))
                       num_k = num_k+1;
                       end
                   if D(i,j) == 1 && ((D(i-1,j) == 0) && (D(i, j+1) == 0))
                       num_k = num_k+1;
                   end
                   if D(i,j) == 1 && ((D(i-1,j) == 0) && (D(i, j-1) == 0))
                       num_k = num_k+1;
                   end
               end
           end
           
    perim = num_A+num_k*(sqrt(2)-1);
    diam = sqrt(nnz(IM));
    crc = (diam/perim)/0.282095;
end