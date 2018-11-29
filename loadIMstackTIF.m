function [imagestack]=loadIMstackTIF(pathname,filename,i,h) %Load image stacks into variable "imagestack"
    
    file = strcat(pathname,'/',filename);
    fileinfo=imfinfo(file);
    height=fileinfo(1).Height;
    width=fileinfo(1).Width;
    frames=size(fileinfo,1);

    imagestack=zeros(height,width,frames);

    for j=1:frames
        imagestack(:,:,j)=imread(file,j);   
                % Check for Cancel button press
        if getappdata(h,'canceling')
            delete(h)
            error('Operation terminated by user');
        end
        
        %Update progress bar
        waitbar(j/frames,h,sprintf('Loading frame %i of %i',[j,frames]));
        
    end

end