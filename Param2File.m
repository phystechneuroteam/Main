function Param2File(param_names, param_values, paramfile)
%Writes parameters listed in param_names and param_values into paramfile;
%paramfile will be written strictly as .csv file

fnamelen = length(paramfile);

if exist(paramfile, 'file')
    T = readtable(paramfile, 'ReadVariableNames', false);
    len = length(T{:,1});
else
    T = table();
    len = 0;
end

NEWT = table2cell(T);

for i = 1:length(param_names)
    overl = 0; %check if there is existing param_name in paramfile
    for j = 1:len
        if strcmp(NEWT{j,1},param_names{i})
            overl = 1;
            break;
        end
    end
    if overl %param_name already exists
        NEWT{j,2} = param_values{i};
    else
        NEWT{len+1,1} = param_names{i};
        NEWT{len+1,2} = param_values{i};
        len = len + 1;
    end
end
writetable(cell2table(NEWT), sprintf('%s.csv',paramfile(1:fnamelen-4)), 'WriteVariableNames', false);

end
