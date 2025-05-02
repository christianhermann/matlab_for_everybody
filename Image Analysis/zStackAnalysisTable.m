%% Set up the Import Options and import the data
opts = spreadsheetImportOptions("NumVariables", 4);

% Specify sheet and range
opts.Sheet = "Tabelle1";
opts.DataRange = "A2:D25";

% Specify column names and types
opts.VariableNames = ["folder", "filename", "bgManual", "zDim"];
opts.VariableTypes = ["string", "string", "double", "double"];

% Specify variable properties
opts = setvaropts(opts, ["folder", "filename"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["folder", "filename"], "EmptyFieldRule", "auto");

% Import the data
Daten = readtable("U:\Projekte\Christian\Matlab_for_everybody\Image Analysis\Julien\Daten.xlsx", opts, "UseExcel", false);


%% Clear temporary variables
clear opts

for i = 1:height(Daten)
    disp("------------------------------------------");
    disp("Row: "+i);
    disp("------------------------------------------");
    zDim = Daten.zDim(i);
    folder = Daten.folder(i);
    fileNameNuclearReceptor = Daten.filename(i);
    bgManual = Daten.bgManual(i);

    %% Settings %%
zStacksSettings.Width = 33.2106; % microns
zStacksSettings.Height = 33.2106; % microns
zStacksSettings.Depth = 14.2; % microns
zStacksSettings.Dimensions = [1000 1000 zDim]; %[x y z]
zStacksSettings.Voxelsize = [0 0 0];
zStacksSettings.Voxelsize(1) = zStacksSettings.Width  /  zStacksSettings.Dimensions(1);
zStacksSettings.Voxelsize(2) = zStacksSettings.Height  /  zStacksSettings.Dimensions(2);
zStacksSettings.Voxelsize(3) = zStacksSettings.Depth  /  zStacksSettings.Dimensions(3);
zStacksSettings.voxelVolume = prod(zStacksSettings.Voxelsize); %um³
bgMultiplier = 1.01;

%Ohne Histogramme
[zStacks, labels, volume, intensity, intensityDividedByVolume] = ...
    zStackAnalysisFunction(bgMultiplier, zStacksSettings, folder, bgManual, fileNameNuclearReceptor);

end

