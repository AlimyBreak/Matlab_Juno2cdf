import pdr
import os
os.environ['CDF_LIB'] = r'D:\cdf3.8.0_64bit_VS2015\lib'
from spacepy import pycdf


def work_function(src_full_path,dst_full_path):
    
    dummy = pdr.read(src_full_path)
    dummy.load('all')
    lablel = dummy['LABEL']
    spreadsheet = dummy['SPREADSHEET']
    s_keys = spreadsheet.keys()
            
    # 获取数据
    for each in s_keys:
        cmd_str = "locals()['%s'] = spreadsheet['%s']" % (each, each)
        exec(cmd_str)
               
    # 写入数据到CDF文件
    # 创建CDF文件
    if os.path.exists(dst_full_path):
        os.remove(dst_full_path)
                                    
    with pycdf.CDF(dst_full_path, '') as cdf:
        # 写入数据
        for each in s_keys:
            cmd_str = "cdf['%s'] = list(locals()['%s'])" % (each, each)
            #print(cmd_str)
            exec(cmd_str)

if __name__ == '__main__':
    src_root_dir = r'E:\Yang_wenjian\data\JNO-J-JAD-5-MOMENTS-V1.0\DATA'
    dst_root_dir = r'E:\juno_jad_5_mom_cdf_V20231110'
    for year in range(2015,2022):
        cur_year_dir = os.path.join(src_root_dir, str(year))
        if not os.path.exists(cur_year_dir):
            continue
        for day in os.listdir(cur_year_dir):
            cur_day_dir = os.path.join(cur_year_dir, day)
            if not os.path.isdir(cur_day_dir):
                continue
            for file in os.listdir(cur_day_dir):
                if file.upper().endswith('.LBL'):
                    src_full_path = os.path.join(cur_day_dir, file)
                    print(src_full_path)
                    dst_full_path = os.path.join(dst_root_dir,file[:-4] + '.cdf')
                    work_function(src_full_path,dst_full_path)

