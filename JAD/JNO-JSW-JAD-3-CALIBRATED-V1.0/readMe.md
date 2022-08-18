0. 这是一个读取JADE仪器L3等级lbl和dat文件的工具，使用Matlab语言编写。
1. 工作函数说明
+ juno_jad_analyse_lable_V02:分析lbl文件中的信息，需要输入lbl文件所在的全路径，以结构体返回相关信息。
```matlab
%{
    juno_jad_analyse_lable_V02: YQW/2021.12.07
    用于分析lable文件信息,返回值用于后续dat文件读取.
    预备支持的*.lbl文件序列(※开头表示已经支持了)
    电子
        ※JAD_L30_HRS_ELC_ALL_CNT_*_V03.lbl
        ※JAD_L30_HRS_ELC_TWO_CNT_*_V03.lbl
        ※JAD_L30_LRS_ELC_ANY_CNT_*_V03.lbl
    离子(未测试是否可以)
        JAD_L30_HLS_ION_LOG_CNT_*_V02.lbl
        JAD_L30_HRS_ION_ANY_CNT_*_V02.lbl
        JAD_L30_LRS_ION_ANY_CNT_*_V02.lbl
        JAD_L30_HLS_ION_TOF_CNT_*_V02.lbl
    输入:
        fullpath_lbl        :   *.lbl 的全路径
    输出:
        lbl_info_s          :   读取dat文件所需要的信息，使用者不需要关心细节
```

+ juno_jad_analyse_dat_V02: 通过lbl_info_s对对应的dat文件进行读取。
```matlab
%{
    juno_jad_analyse_dat_V02: YQW/2021.12.08
    用于获取dat文件信息
    预备支持的*.dat文件序列(※开头表示已经支持了)
    电子
        ※JAD_L30_HRS_ELC_ALL_CNT_*_V03.lbl
        ※JAD_L30_HRS_ELC_TWO_CNT_*_V03.lbl
        ※JAD_L30_LRS_ELC_ANY_CNT_*_V03.lbl
    离子(未测试是否可以)
        JAD_L30_HLS_ION_LOG_CNT_*_V02.lbl
        JAD_L30_HRS_ION_ANY_CNT_*_V02.lbl
        JAD_L30_LRS_ION_ANY_CNT_*_V02.lbl
        JAD_L30_HLS_ION_TOF_CNT_*_V02.lbl
    输入:
        lbl_info_s          :   lbl文件返回的信息结构体，使用者不需要关心细节.
    输出:
        data_s              :   以struct返回dat中的数据文件
%}

```
2. test_main给出了一个读取范例。
3. 不鼓励研究人员过于被二进制文件的处理过程吸引或困惑，所以加密了源代码。pcode编译版本：Matlab R2020a。
Author: YQW/alimy1990@foxmail.com
2022年8月18日 16:31:38