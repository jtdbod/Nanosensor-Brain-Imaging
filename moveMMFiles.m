%%
mainDirectory = uigetdir();
dirContent = dir(mainDirectory);
folderIndex = find(vertcat(dirContent.isdir));

folderList = dirContent(folderIndex);

folderList = folderList(3:end); %Exclude '.' and '..'

for i = 1:size(folderList)
    
    pathname = strcat(mainDirectory,'/',(folderList(i).name));
    filename = dir(strcat(pathname,'/*.tif'));
    if ~isempty(filename)
    movefile(strcat(pathname,'/',filename.name),mainDirectory)
    end

end


