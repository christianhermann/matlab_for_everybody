addpath(genpath('U:\Projekte an Analysis1\Christian\Matlab for everybody\Photoswitch Fit Ramps'))

StartWerte = [0.001; 0.05; 0.001; 0.11; 0.01];
[file, path] = uigetfile('*.asc');
data = importfileRamps(fullfile(path,file));
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
value = (value - min(value)) / ( max(value) - min(value) );


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

value = (value - min(value)) / ( max(value) - min(value) );
f = @(b,x) (b(1).*exp(x / b(2)) + b(3).*exp(x / b(4))) + b(5) ; % Objective Function
fcn = @(b) sum((f(b,time) - value).^2); 
options=optimset('MaxFunEvals', 5000,'MaxIter',10000,'TolX',1e-10,'TolFun',1e-6,'Display','iter','PlotFcns','optimplotfval');
%B = fminsearch(@(b) norm(value - f(b,time)), [0.00000000001; 10],options);
B = fminsearch(fcn, StartWerte,options);
fitValue = f(B,time);
ftau = @(x) abs(log(2) * x);
rsquared = 1 - (sum((value-fitValue).^2 ) / sum((value-mean(value)).^2));

fig = tiledlayout(1,1,'Padding','tight');
fig.Units = 'centimeters';
fig.OuterPosition = [0.25 0.25 8 8];
nexttile;

plot(time, value, '-o')
hold on
plot(time, f(B,time), '-r')

newFile  = append(regexprep(file, '\.asc$', ''), 'InAkt');

S1 = '$f(t) = ';
S2= sprintf('%0.2e', B(1));
S2 = regexprep(S2, 'e\+?(-?\d+)', '\\cdot 10^{$1}');
S3 = '\cdot e^{\frac{t}{';
S4 = num2str(B(2));
S5 = 's}}+ ';
S6 = sprintf('%0.2e', B(3));
S6 = regexprep(S6, 'e\+?(-?\d+)', '\\cdot 10^{$1}');
S7 = '\cdot e^{\frac{t}{';
S8 = num2str(B(4));
S9 = 's}}$';
S10 = ' + ';
S11 = num2str(B(5));

text(0.1, 0.7*(max(value)), [S1 S2 S3 S4 S5 S6 S7 S8 S9 S10 S11],'Interpreter','latex', 'FontSize',14);
text(0.1, 0.6*(max(value)),sprintf('\\tau_{1H} = %0.5f s',ftau(B(2))))
text(0.1, 0.5*(max(value)),sprintf('\\tau_{2H} = %0.5f s',ftau(B(4))))
text(0.1, 0.4*(max(value)),sprintf('r^2: %0.5f',rsquared))

xlabel('t (s)') 
ylabel('f(t)')
title('OptoBI S814A_S835A: Inactivation','Interpreter','none')
fig = gcf;

saveFig(fig, path, 4, '\Tau Auswertung', newFile); %Ordner zum speichern auswählen

pause(2);
close;
tauData = readtable('U:\Projekte an Analysis1\Clara\TRPM8\Messungen Patch3\Exportierte Daten AktDeakt AktInakt\Matlab Tau Auswertung.xlsx');
tauDataNew = [tauData;{newFile,'S814A_S835A', 'OptoBI' ,'Activation - Fast',ftau(B(2))*1000, 99, 3 }];
tauDataNew = [tauDataNew;{newFile,'S814A_S835A', 'OptoBI' ,'Activation - Slow',ftau(B(4))*1000, 99, 3 }];
writetable(tauDataNew, 'U:\Projekte an Analysis1\Clara\TRPM8\Messungen Patch3\Exportierte Daten AktDeakt AktInakt\Matlab Tau Auswertung.xlsx');


