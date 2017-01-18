function Delart = Del_artifact_by_vvp(IM,height,width)
%IM = imread('F:\filters\filters170.tif'); width = 520; height =500;
[L,n_segments] = bwlabel(IM);
    feats=regionprops(L, 'Area'); 
    
    for i=1:1:n_segments 
    Areas(i)=feats(i).Area; 
    end; 
    
    maxS  = max(Areas);
    
    for i=1:1:n_segments
        if Areas(i) < maxS
            for k = 1:height
                for j = 1:width                     
                    if L(k,j) == i
                        L(k,j) = 0;
                    end
                end
            end            
        end
    end
    IM = double(L).*double(IM);
    maxim = max(max(IM));
    Delart = IM./maxim;
%imshow(Delart);
end
