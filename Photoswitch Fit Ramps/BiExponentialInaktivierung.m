addpath(genpath('U:\Projekte an Analysis1\Christian\Matlab for everybody\Photoswitch Fit Ramps'))
close all;
%StartWerte = [1; 25; 1; 100] von Christian: A1;T1;A2;T2 (äquvalent zu
%Origin)
StartWerte = [1; 0.02; 1; 3.8; 0.1];
Grenzen = [0 0 0 0 -inf];
%False wenn Deaktivierung (Ändert die Darstellung der Formel)
Inaktivierung = true;

[file, path] = uigetfile('*.asc');
%data = importfileRamps(fullfile(path,file)); Für Rampen!
data = importfile(fullfile(path,file));% Für Haltepotential
data.ImonA = data.ImonA * - 1;  % Für Haltepotential

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
% plot(time((length(time)-1000):length(time)), value(length(time)-1000:length(time)), '-o')
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
% dataIndex{1} = length(time) - (1000-dataIndex{1});
% dataIndex{2} = length(time) - (1000-dataIndex{2});
% 
% value = value - mean(value(dataIndex{1}:dataIndex{2}));
value = (value - min(value)) / ( max(value) - min(value) );

f = @(b,x) b(1).*exp(-x / b(2)) + b(3).*exp(-x/b(4)) + b(5); % Objective Function
fcn = @(b) sum((f(b,time) - value).^2); 
options=optimset('MaxFunEvals', 5000,'MaxIter',10000,'TolX',1e-10,'TolFun',1e-6,'Display','iter','PlotFcns','optimplotfval');
%B = fminsearch(@(b) norm(value - f(b,time)), [0.00000000001; 10],options);
%B = fminsearch(fcn, StartWerte,options);
B = fminsearchbnd(fcn, StartWerte,Grenzen,[], options);
% John D'Errico (2023). fminsearchbnd, fminsearchcon (https://www.mathworks.com/matlabcentral/fileexchange/8277-fminsearchbnd-fminsearchcon), MATLAB Central File Exchange. Retrieved June 20, 2023. 


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

S1 = '$f(t) = ';
S2= sprintf('%0.2f', B(1));
if Inaktivierung == false
   S2= sprintf('%0.2e', B(1)); 
   S2 = regexprep(S2, 'e\+?(-?\d+)', '\\cdot 10^{$1}');
end
S3 = '\cdot e^{-\frac{t}{';
S4 = num2str(B(2));
S5 = 's}}+ ';
S6 = sprintf('%0.2f', B(3));
if Inaktivierung == false
    S6 = sprintf('%0.2e', B(3));
    S6 = regexprep(S6, 'e\+?(-?\d+)', '\\cdot 10^{$1}');
end
S7 = '\cdot e^{-\frac{t}{';
S8 = num2str(B(4));
S9 = 's}}$';
S10 = ' + ';
S11 = num2str(B(5));

newFile  = append(regexprep(file, '\.asc$', ''), 'InAkt');
text(0.3, 0.2*(max(value)), [S1 S2 S3 S4 S5 S6 S7 S8 S9 S10 S11],'Interpreter','latex', 'FontSize',9)
text(0.3, 0.15*(max(value)),sprintf('\\tau_{H} = %0.1f ms',ftau(B(2))*1000), 'FontSize',9)
text(0.3, 0.1*(max(value)),sprintf('\\tau_{H2} = %0.5f s',ftau(B(4))), 'FontSize',9)
text(0.3, 0.05*(max(value)),sprintf('r^2: %0.5f',rsquared), 'FontSize',9)
xlabel('t (s)') 
ylabel('f(t)')
title('OptoDArG M117L: Inactivation','Interpreter','none') %Benennung im Bild
fig = gcf;

saveFig(fig, path, 3, '\Auswertung\Tau Auswertung Bilder Inakt', newFile); %Ordner zum speichern auswählen
pause(2);
close;
tauData = readtable('U:\Projekte an Analysis1\Sebastian TRPC6\Auswertung\Matlab\Tau Data Seb.xlsx');
tauDataNew = [tauData;{newFile,'M117L', 'OptoDArG' ,'Inactivation - Fast',ftau(B(2))*1000, 99, 2 }];
tauDataNew = [tauDataNew;{newFile,'M117L', 'OptoDArG' ,'Inactivation - Slow',ftau(B(4))*1000, 99, 2 }];
writetable(tauDataNew,  'U:\Projekte an Analysis1\Sebastian TRPC6\Auswertung\Matlab\Tau Data Seb.xlsx');
