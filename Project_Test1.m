%% Clear
clc;
clear;
%% Load the image
B1 = im2double(imread('assets/video_1/Image_Frame118.jpg'));
B2 = im2double(imread('assets/video_1/Image_Frame119.jpg'));
B3 = im2double(imread('assets/video_1/Image_Frame120.jpg'));
B_avg = (B1 + B2 + B3) ./ 3;

I = im2double(imread('assets/video_1/Image_Frame121.jpg'));
I_subtr = I - B_avg;

imshow(B_avg);
imshow(I_subtr);