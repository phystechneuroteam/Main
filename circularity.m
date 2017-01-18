function crc = circularity (IM)
%Returns ratio of square root of square over perimeter; normalized such
%that it equals 1.0 for circle
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
           
    perim = length(find(D==1));
    diam = sqrt(nnz(IM));
    crc = (diam/perim)/0.282095;
end