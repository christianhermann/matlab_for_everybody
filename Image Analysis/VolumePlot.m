function VolumePlot(zStacksSettings, vol, plotSettings, plotType, fileNameAnimation)
%% Plot
A = [zStacksSettings.Voxelsize(1) 0 0 0; 0 zStacksSettings.Voxelsize(2) 0 0; 0 0 zStacksSettings.Voxelsize(3) 0; 0 0 0 1];
tform = affinetform3d(A);

switch lower(plotType)
    case 'mip'
        viewer = viewer3d(BackgroundColor="black", GradientColor=[0.5 0.5 0.5], Lighting="on", BackgroundGradient="off");
        volBGCorrected = volshow(vol, plotSettings.MIP, "Transformation", tform, "Parent", viewer);
    case 'grad'
        viewer = viewer3d(BackgroundColor="black", GradientColor=[0.5 0.5 0.5], Lighting="on", BackgroundGradient="off");
        volBGCorrected = volshow(vol, plotSettings.Gradient, "Transformation", tform, "Parent", viewer);
    case 'vol'
        viewer = viewer3d(BackgroundColor="black", GradientColor=[0.5 0.5 0.5], Lighting="on", BackgroundGradient="off");
        volBGCorrected = volshow(vol, plotSettings.Volume, "Transformation", tform, "Parent", viewer);
    otherwise
        error('Invalid plot type. Use ''mip'', ''grad'', or ''vol''.');
end

frame = getframe(viewer.Parent);
fMIP = figure('Position',[0 0 561 421]);
axMIP = axes(fMIP);
imagesc(axMIP,frame.cdata);

% Check if animation filename is provided
if nargin == 5 && ~isempty(fileNameAnimation)
    hFig = viewer.Parent;
    sz = size(vol);
    center = sz/2 + 0.5;
    numberOfFrames = 48;
    vec = linspace(0,2*pi,numberOfFrames)';
    dist = sqrt(sz(1)^2 + sz(2)^2 + sz(3)^2);
    myPosition = center + ([cos(vec) sin(vec) ones(size(vec))]*dist);

    for idx = 1:length(vec)
        % Update the current view
        viewer.CameraPosition = myPosition(idx,:);
        % Capture the image using the getframe function
        I = getframe(hFig);
        [indI,cm] = rgb2ind(I.cdata,256);
        % Write the frame to the GIF file
        if idx == 1
            % Do nothing. The first frame displays only the viewer, not the volume.
        elseif idx == 2
            imwrite(indI, cm, fileNameAnimation, "gif", Loopcount=inf, DelayTime=0);
        else
            imwrite(indI, cm, fileNameAnimation, "gif", WriteMode="append", DelayTime=0);
        end
    end
end
end