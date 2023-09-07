function saveFig(fig,path, partNum, extraPath ,file)
%saveFig Summary of this function goes here
%   Detailed explanation goes here
parts = strsplit(path, '\');
newPath = append(strjoin(parts(1:partNum), '\'),extraPath);
savefig(fig, fullfile(newPath, append(file,'.fig')));
exportgraphics(fig, fullfile(newPath, append(file,'.png')),'Resolution', 600)
end