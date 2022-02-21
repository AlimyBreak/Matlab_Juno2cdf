%{
    main_juno_fgm_r1s_toCDF_V01 YQW/2022.01.07
    alimy1990@foxmail.com
    本程序将 JNO-J-3-FGM-CAL-V1.0.zip 的 *_r1s_* 文件转为cdf文件.
    注意:
    1. 需要设置的参数只有  root_dir(27行) 和 reserv_word(30行) ;
    2. 存储年份文件夹需要事先新建好, 就新建在本程序文件所在的目录下，年份文件夹名为 2016 2017 2018 2019 2020
    2021 ;
    3. 环境要求： 需要 Matlab R2020a 或以上版本;
    4. 性能说明： 经过测试，读取和处理一天的数据大约需要80s, 若电脑不足够强力 , 可以将 parfor(36行)改为 for .
    缺点:
    1. 写入cdf文件的只有名字和数据, 没有写入注释或描述信息(不知道怎么写), 其实已经获取到了 com_info_s.*.DESCRIPTION 和 pj_info_s.*.DESCRIPTION
    中，可以通过对com_info_s和pj_info_s进行深度优先搜索(DFS)获取这些DESCRIPTION信息.
    
    
    依赖文件:
        Juno_search_file_assembly_V2.m
        juno_fgm_r1s_lbl_byday_V01.m
        juno_fgm_r1s_sts_byday_V01.m

%}

close all;
clear;
clc;

% 基础变量设置
root_dir        =   'D:\DATA\Juno_ForDraw'  ;   % 下级目录必须含有 \FGM\JNO-J-3-FGM-CAL-V1.0\DATA\
instrument_name =   'FGM'                   ;     
subpackage_idx  =   11                      ;
reserv_word     =   'PC'                    ;   % 坐标系,可以是 'PC', 'PL' 或者 'SS'

% 年份遍历
for year = 2021:2021
    
    % 天数遍历，并行处理
    parfor dayofyear = 54:180
    
        % 展示当前在处理的日期, 可以屏蔽
        fprintf('current year = %d , current day = % \n', year, dayofyear);
    
        % 查找对应日期中所有含有 _r1s_ 的文件.
        [valid_11,filefullpath_11] = Juno_search_file_assembly_V2(                      ...
                                                                    root_dir        ,   ...
                                                                    instrument_name ,   ...
                                                                    subpackage_idx  ,   ...
                                                                    reserv_word     ,   ...
                                                                    year            ,   ...
                                                                    dayofyear           ...
                                                                 );
                                                                 
        % 0表示啥也没找到 1表示找到了
        if ~valid_11    
            continue;
        end
        
        % 合法返回文件个数只能是2或者4
        if (length(filefullpath_11) ~= 2) && (length(filefullpath_11)~= 4)
            fid = fopen([reserv_word,'坐标系_问题日期.txt'],'a');
            fprintf(fid, 'err file: year = %d, doy = %d\n', year , dayofyear);
            fclose(fid);
            continue;
        end

        % 获取lbl信息和sts文件信息
        [ com_info_s , pj_info_s ] = juno_fgm_r1s_lbl_byday_V01(filefullpath_11);
        [ com_data_s , pj_data_s ] = juno_fgm_r1s_sts_byday_V01(filefullpath_11, com_info_s, pj_info_s);
         
        
        % 将获取到的信息写入到cdf文件并存放到年份对应文件, 年份文件夹需要已经新建好
        com_cdf_file_str = [ num2str(year), '\fgm_jno_l3_', reserv_word,'_',    num2str(year), num2str(dayofyear,'%03d'), 'r1s.cdf' ];
        pj_cdf_file_str  = [ num2str(year), '\fgm_jno_l3_', reserv_word,'_pj_', num2str(year), num2str(dayofyear,'%03d'), 'r1s.cdf' ];
        
        fileds = fieldnames(com_data_s);
        for ii = 1:length(fileds)
            if ii == 1
                cdfwrite(com_cdf_file_str, {fileds{ii}, getfield(com_data_s,fileds{ii})}); 
            else
                cdfwrite(com_cdf_file_str, {fileds{ii}, getfield(com_data_s,fileds{ii})}, 'WriteMode', 'append'); 
            end
        end
        
        if ~isempty(pj_data_s)
            fileds = fieldnames(pj_data_s);
            for ii = 1:length(fileds)
                if ii == 1
                    cdfwrite(pj_cdf_file_str, {fileds{ii}, getfield(pj_data_s,fileds{ii})}); 
                else
                    cdfwrite(pj_cdf_file_str, {fileds{ii}, getfield(pj_data_s,fileds{ii})}, 'WriteMode', 'append'); 
                end
            end
        end
        
    end
    
end






return;

% 下面的都不会被运行.









































































fid = fopen('文件信息.csv','w');
fprintf(fid,'year, doy, numfile\n');
for iii = 2016:2021
	for jjj = 1:366
        year        = iii;
        dayofyear   = jjj;
        instrument_name =   'FGM'                   ;
        subpackage_idx  =   13                      ;
        reserv_word     =   'PL'                    ;
        [valid_11,filefullpath_11] = Juno_search_file_assembly_V2(                      ...
                                                                    root_dir        ,   ...
                                                                    instrument_name ,   ...
                                                                    subpackage_idx  ,   ...
                                                                    reserv_word     ,   ...
                                                                    year            ,   ...
                                                                    dayofyear           ...
                                                                );
        fprintf(fid,'%d, %d, %d\n', iii , jjj , length(filefullpath_11));
	end
end
fclose(fid);
return;

%fid = fopen('画图信息.txt','a');
tic;
for iii = 2019:2019
    for jjj = 308:308
        year        = iii;
        dayofyear   = jjj;


        instrument_name =   'FGM'                   ;
        subpackage_idx  =   13                      ;
        reserv_word     =   'PC'                    ;
        [valid_11,filefullpath_11] = Juno_search_file_assembly_V2(                                ...
                                                                        root_dir        ,   ...
                                                                        instrument_name ,   ...
                                                                        subpackage_idx  ,   ...
                                                                        reserv_word     ,   ...
                                                                        year            ,   ...
                                                                        dayofyear           ...
                                                                );


        instrument_name     =   'WAV'   ;
        subpackage_idx      =   43      ;
        reserv_word         =   ''      ;
        [valid_43,filefullpath_43] = Juno_search_file_assembly_V1(                                ...
                                                                        root_dir        ,   ...
                                                                        instrument_name ,   ...
                                                                        subpackage_idx  ,   ...
                                                                        reserv_word     ,   ...
                                                                        year            ,   ...
                                                                        dayofyear           ...
                                                                );
                                                       
        

        if valid_11 == 1           
            if endsWith(filefullpath_11{2},'sts')
                fgm_file_1s = filefullpath_11{12};  
            else
                fgm_file_1s = filefullpath_11{1};
            end
        else
            continue;
        end

        if valid_43 == 1
            wav_b_file = filefullpath_43{1};
            wav_e_file = filefullpath_43{3};
        else
            continue;
        end
        
        fprintf('year = %d ，dayofyear = %d , 已经用掉 %f mins \n', year, dayofyear, toc/60 );
        %fprintf(fid,'year = %d ，dayofyear = %d , 已经用掉 %f mins \n', year, dayofyear, toc/60 );
        Juno_EB_Overview_V2(fgm_file_1s,wav_b_file,wav_e_file,year,dayofyear); 
    end
end


%fclose(fid);