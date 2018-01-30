
function main
[file,path]=uigetfile('*.*','Select input image');
	I=imread(strcat(path,file));
    Io=I;
    
    
%% Pre processing
%        if size(I,3)==3
%            I=rgb2gray(I); 
%        end
       I1=imresize(I,[256,256]);
       I=double(I); 
   subplot(1,3,1),imshow(uint8(I),[]);
   title('Original Image');
  %%
   

 FDetect = vision.CascadeObjectDetector;
 I(:,:,1)=adapthisteq(I(:,:,1));
 I(:,:,2)=adapthisteq(I(:,:,2));
 I(:,:,3)=adapthisteq(I(:,:,3));
 subplot(1,3,2),imshow(I1,[]);
   title('Pre-Processed Image'); 
 subplot(1,3,3),imshow(uint8(I1));
 title('Face detected image');
%Returns Bounding Box values based on number of objects
BB = step(FDetect,I1);
n=1;
if size(BB,1)>=1 
for i=1:size(BB,1) 
F=imcrop(I1,BB(i,:));


F=imresize(F,[300,300]);
imwrite(F,['face\',num2str(n),'.jpg']);n=n+1;
hold on
%  figure,imshow(F);
rectangle('Position',BB(i,:),'LineWidth',4,'LineStyle','-','EdgeColor','b');
hold off
end
end







