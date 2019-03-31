%% Step 1 - Play through the video and determine a mean background
BG=GetBackground('assets/video_3/video3.mp4',390);%video name and number of frame   really slow!!!!
%% Step 2 - Play video and detect candidates
videoPlayer = VideoReader('assets/video_3/video3.mp4'); 
position=[0 0 0 0 0];%Trajectory position
frames = 0;
%Video Information
numberOfFrames = videoPlayer.NumberOfFrames;

for i = 1:1:numberOfFrames
    %update the frame
    frame = read(videoPlayer,i);
    frames = frames + 1;
    %extract from the frame
    grayframe = im2double(rgb2gray(frame));
    diff=grayframe-BG;
    FG_mask=diff>0.12;
    FG_mask=bwareaopen(FG_mask,3);
    FG=FG_mask.*grayframe;
    FG=imopen(FG,strel('disk',2));
    FG=imdilate(FG,strel('disk',5));
    FG=im2bw(FG);
     [Label,Number]=bwlabel(FG);
    region=regionprops(Label,'all');
    [r,c]=size(FG);
    onlyball=zeros(r,c);
    for i=1:Number
        item=double(Label==i);
        if(region(i).Area<420)
            onlyball=onlyball+item;
        end
    end
    [BW,frame_rgbSegmented] = createMaskWhite(frame); %Colour segment the object
    FG_segment = im2bw(rgb2gray(frame_rgbSegmented));
    FG_segment(1:180,:)=0;
    FG_segment(832:1080,:)=0;
    FG_segment(:,1:250)=0;
    FG_segment(:,1650:1920)=0;
    FG_segment=imerode(FG_segment,strel('disk',2));
    FG_segment=imdilate(FG_segment,strel('disk',6));
    %apply and oporator on both the gausian and the color segmented object
    NFG = bitand(onlyball, FG_segment);
    % Use morphological opening to remove noise in the FG
    filteredFG = imopen(NFG, strel('disk', 3));
    filteredFG=imdilate(filteredFG,strel('disk',3));
    [vid,posi]=detectobject(filteredFG,frame,140);
    posi = posi(1:length(posi(:,1))-1, :);
    
    posi_new = zeros(length(posi(:,1)),5);
    posi_new(:,1:4) = posi;
    posi_new(:,5) = frames;
    position=cat(1,position,posi_new);
    
    %Add the frame number into the image
    vid = insertText(vid,[1,1],frames);
    %Show the video frame
    imshow(vid);
end
position = position(2:length(position(:,1)), 1:5);

%% Step 3 - Candidate Level
t = position(:,5);
x = position(:,1) + position(:,3)/2;
y = position(:,2) + position(:,4)/2;
figure, plot(t,x,'r*','color','red','LineWidth',2,'MarkerSize',2);
figure, plot(t,y,'r*','color','blue','LineWidth',2,'MarkerSize',2);

[HEIGHT,WIDTH] = size(BG);
v = 3;
storedIndexes = [];
for i = v+1:1:numberOfFrames-v
    %Check and makesure we have a candidate at frmae i
    candidates_i = getCandidates(position,i);
    if length(candidates_i) == 0
        continue;
    end
    %Extract Candidates across frames 2V+1
    candidates = []; 
    n = 0;
    for j=i-v:1:i+v
        candidates_j = getCandidates(position,j);
        if length(candidates) == 0 && length(candidates_j) > 0 && j~=i
            candidates = candidates_j;
            n = n+1;
        elseif length(candidates_j) > 0 && j~=i
            candidates = cat(1,candidates,candidates_j);
            n = n+1;
        end
    end
    if n < 3
        continue;
    end
    %Create a single frame from the candidates centered on candidate_i
    R = 30; 
    %Loop through each candidate from this frame
    for li=1:1:length(candidates_i(:,1))
        xi = candidates_i(li,2) + candidates_i(li,4)/2;
        yi = candidates_i(li,1) + candidates_i(li,3)/2;
        
        candidateFrame = zeros(2*R,2*R);
        window_candidates = [];
        
        %Loop through all the candidates on frames near frame i
        for j=1:1:n
            x = candidates(j,2) + candidates(j,4)/2;
            y = candidates(j,1) + candidates(j,3)/2;
            r = sqrt((x-xi)^2 + (y-yi)^2);
            if r < R         && length(window_candidates) == 0
                candidateFrame( uint8(R+(x-xi)), uint8(R+(y-yi)) ) = 1;
                new_candidate = zeros(1,6);
                new_candidate(1:5) = candidates(j,:);
                new_candidate(6) = r;
                window_candidates = new_candidate;
            elseif r < R
                candidateFrame( uint8(R+(x-xi)), uint8(R+(y-yi)) ) = 1;
                new_candidate = zeros(1,6);
                new_candidate(1:5) = candidates(j,:);
                new_candidate(6) = r;
                window_candidates = cat(1,window_candidates,new_candidate);
            end
        end
        %Check how many candidates are within the radius of candidate_i
        m = sum(sum(candidateFrame));
        [m2 c] = size(window_candidates);
        if m < 2
            continue;
        end
        %Check and see if frame i-1 and i+1 are in the window
        frameVector = window_candidates(:,5)';
        isSeed = sum(sum((frameVector==i-1) + (frameVector==i+1))) >= 2;
        if ~isSeed
            continue;
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        imshow(candidateFrame);
        %Store the 3 points into the storedFrames vector
%         if length(storedFrames) == 0
%             storedIndexes = i-1;
%         else
%             storedFrames = cat(1,storedFrames,i-1);
%         end
%         storedFrames = cat(1,storedFrames,i);
%         storedFrames = cat(1,storedFrames,i+1);
        %We have found a seed, now we compute a tracklet using the seed
        tracklet_top = getCandidates(window_candidates,i+1);
        tracklet_bot = getCandidates(window_candidates,i-1);
        %Get the three points
        p1 = getCoordinates(window_candidates,i-1);
        p2 = candidates_i(li,1:2);
        p3 = getCoordinates(window_candidates,i+1);
        %Loop through increasing frames
        foundPoint = true;
        delK = 3;
        while foundPoint
            %Calculate velocity and acceleration
            a = (p3-p2)-(p2-p1);
            v1 = (p2 - p1) - a/2;
            %predict next point
            pk = p1 + delK*v1 + 1/2*a;
            k = i + delK;
            disp(pk);
            %get candidates at frame k
            Ck = getCandidates(position,k);
            %Check if there is a candidate within range to pk
            for kj=1:1:length(Ck(:,1))
                x = candidates(j,2) + candidates(j,4)/2;
                y = candidates(j,1) + candidates(j,3)/2;
                r = sqrt((x-xi)^2 + (y-yi)^2);
            end
            foundPoint = false;
        end
        
        %Loop through decreasing frames
    end
    
end

%showTrajectory(BG,position(:,1:4));

%% Function for getting candidates at a certain frame
function candidates = getCandidates(positionMatrix,frame)
    indexes = positionMatrix(:,5)==frame;
    a = positionMatrix .* indexes;
    candidates = a(any(a,2),:);
end
function points = getCoordinates(candidateMatrix,frame)
    indexes = candidateMatrix(:,5)==frame;
    a = candidateMatrix .* indexes;
    candidates = a(any(a,2),:);
    points = candidates(:,1:2);
end