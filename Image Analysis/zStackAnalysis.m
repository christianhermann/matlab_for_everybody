%% Settings %%
zStacksSettings.Width = 33.2106; % microns
zStacksSettings.Height = 33.2106; % microns
zStacksSettings.Depth = 14.2; % microns
zStacksSettings.Dimensions = [1000 1000 19]; %[x y z]
zStacksSettings.Voxelsize = [0 0 0];
zStacksSettings.Voxelsize(1) = zStacksSettings.Width  /  zStacksSettings.Dimensions(1);
zStacksSettings.Voxelsize(2) = zStacksSettings.Height  /  zStacksSettings.Dimensions(2);
zStacksSettings.Voxelsize(3) = zStacksSettings.Depth  /  zStacksSettings.Dimensions(3);
zStacksSettings.voxelVolume = prod(zStacksSettings.Voxelsize); %um³
bgMultiplier = 1.01;
bgManual = 1000;
load("plotSettings.mat");
%% Import Image Data and Labels %% 

folder = "U:\Projekte\Christian\Matlab_for_everybody\Image Analysis\Lingfei\GR-ohne-30min\GR-ohne-30min-6";
fileNameNuclearReceptor = "C2-pA-GR-ohne-30min-6.tif"


%Ohne Histogramme
[zStacks, labels, volume, intensity, intensityDividedByVolume] = ...
    zStackAnalysisFunction(bgMultiplier, zStacksSettings, folder, bgManual, fileNameNuclearReceptor);

%Mit Histogramme
%[zStacks, labels, volume, intensity, intensityDividedByVolume, histoCell, histoCytoplasmaCalc, histoCytoplasmaDrawn, histoNucleus] = ...
%    zStackAnalysisFunction(bgMultiplier, zStacksSettings, folder, fileNameNuclearReceptor);

%[zStacks, labels, volume, intensity, intensityDividedByVolume, histoCell, histoCytoplasmaCalc, histoCytoplasmaDrawn, histoNucleus] = ...
%    clusterAnalysisFunction(bgMultiplier, zStacksSettings, folder, fileNameNuclearReceptor, fileNameNucleus, fileNameCytoplasma);

%VolumePlot(zStacksSettings, zStacks.NuclearReceptor.IntensitiesWithoutBackground, plotSettings, "grad");


