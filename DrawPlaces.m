function DrawPlaces (filename, in_rad, ext_rad, bord_wid, turn_b)
%Draws sircle of length(A) sectors with colors, obtained from values of array A, colored with jet colormap
%A - array with data
%in_rad - inner radius of sectors (in pixels)
%ext_rad - outer radius of sectors
%bord_wid - thickness of black border at closed sectors (if 0, no closed sectors will be drawn)
%lab_dist - distance from ext_rad to text labels (if 0, no text labels will be drawn)
%LABELS - array of numbers which will be considered as text labels
%decim - 1/0 - display/not display label's decimal places 
%turn_b - 1/0 - turn/not turn black borders on 90 deg conterclockwise
path = 'J:\CA_1\CA1_7_20160817\rows_n_colums_output\';

A = csvread (sprintf('%s%s', path, filename));
dim = size(A);
    
n_sect = 40;
c_map = colormap(jet);
n_colors = length(c_map);
m = max(A);
max_a = m(3) + 0.0000001;
m = min(A);
min_a = m(3);
figure;

for i = 1:dim 
    %draw main sectors
     X = [in_rad*cos(A(i,1)), ext_rad*cos(A(i,1)), ext_rad*cos(A(i,1)+2*2*pi/360), in_rad*cos(A(i,1)+2*2*pi/360)]; 
     Y = [in_rad*sin(A(i,1)), ext_rad*sin(A(i,1)), ext_rad*sin(A(i,1)+2*2*pi/360), in_rad*sin(A(i,1)+2*2*pi/360)];
     color = c_map(fix((A(i,3)-min_a)*n_colors/(max_a-min_a)) + 1, 1:3);
     patch(X, Y, color);
     %draw borders
     if ~mod(fix((i-1)*4/n_sect) + turn_b + 1, 2) && bord_wid
          X = [(in_rad-bord_wid)*cos((i-1)*2*pi/n_sect), in_rad*cos((i-1)*2*pi/n_sect), in_rad*cos(i*2*pi/n_sect), (in_rad-bord_wid)*cos(i*2*pi/n_sect)]; 
          Y = [(in_rad-bord_wid)*sin((i-1)*2*pi/n_sect), in_rad*sin((i-1)*2*pi/n_sect), in_rad*sin(i*2*pi/n_sect), (in_rad-bord_wid)*sin(i*2*pi/n_sect)];
          patch(X, Y, [0.3 0.3 0.3]);
          X = [ext_rad*cos((i-1)*2*pi/n_sect), (ext_rad+bord_wid)*cos((i-1)*2*pi/n_sect), (ext_rad+bord_wid)*cos(i*2*pi/n_sect), ext_rad*cos(i*2*pi/n_sect)]; 
          Y = [ext_rad*sin((i-1)*2*pi/n_sect), (ext_rad+bord_wid)*sin((i-1)*2*pi/n_sect), (ext_rad+bord_wid)*sin(i*2*pi/n_sect), ext_rad*sin(i*2*pi/n_sect)];
          patch(X, Y, [0.3 0.3 0.3]);
     end  
    
end

%adding colorbar
clb = cell(11,1);
for j = 0:10
    clb{j+1} = sprintf('%.f',min_a + (max_a - min_a)*j/10);
end
colorbar('YTickLabel',clb);
end
    