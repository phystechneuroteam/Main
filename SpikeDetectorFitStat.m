function SpikeDetectorFitStat(path, filename, thr, t_before, t_after, max_t_on, min_t_off, toler, j_wind, sp_ampl, m_left, m_right)

%20 Sep 2017 Vova - MAD and F0 added for each spike; aux removed
%
%5 Aug 2017 Vova - modified from SpikeDetectorFit, option to write all the
%peaks and their fits to special tables added
%
%Fits calcium activity data in given .csv file with function single_spike_model
%i.e., y(i) = ampl*(1 - exp((t - x(i))/t_on))*exp((t - x(i))/t_off) + backgr, x(i) >=t
%      y(i) = backgr, x(i) < t.
%Fitting begins whenever the signal cross threshold level, and is
%restricted to definite time window, designed to catch fast spike rise,
%peak and beginning of slow decay.
%
%arguments:
%path, filename of .csv file with data
%thr - threshold level for spike detection, MADs above background
%t_before - window interval before threshold crossing, s
%t_after - window interval after nearest peak, s
%max_t_on - upper limit of e-fold rise time, s 
%min_t_off - lower limit of e-fold decay time, s 
%toler - fitting tolerance, 0..1
%j_wind  - peak smoothing window half-interval, frames (1 = skip peak smoothing)'
%m_left, m_right - margins for peak recording, s (m_left + m_right = length
%of table with peaks)

if nargin < 2 
    [filename, path] = uigetfile('*.csv','Select .csv file with calcium activity traces');
end

if nargin < 12 || isempty(thr) || isempty(t_before) || isempty(t_after) || isempty(max_t_on) || isempty(min_t_off) || isempty(toler) || isempty(j_wind) || isempty(sp_ampl) || isempty(m_left) || isempty(m_right)
    prompt = {'Threshold level, MADs', 'Window interval before threshold crossing, s', 'Window interval after nearest peak, s', 'Maximal e-fold rise time, s', 'Minimal e-fold decay time, s', 'Fitting tolerance, 0..1', 'Peak smoothing window half-time, frames (1 = skip peak smoothing)','Write spike amplitudes (vs ones) - y/n', 'Left margin,s', 'Right margin,s'}; 
    default_data = {'4','3','6','1','0.2','0.8','5','y','3','6'};
    options.Resize='on';
    dlg_data = inputdlg(prompt, 'Parameters', 1, default_data, options);

    thr = str2double(dlg_data{1});
    t_before = str2double(dlg_data{2});
    t_after = str2double(dlg_data{3});
    max_t_on = str2double(dlg_data{4});
    min_t_off = str2double(dlg_data{5});
    toler = str2double(dlg_data{6});
    j_wind = str2double(dlg_data{7});
    sp_ampl = dlg_data{8};
    m_left = str2double(dlg_data{9});
    m_right = str2double(dlg_data{10});
end

%reading data
T = readtable(sprintf('%s%s',path,filename));
dim = size(T);
X = T{1:dim(1),1};
fps = round((dim(1) - 1)/(X(dim(1))-X(1)));

%main spikes array
SPIKES = zeros(dim(1)+1,dim(2)); 
SPIKES(2:dim(1)+1,1) = X;

%array of fits
FITS = zeros(dim(1)+1,dim(2)); 
FITS(2:dim(1)+1,1) = X;

%auxiliary array of threshold level
THRES = zeros(dim(1)+1,dim(2)); 
THRES(2:dim(1)+1,1) = X;

%tables for spikes and their fits
STAT = table;
STATFIT = table;
dimstat = round((m_left + m_right)*fps);
numspikes = 0;
for i = 1:dimstat+1
    STAT{i,1} = (i-1)/fps;
    STATFIT{i,1} = (i-1)/fps;
end

STAT{dimstat+2:dimstat+3,1} = 0;

h = waitbar(0, sprintf('Processing trace %d of %d', 0,  dim(2)-1)); 

for i = 2:dim(2)
    waitbar((i-1)/(dim(2)-1), h, sprintf('Processing trace %d of %d', i-1,  dim(2)-1));
    m_dev = mad(T{1:dim(1),i},1);
    backgr = median(T{1:dim(1),i});
    f_zero = mean(T{1:dim(1),i});
    THRES(2:dim(1)+1,i) = backgr + m_dev*thr;
    
    for j = j_wind+1:dim(1)
        %condition of threshold crossing
        if T{j,i} > backgr + m_dev*thr && T{j-1,i} <= backgr + m_dev*thr
            
            %nearest peak searching
            ampl =  mean(T{j-j_wind:min(dim(1),j+j_wind),i});
            j_peak = j+1;
            while j_peak + j_wind <= dim(1) && mean(T{j_peak-j_wind:j_peak+j_wind,i}) > ampl
                ampl = mean(T{j_peak-j_wind:j_peak+j_wind,i});
                j_peak = j_peak + 1;
            end

            %fitting
            j_start = round(max(2, j - t_before*fps));
            j_end = round(min(dim(1)-1, j_peak + t_after*fps));
            
            [fitresult, gof] = SpikeFit(X(j_start:j_end), T{j_start:j_end, i}, backgr, m_dev*thr, max_t_on, min_t_off);
            
            if gof.rsquare >= toler
                t = fitresult.t;
                t_on = fitresult.t_on;
                t_off = fitresult.t_off;
                ampl = fitresult.ampl;
                bckgr = fitresult.backgr;
                Y = single_spike_model(X, t, t_on, t_off, ampl, bckgr);
                
                statstart = round((t-m_left)*20);
                if statstart >=1 && statstart + dimstat <= dim(1)
                    numspikes = numspikes + 1;
                    STAT{1, numspikes+1} = 0;
                    STATFIT{1, numspikes+1} = 0;
                    STAT{2:dimstat+1, numspikes+1} = T{statstart:statstart+dimstat-1,i};
                    STATFIT{2:dimstat+1, numspikes+1} = Y(statstart:statstart+dimstat-1);
                    
                    STAT{dimstat+2, numspikes+1} = m_dev;
                    STAT{dimstat+3, numspikes+1} = f_zero;
                  
                end
                                
                %subtracting fit from original data - this allows next
                %potential spikes to be scored                
                T{1:dim(1),i} = T{1:dim(1),i} - Y;
                backgr = backgr - bckgr;
                THRES(j,i) = backgr + m_dev*thr;             
                
                %FITS saves cumulative spike fits
                FITS(2:dim(1)+1,i) = FITS(2:dim(1)+1,i) + Y;
                %spike scoring
                if sp_ampl == 'y'
                    SPIKES(round(t*fps)+ 1, i) = max(FITS(j_start:j_end, i));
                else
                    SPIKES(round(t*fps)+ 1, i) = 1;
                end

            else
                %one isolated point will not alter fit significantly, but
                %it can allow next potential over-thresholded spike to be scored
                T{j_end,i} = backgr  + m_dev*thr; 
            end
                
        end  
    end
end
csvwrite(sprintf('%sspikes_%s',path,filename), SPIKES);

csvwrite(sprintf('%sstat_%s',path,filename), table2cell(STAT));
csvwrite(sprintf('%sstatfit_%s',path,filename), table2cell(STATFIT));

delete(h);

end
    