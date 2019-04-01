%% Clear Memory 
clc;
clear;
video_file = 'assets/video_3/video3.mp4';
%% Step 1 - Get Background image 
disp("Getting Background Image (Please Wait)...");
BG=GetBackground(video_file,390);%video name and number of frame   really slow!!!!
%% Step 2 & 3 - Detect Candidates & Predict Missing Candidates
disp("Getting Candidates from video (Please Wait)...");
videoReader = vision.VideoFileReader(video_file);
position=[0 0 0 0 0];%Trajectory position
frames = 1;
while ~isDone(videoReader)
    frame=step(videoReader);
    grayframe = im2double(rgb2gray(frame));
    diff=grayframe-BG;
    FG_mask=diff>0.15;
    FG_mask=bwareaopen(FG_mask,3);
    FG=FG_mask.*grayframe;
    FG=imopen(FG,strel('disk',2));
    %FG=imerode(FG,strel('disk',1));
    FG=imdilate(FG,strel('disk',10));
    FG=imclose(FG,strel('disk',2));
    FG=im2bw(FG);
     [Label,Number]=bwlabel(FG);
    region=regionprops(Label,'all');
    [r,c]=size(FG);
    onlyball=zeros(r,c);
    
    for i=1:Number
        item=double(Label==i);
        if(region(i).Area<950)
            onlyball=onlyball+item;
        end
    end
    
    [BW2,frame_layer2] = createMasklayer2(frame);
    FG_layer2 = im2bw(rgb2gray(frame_layer2));
    FG_layer2 =imerode(FG_layer2 ,strel('disk',2));
    FG_layer2 =imdilate(FG_layer2 ,strel('disk',6));
    
    
    [BW,frame_rgbSegmented] = createMasknew2(frame);
    FG_segment = im2bw(rgb2gray(frame_rgbSegmented));
    FG_segment(1:160,:)=0;
    FG_segment(832:1080,:)=0;
    FG_segment(:,1:250)=0;
    FG_segment(:,1650:1920)=0;
    FG_segment = imerode(FG_segment,strel('disk',2));
    FG_segment = imdilate(FG_segment,strel('disk',6));
    %apply and oporator on both the gausian and the color segmented object
    NFG = bitand(onlyball, FG_segment);
    % Use morphological opening to remove noise in the FG
    filteredFG = imopen(NFG, strel('disk', 3));
    filteredFG = imdilate(filteredFG,strel('disk',3));
    
    [vid,posi]=newdetectobject(filteredFG,frame,50);
    [vidl2,posil2]=newdetectobject(FG_layer2,frame,50);
    [porow,pocol]=size(position);
    [l2row,l2col]=size(posil2);
    
    if posi(1,1)~=0
        p = zeros(1,5);
        if length(posi(:,1)) > 1
           disp(length(posi(:,1)) + " objects detected on: " + frames); 
        end
        p(1:4) = posi(1,:);
        p(5) = frames;
        position=cat(1,position,p);
    else
        for j=1:l2row
            xdir = position(porow,2)+(position(porow,4)/2);
            ydir = position(porow,1)+(position(porow,3)/2);
            xdirl2 = posil2(j,2)+(posil2(j,4)/2);
            ydirl2 = posil2(j,1)+(posil2(j,3)/2);
            r=sqrt((xdir-xdirl2).^2+(ydir-ydirl2).^2);
            if r<60
                p = zeros(1,5);
                p(1:4) = posil2(j,:);
                p(5) = frames;
                position=cat(1,position,p);
                vid=predicted(posil2(j,:),frame);
            end
        end
    end
    frames = frames + 1;
end
position = position(2:length(position),:);
%% Step 5 - Find Events
disp("Finding all events from candidates...");
t = position(:,5);
x = position(:,1) + position(:,3)/2;
y = position(:,2) + position(:,4)/2;
p = [x y];

%Calculate acceleration -> store into a matrix
acc = [];
events = [];
for i=3:1:length(x)
    a = (p(i,:)-p(i-1,:))/(t(i)-t(i-1)) - (p(i-1,:)-p(i-2,:))/(t(i-1)-t(i-2));
    if length(acc) == 0
        acc = a;
    else
        acc = cat(1,acc,a);
    end
    
    if a(2) > 20 || a(2) < -28
        if length(events) == 0
            events = t(i);
        else
            events = cat(1,events,t(i));
        end
    end
end

v = 3;
thresh = 4;
events1 = events;
events = [];
last = 379;
i = 1;
while i < length(events1)
    avg = events1(i);
    disp(avg);
    if i < length(events1)-v
        e = events1(i);
        for j=i:1:i+v
            if events1(j) - events1(i) < thresh && i~=j
                e = cat(1,e,events1(j));
            end
        end
        if length(e) > 1
            avg = e(uint8(length(e)/2));
            i = i + length(e)-1;
        end
        if length(events) == 0
           events = avg;
        else
           events = cat(1,events,avg);
        end
    else
        e = events1(i);
        for j=i-v:1:i
            if events1(i) - events1(j) < thresh && i~=j
                e = cat(1,e,events1(j));
            end
        end
        if length(e) > 1
            avg = e(uint8(length(e)/2));
            i = i + length(e)-1;
            if length(events) == 0
               events(i-1) = avg;
            end
        else
            if length(events) == 0
               events = avg;
            else
               events = cat(1,events,avg);
            end
        end
    end
   i = i + 1;
end
events = cat(1,events,last);

%% Plots from position and acceleration
%x-axis
figure, plot(t,x,'b*','color','red','LineWidth',2,'MarkerSize',2), ...
    title("Ball Position in the x-axis vs. Frames"), xlabel("frame"), ylabel("x-position");
%figure, plot(t(3:length(t)),acc(:,1),'b*','color','red','LineWidth',2,'MarkerSize',2);

%y-axis
figure, plot(t,y,'r*','color','blue','LineWidth',2,'MarkerSize',2), ...
    title("Ball Position in the y-axis vs. frames"), xlabel("frame"), ylabel("y-position");
%figure, plot(t(3:length(t)),acc(:,2),'r*','color','red','LineWidth',2,'MarkerSize',2);

%figure, plot(t(3:length(t)),(acc(:,1).^2+acc(:,2).^2).^0.5,'r*','color','red','LineWidth',2,'MarkerSize',2);

figure, scatter3(x,y,t,'filled'), view(-30,10), title("Ball position vs. frame"), ...
    xlabel("x-position"), ylabel("y-position"), zlabel("frame");

showTrajectory(BG,position,events);

%% Step 6 - Use last event to determine score accross frames
disp("Applying tennis rules to events...");
prev = getCandidate(position,events(length(events)-1));
last = getCandidate(position,events(length(events)));
p1 = [prev(2) + prev(4)/2, prev(1) + prev(3)/2];
p2 = [last(2) + last(4)/2, last(1) + last(3)/2];
dt = last(5) - prev(5);
v = (p2-p1)/dt;
%determine the player based on direction of the ball's movement between the
%last and 2nd last frames
player = 0;
if v(1) > 0
   player = 1;
elseif v(1) < 0
    player = 2;
end
disp(v);
%determine if the ball was in-bounds on the last hit


%% Play the video to the user
videoReader = vision.VideoFileReader(video_file);
videoPlayer = vision.VideoPlayer('Name', 'Candidate and Event Detection');
videoPlayer.Position(1:4) = [0 0 500 500];
%videoWriter = VideoWriter('output.avi');
%open(videoWriter);
i = 1;

while ~isDone(videoReader)
    frame=step(videoReader);
    result = frame;
    
    %Show the bounding box around the ball
    candidates = getCandidate(position,i);
    if length(candidates(:,1)) > 0
        result=insertShape(result, 'Rectangle',candidates(:,1:4), 'Color', 'red');
    end
    
    event = getEvent(events,i);
    if length(event) > 0
        result=insertShape(result, 'Rectangle',candidates(:,1:4), 'Color', 'green');
    end
    
    insertShape(result,'Line',[950 0 0 WIDTH], 'Color', 'blue');
    
    step(videoPlayer,result);
    %writeVideo(videoWriter,result);
    i = i + 1;
end
release(videoPlayer);
%close(videoWriter);


%% Functions
function candidates = getCandidate(positionMatrix,frame)
    indexes = positionMatrix(:,5)==frame;
    a = positionMatrix .* indexes;
    candidates = a(any(a,2),:);
end
function event = getEvent(events,frame)
    indexes = events==frame;
    a = events .* indexes;
    event = a(any(a,2),:);
end