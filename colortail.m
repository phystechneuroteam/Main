function ct = colortail(num)
%Auxilary routine for colornum
    switch num
        case 4
            ct = [0, 1, 0];
            return;
        case 5
            ct = [0, 0, 1];
            return;
        case 6
            ct = [1, 0, 0];
            return;
        otherwise
            iter = 2.^fix(log((num-1)/3)/log(2));
            if num - iter*3 <= iter*3/2
                ct = colornum(num - iter*3/2);
                return;
            else
                ct = colortail(num - iter*3);
                return;
            end
    end
 
end