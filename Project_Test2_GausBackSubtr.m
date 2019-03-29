%% Clear Memory
clc;
clear;
%% Step 1 - Import Video and Initialize Foreground Detector
FG_Detector = vision.ForegroundDetector('NumGaussians',5,'NumTrainingFrames', 5);
videoReader = vision.VideoFileReader('assets/video_2/video2.mp4');
%% Step 2 - Detect tenis ball candidates
videoPlayer = vision.VideoPlayer('Name', 'Gausian Background Subtraction');
videoPlayer.Position(3:4) = [960,640]; % window size: [width, height]
blobAnalysis = vision.BlobAnalysis('BoundingBoxOutputPort', true, ...
    'AreaOutputPort', false, 'CentroidOutputPort', false, ...
    'MaximumBlobArea', 300, 'MinimumBlobArea', 6);
se = strel('disk', 3); % morphological filter for noise removal
%peopleDetector = vision.PeopleDetector; %used for HOG detection of players

%% Candidate Level - Create data structure for storing the candidates 
candidates = zeros(1,1);

while ~isDone(videoReader)
    frame = step(videoReader); % read the next video frame
    % Detect the FG in the current video frame using Gausian
    FG_gaus = step(FG_Detector, frame);
    
    %Use color segmentatation to determine another binary image
    [BW,frame_rgbSegmented] = createMask1(frame);
    FG_segment = im2bw(rgb2gray(frame_rgbSegmented));
    
    %apply and oporator on both the gausian and the color segmented object
    FG = bitand(FG_gaus, FG_segment);
    
    % Use morphological opening to remove noise in the FG
    filteredFG = imopen(FG, se); 
    
    % Now we need to remove the false candidates from the player
    % -> this is done by first detecting the player with HOG
    %[bboxPeople, peopleScores] = peopleDetector(frame); 
    %Using the bbox of the people we remove objects inside the bbox
    %for i=1:length(bboxPeople)
    %   filteredFG(bboxPeople) = 0; 
    %end
    
    % Now we need to detect the lines of the court and remove these as well
    %E = edge(rgb2gray(frame), 'canny',[],5);
    %[H,T,R] = hough(E);
    %peaks = houghpeaks(H,50,'Threshold',30);
    %lines = houghlines(E,T,R,peaks,'FillGap',5,'MinLength',50);
    
    % Detect connected components with specified max area & find bounding boxes
    bbox = step(blobAnalysis, filteredFG);
    
    % Add to candidates
    cat(1,bbox, candidates);
    
    % Draw bounding boxes around the detected objects
    result = insertShape(frame, 'Rectangle', bbox, 'Color', 'green');
    %result = insertObjectAnnotation(result,'rectangle',bboxPeople,peopleScores);
    %result = insertShape(result, 'Line', [lines.point1 lines.point2], 'Color', 'cyan');
    % Display the number of tennis balls found in the video frame
    numBalls = size(bbox, 1);
    result = insertText(result, [10 10], numBalls, 'BoxOpacity', 1, 'FontSize', 14);
    step(videoPlayer, result); % display the results
end
release(videoPlayer); % Close the video file