function SpikeDetector_new(path, filename, thr, tau_off_s)
%Detects positive spikes in user-specified .csv file, write them in another
%.csv file; ampl (def=3) is treshold in M.A.D., tau_off_s (def=2) is a time
%of half-decay of the spike; no another spike can be detected during  tau_off_s (def=5);
%time of the spike is determined as a first threshold crossing.
if nargin < 2 
    [filename, path] = uigetfile('*.csv','Select .csv file with traces', 'J:\CA_1\CA1_1_20160915\df_recording_20160915_130942_corrected.tif_neuropil_40.csv_medlowpassed_5.000000e-01_60.csv');
end
if nargin < 4 || isempty (thr) || isempty (tau_off_s)
    prompt = {'Spike threshold (MADs):', 'Half-decay minimal time, s'}; 
    default_data = {'6','0.5'};
    options.Resize='on';
    dlg_data = inputdlg(prompt, 'Parameters', 1, default_data, options);

    thr = str2double(dlg_data{1});
    tau_off_s = str2double(dlg_data{2});
end

T = readtable(sprintf('%s%s',path,filename));
dim = size(T);
X = T{1:dim(1),T.Properties.VariableNames{1}};
fps = round((dim(1) - 1)/(X(dim(1))-X(1)));
tau_off = round(tau_off_s*fps);
decrement = 2^(1/tau_off);

%main spikes array
SPIKES = zeros(dim(1)+1,dim(2)); 
SPIKES(2:dim(1)+1,1) = X;

%auxilary arrays
BACKG = zeros(dim(1)+1,dim(2)); 
BACKG(2:dim(1)+1,1) = X;
THRES = zeros(dim(1)+1,dim(2)); 
THRES(2:dim(1)+1,1) = X;


h = waitbar(0, sprintf('Processing trace %d of %d', 0,  dim(2)-1)); 

for i = 2:dim(2)
    waitbar((i-1)/(dim(2)-1), h, sprintf('Processing trace %d of %d', i-1,  dim(2)-1));
    m_dev = mad(T{1:dim(1),i},1);
    med = median(T{1:dim(1),i});
    backgr = med; %initial background level
    
    j_peak = 2;
    tau_thr = med;
    for j = 2:dim(1)
        %condition of threshold crossing
        if T{j,i} >= backgr + m_dev*thr && T{j-1,i} < backgr + m_dev*thr 
            
            %nearest peak searching
            ampl = med + m_dev*thr;
            j_peak = j;
            while j_peak <= dim(1) && T{j_peak,i} > ampl
                ampl = T{j_peak,i};
                j_peak = j_peak + 1;
            end

            %duration test
            off = 1;
            tau_thr = (ampl - backgr)/2 + backgr; %threshold value which must not be crossed during tau_off
            for j_sp = j_peak:j_peak+tau_off
                if j_sp > dim(1)
                    break;
                elseif T{j_sp,i} <= tau_thr;
                    off = 0;
                end
            end
            
            if off %test succeeded
                SPIKES(j,i) = ampl;
                backgr = ampl;
            end
        end
        %background decreasing 
        if j > j_peak && backgr > med
            backgr = (backgr-med)/decrement + med;
        end
        if backgr < med
            backgr = med;
        end
        
        %writing background as lower threshold (for spike's end)
        if j > j_peak && j <= j_peak+tau_off
            BACKG(j,i) = tau_thr;
        else
            BACKG(j,i) = backgr;
        end
        %writing higher threshold ((for spike's beginning)
        THRES(j,i) = backgr + m_dev*thr;
    end  
end

csvwrite(sprintf('%sspikes_%s',path,filename), SPIKES);
csvwrite(sprintf('%sbackgr_%s',path,filename), BACKG);
csvwrite(sprintf('%sthres_%s',path,filename), THRES);

delete(h);
end