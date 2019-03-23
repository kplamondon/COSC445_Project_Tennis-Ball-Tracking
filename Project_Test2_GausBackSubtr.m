%% Clear Memory
clc;
clear;
%% Step 1 - Import Video and Initialize Foreground Detector
FG_Detector = vision.ForegroundDetector('NumGaussians',5,'NumTrainingFrames', 15);
videoReader = vision.VideoFileReader('assets/video_1/video1.mp4');
%% Step 2 - Detect Cars
videoPlayer = vision.VideoPlayer('Name', 'Gausian Background Subtraction');
videoPlayer.Position(3:4) = [960,640]; % window size: [width, height]
blobAnalysis = vision.BlobAnalysis('BoundingBoxOutputPort', true, ...
    'AreaOutputPort', false, 'CentroidOutputPort', false, ...
    'MaximumBlobArea', 50);
se = strel('disk', 2); % morphological filter for noise removal
while ~isDone(videoReader)
    frame = step(videoReader); % read the next video frame
    % Colour segment
    [BW,frame_rgbSegmented] = createMask3(frame);
    % Detect the FG in the current video frame
    FG = step(FG_Detector, frame_rgbSegmented);
    % Use morphological opening to remove noise in the FG
    filteredFG = imopen(FG, se);
    % Detect connected components with specified max area & find bounding boxes
    bbox = step(blobAnalysis, filteredFG);
    % Draw bounding boxes around the detected cars
    result = insertShape(frame_rgbSegmented, 'Rectangle', bbox, 'Color', 'green');
    % Display the number of cars found in the video frame
    numBalls = size(bbox, 1);
    %result = insertText(result, [10 10], numBalls, 'BoxOpacity', 1, 'FontSize', 14);
    step(videoPlayer, result); % display the results
end
release(videoPlayer); % Close the video file