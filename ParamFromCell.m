function P = ParamFromCell(param_names, param_values, P)
%Retrives structure P with parameters, which names are taken from
%param_names, and values from param_values
%All field names of P structure coincide with param_names.
%P is optional argument, if it is omitted, empty structure will be created.
%if P is NOT omitted, all existed fields will NOT be overwritten.

if nargin < 3 
    P = struct;
end

for i = 1:length(param_names)
    if isfield (P, param_names{i})
        continue;
    end
    
    switch param_names{i}
%(path, filename, left, top, right, bottom, sp_bin, m_start, m_end, m_corr, m_corr_crop, target_image)        
        case 'Path'
            P.Path = cut_string(param_values{i});
            
        case 'Filenames'
            P.Filenames = cut_string(param_values{i});
            
        case 'FilesADay'
            P.FilesADay = cut_string(param_values{i});
            for j=1:length(P.FilesADay)
                temp = str2num(P.FilesADay{j});
                P.FilesADay{j} = temp;
            end
            
        case 'Trim'
            P.Trim = cut_string(param_values{i});
            for j=1:length(P.Trim)
                temp = str2num(P.Trim{j});
                P.Trim{j} = temp;
            end
            
        case 'Crop'
            P.Crop = cut_string(param_values{i});
            for j=1:length(P.Crop)
                temp = str2num(P.Crop{j});
                P.Crop{j} = temp;
            end
            
        case 'Sbf'
            P.Sbf = str2num(param_values{i});
            
        case 'MC_roi'
            P.MC_roi = str2num(param_values{i}); 
            
        case 'MC_crop'
            P.MC_crop = str2num(param_values{i});
            
        case 'RefFrame'
            P.RefFrame = param_values{i};
            
        case 'Corrected'
            P.Corrected = cut_string(param_values{i});    
            
        case 'Tbf'
            P.Tbf = str2num(param_values{i});
            
        case 'IC_num'
            P.IC_num = str2num(param_values{i});
            
        case 'Concatenated'
            P.Concatenated = cut_string(param_values{i});
            
        case 'Refined'
            P.Refined = param_values{i};
            
        case 'Neur_rad'
            P.Neur_rad = str2num(param_values{i});
            
        case 'Neur_coeff'
            P.Neur_coeff = str2double(param_values{i});
            
        case 'Neur_df'
            P.Neur_df = str2num(param_values{i});
        
        case 'Fps'
            P.Fps = str2num(param_values{i});            
            
    end
    
    
end
end