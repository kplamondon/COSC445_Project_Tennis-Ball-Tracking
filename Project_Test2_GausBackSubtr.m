%% Clear Memory
clc;
clear;
%% Step 1 - Import Video and Initialize Foreground Detector
FG_Detector = vision.ForegroundDetector('NumGaussians',5,'NumTrainingFrames', 5);
videoReader = vision.VideoFileReader('assets/video_2/video2.mp4');
%% Step 2 - Detect Cars
videoPlayer = vision.VideoPlayer('Name', 'Gausian Background Subtraction');
videoPlayer.Position(3:4) = [960,640]; % window size: [width, height]
blobAnalysis = vision.BlobAnalysis('BoundingBoxOutputPort', true, ...
    'AreaOutputPort', false, 'CentroidOutputPort', false, ...
    'MaximumBlobArea', 300, 'MinimumBlobArea', 5);
se = strel('disk', 2); % morphological filter for noise removal
while ~isDone(videoReader)
    frame = step(videoReader); % read the next video frame
    % Detect the FG in the current video frame using Gausian
    FG_gaus = step(FG_Detector, frame);
    
    %Use color segmentatation to determine another binary image
    [BW,frame_rgbSegmented] = createMaskWhite(frame);
    FG_segment = im2bw(rgb2gray(frame_rgbSegmented));
    
    %apply and oporator on both the gausian and the color segmented object
    FG = bitand(FG_gaus, FG_segment);
    
    % Use morphological opening to remove noise in the FG
    filteredFG = imopen(FG, se);
    
    
    
    % Detect connected components with specified max area & find bounding boxes
    %bbox = step(blobAnalysis, filteredFG);
    % Draw bounding boxes around the detected objects
    %result = insertShape(frame, 'Rectangle', bbox, 'Color', 'green');
    % Display the number of tennis balls found in the video frame
    %numBalls = size(bbox, 1);
    %result = insertText(result, [10 10], numBalls, 'BoxOpacity', 1, 'FontSize', 14);
    step(videoPlayer, FG); % display the results
end
release(videoPlayer); % Close the video file