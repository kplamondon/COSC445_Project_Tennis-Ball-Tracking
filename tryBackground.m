BG=GetBackground('Test2.mp4',390);%video name and number of frame   really slow!!!!
%%
videoReader = vision.VideoFileReader('Test2.mp4');
videoPlayer = vision.VideoPlayer('Name', 'Gausian Background Subtraction');
videoPlayer.Position(3:4) = [1400,800];
position=[0 0 0 0];%Trajectory position
while ~isDone(videoReader)
    frame=step(videoReader);
    grayframe = im2double(rgb2gray(frame));
    diff=grayframe-BG;
    FG_mask=diff>0.15;
    FG_mask=bwareaopen(FG_mask,3);
    FG=FG_mask.*grayframe;
    FG=imopen(FG,strel('disk',2));
    %FG=imerode(FG,strel('disk',1));
    FG=imdilate(FG,strel('disk',8));
    FG=im2bw(FG);
     [Label,Number]=bwlabel(FG);
    region=regionprops(Label,'all');
    [r,c]=size(FG);
    onlyball=zeros(r,c);
    for i=1:Number
        item=double(Label==i);
        if(region(i).Area<650)
            onlyball=onlyball+item;
        end
    end
    [BW,frame_rgbSegmented] = createMasknew2(frame);
    FG_segment = im2bw(rgb2gray(frame_rgbSegmented));
    FG_segment(1:160,:)=0;
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
    [vid,posi]=detectobject(filteredFG,frame,50);
    if posi(1,1)~=0
    position=cat(1,position,posi);
    end
    step(videoPlayer,vid);
end
release(videoPlayer)
%%
[row,col]=size(position);
NoNoise=position(2,:);
for i=2:row
    if position(i,1)~=0
        NoNoise=cat(1,NoNoise,position(i,:));
    end
end
%%
showTrajectory(BG,NoNoise);