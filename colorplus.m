function cp = colorplus(color1, color2, norm_mode)
%Sum of 2 colors (should be vectors like [R,G,B], where R + G + B = 1),
%normalized by sum (norm_mode = 1) or maximum (norm_mode = 2) of red, green, 
%and blue values, or non-normalised (norm_mode=0)
    color = [0, 0 , 0];
    sum = 0;
    max = 0;
    for i = 1:3
        color(i) = color1(i)+color2(i);
        sum = sum + color(i);
        if color(i) > max
            max = color(i);
        end        
    end
    if max==0
        max = 1;
    end
    switch norm_mode
        case 1
            cp = [color(1)/sum, color(2)/sum, color(3)/sum];
            return;
        case 2 
            cp = [color(1)/max, color(2)/max, color(3)/max];
            return;
        otherwise
            cp = [color(1), color(2), color(3)];
    end
end