%% Clear
clc;
clear;
%% Load the background images and take the average
B1 = im2double(imread('assets/video_1/Image_Frame118.jpg'));
B2 = im2double(imread('assets/video_1/Image_Frame119.jpg'));
B3 = im2double(imread('assets/video_1/Image_Frame120.jpg'));
B_avg = (B1 + B2 + B3) ./ 3;

%% Load the image
I = im2double(imread('assets/video_1/Image_Frame121.jpg'));
%% Try applying colour segmentation
[BW,I_rgbSegmented] = createMask2(I);
figure, imshow(I_rgbSegmented);

%% Apply Background subtraction
I_subtr = I_rgbSegmented - B_avg;
%show the image
figure, imshow(I_subtr);

%% Try openning the image to remove noise
I2 = imopen(I_subtr, strel('disk',3));
figure, imshow(I2);

%% Try dilating the image to show the ball more defined
I3 = imdilate(I_subtr, strel('disk',2));
%show the image
figure, imshow(I3);