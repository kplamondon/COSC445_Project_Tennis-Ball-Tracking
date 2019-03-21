%% Clear Memory
clc;
clear;
%% Step 1 - Import Video and Initialize Foreground Detector
FG_Detector = vision.ForegroundDetector('NumGaussians',3,'NumTrainingFrames', 50);
videoReader = vision.VideoFileReader('assets/video_1/video1.mp4');
%% Step 2 - Detect Cars
videoPlayer = vision.VideoPlayer('Name', 'Gausian Background Subtraction');
videoPlayer.Position(3:4) = [650,400]; % window size: [width, height]
blobAnalysis = vision.BlobAnalysis('BoundingBoxOutputPort', true, ...
    'AreaOutputPort', false, 'CentroidOutputPort', false, ...
    'MinimumBlobArea', 150);
se = strel('square', 3); % morphological filter for noise removal
while ~isDone(videoReader)
    frame = step(videoReader); % read the next video frame
    % Detect the FG in the current video frame
    FG = step(FG_Detector, frame);
    % Use morphological opening to remove noise in the FG
    filteredFG = imopen(FG, se);
    % Detect connected components with specified minimum area & find bounding boxes
    bbox = step(blobAnalysis, filteredFG);
    % Draw bounding boxes around the detected cars
    result = insertShape(frame, 'Rectangle', bbox, 'Color', 'green');
    % Display the number of cars found in the video frame
    numCars = size(bbox, 1);
    result = insertText(result, [10 10], numCars, 'BoxOpacity', 1, 'FontSize', 14);
    step(videoPlayer, result); % display the results
end
release(videoReader); % Close the video file