FG_Detector = vision.ForegroundDetector('NumGaussians',5,'NumTrainingFrames', 50);
videoReader = vision.VideoFileReader('assets/video_2/video2.mp4');

videoPlayer = vision.VideoPlayer('Name', 'Gausian Background Subtraction');
videoPlayer.Position(1:4) = [0,48,960,640]; % window size: [width, height]
blobAnalysis = vision.BlobAnalysis('BoundingBoxOutputPort', true, ...
    'AreaOutputPort', false, ...
    'MaximumBlobArea', 300, 'MinimumBlobArea', 30);


se = strel('disk', 3); % morphological filter for noise removal
kalmanFilter=[];
isTrackInitialized=false;

 while ~isDone(videoReader)
    frame = step(videoReader); % read the next video frame
    % Detect the FG in the current video frame using Gausian
    FG_gaus = step(FG_Detector, frame);
    %Use color segmentatation to determine another binary image
    [BW,frame_rgbSegmented] = createMask1(frame);
    FG_segment = im2bw(rgb2gray(frame_rgbSegmented));
    FG_segment=imopen(FG_segment,strel('disk',1));
    %apply and oporator on both the gausian and the color segmented object
    FG = bitand(FG_gaus, FG_segment);
    % Use morphological opening to remove noise in the FG
    filteredFG = imopen(FG, se);
    filteredFG=imdilate(filteredFG,strel('disk',2));
    % Detect connected components with specified max area & find bounding boxes
    bbox = step(blobAnalysis, filteredFG);
    
    isObjectDetected=size(bbox)>0;
    
     if ~isTrackInitialized
       if isObjectDetected
         kalmanFilter = configureKalmanFilter('ConstantAcceleration',...
                  bbox(1,:), [1 1 1]*1E5, [1, 15, 1], 30);
         isTrackInitialized = true;
       end
       label = ''; 
       circle = zeros(0,3);
     else
       if isObjectDetected
         predict(kalmanFilter);
         trackedLocation = correct(kalmanFilter, bbox(1,:));
         label = 'Corrected';
       else
         trackedLocation = predict(kalmanFilter);
         label = 'Predicted';
       end
       circle = [trackedLocation, 6];
     end
     kal = insertObjectAnnotation(frame,'circle',...
                circle,label,'Color','red');
     
     step(videoPlayer,kal);
     
 end
 release(videoPlayer);
 release(videoReader);