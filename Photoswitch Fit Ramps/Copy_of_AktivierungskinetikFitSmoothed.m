addpath(genpath('U:\Projekte an Analysis1\Christian\Matlab for everybody\Photoswitch Fit Ramps'))

StartWerte = [0.01; 1; 0.01];

[file, path] = uigetfile('*.asc');
data = importfileRamps(fullfile(path,file));


 data = smoothdata(data,...
    "gaussian","SmoothingFactor",0.11,"DataVariables","ImonA");

fig = figure;
plot(data.Times, data.ImonA, '-o');
fig.WindowState = 'maximized';
for i = 1:2
    shg
    dcm_obj = datacursormode(1);
    set(dcm_obj,'DisplayStyle','window',...
    'SnapToDataVertex','off','Enable','on')
    waitforbuttonpress
    c_info{i} = getCursorInfo(dcm_obj);
    dataIndex{i} = c_info{i}.DataIndex;
end
close(fig);
time = data.Times(dataIndex{1}:dataIndex{2});
value = data.ImonA(dataIndex{1}:dataIndex{2});

time = time - time(1);



% fig = figure;
% plot(time, value, '-o')
% pause(0.2)
% fig.WindowState = 'maximized';
% 
% for i = 1:2
%     shg
%     dcm_obj = datacursormode(1);
%     set(dcm_obj,'DisplayStyle','window',...
%     'SnapToDataVertex','off','Enable','on')
%     waitforbuttonpress
%     m_info{i} = getCursorInfo(dcm_obj);
%     dataIndex{i} = m_info{i}.DataIndex;
% end
% close(fig);
% value = value - mean(value(dataIndex{1}:dataIndex{2}));

value = (value - min(value)) / ( max(value) - min(value));

time_interp = 0:0.001:time(numel(time));

value_interp = interp1(time, value, time_interp, 'linear');

f = @(b,x) b(1).*exp(x / b(2)) + b(3); % Objective Function
fcn = @(b) sum((f(b,time_interp) - value_interp).^2); 
options=optimset('MaxFunEvals', 5000,'MaxIter',10000,'TolX',1e-10,'TolFun',1e-6,'Display','iter','PlotFcns','optimplotfval');
%B = fminsearch(@(b) norm(value - f(b,time)), [0.00000000001; 10],options);
B = fminsearch(fcn, StartWerte,options);

fitValue = f(B,time_interp);
ftau = @(x) abs(log(2) * x);
rsquared = 1 - (sum((value_interp-fitValue).^2 ) / sum((value_interp-mean(value_interp)).^2));




fig = tiledlayout(1,1,'Padding','tight');
fig.Units = 'centimeters';
fig.OuterPosition = [0.25 0.25 8 8];
nexttile;

plot(time_interp, value_interp, '-o')
hold on
plot(time_interp, fitValue, '-r')
    
%S= sprintf('f(t) = %0.2e\\cdote^{%.3f\\cdott}', B);
%S= sprintf('f(t) = %0.2e\\cdote^{\\frac{ln(2)\\cdott}{%.3f}}', B(1), ftau(B));
%S = sprintf('$\\frac{ln(2)\cdott}{%.3f}$', B(1));
%S= sprintf('f(t) = %0.2e\\cdote^{%.3f\\cdott}', [B(1) ; 1/B(2)]);
%S = regexprep(S, 'e\+?(-?\d+)', '\\cdot10^{$q1}');

S1 = '$f(t) = ';
S2= sprintf('%0.2e', B(1));
S2 = regexprep(S2, 'e\+?(-?\d+)', '\\cdot 10^{$1}');
S3 = '\cdot e^{\frac{t}{';
S4 = num2str(B(2));
S5 = 's}}$ ';
S6 = ' + ';
S7 = num2str(B(3));

newFile  = regexprep(file, '\.asc$', '');
text(0.02, 0.6*(max(value)), [S1 S2 S3 S4 S5 S6 S7],'Interpreter','latex', 'FontSize',9);
%text(0.1, 0.6*(max(value)), S, 'Interpreter','latex' );
text(0.02, 0.5*(max(value)),sprintf('\\tau_{H} = %0.1f ms',ftau(B(2))*1000), 'FontSize',9)
text(0.02, 0.4*(max(value)),sprintf('r^2: %0.2f',rsquared), 'FontSize',9)
xlabel('t (s)') 
ylabel('f(t)')
title('AzoMenthol Y745H: Activation','Interpreter','none')
fig = gcf;

saveFig(fig, path, 8, '', newFile); %Ordner zum speichern auswählen
pause(1);
close;
%Aufbau Tabelle: Measurement	Mutation	Pharmacon	Type	Tau	Quality
%Patchstand

tauData = readtable('U:\Projekte an Analysis1\Clara\TRPM8\Messungen Patch3\Exportierte Daten AktDeakt AktInakt\Matlab Tau Auswertung.xlsx');
tauDataNew = [tauData;{newFile,'Y745H', 'AzoMenthol' ,'Activation',ftau(B(2))*1000, 99, 3, '' }];
writetable(tauDataNew, 'U:\Projekte an Analysis1\Clara\TRPM8\Messungen Patch3\Exportierte Daten AktDeakt AktInakt\Matlab Tau Auswertung.xlsx');
