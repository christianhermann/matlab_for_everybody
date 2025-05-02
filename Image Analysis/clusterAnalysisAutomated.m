%% Settings %%
zStacksSettings.Width = 33.2106; % microns
zStacksSettings.Height = 33.2106; % microns
zStacksSettings.Depth = 14.2; % microns
zStacksSettings.Dimensions = [1000 1000 71]; %[x y z]
zStacksSettings.Voxelsize = [0 0 0];
zStacksSettings.Voxelsize(1) = zStacksSettings.Width  /  zStacksSettings.Dimensions(1);
zStacksSettings.Voxelsize(2) = zStacksSettings.Height  /  zStacksSettings.Dimensions(2);
zStacksSettings.Voxelsize(3) = zStacksSettings.Depth  /  zStacksSettings.Dimensions(3);
zStacksSettings.voxelVolume = prod(zStacksSettings.Voxelsize); %um³
zStacksSettings.voxelVolumeUnit = "µm³";
bgMultiplier = 1.01;
% Set a minimum voxel size threshold
minVoxelSize = 150; % Adjust this value based on your requirement
threshold_cor = 0.5;
load("plotSettings.mat");

%% Import Image Data and Labels %% 

filePathNuclearReceptor = "pA_cpmTq2-GR + Cycloheximid + 1um Dexa_15min_02.tif";

zStacks.NuclearReceptor.Raw.Intensities = tiffreadVolume(filePathNuclearReceptor);

labels.BackgroundCluster = load('labelClusterBG.mat').labels;

%% Calculate Backgrounds
zStacks.NuclearReceptor.Background.Intensities = median(zStacks.NuclearReceptor.Raw.Intensities(labels.BackgroundCluster));
zStacks.NuclearReceptor.IntensitiesWithoutBackground.Intensities = zStacks.NuclearReceptor.Raw.Intensities - zStacks.NuclearReceptor.Background.Intensities;



volshow(zStacks.NuclearReceptor.IntensitiesWithoutBackground.Intensities, plotSettings.MIP);

zStacks.NuclearReceptor.IntensitiesWithoutBackground.threshold = graythresh(zStacks.NuclearReceptor.IntensitiesWithoutBackground.Intensities);

% Convert grayscale image to binary using the threshold
zStacks.NuclearReceptor.IntensitiesWithoutBackground.binaryStack = imbinarize(zStacks.NuclearReceptor.IntensitiesWithoutBackground.Intensities, zStacks.NuclearReceptor.IntensitiesWithoutBackground.threshold + threshold_cor);

% Perform morphological reconstruction to merge nearby regions
se = strel('sphere', 1); % Adjust the size of the structuring element as needed
zStacks.NuclearReceptor.IntensitiesWithoutBackground.binaryStackReconstructed = imdilate(zStacks.NuclearReceptor.IntensitiesWithoutBackground.binaryStack, se);

% Perform 3D connected component analysis on the reconstructed image
zStacks.NuclearReceptor.IntensitiesWithoutBackground.ccReconstructed = bwconncomp(zStacks.NuclearReceptor.IntensitiesWithoutBackground.binaryStackReconstructed, 26); % 26-connectivity for 3D


% Filter out smaller objects
zStacks.NuclearReceptor.IntensitiesWithoutBackground.ccFiltered = zStacks.NuclearReceptor.IntensitiesWithoutBackground.ccReconstructed;
zStacks.NuclearReceptor.IntensitiesWithoutBackground.ccFiltered.PixelIdxList = zStacks.NuclearReceptor.IntensitiesWithoutBackground.ccReconstructed.PixelIdxList(cellfun(@numel, zStacks.NuclearReceptor.IntensitiesWithoutBackground.ccReconstructed.PixelIdxList) >= minVoxelSize);
zStacks.NuclearReceptor.IntensitiesWithoutBackground.ccFiltered.NumObjects = width(zStacks.NuclearReceptor.IntensitiesWithoutBackground.ccFiltered.PixelIdxList);
zStacks.NuclearReceptor.IntensitiesWithoutBackground.props = regionprops3(zStacks.NuclearReceptor.IntensitiesWithoutBackground.ccFiltered, 'all');


volumes = zStacks.NuclearReceptor.IntensitiesWithoutBackground.props.Volume;
intensity.Sum.Raw = cellfun(@(x) sum(zStacks.NuclearReceptor.Raw.Intensities(x),'all'), zStacks.NuclearReceptor.IntensitiesWithoutBackground.props.VoxelIdxList, 'UniformOutput', false);
intensity.Median.Raw = cellfun(@(x) median(nonzeros(double(zStacks.NuclearReceptor.Raw.Intensities(x)))), zStacks.NuclearReceptor.IntensitiesWithoutBackground.props.VoxelIdxList, 'UniformOutput', false);
intensity.Sum.dividedbyVolume.Raw = intensity.Sum.Raw{1} / volumes * zStacksSettings.voxelVolume;
intensity.Median.dividedbyVolume.Raw = intensity.Median.Raw{1} / volumes * zStacksSettings.voxelVolume;

intensity.Sum.BackgroundCorrected = cellfun(@(x) sum(zStacks.NuclearReceptor.IntensitiesWithoutBackground.Intensities(x),'all'), zStacks.NuclearReceptor.IntensitiesWithoutBackground.props.VoxelIdxList, 'UniformOutput', false);
intensity.Median.BackgroundCorrected = cellfun(@(x) median(nonzeros(double(zStacks.NuclearReceptor.IntensitiesWithoutBackground.Intensities(x)))), zStacks.NuclearReceptor.IntensitiesWithoutBackground.props.VoxelIdxList, 'UniformOutput', false);
intensity.Sum.dividedbyVolume.BackgroundCorrected = intensity.Sum.BackgroundCorrected{1} / volumes * zStacksSettings.voxelVolume;
intensity.Median.dividedbyVolume.BackgroundCorrected = intensity.Median.BackgroundCorrected{1} / volumes * zStacksSettings.voxelVolume;

flatStruct = flattenStruct(intensity);

clusterTable = struct2table(flatStruct);
clusterTable.Voxel = volumes;
clusterTable.Volume = volumes * zStacksSettings.voxelVolume;
clusterTable.VolumeUnit = zStacksSettings.voxelVolumeUnit;
clusterTable.Name = repmat(filePathNuclearReceptor, height(clusterTable),1);
clusterTable.Cluster = (1:height(clusterTable))';


% Create a 3D figure using volshow
hVolume = volshow(zStacks.NuclearReceptor.IntensitiesWithoutBackground.Intensities, plotSettings.Gradient); % You can adjust the renderer based on your preference


% Create a binary overlay highlighting the traced cluster boundaries
overlayData = zeros(size(zStacks.NuclearReceptor.IntensitiesWithoutBackground.Intensities));
for k = 1:length(zStacks.NuclearReceptor.IntensitiesWithoutBackground.ccFiltered.PixelIdxList)
    overlayData(zStacks.NuclearReceptor.IntensitiesWithoutBackground.ccFiltered.PixelIdxList{k}) = 1;
end

% Overlay the traced cluster boundaries on the 3D volume using 'OverlayData'
hVolume.OverlayAlphamap = 0.9;
hVolume.OverlayRenderingStyle = "LabelOverlay";
hVolume.OverlayData = overlayData;
