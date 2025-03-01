close all;
clear;
clc;

lbl_file = 'F:\JUNO_pdsppi\JNO-J_SW-JAD-5-CALIBRATED-V1.0\data\2017\2017078\ELECTRONS\JAD_L50_LRS_ELC_ANY_DEF_2017078_V01.lbl';
dat_file = strrep(strrep(lbl_file,'.lbl','.dat'),'.LBL','.dat');

[lbl_s] = juno_jad_analyse_lable_V04(lbl_file);
[data_s] = juno_jad_analyse_dat_V04(dat_file,lbl_s);


cdf_dst_path = 'JAD_L50_LRS_ELC_ANY_DEF_2017078_V01.cdf';%strrep(strrep(lbl_file,'.lbl','.cdf'),'.LBL','.cdf');
fileds = fieldnames(data_s);
for jj = 1:length(fileds)
    if jj == 1
        cdfwrite(cdf_dst_path, {fileds{jj}, getfield(data_s,fileds{jj})}); 
    else
        cdfwrite(cdf_dst_path, {fileds{jj}, getfield(data_s,fileds{jj})}, 'WriteMode', 'append'); 
    end
end