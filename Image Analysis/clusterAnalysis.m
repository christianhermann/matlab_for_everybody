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
bgMultiplier = 1.01;
load("plotSettings.mat");
%% Import Image Data and Labels %% 

filePathNuclearReceptor = "pA_cpmTq2-GR + Cycloheximid + 1um Dexa_5min_02.tif";

zStacks.NuclearReceptor.Intensities = tiffreadVolume(filePathNuclearReceptor);

labels.BackgroundCluster = load('labelClusterBG.mat').labels;

labels.Cluster = load('labelCluster.mat').labels;

%% Calculate Backgrounds
zStacks.NuclearReceptor.Background = median(zStacks.NuclearReceptor.Intensities(labels.BackgroundCluster));
zStacks.NuclearReceptor.IntensitiesWithoutBackground = zStacks.NuclearReceptor.Intensities - zStacks.NuclearReceptor.Background;

%% Image
A = [zStacksSettings.Voxelsize(1) 0 0 0; 0 zStacksSettings.Voxelsize(2) 0 0; 0 0 zStacksSettings.Voxelsize(3) 0; 0 0 0 1];
tform = affinetform3d(A);

viewerMIP = viewer3d(BackgroundColor="black", GradientColor=[0.5 0.5 0.5],Lighting="on",BackgroundGradient="off");
volBGCorrectedMIP = volshow(zStacks.NuclearReceptor.IntensitiesWithoutBackground, plotSettings.MIP, "Transformation",tform, "Parent", viewerMIP);
viewerGrad = viewer3d(BackgroundColor="black", GradientColor=[0.5 0.5 0.5],Lighting="on",BackgroundGradient="off");
volBGCorrectedGrad = volshow(zStacks.NuclearReceptor.IntensitiesWithoutBackground, plotSettings.Gradient, "Transformation",tform, "Parent", viewerGrad);
viewerVol = viewer3d(BackgroundColor="black", GradientColor=[0.5 0.5 0.5],Lighting="on",BackgroundGradient="off");
volBGCorrectedVol = volshow(zStacks.NuclearReceptor.IntensitiesWithoutBackground, plotSettings.Volume, "Transformation",tform, "Parent", viewerVol);

frameMIP = getframe(viewerMIP.Parent);
fMIP = figure('Position',[0 0 561 421]);
axMIP = axes(fMIP);
imagesc(axMIP,frameMIP.cdata);

frameGrad = getframe(viewerGrad.Parent);
fGrad = figure('Position',[0 0 561 421]);
axGrad = axes(fGrad);
imagesc(axGrad,frameGrad.cdata);

frameVol = getframe(viewerVol.Parent);
fVol = figure('Position',[0 0 561 421]);
axVol = axes(fVol);
imagesc(axVol,frameVol.cdata);

hFig = viewerMIP.Parent;
sz = size(zStacks.NuclearReceptor.IntensitiesWithoutBackground);
center = sz/2 + 0.5;
filename = "animated.gif";
numberOfFrames = 48;
vec = linspace(0,2*pi,numberOfFrames)';
dist = sqrt(sz(1)^2 + sz(2)^2 + sz(3)^2);
myPosition = center + ([cos(vec) sin(vec) ones(size(vec))]*dist);

for idx = 1:length(vec)
    % Update the current view
    viewerMIP.CameraPosition = myPosition(idx,:);
    % Capture the image using the getframe function
    I = getframe(hFig);
    [indI,cm] = rgb2ind(I.cdata,256);
    % Write the frame to the GIF file
    if idx==1
        % Do nothing. The first frame displays only the viewer, not the
        % volume.
    elseif idx == 2
        imwrite(indI,cm,filename,"gif",Loopcount=inf,DelayTime=0)
    else
        imwrite(indI,cm,filename,"gif",WriteMode="append",DelayTime=0)
    end
end
%% Cluster Analysis%%
CC = bwconncomp(labels.Cluster,26);
ind = cellfun(@(x) numel(x) == 1, CC.PixelIdxList);
CC.PixelIdxListFilt = CC.PixelIdxList(~ind);

props = regionprops3(bwconncomp(labels.Cluster,26), 'all');
volumes = props.Volume;
intensity.Sum.Raw = cellfun(@(x) sum(zStacks.NuclearReceptor.Intensities(x),'all'), props.VoxelIdxList, 'UniformOutput', false);
intensity.Median.Raw = cellfun(@(x) median(nonzeros(double(zStacks.NuclearReceptor.Intensities(x)))), props.VoxelIdxList, 'UniformOutput', false);

intensity.Sum.BackgroundCorrected = cellfun(@(x) sum(zStacks.NuclearReceptor.IntensitiesWithoutBackground(x),'all'), props.VoxelIdxList, 'UniformOutput', false);
intensity.Median.BackgroundCorrected = cellfun(@(x) median(nonzeros(double(zStacks.NuclearReceptor.IntensitiesWithoutBackground(x)))), props.VoxelIdxList, 'UniformOutput', false);

flatStruct = flattenStruct(intensity);

clusterTable = struct2table(flatStruct);
clusterTable.Volume = volumes * zStacksSettings.voxelVolume;
clusterTable.Name = repmat(filePathNuclearReceptor, height(clusterTable),1);
clusterTable.Size = volumes;
clusterTable.Cluster = (1:height(clusterTable))';
