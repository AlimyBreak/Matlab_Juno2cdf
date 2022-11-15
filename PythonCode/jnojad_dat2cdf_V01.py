# -*- coding: utf-8 -*-
"""
Ref:
The Planetary Data Reader: https://github.com/MillionConcepts/pdr
Spacepy                  : https://spacepy.github.io/
cdf_lib                  : spdf.gsfc.nasa.gov/pub/software/cdf/dist/cdf38_0
"""

import os 
os.environ["CDF_LIB"] = r'D:\common_Libs\cdf3.8.0_64bit_VS2015\lib'
from spacepy import pycdf
import pdr   


test_lbl_file = r'C:\Users\Administrator\Desktop\Python_Juno\JAD_L30_LRS_ELC_ANY_CNT_2021365_V04.lbl'
temp = pdr.Data(test_lbl_file)
LABEL = temp['LABEL'] # 此项就是lbl的文件内容.
TABLE = temp['TABLE']

test_cdf_file = test_lbl_file.replace('.lbl','.cdf').replace('.LBL','.cdf');
cdf = pycdf.CDF(test_cdf_file, '')
for cur_key in TABLE.keys():
    cdf[cur_key] = list(TABLE[cur_key]) # 比较慢
    
cdf.close();