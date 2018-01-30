load name.mat
%Fields = {'Filter','Window','MSE','PSNR','SNR'};
%(fid,'%s',[num2str(i),'.',name{detect(i)}]);
a=name
index_num = i+1;
   index = num2str(index_num);
   cell = strcat('A',index);
   xlswrite('www.xlsx',name,cell);