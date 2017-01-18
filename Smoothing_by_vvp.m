function Smooth = Smoothing_by_vvp(IM, sigma, otsechka,height,width)

    hs = fspecial('gaussian', 30, double(sigma));
    SG = conv2(IM, single(hs), 'same'); 
    maxin = max(max(SG));
    for i = 1:height
      for j = 1:width
          SG(i,j) = SG(i,j)/maxin;
          if SG(i,j) < otsechka
              SG(i,j) = 0;
          end
      end
    end
    
    Smooth = double(SG);
  
end
