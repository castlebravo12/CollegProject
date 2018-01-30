function main
%Detect objects using Viola-Jones Algorithm

%To detect Face
vid = videoinput('winvideo',1,'MJPG_320x240');
set(vid,'ReturnedColorSpace','rgb');
 triggerconfig(vid,'immediate');
 set(vid,'FramesPerTrigger',10);


%vid = videoinput('winvideo',1);

%set(vid, 'TriggerRepeat', Inf);
%vid.FrameGrabInterval = 1;

%Npix_resolution = get(vid, 'VideoResolution');
%Nfrm_movie = 50;

%% Object Tracking by Particle Filter
Npix_resolution = get(vid, 'VideoResolution');
dim_x             = Npix_resolution(1);
dim_y             = Npix_resolution(2);
%start(vid);
 preview(vid);
 start(vid);
 data = getdata(vid);
 imshow(data(:,:,:,end));
 stop(vid)
delete(vid)
 imwrite(data(:,:,:,end),'a1.jpg')
%I = getdata(vid, 1); 
%%
n=1;
% stop(vid)
load('name.mat');
for k = 1:1
%     load('name.mat');
    
     % Getting Image
     I = imread('a1.jpg');
     figure(1),subplot(1,3,1),imshow(I);
     title('Original image');
 FDetect = vision.CascadeObjectDetector;
I(:,:,1)=adapthisteq(I(:,:,1));
 I(:,:,2)=adapthisteq(I(:,:,2));
 I(:,:,3)=adapthisteq(I(:,:,3));
subplot(1,3,2),imshow(I);
     title('Enhanced image');

%Returns Bounding Box values based on number of objects
BB = step(FDetect,I);
videoOut=I;
if size(BB,1)>=1 
figure(2),
%      hold on
for i=1:size(BB,1)

% for i = 1:1%size(BB,1)
%     rectangle('Position',BB(i,:),'LineWidth',5,'LineStyle','-','EdgeColor','r');
% end
     
% title('Face Detection');
hold off;
F=imcrop(I,BB(i,:));
folder = '/Desktop/attentance/frame'
imwrite(F,['frame\',num2str(n),'.jpg']);n=n+1;
F=imresize(F,[500,500]);
subplot(2,4,i),imshow(F);
title(['Face detected no= ',num2str(i)]);
ab=rgb2gray(F);
b=edge(ab,'canny');
figure, imshow(b);
[a, E1,num]=selectsignal2(F);
% [a, E2]=selectsignal3(Eyes);

if a>0.5
    detect(i)=E1;
videoOut = insertObjectAnnotation(videoOut,'rectangle',BB(i,:),name{E1},'FontSize' ,25);
end
% if a>0.4 & a<=0.69
% %     Q=inputdlg('This face is new Enter your name');
% %     name(length(name)+1)=Q;
% %     imwrite(F,['data\',num2str(num),'\','1.jpg']);
% %     videoOut = insertObjectAnnotation(I,'rectangle',BB(i,:),name{E1},'FontSize' ,25);
% %     save('name.mat','name');
% end
end

figure,imshow(videoOut );
     title('Face Named image');


end
% flushdata(vid);
%  pause(0.000001)
end

% save('name.mat','name')
%% Stopping Video Camera
%  fclose(s);
%stop(vid)
%delete(vid)

fid = fopen('text1.txt', 'wt');
if length(detect)>=1
for i=1:length(detect)
    fprintf(fid,'%s\n',[name{detect(i)}]);
end
else
    fprintf(fid,'%s','No Faces available');
end

matmal('pankaj14.6.1994@gmail.com', 'Attentance', 'command complete');
end


% MATLABMAIL Send an email from a predefined gmail account.

%% Importent
%% Go to this link and change the setting
% https://www.google.com/settings/security/lesssecureapps
