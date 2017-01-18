function cn = colornum(num)
%Returns color vector [R, G, B], where R, G, B ranges from 0 to 1, which
%number in palette is 'num'
    switch num
        case 1
            cn = [1, 0, 0];
            return;
        case 2
            cn = [0, 1, 0]; 
            return;
        case 3
            cn = [0, 0, 1]; 
            return;
        otherwise
            if mod (num+4, 12) <= 6 && num > 7 
                mode = 1;
            else
                mode = 2;
            end
            iter = 2.^fix(log((num-1)/3)/log(2));
            cn = colorplus(colornum(num - 3*iter), colortail(num), mode);
            return;
    end
end
