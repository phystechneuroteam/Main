function ccntr = Eccentricity_by_vvp(IP)
%Returns the eccentricity of the ellipse. 0 for circle 
%optimal border 0.9
%IP = imread('F:\filters\refined\filter_94.tif');
L = bwlabel(IP);
feats = regionprops(L, 'Eccentricity');
ccntr = feats(1).Eccentricity;
end
