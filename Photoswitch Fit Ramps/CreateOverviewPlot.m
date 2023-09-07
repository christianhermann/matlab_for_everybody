addpath(genpath('U:\Projekte an Analysis1\Christian\Matlab for everybody\Photoswitch Fit Ramps'))

pharmacon2 = 'OptoBI';
pharmacon1 = 'OptoBI';
mutation2 = 'WT';
mutation1 = 'WT';
nameFigure = 'ÜbersichtWT';
ismutation = true; %true wenn Mutation verglichen werden soll
plotHeight = 15;

tauData = readtable('U:\Projekte an Analysis1\Clara\TRPM8\Messungen Patch3\Exportierte Daten AktDeakt AktInakt\Matlab Tau Auswertung.xlsx');


[pAkt,hAkt,statsAkt] = ranksum(tauData(strcmp(tauData.Pharmacon,pharmacon1) & strcmp(tauData.Type,'Activation') & strcmp(tauData.Mutation,mutation1) & tauData.Quality == 1,:).Tau, tauData(strcmp(tauData.Pharmacon,pharmacon2) & strcmp(tauData.Mutation,mutation2) & strcmp(tauData.Type,'Activation') & tauData.Quality == 1,:).Tau);
[pDeakt,hpDeakt,statspDeakt] = ranksum(tauData(strcmp(tauData.Pharmacon,pharmacon1) & strcmp(tauData.Type,'Deactivation') & strcmp(tauData.Mutation,mutation1) & tauData.Quality == 1,:).Tau, tauData(strcmp(tauData.Pharmacon,pharmacon2) & strcmp(tauData.Mutation,mutation2) & strcmp(tauData.Type,'Deactivation') & tauData.Quality == 1,:).Tau);
%[pInakt,hInakt,statsInakt] = ranksum(tauData(strcmp(tauData.Pharmacon,pharmacon1) & strcmp(tauData.Type,'Inactivation') & strcmp(tauData.Mutation,mutation1) & tauData.Quality == 1,:).Tau, tauData(strcmp(tauData.Pharmacon,pharmacon2) & strcmp(tauData.Mutation,mutation2) & strcmp(tauData.Type,'Inactivation') & tauData.Quality == 1,:).Tau);


fig = figure();
g = gramm('x',tauData.Type,'y',tauData.Tau,'color',tauData.Pharmacon,'subset',tauData.Quality == 1 & strcmp(tauData.Mutation, mutation1), 'ymin',  repelem(0, height(tauData)), 'ymax',  repelem(plotHeight, height(tauData)));
if ismutation == true 
    g = gramm('x',tauData.Type,'y',tauData.Tau,'color',tauData.Mutation,'subset',tauData.Quality == 1 & strcmp(tauData.Pharmacon, pharmacon1), 'ymin',  repelem(0, height(tauData)), 'ymax',  repelem(plotHeight, height(tauData)));
end
g.stat_violin('fill','transparent','dodge',0.7, 'normalization','width');
g.no_legend()
g.stat_boxplot('width',0.15,'dodge',0.7);
g.no_legend()
g.set_names('x','Type','y','Tau1/2','color','Pharmakon')
if ismutation == true
    g.set_names('x','Type','y','Tau1/2','color','Mutation')
    g.set_order_options('color' ,{mutation1 mutation2});
end 
if ismutation == false
    g.set_order_options('color' ,{pharmacon1 pharmacon2});
end
g.draw();
g.update();
g.geom_jitter('dodge',0.7);
g.draw();
text(0.8,40,{['p = ' sprintf('%0.4f', pAkt)]},'Parent',g.facet_axes_handles,'FontName','Arial');
text(1.8,92,{['p = ' sprintf('%0.4f', pDeakt)]},'Parent',g.facet_axes_handles,'FontName','Arial');
text(2.7,30,{['p = ' sprintf('%0.4f', pInakt)]},'Parent',g.facet_axes_handles,'FontName','Arial');

saveFig(fig, path, 3, '\Tau Auswertung', nameFigure); %Ordner zum speichern auswählen
