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

filePathStainingNucleus = "pAz_cpmTq2-MR + NucSpot 650 starving_NucSpot.tif";
filePathStainingCytoplasma = "pAz_cpmTq2-MR + NucSpot 650 starving_MR.tif";
filePathNuclearReceptor = "pAz_cpmTq2-MR + NucSpot 650 starving_MR.tif";


zStacks.Nucleus.Intensities = tiffreadVolume(filePathStainingNucleus);
zStacks.Cytoplasma.Intensities = tiffreadVolume(filePathStainingCytoplasma);
zStacks.NuclearReceptor.Intensities = tiffreadVolume(filePathNuclearReceptor);

labels.Nucleus.Drawn = load('labelNucleus.mat').labels;
labels.Cell.Drawn = load('labelCytoplasma.mat').labels;

labels.BackgroundCytoplasma = load('labelCytoplasmaBG.mat').labels;

%% Calculate Backgrounds
zStacks.Nucleus.Background = median(zStacks.Nucleus.Intensities(labels.BackgroundCytoplasma));
zStacks.Cytoplasma.Background = median(zStacks.Cytoplasma.Intensities(labels.BackgroundCytoplasma));
zStacks.NuclearReceptor.Background = median(zStacks.Cytoplasma.Intensities(labels.BackgroundCytoplasma));

%% Create Labels
labels.Cytoplasma.Calculated = zStacks.Cytoplasma.Intensities;
labels.Cytoplasma.Calculated(labels.Cytoplasma.Calculated < zStacks.Cytoplasma.Background * bgMultiplier) = 0;
labels.Cytoplasma.Calculated = labels.Cytoplasma.Calculated .* uint16(labels.Cell.Drawn);
labels.Cytoplasma.Calculated(labels.Cytoplasma.Calculated > 0) = 1;

labels.Cytoplasma.Drawn = uint16(labels.Cell.Drawn);
labels.Cytoplasma.Drawn(uint16(labels.Nucleus.Drawn) == 1) = 0;

zStacks.Nucleus.labels.Nucleus.Drawn = zStacks.Nucleus.Intensities .* uint16(labels.Nucleus.Drawn);
zStacks.Nucleus.labels.Cell.Drawn = zStacks.Nucleus.Intensities .* uint16(labels.Cell.Drawn);
zStacks.Nucleus.labels.Cytoplasma.Calculated = zStacks.Nucleus.Intensities .* uint16(labels.Cytoplasma.Calculated);
zStacks.Nucleus.labels.Cytoplasma.Drawn = zStacks.Nucleus.Intensities .* uint16(labels.Cytoplasma.Drawn);

zStacks.Cytoplasma.labels.Nucleus.Drawn = zStacks.Cytoplasma.Intensities .* uint16(labels.Nucleus.Drawn);
zStacks.Cytoplasma.labels.Cell.Drawn = zStacks.Cytoplasma.Intensities .* uint16(labels.Cell.Drawn);
zStacks.Cytoplasma.labels.Cytoplasma.Calculated = zStacks.Cytoplasma.Intensities .* uint16(labels.Cytoplasma.Calculated);
zStacks.Cytoplasma.labels.Cytoplasma.Drawn = zStacks.Cytoplasma.Intensities .* uint16(labels.Cytoplasma.Drawn);

zStacks.NuclearReceptor.labels.Nucleus.Drawn = zStacks.NuclearReceptor.Intensities .* uint16(labels.Nucleus.Drawn);
zStacks.NuclearReceptor.labels.Cell.Drawn = zStacks.NuclearReceptor.Intensities .* uint16(labels.Cell.Drawn);
zStacks.NuclearReceptor.labels.Cytoplasma.Calculated = zStacks.NuclearReceptor.Intensities .* uint16(labels.Cytoplasma.Calculated);
zStacks.NuclearReceptor.labels.Cytoplasma.Drawn = zStacks.NuclearReceptor.Intensities .* uint16(labels.Cytoplasma.Drawn);

zStacks.NuclearReceptor.IntensitiesWithoutBackground = zStacks.NuclearReceptor.Intensities - zStacks.NuclearReceptor.Background;

%% Volumes
volume.Cell = sum(labels.Cell.Drawn(:)) * zStacksSettings.voxelVolume;
volume.Nucleus = sum(labels.Nucleus.Drawn(:)) * zStacksSettings.voxelVolume;
volume.CytoplasmaLabel = sum(labels.Cytoplasma.Drawn(:)) * zStacksSettings.voxelVolume;
volume.CytoplasmaBG = sum(labels.Cytoplasma.Calculated(:)) * zStacksSettings.voxelVolume;
volume.ratioNucleusCell = volume.Nucleus / volume.Cell;
volume.ratioNucleusCytoplasmaDrawn = volume.Nucleus / volume.CytoplasmaLabel;
volume.ratioNucleusCytoplasmaCalculated = volume.Nucleus / volume.CytoplasmaBG;
volume.unit = "µm³";
intensityTable = struct2table(volume);
intensityTable.name = [filePathNuclearReceptor filePathStainingCytoplasma filePathStainingNucleus];

%% Intensitys
intensity.Sum.Raw.Cell = sum(zStacks.NuclearReceptor.labels.Cell.Drawn(:));
intensity.Sum.Raw.CytoplasmaLabel = sum(zStacks.NuclearReceptor.labels.Cytoplasma.Calculated(:));
intensity.Sum.Raw.CytoplasmaBG = sum(zStacks.NuclearReceptor.labels.Cytoplasma.Drawn(:));
intensity.Sum.Raw.Nucleus = sum(zStacks.NuclearReceptor.labels.Nucleus.Drawn(:));

intensity.Sum.BGCorrected.Cell = sum(zStacks.NuclearReceptor.labels.Cell.Drawn(zStacks.NuclearReceptor.labels.Cell.Drawn ~= 0) - zStacks.NuclearReceptor.Background, 'all');
intensity.Sum.BGCorrected.CytoplasmaLabel = sum(zStacks.NuclearReceptor.labels.Cytoplasma.Calculated(zStacks.NuclearReceptor.labels.Cytoplasma.Calculated ~= 0) - zStacks.NuclearReceptor.Background, 'all');
intensity.Sum.BGCorrected.CytoplasmaBG = sum(zStacks.NuclearReceptor.labels.Cytoplasma.Drawn(zStacks.NuclearReceptor.labels.Cytoplasma.Drawn ~= 0) - zStacks.NuclearReceptor.Background,'all');
intensity.Sum.BGCorrected.Nucleus = sum(zStacks.NuclearReceptor.labels.Nucleus.Drawn(zStacks.NuclearReceptor.labels.Nucleus.Drawn ~= 0) - zStacks.NuclearReceptor.Background, 'all');

intensity.Median.Raw.Cell = median(double(zStacks.NuclearReceptor.labels.Cell.Drawn(zStacks.NuclearReceptor.labels.Cell.Drawn ~= 0)));
intensity.Median.Raw.CytoplasmaLabel = median(double(zStacks.NuclearReceptor.labels.Cytoplasma.Calculated(zStacks.NuclearReceptor.labels.Cytoplasma.Calculated ~= 0)));
intensity.Median.Raw.CytoplasmaBG = median(double(zStacks.NuclearReceptor.labels.Cytoplasma.Drawn(zStacks.NuclearReceptor.labels.Cytoplasma.Drawn ~= 0)));
intensity.Median.Raw.Nucleus = median(double(zStacks.NuclearReceptor.labels.Nucleus.Drawn(zStacks.NuclearReceptor.labels.Nucleus.Drawn ~= 0)));

intensity.Median.BGCorrected.Cell = median(double(zStacks.NuclearReceptor.labels.Cell.Drawn(zStacks.NuclearReceptor.labels.Cell.Drawn ~= 0)) - double(zStacks.NuclearReceptor.Background));
intensity.Median.BGCorrected.CytoplasmaLabel = median(double(zStacks.NuclearReceptor.labels.Cytoplasma.Calculated(zStacks.NuclearReceptor.labels.Cytoplasma.Calculated ~= 0)) - double(zStacks.NuclearReceptor.Background));
intensity.Median.BGCorrected.CytoplasmaBG = median(double(zStacks.NuclearReceptor.labels.Cytoplasma.Drawn(zStacks.NuclearReceptor.labels.Cytoplasma.Drawn ~= 0)) - double(zStacks.NuclearReceptor.Background));
intensity.Median.BGCorrected.Nucleus = median(double(zStacks.NuclearReceptor.labels.Nucleus.Drawn(zStacks.NuclearReceptor.labels.Nucleus.Drawn ~= 0)) - double(zStacks.NuclearReceptor.Background));

intensity.Ratio.Sum.Raw.NucleusCell = intensity.Sum.Raw.Nucleus / intensity.Sum.Raw.Cell;
intensity.Ratio.Sum.Raw.NucleusCytoplasmaDrawn = intensity.Sum.Raw.Nucleus / intensity.Sum.Raw.CytoplasmaLabel;
intensity.Ratio.Sum.Raw.NucleusCytoplasmaCalculated = intensity.Sum.Raw.Nucleus / intensity.Sum.Raw.CytoplasmaBG;

intensity.Ratio.Sum.BGCorrected.NucleusCell = intensity.Sum.BGCorrected.Nucleus / intensity.Sum.BGCorrected.Cell;
intensity.Ratio.Sum.BGCorrected.NucleusCytoplasmaDrawn = intensity.Sum.BGCorrected.Nucleus / intensity.Sum.BGCorrected.CytoplasmaLabel;
intensity.Ratio.Sum.BGCorrected.NucleusCytoplasmaCalculated = intensity.Sum.BGCorrected.Nucleus / intensity.Sum.BGCorrected.CytoplasmaBG;

intensity.Ratio.Median.Raw.NucleusCell = intensity.Median.Raw.Nucleus / intensity.Median.Raw.Cell;
intensity.Ratio.Median.Raw.NucleusCytoplasmaDrawn = intensity.Median.Raw.Nucleus / intensity.Median.Raw.CytoplasmaLabel;
intensity.Ratio.Median.Raw.NucleusCytoplasmaCalculated = intensity.Median.Raw.Nucleus / intensity.Median.Raw.CytoplasmaBG;

intensity.Ratio.Median.BGCorrected.NucleusCell = intensity.Median.BGCorrected.Nucleus / intensity.Median.BGCorrected.Cell;
intensity.Ratio.Median.BGCorrected.NucleusCytoplasmaDrawn = intensity.Median.BGCorrected.Nucleus / intensity.Median.BGCorrected.CytoplasmaLabel;
intensity.Ratio.Median.BGCorrected.NucleusCytoplasmaCalculated = intensity.Median.BGCorrected.Nucleus / intensity.Median.BGCorrected.CytoplasmaBG;

flatStruct = flattenStruct(flattenStruct(flattenStruct(intensity)));

intensityTable = struct2table(flatStruct);
intensityTable.name = [filePathNuclearReceptor filePathStainingCytoplasma filePathStainingNucleus];
%% Plot
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