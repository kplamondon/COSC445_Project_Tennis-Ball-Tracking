%% Clear memory
clc;
clear;
%% Read in video
V = VideoReader('movietrailer.mp4'); % open file
% Read a single frame by its index
I = read(V, 1); % read the first frame
I = read(V, 500); % read the 500th frame
I2 = read(V, inf); % read the last frame
% Read multiple frames by index
images = read(V, [500 505]); %read 6 froms from 500 to 505
imshow(images(:,:,:,5)); % display a frame
% get number of frames
N = V.NumberOfFrames;
% Display one frame every 500 frames
for i = 1:500:N
    imshow(read(V,i));
