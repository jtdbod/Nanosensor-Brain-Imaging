classdef SpeReader < hgsetget
    % SpeReader Create a spe-file reader object.
    %
    %   OBJ = SpeReader(FILENAME) constructs a spe-file reader object, OBJ, that
    %   can read in video data from a SPE file.  FILENAME is a string
    %   specifying the name of a spe-file.  By default, MATLAB looks for the file FILENAME on
    %   the MATLAB path.
    %
    %   If the object cannot be constructed for any reason (for example, if the
    %   file cannot be opened or does not exist, or if the file format is not
    %   recognized or supported), then MATLAB throws an error.
    %
    %   Example:
    %      % Construct a multimedia reader object associated with file 'xylophone.mpg' with
    %      % user tag set to 'myreader1'.
    %      readerobj = SpeReader('xylophone.spe');
    %
    %      % Read in all video frames.
    %      vidFrames = read(readerobj);
    %
    %      % Get the number of frames.
    %      numFrames = readerobj.NumberOfFrames;
    %
    %      % Read in all but the first frames.
    %      vidFrames = read(readerobj, [2 Inf]);
    %
    %
    %   See also AUDIOVIDEO, VIDEOREADER, MMFILEINFO.
    %
    
    %   Author: JaW
    %   Based upon VideoReader implementation by NH DL - The Mathworks
    %   Class SpeReader extends hgsetget superclass, in order to customly
    %   get/set some properties
    %   Properties/methods correspond to those in VideoReader.m except for
    %   logic concerning the actual reading of the spe-files
    
    %------------------------------------------------------------------
    % General properties (in alphabetic order)
    %------------------------------------------------------------------
    properties(Constant, Hidden)
        DataType = containers.Map({'single','int32','int16','uint16','double','uint8','uint32'},...
            {0,1,2,3,5,6,8}); %DataType enumerator.
    end
    
    properties(Access='private', Hidden)
        FooterOffset    % Footer offset starting XML.
    end
    
    properties(GetAccess='public', SetAccess='private')
        FooterXML       % Footer contents of spe-file.
        Name            % Name of the file to be read.
        Path            % Path of the file to be read.
    end
    
    properties(Access='public')
        Tag = '';       % Generic string for the user to set.
    end
    
    properties(GetAccess='public', SetAccess='private')
        Type            % Classname of the object.
    end
    
    properties(Access='public')
        UserData        % Generic field for any user-defined data.
    end
    
     properties(GetAccess='public', SetAccess='private')
        Version         % Version number of SPE-file
    end
    
    %------------------------------------------------------------------
    % Video properties (in alphabetic order)
    %------------------------------------------------------------------
    properties (GetAccess='public', SetAccess='private')
        Height          % Height of the video frame in pixels.
        NumberOfFrames  % Total number of frames in the video stream.
        PixelType       % Data type used for pixel representation.
        Width           % Width of the video frame in pixels.
    end
    
    %------------------------------------------------------------------
    % Misc properties (in alphabetic order)
    %------------------------------------------------------------------
    properties (GetAccess='public', SetAccess='private', Hidden)
        lastvalue       %last value in header
        lnoscan         %number of scans
        noscan          %old number of scans, should be --> -1
        scramble        %0=scrambled, 1=unscrambled
        winViewId       %file created in winx?
        yDimDet         %y dims of CCD or detector
        xDimDet         %x dims of detector chip
        XML             %xml contents of footer
    end
    
    %------------------------------------------------------------------
    % Start of class methods
    %------------------------------------------------------------------
    methods(Access='public')
        %------------------------------------------------------------------
        % Constructor
        %------------------------------------------------------------------
        function obj = SpeReader(fileName, varargin)
            
            % If no file name provided.
            if nargin == 0
                error('FILENAME must be specified.');
            end
            
            % Initialize the object.
            obj.init(fileName);
            
            % Set properties that user passed in (not implemented).
            if nargin > 1
                warning('SpeReader:vargin','only designated fileName has been used!');
            end
        end
        
        %------------------------------------------------------------------
        % Operations
        %------------------------------------------------------------------
        function frames = read(obj, varargin)
            %read frames from spe-file
            %first check the input parameters
            if nargin == 1 % select all frames
                frameset = 1:obj.NumberOfFrames;
            elseif nargin == 2 && numel(varargin{1}) < 3 && ~isempty(varargin{1}) && ...
                    isnumeric(varargin{1})
                fr = varargin{1};
                if numel(fr) == 1 %select just 1 frame
                    frameset = min(obj.NumberOfFrames,max(1,fr));
                else %select some range between 2 frames
                    mir = min(fr);
                    mir = min(obj.NumberOfFrames,max(1,mir));
                    mar = max(fr);
                    mar = min(obj.NumberOfFrames,max(1,mar));
                    frameset = mir:mar;
                end
            else
                error('VARARGIN should either be a 1 or 2 element array')
            end
            %do the actual reading of frames from spe-file
            frames = parseFrames(obj, frameset);
        end
    end
    
    methods (Static, Access='public')
        function fullPathName = getFullPathName(fileName)
            % Given a fileName, relative file path, or full file path, return
            % the Full path (i.e. fullpath/fileName.ext) to the given file
            
            % First check the MATLAB path for the file.
            whichFileName = which(fileName);
            if ~strcmp(whichFileName, '')
                fullPathName = whichFileName;
                return;
            end
            
            % We have file not on the MATLAB path,
            % get the full path using fileattrib.
            [stat info] = fileattrib(fileName);
            if ~stat
                error('File not found');
            end
            
            fullPathName = info.Name;
            if strcmp(fullPathName,'')
                error('File not found');
            end
        end
        
        function dataTypeId = getDataTypeId(dataType)
            %Given a dataType, return the associated ID
            %Would be nice if it could be done with an enum, but they are
            %not properly implemented
            dataTypeId = [];
            if ischar(dataType) %do a key-->value lookup
                dataType = lower(dataType);
                try
                    dataTypeId = SpeReader.DataType(dataType);
                catch exception
                    warning(exception.message);
                end
            elseif isnumeric(dataType) %do an inverse lookup
                dataKeys = SpeReader.DataType.keys;
                dataValues = SpeReader.DataType.values;
                dataTypeId = dataKeys(cell2mat(dataValues)==dataType);
                if ~isempty(dataTypeId) %select first occurence
                    dataTypeId = dataTypeId{1};
                end
            end
            if isempty(dataTypeId) %if not found:die
                error(['Unknown dataType encountered: ' dataType]);
            end
        end
    end
    
    methods (Access='private', Hidden)
        function init(obj, fileTaget)
            % Properly initialize the object on construction or load.
            fullName = SpeReader.getFullPathName(fileTaget);
            if ~exist(fullName,'file')
                error('FILENAME does not exist!')
            end
            
            % Save properties:
            [filePath, fileName, fileExt] = fileparts(fullName);
            if ~strcmpi(fileExt, '.spe')
                error('FILE is not of type SPE!')
            end
            obj.Name = [fileName fileExt];
            obj.Path = filePath;
            
            %read header parameters:
            obj.parseHeaders(fullName);
        end
        
        function fileName = getFileName(obj)
            fileName = [obj.Path filesep obj.Name];
        end
        
        function parseHeaders(obj, fileName)
            % Open the file
            fd = fopen(fileName,'r','native','UTF-8');
            if(fd < 0)
                error('Could not open file, bad filename')
            end
            
            %try to evaluate the input file:
            try
                % Get the image dimensions:
                obj.Height = getData(fd, '2A', 'uint16');%first dim
                obj.Width = getData(fd, '290', 'uint16');%second dim
                obj.NumberOfFrames = getData(fd, '5A6', 'int32');%third dim
                
                % Get file related properties:
                obj.Version = getData(fd, '7C8', 'single'); %version number
                obj.FooterOffset = getData(fd, '2A6', 'uint64'); %offset of footer

                % Get misc properties - usually just for legacy purposes:
                obj.xDimDet = getData(fd, '6', 'uint16'); %x dims of detector chip
                obj.yDimDet = getData(fd, '12', 'uint16'); %y dims of CCD or detector
                obj.noscan = getData(fd, '22', 'int16'); %old number of scans --> -1
                obj.scramble = getData(fd, '292', 'int16'); %0=scrambled, 1=unscrambled
                obj.lnoscan = getData(fd, '298', 'int32'); %number of scans
                obj.winViewId = getData(fd, 'BB4', 'int32'); %file created in winx?
                obj.lastvalue = getData(fd, '1002', 'int16'); %last value in header
      
                % Get the pixel data type
                dataType = getData(fd, '6C', 'int16');
                dataTypeAll = cell2mat(SpeReader.DataType.values);
                if ~ismember(dataType,dataTypeAll) %check on validity of datatype
                    if ~isnumeric(obj.FooterOffset)
                        fseek(fd,0,'eof');
                        ifd = ftell(fd);
                    else
                        ifd = obj.FooterOffset;
                    end
                    ifd = ifd - hex2dec('1004');
                    ifd = ifd/obj.Height/obj.Width/obj.NumberOfFrames;
                    error(['found unknown ' num2str(ifd) 'byte type, of ' ...
                            num2str(obj.Height) '*' num2str(obj.Width) '*' ...
                            num2str(obj.NumberOfFrames)])
                end
                % Get dataType correstonding to enum value:
                obj.PixelType = SpeReader.getDataTypeId(dataType);
                
                % Writer footer xml [if there is any]:
                if ~isempty(obj.FooterOffset) && obj.FooterOffset > hex2dec('1004')
                    fseek(fd, obj.FooterOffset, 'bof');
                    xml = fread(fd, Inf, 'char');
                    obj.FooterXML = char(xml');
                    obj.XML = parseXML(obj);
                end
                
            catch exception
                %close the file and die:
                fclose(fd);
                rethrow(exception);
            end
            %close the file:
            fclose(fd);
            
            % getData() reads one piece of data at a specific location
            function data = getData(fd, hexLoc, dataType)
                % Inputs: fd - int    - file descriptor
                %     hexLoc - string - location of data relative to beginning of file
                %   dataType - string - type of data to be read
                %
                fseek(fd, hex2dec(hexLoc), 'bof');
                data = fread(fd, 1, dataType);
            end
        end
        
        function frames = parseFrames(obj, frameset)
            fileName = obj.getFileName;
            % Open the file
            fd = fopen(fileName,'r');
            if(fd < 0)
                error('Could not open file, bad filename')
            end
            
            %try to evaluate the input file:
            try
                % Get properties:
                height = obj.Height;
                width = obj.Width;
                numFrames = numel(frameset);
                dataType = obj.PixelType;
                
                % Get amount of bytes the image is represented by:
                dataByte = zeros(1,dataType); %#ok<NASGU>
                dataProps = whos('dataByte');
                databytes = dataProps.bytes;
                
                % Seek towards start of framedata and desired frame
                seekstart = hex2dec('1004');
                frameskip = frameset(1)-1;
                seekstart = seekstart + frameskip*width*height*databytes;
                fseek(fd, seekstart, 'bof');
                
                % Define frameblock to be put in memory:
                frames = zeros([width,height,1,numFrames],dataType);
                
                % Extract movie from SPE block
                for k=1:numFrames
                    frames(:,:,:,k) = fread(fd, [height,width], dataType)';
                end
            catch exception
                %close the file and die:
                fclose(fd);
                rethrow(exception);
            end
            %close the file:
            fclose(fd);
            
        end
        
        function xml = parseXML(obj)
            %misc feature, so don't crash if it will error:
            try
                xmlDocument = javax.xml.parsers.DocumentBuilderFactory.newInstance().newDocumentBuilder.parse(java.io.StringBufferInputStream(obj.FooterXML));
                xml = parseXMLNodes(xmlDocument);
            catch ex
                xml = ex;
            end
        
            function tree = parseXMLNodes(parentNode)
                tree = [];
                %assign attributes
                if parentNode.hasAttributes
                   theAttributes = parentNode.getAttributes;
                   numAttributes = theAttributes.getLength;

                   for count = 1:numAttributes
                       try
                       attrib = theAttributes.item(count-1);
                       tree.(char(attrib.getName)) = char(attrib.getValue);
                       catch ex %#ok<NASGU>
                           %likely invalid name, so replace illegal characters with _
                           oldName = char(attrib.getName);
                           newName = regexprep(oldName, '[:,;.]', '_');
                           tree.(newName) = char(attrib.getValue);
                           %save original name to structure:
                           tree.(['RENAMED__' newName]) = oldName;
                       end
                   end
                end

                %recurse over child nodes
                if parentNode.hasChildNodes
                    childNodes = parentNode.getChildNodes;
                    numChildNodes = childNodes.getLength;

                    for count = 1:numChildNodes
                        theChild = childNodes.item(count-1);
                        childName = char(theChild.getNodeName);
                        if strcmp(childName,'#text') %this is supposed to be a root value
                            childName = 'ROOT';
                        end
                        if isfield(tree, childName)
                            warning('SpeReader:xmlparser',['field ' childName ' exists in: ' char(parentNode.getNodeName) '!!'])
                            A=tree.(childName);
                            B=parseXMLNodes(theChild);

                            ufn = unique([fieldnames(A);fieldnames(B)]);
                            nA = ~ismember(ufn,fieldnames(A)); %not a field in A
                            nB = ~ismember(ufn,fieldnames(B));
                            fA=ufn{nA}; %unknown fieldnames in A
                            fB=ufn{nB};
                            A.(fA) = []; %create these fieldnames in A
                            B.(fB) = [];
                            tree = [A,B];
                        else
                            tree.(childName) = parseXMLNodes(theChild);
                        end
                    end
                end
            end 
        end
        
    end
    
    methods
        % Properties that need to be customly get or set
        function set.Tag(obj, value)
            if ~(ischar(value) || isempty(value))
                error('Tag must be a string value!');
            end
            obj.Tag = value;
        end
        
        function value = get.Type(obj)
            value = class(obj);
        end
        
    end
    
end