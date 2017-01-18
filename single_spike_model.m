function y = single_spike_model(x, t, t_on, t_off, ampl, backgr)
%Function which models single calcium spike
%t - time of spike start
%t_on - rise parameter
%t_off - decay parameter
%ampl - amplitude of spike
%backgr - background level
y = zeros(size(x));

for i = 1:length(x)
    if x(i) < t
        y(i) = backgr;
    else
        y(i) = ampl*(1 - exp((t - x(i))/t_on))*exp((t - x(i))/t_off) + backgr;
    end
end
end