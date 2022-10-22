close all;
clear;
clc;

lbl_file = 'C:\Users\admin\Desktop\JAD2CDF_V01_20220305\2016240\ION_TOF\JAD_L30_HLS_ION_TOF_CNT_2016240_V04.lbl';
dat_file = strrep(strrep(lbl_file,'.lbl','.dat'),'.LBL','.dat');

[lbl_s] = juno_jad_analyse_lable_V03(lbl_file);
[data_s] = juno_jad_analyse_dat_V03(dat_file,lbl_s);



cdf_dst_path = strrep(strrep(lbl_file,'.lbl','.cdf'),'.LBL','.cdf');
fileds = fieldnames(data_s);
for jj = 1:length(fileds)
    if jj == 1
        cdfwrite(cdf_dst_path, {fileds{jj}, getfield(data_s,fileds{jj})}); 
    else
        cdfwrite(cdf_dst_path, {fileds{jj}, getfield(data_s,fileds{jj})}, 'WriteMode', 'append'); 
    end
end