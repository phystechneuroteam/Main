function [fitresult, gof] = SpikeFit(x, y, bckg, thr, max_t_on, min_t_off)
%Fitting data [x, y] (must be columns!) with function single_spike_model
%i.e., y(i) = ampl*(1 - exp((t - x(i))/t_on))*exp((t - x(i))/t_off) + backgr, x(i) >=t
%      y(i) = backgr, x(i) < t.
%arguments:
%bckg - estimate of background (backgr)
%thr - threshold level for spike detection, a.u. above background (usually n MADs)
%max_t_on - upper limit of e-fold rise time, s 
%min_t_off - lower limit of e-fold decay time, s 
%
%returns the same values as std fit function does

[xData, yData] = prepareCurveData(x, y);
% Setting up missing parameters
len = length(x);
max_ampl = thr*100;
min_t_on = max_t_on/100;
max_t_off = min_t_off*10;

% Setting up fittype and options.
ft = fittype( 'single_spike_model(x, t, t_on, t_off, ampl, backgr)', 'independent', 'x', 'dependent', 'y' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';
%f*ckin alphabet!! [ampl, backg, t, t_off, t_on]
opts.Lower = [thr, bckg - max_ampl, x(1),  min_t_off, min_t_on];
opts.StartPoint = [thr, bckg - max_ampl, x(1),  min_t_off, min_t_on];
opts.Upper = [max_ampl, bckg + thr, x(len), max_t_off, max_t_on];

% Fit model to data.
[fitresult, gof] = fit( xData, yData, ft, opts );

end