
close all;
clear;
clc;


lbl = 'E:\JUNO\JAD\JNO-JSW-JAD-3-CALIBRATED-V1.0\DATA\2020\2020001\ELECTRONS\JAD_L30_LRS_ELC_ANY_CNT_2020001_V03.lbl';
dat = 'E:\JUNO\JAD\JNO-JSW-JAD-3-CALIBRATED-V1.0\DATA\2020\2020001\ELECTRONS\JAD_L30_LRS_ELC_ANY_CNT_2020001_V03.dat';

[lbl_info_s] = juno_jad_analyse_lable_V02(lbl);
[ data_s   ] = juno_jad_analyse_dat_V02(dat,lbl_info_s);

