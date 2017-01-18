function output = cut_string(input_str)
    l = length(input_str);
    j=1;
    n(1)=0;
    for i=1:l
       %output[n]=input(i);
       if  input_str(i) == ';'
           n(j)=i;
           j=j+1;
          
       end
      
    end
    j = j-1;
    
    if n(1) == 0
       output = input_str; 
      
    else
        output = cell(1,j+1);
        output{1} = input_str(1:(n(1)-1));
        for k=2:j
            output{k} = input_str((n(k-1)+1):(n(k)-1)); 
        end
        
        k=j;
        output{k+1} = input_str((n(k)+1):l); 
    end
 
   
end