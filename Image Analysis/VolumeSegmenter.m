%% Settings %%
zStacksSettings.Width = 33.2106; % microns
zStacksSettings.Height = 33.2106; % microns
zStacksSettings.Depth = 14.2; % microns
zStacksSettings.Dimensions = [1000 1000 36]; %[x y z]
zStacksSettings.Voxelsize = [0 0 0];
zStacksSettings.Voxelsize(1) = zStacksSettings.Width  /  zStacksSettings.Dimensions(1);
zStacksSettings.Voxelsize(2) = zStacksSettings.Height  /  zStacksSettings.Dimensions(2);
zStacksSettings.Voxelsize(3) = zStacksSettings.Depth  /  zStacksSettings.Dimensions(3);
zStacksSettings.voxelVolume = prod(zStacksSettings.Voxelsize); %um³
bgMultiplier = 1.01;
load("plotSettings.mat");
%% Import Image Data and Labels %% 

folder = "U:\Projekte\Christian\Matlab_for_everybody\Image Analysis\Lingfei\GR-ohne-30min\GR-ohne-30min-6";
fileNameNuclearReceptor = "C1-pA-GR-ohne-30min-6.tif"

vol = tiffreadVolume(fullfile(folder, fileNameNuclearReceptor));
VolumePlot(zStacksSettings, vol, plotSettings, "MIP")
threshold = graythresh(vol);
binaryImage = imbinarize(vol, threshold +0.1);
VolumePlot(zStacksSettings, binaryImage, plotSettings, "MIP")

volumeSegmenter(uint16(binaryImage));
volumeSegmenter(vol);