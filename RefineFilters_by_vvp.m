function m = RefineFilters_by_vvp(path, delopt, sigma, ssquare, bsquare, diamrt, overlap)
%Refines filters in the given folder (should be of the same size). Overlapping 
%more than on [overl] ratio filters, and filters with square and circularity/eccenticity/diamratio which exceed  
%the limits will be discarded. Sigma - parameter of
%pre-filtering, bsquare, ssquare - limits of square (e.g. non-zero pixels),
%circ - lowest circularity.
%Returns number of proper filters which are written into folder ../refined.
%Добавлен режим автоматического и ручного удаления сосудов

%Defining missing arguments
if nargin < 1 
    [filename, path] = uigetfile('*.tif','Select TIFF image','F:\filters\filters.tif');
end
if nargin < 7 || isempty (delopt) || isempty (sigma) || isempty (ssquare) || isempty (bsquare) || isempty(diamrt) || isempty (overlap)
    prompt = {'Vessels deleting(1 - automatic, 0 - manually)', 'Sigma for smoothing (2 - optimal, -1 - skip)','Smallest filter square, px', 'Biggest filter square, px', 'Maximal diameter rate(1 for circle and square)', 'Maximal overlapping ratio'}; 
    default_data = {'1','2','50','5000','0.35','0.2'};
    options.Resize='on';
    dlg_data = inputdlg(prompt, 'Parameters', 1, default_data, options);

    delopt = str2num(dlg_data{1});
    sigma = str2num(dlg_data{2});
    ssquare = str2num(dlg_data{3});
    bsquare = str2num(dlg_data{4});
    diamrt = str2num(dlg_data{5});
    overlap = str2double(dlg_data{6});
end

otsechka = 0.3; %brightness cropping for smoothing
m = 1; %number of refined filters

%Creating folder 'refinedX' for writing filters into it, if such folder exist, it will
%be created folder 'refinedX+1'
num_dir = 1;
while isdir(sprintf('%s\\refined%d', path, num_dir))
        num_dir = num_dir+1; 
end
[s, ~, ~] = mkdir(path,sprintf('refined%d', num_dir));
while ~s
   [s, ~, ~] = mkdir(path,sprintf('refined%d', num_dir));
end
[s, ~, ~] = mkdir(sprintf('%s\\refined%d',path,num_dir),'temp');

%Getting files
files = dir(sprintf('%s\\*.tif',path));
n_files = length(files);

%Creating waitbar
h = waitbar(1/n_files, sprintf('Writing filter %d of %d', 0,  n_files));

info = imfinfo(sprintf('%s%s', path, files(1).name));
width = info.Width;
height = info.Height;
SUM_IM = zeros(height, width, 'double');

%creating parameters file
prmtr=fopen(sprintf('%s\\refined%d\\parameters%d.txt', path,num_dir,num_dir),'w');
fprintf(prmtr, 'sigma = %d ssquare = %d bsquare = %d diamrate = %0.2g overlap = %0.2g otsechka = %0.2g \n',sigma, ssquare, bsquare, diamrt, overlap, otsechka);
fprintf(prmtr,'N  S  diamrt \n');


for f = 1:n_files 
    h = waitbar(f/n_files, h, sprintf('PreProcessing filter %d of %d', f,  n_files));
    IM = double(imread(sprintf('%s%s', path, files(f).name)));
    
%smoothing        
    if sigma ~= -1
    IM = Smoothing_by_vvp(IM, sigma, otsechka,height,width);
    end
    
%deleting artifacts
    IM = Del_artifact_by_vvp(IM,height,width); 
    
   
   imwrite(double(IM),sprintf('%s\\refined%d\\temp\\%s', path,num_dir, files(f).name));
end     

%Sorting files by their square
for f = 1:n_files 
    IM = double(imread(sprintf('%s\\refined%d\\temp\\%s', path, num_dir, files(f).name)));
    files_sq(f) = setfield(files(f), 'square', nnz(IM)); 
end
FILES = struct2table(files_sq);
FILES = sortrows(FILES, 'square');
files_sq = table2struct(FILES);

delete(h);
%Creating waitbar
h = waitbar(1/n_files, sprintf('Writing filter %d of %d', 0,  n_files));
 if delopt == 1
     len=0;
for f = 1:n_files
    h = waitbar(f/n_files, h, sprintf('Processing filter %d of %d', f,  n_files));
    IM = double(imread(sprintf('%s\\refined%d\\temp\\%s', path, num_dir, files_sq(f).name)));
    maxim = max(max(IM));
    
    %sized,form and overlaping filters        
    ddd = Diamratio_by_vvp(IM);
    sq = nnz(IM);
    if sq < ssquare  || sq > bsquare || (ddd < diamrt) || (ddd > 1) || overlap_is(SUM_IM, IM, overlap)
           continue
    end 
    SUM_IM = SUM_IM + IM;
    
    %writing    
    fprintf(prmtr, '%d  %d  %0.3g\n',m, sq, Diamratio_by_vvp(IM));
    imwrite(IM./maxim, sprintf('%s\\refined%d\\filter_%d.tif',path,num_dir,m));    
    m = m + 1; 
end
 else
     del_list_length = 0;
     merged = zeros(height, width, 3, 'double');
     for f = 1:n_files
    h = waitbar(f/n_files, h, sprintf('Processing filter %d of %d', f,  n_files));
    IM = double(imread(sprintf('%s\\refined%d\\temp\\%s', path, num_dir, files_sq(f).name)));
    maxim = max(max(IM));
    
    %sized,form and overlaping filters        
    ddd = Diamratio_by_vvp(IM);
    sq = nnz(IM);
    if sq < ssquare  || sq > bsquare  || overlap_is(SUM_IM, IM, overlap)
           continue
    end     
    
    if  (ddd < diamrt) || (ddd > 1)
        del_list_length = del_list_length+1;
      %  del_list(:,:,1,del_list_length) = IM;
      
   %make a merge image   
   
          color = colornum(mod(del_list_length, 10)+1);
          for c = 1:3
              merged(:,:,c) = merged(:,:,c) + IM.*color(c);
          end
          
        
    end  
    SUM_IM = SUM_IM + IM;
    
    %writing    
    fprintf(prmtr, '%d  %d  %0.3g\n',m, sq, ddd);
    imwrite(IM./maxim, sprintf('%s\\refined%d\\filter_%d.tif',path,num_dir,m));    
    m = m + 1; 
     end
 %deleting of cells    
max_im = max(max(max(merged)));
     imshow(merged./max_im);
     
     [y, x] = ginput;
     %len=0;
        len=length(x);
        for i = 1:len
            
            filesdel = dir(sprintf('%s\\refined%d\\*.tif', path, num_dir));
            number_of_filters = length(filesdel);
            for n_filter = 1:number_of_filters
                filter = double(imread(sprintf('%s\\refined%d\\%s', path,num_dir, filesdel(n_filter).name)));
                if filter(round(x(i)),round(y(i))) ~= 0
                     delete(sprintf('%s\\refined%d\\%s', path,num_dir, filesdel(n_filter).name));
                end
             end
        end
   % Delete_cells_by_vvp(height,width, path, del_list,del_list_length,num_dir);
     
 end
 %delete(h);
 %h = waitbar(f/n_files, h, sprintf('Processing filter %d of %d', f,  n_files));
 rmdir(sprintf('%s\\refined%d\\temp', path, num_dir),'s')
fclose(prmtr);
delete(h);
m = m - 1 - len;
end


