function [zStacks, labels, volume, intensity, intensityDividedByVolume, histoCell, histoCytoplasmaCalc, histoCytoplasmaDrawn, histoNucleus]  = zStackAnalysisFunction(bgMultiplier, zStacksSettings,folder ,bgManual,fileNameNuclearReceptor, fileNameNucleus, fileNameCytoplasma)

    % Check for required arguments
    if nargin < 4
        error('clusterAnalysisFunction requires at least bgMultiplier and zStacksSettings and folder.');
    end

    % If fileNameNuclearReceptor is not provided, use fileNameNucleus for both
    if nargin < 7
        fileNameNucleus = fileNameNuclearReceptor;
        fileNameCytoplasma = fileNameNuclearReceptor;
    end

    % Check for valid folder and file paths
if ~(isstring(folder)  || ~ischar(folder)) || ...
   ~(isstring(fileNameNuclearReceptor) || ~ischar(fileNameNuclearReceptor)) || ...
   ~(isstring(fileNameNucleus) || ~ischar(fileNameNucleus)) || ...
   ~(isstring(fileNameCytoplasma) || ~ischar(fileNameCytoplasma))
    error('Invalid input: folder and file names must be strings or character arrays.');
end

disp("Reading in data")
filePathStainingNucleus = fullfile(folder, fileNameNucleus);
filePathStainingCytoplasma = fullfile(folder, fileNameCytoplasma);
filePathNuclearReceptor = fullfile(folder, fileNameNuclearReceptor);


zStacks.Nucleus.Intensities = tiffreadVolume(filePathStainingNucleus);
zStacks.Cytoplasma.Intensities = tiffreadVolume(filePathStainingCytoplasma);
zStacks.NuclearReceptor.Intensities = tiffreadVolume(filePathNuclearReceptor);

labels.Nucleus.Drawn = load(fullfile(folder,'labelNucleus.mat')).labels;
labels.Cell.Drawn = load(fullfile(folder,'labelCytoplasma.mat')).labels;

labels.BackgroundCytoplasma = load(fullfile(folder,'labelCytoplasmaBG.mat')).labels;
disp("All data succesfully loaded")
%% Calculate Backgrounds
NucleusBackground = zStacks.Nucleus.Intensities(labels.BackgroundCytoplasma);
CytoplasmaBackground = zStacks.Cytoplasma.Intensities(labels.BackgroundCytoplasma);
NuclearReceptorBackground = zStacks.Cytoplasma.Intensities(labels.BackgroundCytoplasma);

zStacks.Nucleus.Background = median(NucleusBackground(NucleusBackground~=0));
zStacks.Cytoplasma.Background = median(CytoplasmaBackground(CytoplasmaBackground~=0));
zStacks.NuclearReceptor.Background = median(NuclearReceptorBackground(NuclearReceptorBackground~=0));
%% Manual chosen background
zStacks.ManualBackground = bgManual; 
%% Create Labels  %% Nucleus berechnet als eigener Label 
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
volume = struct2table(volume);
volume.name = [filePathNuclearReceptor filePathStainingCytoplasma filePathStainingNucleus];
writetable(volume, fullfile(folder,"zStackAnalysis.xlsx"), 'Sheet','Volumes');
disp("Volumes calculated and saved")
%% Intensitys
intensity.Sum.Raw.Cell = sum(zStacks.NuclearReceptor.labels.Cell.Drawn(:));
intensity.Sum.Raw.CytoplasmaLabel = sum(zStacks.NuclearReceptor.labels.Cytoplasma.Drawn(:));
intensity.Sum.Raw.CytoplasmaBG = sum(zStacks.NuclearReceptor.labels.Cytoplasma.Calculated(:));
intensity.Sum.Raw.Nucleus = sum(zStacks.NuclearReceptor.labels.Nucleus.Drawn(:));

intensity.Sum.BGCorrected.Cell = sum(zStacks.NuclearReceptor.labels.Cell.Drawn(zStacks.NuclearReceptor.labels.Cell.Drawn ~= 0) - zStacks.NuclearReceptor.Background, 'all');
intensity.Sum.BGCorrected.CytoplasmaLabel = sum(zStacks.NuclearReceptor.labels.Cytoplasma.Drawn(zStacks.NuclearReceptor.labels.Cytoplasma.Drawn ~= 0) - zStacks.NuclearReceptor.Background, 'all');
intensity.Sum.BGCorrected.CytoplasmaBG = sum(zStacks.NuclearReceptor.labels.Cytoplasma.Calculated(zStacks.NuclearReceptor.labels.Cytoplasma.Calculated ~= 0) - zStacks.NuclearReceptor.Background,'all');
intensity.Sum.BGCorrected.Nucleus = sum(zStacks.NuclearReceptor.labels.Nucleus.Drawn(zStacks.NuclearReceptor.labels.Nucleus.Drawn ~= 0) - zStacks.NuclearReceptor.Background, 'all');

intensity.Sum.BGCorrectedManual.Cell = sum(zStacks.NuclearReceptor.labels.Cell.Drawn(zStacks.NuclearReceptor.labels.Cell.Drawn ~= 0) - zStacks.ManualBackground, 'all');
intensity.Sum.BGCorrectedManual.CytoplasmaLabel = sum(zStacks.NuclearReceptor.labels.Cytoplasma.Drawn(zStacks.NuclearReceptor.labels.Cytoplasma.Drawn ~= 0) - zStacks.ManualBackground, 'all');
intensity.Sum.BGCorrectedManual.CytoplasmaBG = sum(zStacks.NuclearReceptor.labels.Cytoplasma.Calculated(zStacks.NuclearReceptor.labels.Cytoplasma.Calculated ~= 0) - zStacks.ManualBackground,'all');
intensity.Sum.BGCorrectedManual.Nucleus = sum(zStacks.NuclearReceptor.labels.Nucleus.Drawn(zStacks.NuclearReceptor.labels.Nucleus.Drawn ~= 0) - zStacks.ManualBackground, 'all');

% Median Calculations
intensity.Median.Raw.Cell = median(double(zStacks.NuclearReceptor.labels.Cell.Drawn(zStacks.NuclearReceptor.labels.Cell.Drawn ~= 0)));
intensity.Median.Raw.CytoplasmaLabel = median(double(zStacks.NuclearReceptor.labels.Cytoplasma.Drawn(zStacks.NuclearReceptor.labels.Cytoplasma.Drawn ~= 0)));
intensity.Median.Raw.CytoplasmaBG = median(double(zStacks.NuclearReceptor.labels.Cytoplasma.Calculated(zStacks.NuclearReceptor.labels.Cytoplasma.Calculated ~= 0)));
intensity.Median.Raw.Nucleus = median(double(zStacks.NuclearReceptor.labels.Nucleus.Drawn(zStacks.NuclearReceptor.labels.Nucleus.Drawn ~= 0)));

intensity.Median.BGCorrected.Cell = median(double(zStacks.NuclearReceptor.labels.Cell.Drawn(zStacks.NuclearReceptor.labels.Cell.Drawn ~= 0)) - double(zStacks.NuclearReceptor.Background));
intensity.Median.BGCorrected.CytoplasmaLabel = median(double(zStacks.NuclearReceptor.labels.Cytoplasma.Drawn(zStacks.NuclearReceptor.labels.Cytoplasma.Drawn ~= 0)) - double(zStacks.NuclearReceptor.Background));
intensity.Median.BGCorrected.CytoplasmaBG = median(double(zStacks.NuclearReceptor.labels.Cytoplasma.Calculated(zStacks.NuclearReceptor.labels.Cytoplasma.Calculated ~= 0)) - double(zStacks.NuclearReceptor.Background));
intensity.Median.BGCorrected.Nucleus = median(double(zStacks.NuclearReceptor.labels.Nucleus.Drawn(zStacks.NuclearReceptor.labels.Nucleus.Drawn ~= 0)) - double(zStacks.NuclearReceptor.Background));

intensity.Median.BGCorrectedManual.Cell = median(double(zStacks.NuclearReceptor.labels.Cell.Drawn(zStacks.NuclearReceptor.labels.Cell.Drawn ~= 0)) - double(zStacks.ManualBackground));
intensity.Median.BGCorrectedManual.CytoplasmaLabel = median(double(zStacks.NuclearReceptor.labels.Cytoplasma.Drawn(zStacks.NuclearReceptor.labels.Cytoplasma.Drawn ~= 0)) - double(zStacks.ManualBackground));
intensity.Median.BGCorrectedManual.CytoplasmaBG = median(double(zStacks.NuclearReceptor.labels.Cytoplasma.Calculated(zStacks.NuclearReceptor.labels.Cytoplasma.Calculated ~= 0)) - double(zStacks.ManualBackground));
intensity.Median.BGCorrectedManual.Nucleus = median(double(zStacks.NuclearReceptor.labels.Nucleus.Drawn(zStacks.NuclearReceptor.labels.Nucleus.Drawn ~= 0)) - double(zStacks.ManualBackground));

% Mean Calculations
intensity.Mean.Raw.Cell = mean(double(zStacks.NuclearReceptor.labels.Cell.Drawn(zStacks.NuclearReceptor.labels.Cell.Drawn ~= 0)));
intensity.Mean.Raw.CytoplasmaLabel = mean(double(zStacks.NuclearReceptor.labels.Cytoplasma.Drawn(zStacks.NuclearReceptor.labels.Cytoplasma.Drawn ~= 0)));
intensity.Mean.Raw.CytoplasmaBG = mean(double(zStacks.NuclearReceptor.labels.Cytoplasma.Calculated(zStacks.NuclearReceptor.labels.Cytoplasma.Calculated ~= 0)));
intensity.Mean.Raw.Nucleus = mean(double(zStacks.NuclearReceptor.labels.Nucleus.Drawn(zStacks.NuclearReceptor.labels.Nucleus.Drawn ~= 0)));

intensity.Mean.BGCorrected.Cell = mean(double(zStacks.NuclearReceptor.labels.Cell.Drawn(zStacks.NuclearReceptor.labels.Cell.Drawn ~= 0)) - double(zStacks.NuclearReceptor.Background));
intensity.Mean.BGCorrected.CytoplasmaLabel = mean(double(zStacks.NuclearReceptor.labels.Cytoplasma.Drawn(zStacks.NuclearReceptor.labels.Cytoplasma.Drawn ~= 0)) - double(zStacks.NuclearReceptor.Background));
intensity.Mean.BGCorrected.CytoplasmaBG = mean(double(zStacks.NuclearReceptor.labels.Cytoplasma.Calculated(zStacks.NuclearReceptor.labels.Cytoplasma.Calculated ~= 0)) - double(zStacks.NuclearReceptor.Background));
intensity.Mean.BGCorrected.Nucleus = mean(double(zStacks.NuclearReceptor.labels.Nucleus.Drawn(zStacks.NuclearReceptor.labels.Nucleus.Drawn ~= 0)) - double(zStacks.NuclearReceptor.Background));

intensity.Mean.BGCorrectedManual.Cell = mean(double(zStacks.NuclearReceptor.labels.Cell.Drawn(zStacks.NuclearReceptor.labels.Cell.Drawn ~= 0)) - double(zStacks.ManualBackground));
intensity.Mean.BGCorrectedManual.CytoplasmaLabel = mean(double(zStacks.NuclearReceptor.labels.Cytoplasma.Drawn(zStacks.NuclearReceptor.labels.Cytoplasma.Drawn ~= 0)) - double(zStacks.ManualBackground));
intensity.Mean.BGCorrectedManual.CytoplasmaBG = mean(double(zStacks.NuclearReceptor.labels.Cytoplasma.Calculated(zStacks.NuclearReceptor.labels.Cytoplasma.Calculated ~= 0)) - double(zStacks.ManualBackground));
intensity.Mean.BGCorrectedManual.Nucleus = mean(double(zStacks.NuclearReceptor.labels.Nucleus.Drawn(zStacks.NuclearReceptor.labels.Nucleus.Drawn ~= 0)) - double(zStacks.ManualBackground));

% Ratio of Sum Calculations
intensity.Ratio.Sum.Raw.NucleusCell = intensity.Sum.Raw.Nucleus / intensity.Sum.Raw.Cell;
intensity.Ratio.Sum.Raw.NucleusCytoplasmaDrawn = intensity.Sum.Raw.Nucleus / intensity.Sum.Raw.CytoplasmaLabel;
intensity.Ratio.Sum.Raw.NucleusCytoplasmaCalculated = intensity.Sum.Raw.Nucleus / intensity.Sum.Raw.CytoplasmaBG;

intensity.Ratio.Sum.BGCorrected.NucleusCell = intensity.Sum.BGCorrected.Nucleus / intensity.Sum.BGCorrected.Cell;
intensity.Ratio.Sum.BGCorrected.NucleusCytoplasmaDrawn = intensity.Sum.BGCorrected.Nucleus / intensity.Sum.BGCorrected.CytoplasmaLabel;
intensity.Ratio.Sum.BGCorrected.NucleusCytoplasmaCalculated = intensity.Sum.BGCorrected.Nucleus / intensity.Sum.BGCorrected.CytoplasmaBG;

intensity.Ratio.Sum.BGCorrectedManual.NucleusCell = intensity.Sum.BGCorrectedManual.Nucleus / intensity.Sum.BGCorrectedManual.Cell;
intensity.Ratio.Sum.BGCorrectedManual.NucleusCytoplasmaDrawn = intensity.Sum.BGCorrectedManual.Nucleus / intensity.Sum.BGCorrectedManual.CytoplasmaLabel;
intensity.Ratio.Sum.BGCorrectedManual.NucleusCytoplasmaCalculated = intensity.Sum.BGCorrectedManual.Nucleus / intensity.Sum.BGCorrectedManual.CytoplasmaBG;

% Ratio of Median Calculations
intensity.Ratio.Median.Raw.NucleusCell = intensity.Median.Raw.Nucleus / intensity.Median.Raw.Cell;
intensity.Ratio.Median.Raw.NucleusCytoplasmaDrawn = intensity.Median.Raw.Nucleus / intensity.Median.Raw.CytoplasmaLabel;
intensity.Ratio.Median.Raw.NucleusCytoplasmaCalculated = intensity.Median.Raw.Nucleus / intensity.Median.Raw.CytoplasmaBG;

intensity.Ratio.Median.BGCorrected.NucleusCell = intensity.Median.BGCorrected.Nucleus / intensity.Median.BGCorrected.Cell;
intensity.Ratio.Median.BGCorrected.NucleusCytoplasmaDrawn = intensity.Median.BGCorrected.Nucleus / intensity.Median.BGCorrected.CytoplasmaLabel;
intensity.Ratio.Median.BGCorrected.NucleusCytoplasmaCalculated = intensity.Median.BGCorrected.Nucleus / intensity.Median.BGCorrected.CytoplasmaBG;

intensity.Ratio.Median.BGCorrectedManual.NucleusCell = intensity.Median.BGCorrectedManual.Nucleus / intensity.Median.BGCorrectedManual.Cell;
intensity.Ratio.Median.BGCorrectedManual.NucleusCytoplasmaDrawn = intensity.Median.BGCorrectedManual.Nucleus / intensity.Median.BGCorrectedManual.CytoplasmaLabel;
intensity.Ratio.Median.BGCorrectedManual.NucleusCytoplasmaCalculated = intensity.Median.BGCorrectedManual.Nucleus / intensity.Median.BGCorrectedManual.CytoplasmaBG;

% Ratio of Mean Calculations
intensity.Ratio.Mean.Raw.NucleusCell = intensity.Mean.Raw.Nucleus / intensity.Mean.Raw.Cell;
intensity.Ratio.Mean.Raw.NucleusCytoplasmaDrawn = intensity.Mean.Raw.Nucleus / intensity.Mean.Raw.CytoplasmaLabel;
intensity.Ratio.Mean.Raw.NucleusCytoplasmaCalculated = intensity.Mean.Raw.Nucleus / intensity.Mean.Raw.CytoplasmaBG;

intensity.Ratio.Mean.BGCorrected.NucleusCell = intensity.Mean.BGCorrected.Nucleus / intensity.Mean.BGCorrected.Cell;
intensity.Ratio.Mean.BGCorrected.NucleusCytoplasmaDrawn = intensity.Mean.BGCorrected.Nucleus / intensity.Mean.BGCorrected.CytoplasmaLabel;
intensity.Ratio.Mean.BGCorrected.NucleusCytoplasmaCalculated = intensity.Mean.BGCorrected.Nucleus / intensity.Mean.BGCorrected.CytoplasmaBG;

intensity.Ratio.Mean.BGCorrectedManual.NucleusCell = intensity.Mean.BGCorrectedManual.Nucleus / intensity.Mean.BGCorrectedManual.Cell;
intensity.Ratio.Mean.BGCorrectedManual.NucleusCytoplasmaDrawn = intensity.Mean.BGCorrectedManual.Nucleus / intensity.Mean.BGCorrectedManual.CytoplasmaLabel;
intensity.Ratio.Mean.BGCorrectedManual.NucleusCytoplasmaCalculated = intensity.Mean.BGCorrectedManual.Nucleus / intensity.Mean.BGCorrectedManual.CytoplasmaBG;

flatStruct = flattenStruct(intensity);

intensityTable = struct2table(flatStruct);
intensityTable.name = [filePathNuclearReceptor filePathStainingCytoplasma filePathStainingNucleus];
intensityTable.Background = double(zStacks.NuclearReceptor.Background);

writetable(intensityTable, fullfile(folder,"zStackAnalysis.xlsx"), 'Sheet','Intensity');
disp("Intensities calculated and saved")

%% Volumen korrigiert %%
% Calculate intensities divided by respective volume and save them in the struct
intensityDividedByVolume.Sum.Raw.Cell = intensity.Sum.Raw.Cell / volume.Cell;
intensityDividedByVolume.Sum.Raw.CytoplasmaLabel = intensity.Sum.Raw.CytoplasmaLabel / volume.CytoplasmaLabel;
intensityDividedByVolume.Sum.Raw.CytoplasmaBG = intensity.Sum.Raw.CytoplasmaBG / volume.CytoplasmaBG;
intensityDividedByVolume.Sum.Raw.Nucleus = intensity.Sum.Raw.Nucleus / volume.Nucleus;

intensityDividedByVolume.Sum.BGCorrected.Cell = intensity.Sum.BGCorrected.Cell / volume.Cell;
intensityDividedByVolume.Sum.BGCorrected.CytoplasmaLabel = intensity.Sum.BGCorrected.CytoplasmaLabel / volume.CytoplasmaLabel;
intensityDividedByVolume.Sum.BGCorrected.CytoplasmaBG = intensity.Sum.BGCorrected.CytoplasmaBG / volume.CytoplasmaBG;
intensityDividedByVolume.Sum.BGCorrected.Nucleus = intensity.Sum.BGCorrected.Nucleus / volume.Nucleus;

intensityDividedByVolume.Sum.BGCorrectedManual.Cell = intensity.Sum.BGCorrectedManual.Cell / volume.Cell;
intensityDividedByVolume.Sum.BGCorrectedManual.CytoplasmaLabel = intensity.Sum.BGCorrectedManual.CytoplasmaLabel / volume.CytoplasmaLabel;
intensityDividedByVolume.Sum.BGCorrectedManual.CytoplasmaBG = intensity.Sum.BGCorrectedManual.CytoplasmaBG / volume.CytoplasmaBG;
intensityDividedByVolume.Sum.BGCorrectedManual.Nucleus = intensity.Sum.BGCorrectedManual.Nucleus / volume.Nucleus;

% Median Calculations Divided by Volume
intensityDividedByVolume.Median.Raw.Cell = intensity.Median.Raw.Cell / volume.Cell;
intensityDividedByVolume.Median.Raw.CytoplasmaLabel = intensity.Median.Raw.CytoplasmaLabel / volume.CytoplasmaLabel;
intensityDividedByVolume.Median.Raw.CytoplasmaBG = intensity.Median.Raw.CytoplasmaBG / volume.CytoplasmaBG;
intensityDividedByVolume.Median.Raw.Nucleus = intensity.Median.Raw.Nucleus / volume.Nucleus;

intensityDividedByVolume.Median.BGCorrected.Cell = intensity.Median.BGCorrected.Cell / volume.Cell;
intensityDividedByVolume.Median.BGCorrected.CytoplasmaLabel = intensity.Median.BGCorrected.CytoplasmaLabel / volume.CytoplasmaLabel;
intensityDividedByVolume.Median.BGCorrected.CytoplasmaBG = intensity.Median.BGCorrected.CytoplasmaBG / volume.CytoplasmaBG;
intensityDividedByVolume.Median.BGCorrected.Nucleus = intensity.Median.BGCorrected.Nucleus / volume.Nucleus;

intensityDividedByVolume.Median.BGCorrectedManual.Cell = intensity.Median.BGCorrectedManual.Cell / volume.Cell;
intensityDividedByVolume.Median.BGCorrectedManual.CytoplasmaLabel = intensity.Median.BGCorrectedManual.CytoplasmaLabel / volume.CytoplasmaLabel;
intensityDividedByVolume.Median.BGCorrectedManual.CytoplasmaBG = intensity.Median.BGCorrectedManual.CytoplasmaBG / volume.CytoplasmaBG;
intensityDividedByVolume.Median.BGCorrectedManual.Nucleus = intensity.Median.BGCorrectedManual.Nucleus / volume.Nucleus;

% Mean Calculations Divided by Volume
intensityDividedByVolume.Mean.Raw.Cell = intensity.Mean.Raw.Cell / volume.Cell;
intensityDividedByVolume.Mean.Raw.CytoplasmaLabel = intensity.Mean.Raw.CytoplasmaLabel / volume.CytoplasmaLabel;
intensityDividedByVolume.Mean.Raw.CytoplasmaBG = intensity.Mean.Raw.CytoplasmaBG / volume.CytoplasmaBG;
intensityDividedByVolume.Mean.Raw.Nucleus = intensity.Mean.Raw.Nucleus / volume.Nucleus;

intensityDividedByVolume.Mean.BGCorrected.Cell = intensity.Mean.BGCorrected.Cell / volume.Cell;
intensityDividedByVolume.Mean.BGCorrected.CytoplasmaLabel = intensity.Mean.BGCorrected.CytoplasmaLabel / volume.CytoplasmaLabel;
intensityDividedByVolume.Mean.BGCorrected.CytoplasmaBG = intensity.Mean.BGCorrected.CytoplasmaBG / volume.CytoplasmaBG;
intensityDividedByVolume.Mean.BGCorrected.Nucleus = intensity.Mean.BGCorrected.Nucleus / volume.Nucleus;

intensityDividedByVolume.Mean.BGCorrectedManual.Cell = intensity.Mean.BGCorrectedManual.Cell / volume.Cell;
intensityDividedByVolume.Mean.BGCorrectedManual.CytoplasmaLabel = intensity.Mean.BGCorrectedManual.CytoplasmaLabel / volume.CytoplasmaLabel;
intensityDividedByVolume.Mean.BGCorrectedManual.CytoplasmaBG = intensity.Mean.BGCorrectedManual.CytoplasmaBG / volume.CytoplasmaBG;
intensityDividedByVolume.Mean.BGCorrectedManual.Nucleus = intensity.Mean.BGCorrectedManual.Nucleus / volume.Nucleus;

% Ratio of Sum Calculations Divided by Volume
intensityDividedByVolume.Ratio.Sum.Raw.NucleusCell = intensityDividedByVolume.Sum.Raw.Nucleus / intensityDividedByVolume.Sum.Raw.Cell;
intensityDividedByVolume.Ratio.Sum.Raw.NucleusCytoplasmaDrawn = intensityDividedByVolume.Sum.Raw.Nucleus / intensityDividedByVolume.Sum.Raw.CytoplasmaLabel;
intensityDividedByVolume.Ratio.Sum.Raw.NucleusCytoplasmaCalculated = intensityDividedByVolume.Sum.Raw.Nucleus / intensityDividedByVolume.Sum.Raw.CytoplasmaBG;

intensityDividedByVolume.Ratio.Sum.BGCorrected.NucleusCell = intensityDividedByVolume.Sum.BGCorrected.Nucleus / intensityDividedByVolume.Sum.BGCorrected.Cell;
intensityDividedByVolume.Ratio.Sum.BGCorrected.NucleusCytoplasmaDrawn = intensityDividedByVolume.Sum.BGCorrected.Nucleus / intensityDividedByVolume.Sum.BGCorrected.CytoplasmaLabel;
intensityDividedByVolume.Ratio.Sum.BGCorrected.NucleusCytoplasmaCalculated = intensityDividedByVolume.Sum.BGCorrected.Nucleus / intensityDividedByVolume.Sum.BGCorrected.CytoplasmaBG;

intensityDividedByVolume.Ratio.Sum.BGCorrectedManual.NucleusCell = intensityDividedByVolume.Sum.BGCorrectedManual.Nucleus / intensityDividedByVolume.Sum.BGCorrectedManual.Cell;
intensityDividedByVolume.Ratio.Sum.BGCorrectedManual.NucleusCytoplasmaDrawn = intensityDividedByVolume.Sum.BGCorrectedManual.Nucleus / intensityDividedByVolume.Sum.BGCorrectedManual.CytoplasmaLabel;
intensityDividedByVolume.Ratio.Sum.BGCorrectedManual.NucleusCytoplasmaCalculated = intensityDividedByVolume.Sum.BGCorrectedManual.Nucleus / intensityDividedByVolume.Sum.BGCorrectedManual.CytoplasmaBG;

% Ratio of Median Calculations Divided by Volume
intensityDividedByVolume.Ratio.Median.Raw.NucleusCell = intensityDividedByVolume.Median.Raw.Nucleus / intensityDividedByVolume.Median.Raw.Cell;
intensityDividedByVolume.Ratio.Median.Raw.NucleusCytoplasmaDrawn = intensityDividedByVolume.Median.Raw.Nucleus / intensityDividedByVolume.Median.Raw.CytoplasmaLabel;
intensityDividedByVolume.Ratio.Median.Raw.NucleusCytoplasmaCalculated = intensityDividedByVolume.Median.Raw.Nucleus / intensityDividedByVolume.Median.Raw.CytoplasmaBG;

intensityDividedByVolume.Ratio.Median.BGCorrected.NucleusCell = intensityDividedByVolume.Median.BGCorrected.Nucleus / intensityDividedByVolume.Median.BGCorrected.Cell;
intensityDividedByVolume.Ratio.Median.BGCorrected.NucleusCytoplasmaDrawn = intensityDividedByVolume.Median.BGCorrected.Nucleus / intensityDividedByVolume.Median.BGCorrected.CytoplasmaLabel;
intensityDividedByVolume.Ratio.Median.BGCorrected.NucleusCytoplasmaCalculated = intensityDividedByVolume.Median.BGCorrected.Nucleus / intensityDividedByVolume.Median.BGCorrected.CytoplasmaBG;

intensityDividedByVolume.Ratio.Median.BGCorrectedManual.NucleusCell = intensityDividedByVolume.Median.BGCorrectedManual.Nucleus / intensityDividedByVolume.Median.BGCorrectedManual.Cell;
intensityDividedByVolume.Ratio.Median.BGCorrectedManual.NucleusCytoplasmaDrawn = intensityDividedByVolume.Median.BGCorrectedManual.Nucleus / intensityDividedByVolume.Median.BGCorrectedManual.CytoplasmaLabel;
intensityDividedByVolume.Ratio.Median.BGCorrectedManual.NucleusCytoplasmaCalculated = intensityDividedByVolume.Median.BGCorrectedManual.Nucleus / intensityDividedByVolume.Median.BGCorrectedManual.CytoplasmaBG;

% Ratio of Mean Calculations Divided by Volume
intensityDividedByVolume.Ratio.Mean.Raw.NucleusCell = intensityDividedByVolume.Mean.Raw.Nucleus / intensityDividedByVolume.Mean.Raw.Cell;
intensityDividedByVolume.Ratio.Mean.Raw.NucleusCytoplasmaDrawn = intensityDividedByVolume.Mean.Raw.Nucleus / intensityDividedByVolume.Mean.Raw.CytoplasmaLabel;
intensityDividedByVolume.Ratio.Mean.Raw.NucleusCytoplasmaCalculated = intensityDividedByVolume.Mean.Raw.Nucleus / intensityDividedByVolume.Mean.Raw.CytoplasmaBG;

intensityDividedByVolume.Ratio.Mean.BGCorrected.NucleusCell = intensityDividedByVolume.Mean.BGCorrected.Nucleus / intensityDividedByVolume.Mean.BGCorrected.Cell;
intensityDividedByVolume.Ratio.Mean.BGCorrected.NucleusCytoplasmaDrawn = intensityDividedByVolume.Mean.BGCorrected.Nucleus / intensityDividedByVolume.Mean.BGCorrected.CytoplasmaLabel;
intensityDividedByVolume.Ratio.Mean.BGCorrected.NucleusCytoplasmaCalculated = intensityDividedByVolume.Mean.BGCorrected.Nucleus / intensityDividedByVolume.Mean.BGCorrected.CytoplasmaBG;


intensityDividedByVolume.Ratio.Mean.BGCorrectedManual.NucleusCell = intensityDividedByVolume.Mean.BGCorrectedManual.Nucleus / intensityDividedByVolume.Mean.BGCorrectedManual.Cell;
intensityDividedByVolume.Ratio.Mean.BGCorrectedManual.NucleusCytoplasmaDrawn = intensityDividedByVolume.Mean.BGCorrectedManual.Nucleus / intensityDividedByVolume.Mean.BGCorrectedManual.CytoplasmaLabel;
intensityDividedByVolume.Ratio.Mean.BGCorrectedManual.NucleusCytoplasmaCalculated = intensityDividedByVolume.Mean.BGCorrectedManual.Nucleus / intensityDividedByVolume.Mean.BGCorrectedManual.CytoplasmaBG;

flatStructDiv = flattenStruct(intensityDividedByVolume);

intensityDividedByVolumeTable = struct2table(flatStructDiv);
intensityDividedByVolumeTable.name = [filePathNuclearReceptor filePathStainingCytoplasma filePathStainingNucleus];

writetable(intensityDividedByVolumeTable, fullfile(folder,"zStackAnalysis.xlsx"), 'Sheet','IntensityDividedByVolume');

sumTable = table(volume.Cell, volume.Nucleus, volume.CytoplasmaLabel, intensityTable.Median_BGCorrected_Cell, intensityTable.Median_BGCorrected_CytoplasmaLabel, intensityTable.Median_BGCorrected_Nucleus, ...
    intensityDividedByVolumeTable.Median_BGCorrected_Cell, intensityDividedByVolumeTable.Median_BGCorrected_CytoplasmaLabel, intensityDividedByVolumeTable.Median_BGCorrected_Nucleus, ...
    intensityTable.Median_BGCorrectedManual_Cell, intensityTable.Median_BGCorrectedManual_CytoplasmaLabel, intensityTable.Median_BGCorrectedManual_Nucleus, ...
    intensityDividedByVolumeTable.Median_BGCorrectedManual_Cell, intensityDividedByVolumeTable.Median_BGCorrectedManual_CytoplasmaLabel, intensityDividedByVolumeTable.Median_BGCorrectedManual_Nucleus,...
    intensityTable.Median_Raw_CytoplasmaLabel, intensityDividedByVolumeTable.Median_Raw_CytoplasmaLabel,...
    'VariableNames', ["Vol. Cell", "Vol. Nucleus", "vol. Cyto", "Median Cell BG", "Median Cyto BG", "Median Nuc BG", "Median I/V Cell BG", "Median I/V Cyto BG", "Median I/V Nuc BG", ...
    "Median Cell MBG", "Median Cyto MBG", "Median Nuc MBG", "Median I/V Cell MBG", "Median I/V Cyto MBG", "Median I/V Nuc MBG", "Median Raw Cyto", "Median I/V Raw Cyto"]);


writetable(sumTable, fullfile(folder,"zStackAnalysis.xlsx"), 'Sheet','Summary');



disp("Intensities divided by volume calculated and saved")


% histoCell = figure;
% title("Cell")
% histogram(zStacks.NuclearReceptor.labels.Cell.Drawn(zStacks.NuclearReceptor.labels.Cell.Drawn ~= 0) - zStacks.NuclearReceptor.Background)
% histoCytoplasmaCalc = figure;
% title("Cytoplasma Calculated")
% histogram(zStacks.NuclearReceptor.labels.Cytoplasma.Calculated(zStacks.NuclearReceptor.labels.Cytoplasma.Calculated ~= 0) - zStacks.NuclearReceptor.Background);
% histoCytoplasmaDrawn = figure;
% title("Cytoplasma Drawn")
% histogram(zStacks.NuclearReceptor.labels.Cytoplasma.Drawn(zStacks.NuclearReceptor.labels.Cytoplasma.Drawn ~= 0) - zStacks.NuclearReceptor.Background);
% histoNucleus = figure;
% title("Nucleus")
% histogram(zStacks.NuclearReceptor.labels.Nucleus.Drawn(zStacks.NuclearReceptor.labels.Nucleus.Drawn ~= 0) - zStacks.NuclearReceptor.Background);
% disp("Histograms created")

save(fullfile(folder,"usedData.mat"));
disp("Data was saved");
end