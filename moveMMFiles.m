currentDir = dir();
mainDirectory = pwd;
folderIndex = find(vertcat(currentDir.isdir));

folderList = currentDir(folderIndex);

folderList = folderList(3:end); %Exclude '.' and '..'

for i = 1:size(folderList)
    
    cd(folderList(i).name);
    filename = dir('*.tif');
    if ~isempty(filename)
    movefile(filename.name,mainDirectory)
    end
    cd ..
end


