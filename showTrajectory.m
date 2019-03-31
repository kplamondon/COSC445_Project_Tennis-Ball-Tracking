function showTrajectory(I,position)
position(:,3)=4;
position(:,4)=4;
Trajectory=insertShape(I, 'FilledRectangle', position, 'Color', 'red');
figure, imshow(Trajectory);



end

