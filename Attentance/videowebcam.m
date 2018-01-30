vid = videoinput('winvideo',1,'MJPG_320x240');
set(vid,'ReturnedColorSpace','rgb');
 triggerconfig(vid,'immediate');
 set(vid,'FramesPerTrigger',10);
 preview(vid);
 start(vid);
 data = getdata(vid);
 imshow(data(:,:,:,end));
 
 stop(vid);
 delete(vid)
 clear vid
% N=size(data,4); % N is the number of frames 
 %for x=1:N
 %filename=strcat('Image',int2str(x),'.jpg'); %  OR JPEG AS  YOU LIKE
 imwrite(data(:,:,:,end),'a1.jpg');
% end
 I=imread('a1.jpg');
 FDetect = vision.CascadeObjectDetector;
BB = step(FDetect,I);
F=imcrop(I,BB);
imwrite(F,'.jpg');