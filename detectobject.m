function [I,posi]=detectobject(BW,COL,minsize)
La=bwlabel(BW);
regi=regionprops(La);
areas=cat(2,regi(:).Area);
obj=find(areas>minsize);
RE=regi(obj);
m=numel(RE);
pos=[0,0,0,0];
for i=1:m
  pos=cat(1,RE(i).BoundingBox,pos);
end
 I=insertShape(COL, 'Rectangle',pos, 'Color', 'red');
 posi=pos;
end
