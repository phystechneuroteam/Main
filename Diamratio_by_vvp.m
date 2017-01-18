function Drt = Diamratio_by_vvp(IM)
%Returns ratio of small to big diameter of cell, 1 for circle and square
%optimal border 0.35
%IP = imread('F:\filters\refined\filter_1.tif');
L = bwlabel(IM);
feats = regionprops(L, 'Extrema');
P = feats(1).Extrema;
axe1 = sqrt(((P(6)+P(5))/2-(P(1)+P(2))/2)^2 + (P(9)-P(13))^2);
axe2 = sqrt(((P(12)+P(11))/2-(P(15)+P(16))/2)^2 + (P(4)-P(7))^2);
Dmax = max(axe1, axe2);
Dmin = 2*max(max(bwdist(~IM)));
Drt = Dmin/Dmax;
end

