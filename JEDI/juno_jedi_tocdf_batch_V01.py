# -*- coding: utf-8 -*-
"""
Created on Tue Oct 18 16:36:02 2022

@author: 
alimy1990@foxmail.com
YQW/2022.10.21
ref:
    Python datetime到Matlab datenum         https://duoduokou.com/python/40741467781001133838.html 
    Python筛选目录下指定后缀的文件          https://blog.csdn.net/qq_41895190/article/details/103333116
    anaconda安装spacepy                     https://blog.csdn.net/QQ_774682/article/details/118831510
    github pdr 工具包                       https://github.com/MillionConcepts/pdr
    spacepy 工具包                          https://spacepy.github.io/
"""

import pdr
import datetime 
import os
import fnmatch
os.environ['CDF_LIB'] = r'D:\common_Libs\cdf3.8.0_64bit_VS2015\lib'
import spacepy.pycdf as spcdf



def date2doy(year,month,day):
    month_leapyear=[31,29,31,30,31,30,31,31,30,31,30,31]
    month_notleap= [31,28,31,30,31,30,31,31,30,31,30,31]
    doy=0
    if month==1:
        pass
    elif year%4==0 and (year%100!=0 or year%400==0):
        for i in range(month-1):
            doy+=month_leapyear[i]
    else:
        for i in range(month-1):
            doy+=month_notleap[i]
    doy+=day
    return doy
    
    
def doy2date(year,doy):    
    month_leapyear=[31,29,31,30,31,30,31,31,30,31,30,31]
    month_notleap= [31,28,31,30,31,30,31,31,30,31,30,31]
    
    if year%4==0 and (year%100!=0 or year%400==0):
        for i in range(0,12):
            if doy>month_leapyear[i]:
                doy-=month_leapyear[i]
                continue
            if doy<=month_leapyear[i]:
                month=i+1
                day=doy
                break
    else:
        for i in range(0,12):
            if doy>month_notleap[i]:
                doy-=month_notleap[i]
                continue
            if doy<=month_notleap[i]:
                month=i+1
                day=doy
                break
    return month,day



def datetime2matlabdn(dt):
   mdn = dt + datetime.timedelta(days = 366)
   frac_seconds = (dt-datetime.datetime(dt.year,dt.month,dt.day,0,0,0)).seconds / (24.0 * 60.0 * 60.0)
   frac_microseconds = dt.microsecond / (24.0 * 60.0 * 60.0 * 1000000.0)
   return mdn.toordinal() + frac_seconds + frac_microseconds

def jedi_tab2cdf_V01(src_dir,lbl_name,dst_dir):
    # 输入输出路径处理
    lblfile_fullpath = os.path.join(src_dir,lbl_name)
    cdfname = lbl_name.replace('.lbl','.cdf')
    cdfname = cdfname.replace('.LBL','.cdf')
    cdffile_fullpath = os.path.join(dst_dir, cdfname)
    
    # 数据读取并根据标签命名变量并复制
    data = pdr.read(lblfile_fullpath);
    table_data = data['ASCII_TABLE']
    variables = table_data.keys();
    var_str_valid = [];
    for index in range(len(variables)):
        temp = variables[index].replace(' ','_')
        temp = temp.replace('-','_')
        var_str_valid.append(temp)
    for index in range(len(var_str_valid)):
        cmd_str = var_str_valid[index] + '=' + "table_data['" + variables[index] + "']"
        exec(cmd_str)
    
    # 写入cdf文件
    if os.path.exists(cdffile_fullpath):
        os.remove(cdffile_fullpath)
    cdftowrite = spcdf.CDF(cdffile_fullpath,'')  #cdffile_fullpath 不能已经存在
    for index in range(len(variables)):
        cmd_str_1 = "temp_var ="+  var_str_valid[index];
        exec(cmd_str_1)
        cmd_str_2 = "cdftowrite['" + var_str_valid[index] + "']=" + 'list(temp_var)'
        exec(cmd_str_2)
    cdftowrite.close();  
    
def run():
    # 下级目录是年份
    src_root_dir = "D:\\temp\\jedi_data_test\\"
    dst_root_dir = "D:\\temp\\jedi_cdf\\"
    for year in range(2016,2022):
        for doy in range(1,367):
            doystr = "%03d" % doy
            src_dir = src_root_dir + str(year) + '\\' + doystr + '\\'
            dst_dir = dst_root_dir + str(year) + '\\'
            if os.path.exists(src_dir):
                lbl_list = fnmatch.filter(os.listdir(src_dir),'*.lbl')
                if len(lbl_list)>0:
                    for lbl_name in lbl_list:
                        jedi_tab2cdf_V01(src_dir,lbl_name,dst_dir)



# 主函数入口                        
if __name__ == '__main__':
    run()