%% Clear Memory
clc;
clear;
%%
FG_Detector = vision.ForegroundDetector('NumGaussians',10,'NumTrainingFrames',100 );
videoReader = vision.VideoFileReader('Test2.mp4');

videoPlayer = vision.VideoPlayer('Name', 'Gausian Background Subtraction');
videoPlayer.Position(3:4) = [960,640]; % window size: [width, height]
blobAnalysis = vision.BlobAnalysis('BoundingBoxOutputPort', true, ...
    'AreaOutputPort', false, 'CentroidOutputPort', false, ...
    'MaximumBlobArea', 300, 'MinimumBlobArea', 5);

se = strel('disk', 3); % morphological filter for noise removal
while ~isDone(videoReader)
    frame = step(videoReader); % read the next video frame
    % Detect the FG in the current video frame using Gausian
    FG_gaus = step(FG_Detector, frame);
    
    %Use color segmentatation to determine another binary image
    [BW,frame_rgbSegmented] = createMask1(frame);
    FG_segment = im2bw(rgb2gray(frame_rgbSegmented));
    FG_segment=imopen(FG_segment,strel('disk',1));
    %apply and oporator on both the gausian and the color segmented object
    FG = bitor(FG_gaus, FG_segment);
    % Use morphological opening to remove noise in the FG
    filteredFG = imclose(FG, se);
    filteredFG=imdilate(filteredFG,strel('disk',2));
   
    
    
    
    % Detect connected components with specified max area & find bounding boxes
    bbox = step(blobAnalysis, filteredFG);
    % Draw bounding boxes around the detected objects
    result = insertShape(frame, 'Rectangle', bbox, 'Color', 'red');
    % Display the number of tennis balls found in the video frame
    numBalls = size(bbox, 1);
    result = insertText(result, [10 10], numBalls, 'BoxOpacity', 1, 'FontSize', 14);
    step(videoPlayer,result); % display the results
end
release(videoPlayer); % Close the video file