0. 这是一个读取JADE仪器L3等级\*V04.lbl和\*V04.dat文件的工具(\*V03.lbl和\*V03.dat也支持)，使用Matlab语言编写。
1. 工作函数说明
+ juno_jad_analyse_lable_V03:分析lbl文件中的信息，需要输入lbl文件所在的全路径，以结构体返回相关信息。
```matlab
%{
	修复了读取某些ION_TOF数据文件报错的bug.
	juno_jad_analyse_lable_V03: YQW/2022.10.22 
	(※表示已经支持了)
		※JAD_L30_HRS_ELC_ALL_CNT_*_V04.lbl
		※JAD_L30_HRS_ELC_TWO_CNT_*_V04.lbl
		※JAD_L30_LRS_ELC_ANY_CNT_*_V04.lbl
		※JAD_L30_HLS_ION_LOG_CNT_*_V04.lbl
		※JAD_L30_HRS_ION_ANY_CNT_*_V04.lbl
		※JAD_L30_LRS_ION_ANY_CNT_*_V04.lbl
    输入:
		fullpath_lbl        :   *.lbl 的全路径
    输出:
		block_size          :   一个块对应的大小(Bytes)
		block_objects_num   :   一个块中成员对象的个数
		block_objects_name  :   一个块中成员对象的名字
		block_objects_dims  :   维度尺寸(方便后续reshape)
		block_fmt           :   字符串或者cell(用于对dat文件进行分析)
		block_num           :   块数量(对应*.dat文件中有多少个block_size大小的块)
References:
1. https://stackoverflow.com/questions/66686265/importing-dat-files-in-python-without-knowing-how-it-is-structured
2. https://gist.github.com/boyank/d9640e9c4dc3877012b8fb4dc9f6c053
%}
```

+ juno_jad_analyse_dat_V02: 通过lbl_info_s对对应的dat文件进行读取。
```matlab
%{
	juno_jad_analyse_dat_V03: YQW/2022.10.22 
    输入:
        fullpath_dat        :   *.dat 的全路径
        block_size          :   一个块对应的大小(Bytes)
        block_objects_num   :   一个块中成员对象的个数
        block_objects_name  :   一个块中成员对象的名字
        block_fmt           :   字符串或者cell(用于对dat文件进行分析)
        block_num           :   块数量(对应*.dat文件中有多少个block_size大小的块)
    输出:
        data_s              :   以struct返回数据
%}

```
2. test_main给出了一个读取范例。
3. 不鼓励研究人员过于被二进制文件的处理过程吸引或困惑，所以加密了源代码。pcode编译版本：Matlab R2020a。
4. Author: YQW/alimy1990@foxmail.com 2022-10-22 23:44:19

***