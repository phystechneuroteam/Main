function P = ParamFromXls(paramfile)
%Retrives structure P with all parameters detailesd in given .xls file.
%All field names of P structure coincide with parameter names in .xls file.

[~, ~, params] = xlsread(paramfile,'','','basic');

for i = 1:length(params)
    switch params{i,1}
        
        case 'Path'
            P.Path = cut_string(params{i,2});
            
        case 'Filenames'
            P.Filenames = cut_string(params{i,2});
            
        case 'FilesADay'
            P.FilesADay = cut_string(params{i,2});
            for j=1:length(P.FilesADay)
                temp = str2num(P.FilesADay{j});
                P.FilesADay{j} = temp;
            end
            
        case 'Trim'
            P.Trim = cut_string(params{i,2});
            for j=1:length(P.Trim)
                temp = str2num(P.Trim{j});
                P.Trim{j} = temp;
            end
            
        case 'Crop'
            P.Crop = cut_string(params{i,2});
            for j=1:length(P.Crop)
                temp = str2num(P.Crop{j});
                P.Crop{j} = temp;
            end
            
        case 'MotionCorrectionCrop'
            P.MotionCorrectionCrop = params{i,2};
            
        case 'RefFrame'
            P.RefFrame = params{i,2};
            
        case 'Neuropil'
            P.Neuropil = params{i,2};
    end
    
    
end
end