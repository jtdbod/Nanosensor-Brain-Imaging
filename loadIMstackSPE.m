function [imagestack,filename]=loadIMstackSPE(folder,files,i,h) %Load image stacks into variable "imagestack"
    
    fprintf(1,'\n\tLoading frame:\t');
    filename=files(i).name;
    readerobj=SpeReader(strcat(folder,'/',files(i).name));
    vidFrames=read(readerobj);
    height=size(vidFrames,1);
    width=size(vidFrames,2);   
    frames=size(vidFrames,4);
     
    imagestack=zeros(height,width,frames);


    
    for j=1:frames

        imagestack(:,:,j)=vidFrames(:,:,1,j);
        fprintf(1,'%d',j)
        fprintf(1,repmat('\b',1,length(num2str(j))))

        % Check for Cancel button press
        if getappdata(h,'canceling')
            delete(h)
            error('Operation terminated by user');
        end
        
        %Update progress bar
        waitbar(j/frames,h,sprintf('Loading frame %i of %i',[j,frames]));
        
    end
        
    fprintf(1,'%d',j)
    fprintf('\n')
end