%% Settings %%
imgSettings.Width = 33.2106; % microns
imgSettings.Height = 33.2106; % microns
imgSettings.Depth = 14.2; % microns
imgSettings.Dimensions = [1000 1000 71]; %[x y z]
imgSettings.Voxelsize = [0 0 0];
imgSettings.Voxelsize(1) = imgSettings.Width / imgSettings.Dimensions(1);
imgSettings.Voxelsize(2) = imgSettings.Height / imgSettings.Dimensions(2);
imgSettings.Voxelsize(3) = imgSettings.Depth / imgSettings.Dimensions(3);
imgSettings.voxelVolume = prod(imgSettings.Voxelsize); %um³
bgMultiplier = 1.01;
%% Import Image Data and Labels %% 

imageNucleus = "pAz_cpmTq2-MR + NucSpot 650 starving_NucSpot.tif";
imageCytoplasma = "pAz_cpmTq2-MR + NucSpot 650 starving_MR.tif";

zStackNucleus = tiffreadVolume(imageNucleus);
zStackCytoplasma = tiffreadVolume(imageCytoplasma);

labelNucleus = load('labelNucleus.mat').labels;
labelCytoplasma = load('labelCytoplasma.mat').labels;

labelNucleusBG = load('labelNucleusBG.mat').labels;
labelCytoplasmaBG = load('labelCytoplasmaBG.mat').labels;

%% 
zStackNucleusBG = median(zStackNucleus(labelNucleusBG));
zStackCytoplasmaBG = median(zStackNucleus(labelCytoplasmaBG));
zStackNucleusLabelNucleus = zStackNucleus .* uint16(labelNucleus);
zStackCytoplasmaLabelCytoplasma = zStackCytoplasma .* uint16(labelCytoplasma);
zStackNucleusLabelCytoplamsa = zStackNucleus .* uint16(labelCytoplasma);
zStackCytoplasmaLabelNucleus = zStackCytoplasma .* uint16(labelNucleus);
labelCytoplasmaWithoutNucleiBackground = zStackCytoplasma;
labelCytoplasmaWithoutNucleiBackground(labelCytoplasmaWithoutNucleiBackground < zStackCytoplasmaBG * bgMultiplier) = 0;
labelCytoplasmaWithoutNucleiBackground = labelCytoplasmaWithoutNucleiBackground .* uint16(labelCytoplasma);
labelCytoplasmaWithoutNucleiBackground(labelCytoplasmaWithoutNucleiBackground > 0) = 1;
labelCytoplasmaWithoutNucleiLabel = uint16(labelCytoplasma);
labelCytoplasmaWithoutNucleiLabel(uint16(labelNucleus) == 1) = 0;
%% Volumes
volume.Cell = sum(labelCytoplasma(:)) * imgSettings.voxelVolume;
volume.Nucleus = sum(labelNucleus(:)) * imgSettings.voxelVolume;
volume.CytoplasmaWONucleusLabel = sum(labelCytoplasmaWithoutNucleiLabel(:)) * imgSettings.voxelVolume;
volume.CytoplasmaWONucleusBG = sum(labelCytoplasmaWithoutNucleiBackground(:)) * imgSettings.voxelVolume;
volume.ratioNucleusCell = volume.Nucleus/volume.Cell;
volume.ratioNucleusCytoplasmaLabelNucleus = volume.Nucleus/volume.CytoplasmaWONucleusLabel;
volume.ratioNucleusCytoplasmaBGNucleus = volume.Nucleus/volume.CytoplasmaWONucleusBG;
volume.unit = "µm³";
volumeTable = struct2table(volume);
volumeTable.name = [imageCytoplasma imageNucleus];
writetable(volumeTable, 'volume.xlsx')