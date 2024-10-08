function [fitresult, gof] = createFit(timeFit, diameterFit)
%CREATEFIT1(TIMEFIT,DIAMETERFIT)
%  Create a fit.
%
%  Data for 'untitled fit 1' fit:
%      X Input: timeFit
%      Y Output: diameterFit
%  Output:
%      fitresult : a fit object representing the fit.
%      gof : structure with goodness-of fit info.
%
%  See also FIT, CFIT, SFIT.

%  Auto-generated by MATLAB on 07-Sep-2023 15:04:13


%% Fit: 'untitled fit 1'.
[xData, yData] = prepareCurveData( timeFit, diameterFit );

% Set up fittype and options.
ft = fittype( 'exp1' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';
opts.StartPoint = [0.763917401078718 -0.0105644049234249];

% Fit model to data.
[fitresult, gof] = fit( xData, yData, ft, opts );

% Plot fit with data.
figure( 'Name', 'untitled fit 1' );
h = plot( fitresult, xData, yData );
legend( h, 'diameterFit vs. timeFit', 'untitled fit 1', 'Location', 'NorthEast', 'Interpreter', 'none' );
% Label axes
xlabel( 'timeFit', 'Interpreter', 'none' );
ylabel( 'diameterFit', 'Interpreter', 'none' );
grid on


