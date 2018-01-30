classdef CascadeObjectDetector < matlab.system.System 
    %CascadeObjectDetector Detect objects using the Viola-Jones algorithm
      
    properties(Nontunable)
        %ClassificationModel A trained cascade classification model
        %   Specify the name of the model as a string. The value specified
        %   for this property may be one of the valid MODEL strings listed 
        %   <a href="matlab:helpview(fullfile(docroot,'toolbox','vision','vision.map'),'vision.CascadeObjectDetector.ClassificationModel')">here</a> or an OpenCV XML file containing custom classification
        %   model data. When an XML file is specified, a full or relative
        %   path is required if the file is not on the MATLAB path.
        %        
        %   Default: 'FrontalFaceCART'           
        %
        %   See also <a href="matlab:helpview(fullfile(docroot,'toolbox','vision','vision.map'),'vision.CascadeObjectDetector.ClassificationModel')">Available models</a>
        ClassificationModel = 'FrontalFaceCART';
    end
    properties
        %MinSize Size of the smallest object to detect
        %   Specify the size of the smallest object to detect, in pixels,
        %   as a two-element vector, [height width]. Use this property to
        %   reduce computation time when the minimum object size is known
        %   prior to processing the image. When this property is not
        %   specified, the minimum detectable object size is the image size
        %   used to train the classification model. This property is
        %   tunable.
        %
        %   Default: []              
        MinSize;
        %MaxSize Size of the biggest object to detect
        %   Specify the size of the biggest object to detect, in pixels, as
        %   a two-element vector, [height width]. Use this property to
        %   reduce computation time when the maximum object size is known
        %   prior to processing the image. When this property is not
        %   specified, the maximum detectable object size is SIZE(I). This
        %   property is tunable.
        %
        %   Default: []
        MaxSize;
        %ScaleFactor Scaling for multi-scale object detection
        %   Specify the factor used to incrementally scale the detection
        %   scale between MinSize and MaxSize. At each increment, N,
        %   the detection scale is
        %
        %     round(TrainingSize*(ScaleFactor^N))
        %
        %   where TrainingSize is the image size used to train the
        %   classification model. The training size used for each
        %   classification model is shown <a href="matlab:helpview(fullfile(docroot,'toolbox','vision','vision.map'),'vision.CascadeObjectDetector.ClassificationModel')">here</a>. This property is tunable.
        %
        %   Default: 1.1
        ScaleFactor = 1.1;
        %MergeThreshold Threshold for merging colocated detections
        %   Specify a threshold value as a scalar integer. This property
        %   defines the minimum number of colocated detections needed to
        %   declare a final detection. Groups of colocated detections that
        %   meet the threshold are merged to produce one bounding box
        %   around the target object. Increasing this threshold can help
        %   suppress false detections by requiring that the target object
        %   be detected multiple times during the multi-resolution
        %   detection phase. By setting this property to 0, all detections
        %   are returned without merging. This property is tunable.
        %
        %   Default: 4
        MergeThreshold = 4;
    end

    properties (Transient,Access = private)        
        pCascadeClassifier; % OpenCV pCascadeClassifier       
    end   
    
    properties (Access = private)
        % used to convert RGB images to grayscale
        pColorSpaceConverter = vision.ColorSpaceConverter(...
            'Conversion','RGB to intensity');
    end
    properties(Hidden,Dependent,SetAccess = private)
        %TrainingSize Image size used to train classification model
        %   This is the smallest object that the classification model is
        %   trained to detect. It is the smallest object size that the
        %   model can detect.
        TrainingSize;
    end    
    methods
        %------------------------------------------------------------------
        % Constructor
        %------------------------------------------------------------------
        function obj = CascadeObjectDetector(varargin)              
            obj.pCascadeClassifier = vision.internal.CascadeClassifier;
            initialize(obj);
            setProperties(obj,nargin,varargin{:},'ClassificationModel');             
            validatePropertiesImpl(obj);
        end
        
        %------------------------------------------------------------------
        % ClassificationModel set method
        %------------------------------------------------------------------
        function set.ClassificationModel(obj,value)            
            validateattributes(value,{'char'},{'nonempty','row'});            
            if ~isKey(obj.ModelMap,value) ...
                    && ~(exist(value,'file') == 2)               
                error(message('vision:ObjectDetector:modelNotFound',value));
            end
            obj.ClassificationModel = value;               
            initialize(obj);
        end
        
        %------------------------------------------------------------------
        % ScaleFactor set method
        %------------------------------------------------------------------
        function set.ScaleFactor(obj,value) 
            validateattributes( value,{'numeric'},...
                {'scalar', '>',1,'real', 'nonempty','nonsparse','finite'},...
                '','ScaleFactor');
            
            obj.ScaleFactor = value;
        end
        
        %------------------------------------------------------------------
        % MinSize set method
        %------------------------------------------------------------------
        function set.MinSize(obj,value)
            validateSize('MinSize',value);
            obj.MinSize = value;
        end
        
        %------------------------------------------------------------------
        % MaxSize set method
        %------------------------------------------------------------------
        function set.MaxSize(obj,value)            
            validateSize('MaxSize',value);
            obj.MaxSize = value;
        end
        
        %------------------------------------------------------------------
        % MergeThreshold set method
        %------------------------------------------------------------------
        function set.MergeThreshold(obj,value)           
            validateattributes( value, ...
                {'numeric'}, {'scalar','>=' 0, 'real','integer',...
                'nonempty','nonsparse','finite'},...
                '','MergeThreshold');
            
            obj.MergeThreshold = value;
        end  
        
        %------------------------------------------------------------------
        % TrainingSize get method
        %------------------------------------------------------------------
        function value = get.TrainingSize(obj)
            info = obj.pCascadeClassifier.getClassifierInfo();
            value = info.originalWindowSize;
        end  
    end
    
    methods(Access = protected)        
        %------------------------------------------------------------------
        % Cross validate properties
        %------------------------------------------------------------------
        function validatePropertiesImpl(obj)

            % validate that MinSize is greater than or equal to the minimum
            % object size used to train the classification model
            if ~isempty(obj.MinSize)
                if any(obj.MinSize < obj.TrainingSize)
                    error(message('vision:ObjectDetector:minSizeLTTrainingSize',...
                        obj.TrainingSize(1),obj.TrainingSize(2)));
                end
            end
            
            % validate the MaxSize is greater than the
            % pModel.TrainingSize when MinSize is not
            % specified
            if isempty(obj.MinSize) && ~isempty(obj.MaxSize)
                if any(obj.TrainingSize >= obj.MaxSize)
                    error(message('vision:ObjectDetector:modelMinSizeGTMaxSize',...
                        obj.TrainingSize(1),obj.TrainingSize(2)));
                end
            end
            
            % validate that MinSize < MaxSize
            if ~isempty(obj.MaxSize) && ~isempty(obj.MinSize)               
                if any(obj.MinSize >= obj.MaxSize)
                    error(message('vision:ObjectDetector:minSizeGTMaxSize'));
                end
            end
            
        end
                     
        %------------------------------------------------------------------
        % Validate inputs to STEP method
        %------------------------------------------------------------------
        function validateInputsImpl(~,I)            
            validateattributes(I,...
                {'uint8','uint16','double','single','int16'},...
                {'real','nonsparse'},...
                '','',2);
            if ~any(ndims(I)==[2 3])
                error(message('vision:dims:imageNot2DorRGB'));
            end
        end
        
        %------------------------------------------------------------------
        % STEP method implementation
        %------------------------------------------------------------------
        function bboxes = stepImpl(obj,I)
                    
            % convert image data to uint8    
            I = im2uint8(I);
            
            % convert RGB to grayscale
            if ndims(I) == 3
                I = step(obj.pColorSpaceConverter,I);
            end 
            
            bboxes = double(obj.pCascadeClassifier.detectMultiScale(I, ...
                double(obj.ScaleFactor), ...
                uint32(obj.MergeThreshold), ...            
                int32(obj.MinSize), ...
                int32(obj.MaxSize)));
        end
                
        %------------------------------------------------------------------
        % Release method implementation
        %------------------------------------------------------------------
        function releaseImpl(obj)
            release(obj.pColorSpaceConverter);
        end
        
        %------------------------------------------------------------------
        % Custom load method
        %------------------------------------------------------------------
        function loadObjectImpl(obj,s, ~)
            obj.ScaleFactor = s.ScaleFactor;
            obj.MinSize = s.MinSize;
            obj.MaxSize = s.MaxSize;
            obj.MergeThreshold = s.MergeThreshold;
            
            try % to set saved ClassificationModel
                obj.ClassificationModel = s.ClassificationModel;
            catch ME %#ok<NASGU>
                % error while setting the ClassificationModel
                % throw a warning and leave ClassificationModel set to default
                warning(...
                    message('vision:ObjectDetector:modelNotFoundOnLoad',...
                    s.ClassificationModel,'FrontalFaceCART'));
            end            
        end
        
        %------------------------------------------------------------------
        % Initialize classification model 
        %------------------------------------------------------------------
        function initialize(obj)                         
            obj.pCascadeClassifier.load(obj.getModelPath(obj.ClassificationModel));
        end
                
        %------------------------------------------------------------------
        % Return the number of inputs
        %------------------------------------------------------------------
        function num_inputs = getNumInputsImpl(~)
            num_inputs = 1;
        end
        
        %------------------------------------------------------------------
        % Return the number of outputs
        %------------------------------------------------------------------
        function num_outputs = getNumOutputsImpl(~)
            num_outputs = 1;
        end              
    end
    properties(Constant,Hidden)      
        %------------------------------------------------------------------
        % ModelMap Map data structure to store ModelName to file mappings
        %------------------------------------------------------------------
        ModelMap = makeModelMap();
    end
    methods(Static, Hidden)
        %------------------------------------------------------------------
        % getModelPath returns full path to model data file
        %------------------------------------------------------------------
        function file_path = getModelPath(name)
            if isdeployed
                rootDirectory = ctfroot;
            else
                rootDirectory = matlabroot;
            end
            dataDirectory = fullfile(rootDirectory,'toolbox','vision',...
            'visionutilities','classifierdata','cascade');
          
            % Get the path to the model data file so that the data can be
            % loaded using OpenCV
            if isKey(vision.CascadeObjectDetector.ModelMap,name)
                filename = vision.CascadeObjectDetector.ModelMap(name);
                if strncmp(filename,'lbp',3)
                    feature_type = 'lbp';
                else
                    feature_type = 'haar';
                end                
                % construct full path to file
                file_path = fullfile(dataDirectory,feature_type,filename);
            else
                % custom file supplied; determine if it is on the path
                file_path = which(name);
                if isempty(file_path) % not on the path nor in current directory
                    file_path = name; % must be full/relative path
                end
            end
        end
        %------------------------------------------------------------------
        % Return whether or not system object generates code 
        %------------------------------------------------------------------
        function tf = generatesCode
            tf = false;
        end
    end
end % of classdef

%--------------------------------------------------------------------------
% Validation for MinSize and MaxSize
%--------------------------------------------------------------------------
function validateSize(prop,value)
% By default MaxSize/MinSize is [], and it can be set to empty too.
validateattributes( value,...
    {'numeric'}, {'real','nonsparse','finite','2d','integer', '>=',0},...
    '',prop);
% Using 'vector',2 in validateattributes fails for [] so the
% following check makes sure that MaxSize has 2-elements
if ~isempty(value) && (numel(value) ~= 2)
    error(message('vision:ObjectDetector:invalidSize',prop));
end

end

%--------------------------------------------------------------------------
% makeModelMap returns a containers.Map object containing the ModelName to
% OpenCV classifier XML file mapping.
%--------------------------------------------------------------------------
function map = makeModelMap()
% Define model to OpenCV XML file name pairings and store them in a Map.

mapData = {...
    'FrontalFaceCART', 'haarcascade_frontalface_alt2.xml';...
    'FrontalFaceLBP',  'lbpcascade_frontalface.xml';...
    'ProfileFace',     'haarcascade_profileface.xml';...
    'Mouth',           'haarcascade_mcs_mouth.xml';...
    'Nose',            'haarcascade_mcs_nose.xml';...    
    'EyePairBig',      'haarcascade_mcs_eyepair_big.xml';...
    'EyePairSmall',    'haarcascade_mcs_eyepair_small.xml';...
    'RightEye',        'haarcascade_mcs_righteye.xml';...
    'LeftEye',         'haarcascade_mcs_lefteye.xml';...
    'RightEyeCART',    'haarcascade_righteye_2splits.xml';...
    'LeftEyeCART',     'haarcascade_lefteye_2splits.xml';...
    'UpperBody',       'haarcascade_mcs_upperbody.xml'};

map = containers.Map(mapData(:,1),mapData(:,2));

end
