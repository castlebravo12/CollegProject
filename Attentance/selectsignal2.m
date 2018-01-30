function [a, b,x]=selectsignal2(temp)
temp=rgb2gray(temp);
x=1;
for i=1:8
    
d=dir(['data\',num2str(i),'\*.jpg']);
if length(d)>=1
for j=1:length(d)
    
    img=imread(['data\',num2str(i),'\',d(j).name]);
    img=imresize(img,[500,500]);
    img=rgb2gray(img);
%     temp=rgb2gray(temp);
    cor(j)=corr2(img,temp);
end
fcor(i)=max(cor);
x=x+1;
else
 fcor(i)=0;   
end
[a,b]=max(fcor);

end