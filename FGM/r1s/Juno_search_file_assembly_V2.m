%{
    Juno_search_file_assembly_V2: YQW/2022.01.05
    alimy1990@foxmail.com
    +1. 完善了FGM-r1s 文件的搜索逻辑
       *表示已经实现(subpackage_idx,对应数据包编号)
       *11  :   JNO-J-3-FGM-CAL-V1.0
                FGM   -   1Hz(r1s)        直流磁场 (返回文件个数为2或4时才合法,一个lbl文件一个sts文件相对应)    
       *12  :   JNO-J-3-FGM-CAL-V1.0
                FGM   -   1/60Hz(r60s)    直流磁场
       *13  :   JNO-J-3-FGM-CAL-V1.0
                FGM   -   64Hz            低频磁场
        21  : JNO-J/SW-JAD-2-UNCALIBRATED-V1.0
        22  : JNO-J/SW-JAD-3-CALIBRATED-V1.0 
        31  : JNO-J-JED-2-EDR-V1.0 
        32  : JNO-J-JED-3-CDR-V1.0
        41  : JNO-E/J/SS-WAV-2-EDR-V1.0 
        42  : JNO-E/J/SS-WAV-3-CDR-BSTFULL-V2.0
       *43  : JNO-E/J/SS-WAV-3-CDR-SRVFULL-V2.0
    输入参数:
        root_dir            : 按照网站目录存放在本地时的根目录
        instrument_name     : 仪器名,共计四个('FGM','JAD','JEDI','WAV'),目前已经实现FGM和WAV(SRVFULL).
        subpackage_idx      : 数据包编号
        reserv_word         : 保留字, 需要和subpackage_idx配合说明意义,
            当subpackage_idx ==  11,12和13时,用于给出坐标系(合法值为'PL','SS','PC',和'', ''默认为'PL')
        year                : 年份,2016~2021
        dayofyear           : 年份日积数,1~366
    输出参数
        valid               : 查找结果, 0 查找失败 , 1 查找成功
        filefullpath        : 当valid==1时,以cell形式存放全路径
        
-----------------------------------------------------------------------------------
    Juno_search_file_assembly_V1: YQW/2021.11.30  
       *表示已经实现(subpackage_idx,数据包编号)
       *11  : FGM   -   1Hz     直流
        21  : JNO-J/SW-JAD-2-UNCALIBRATED-V1.0
        22  : JNO-J/SW-JAD-3-CALIBRATED-V1.0 
        31  : JNO-J-JED-2-EDR-V1.0 
        32  : JNO-J-JED-3-CDR-V1.0
        41  : JNO-E/J/SS-WAV-2-EDR-V1.0 
        42  : JNO-E/J/SS-WAV-3-CDR-BSTFULL-V2.0
       *43  : JNO-E/J/SS-WAV-3-CDR-SRVFULL-V2.0
    输入参数:
        root_dir            : 按照网站目录存放在本地时的根目录
        instrument_name     : 仪器名,共计四个('FGM','JAD','JEDI','WAV'),目前已经实现FGM和WAV(SRVFULL).
        subpackage_idx      : 数据包编号
        reserv_word         : 保留字, 需要和subpackage_idx配合说明意义
        year                : 年份,2016~2021
        dayofyear           : 年份日积数,1~366
    输出参数
        valid               : 查找结果, 0 查找失败 , 1 查找成功
        filefullpath        : 当valid==1时,以cell形式存放全路径
        
%}


function [valid,filefullpath] = Juno_search_file_assembly_V2(                       ...
                                                                root_dir        ,   ...
                                                                instrument_name ,   ...
                                                                subpackage_idx  ,   ...
                                                                reserv_word     ,   ...
                                                                year            ,   ...
                                                                dayofyear           ...
                                                            )
    valid           = 0     ;
    filefullpath    = ''    ;
    
    
    instrument_name =   upper(instrument_name)      ;
    instrument_set  =   {'FGM','JAD','JEDI','WAV'}  ;
    if ismember(instrument_name,instrument_set)
        cur_path = [root_dir,'\',instrument_name,'\'];
    else 
        fprintf('Juno_search_file_assembly_V1 err1, 错误的 instrument_name\n');
        return;
    end
    
    switch subpackage_idx
        case 11 % JNO-J-3-FGM-CAL-V1.0  1Hz     文件名含有字符串 "r1s"
            cur_path = [cur_path , 'JNO-J-3-FGM-CAL-V1.0\DATA\JUPITER\'];
            [valid , filefullpath] = Juno_FGM_FileSearch_11(cur_path,year,dayofyear,reserv_word);
        case 12 % JNO-J-3-FGM-CAL-V1.0  1/60Hz  文件名含有字符串 "r60s"
            cur_path = [cur_path , 'JNO-J-3-FGM-CAL-V1.0\DATA\JUPITER\'];
            [valid , filefullpath] = Juno_FGM_FileSearch_12(cur_path,year,dayofyear,reserv_word);        
        case 13 % JNO-J-3-FGM-CAL-V1.0  64Hz    文件名含较前两个简短,不含 "r*s" 的字符串
            cur_path = [cur_path , 'JNO-J-3-FGM-CAL-V1.0\DATA\JUPITER\'];
            [valid , filefullpath] = Juno_FGM_FileSearch_13(cur_path,year,dayofyear,reserv_word);
        case 21 % JNO-J_SW-JAD-2-UNCALIBRATED-V1.0
            cur_path = [cur_path , 'JNO-J_SW-JAD-2-UNCALIBRATED-V1.0\'];
        case 22 % JNO-J_SW-JAD-3-CALIBRATED-V1.0 
            cur_path = [cur_path , 'JNO-J_SW-JAD-3-CALIBRATED-V1.0\'];
        case 31 % JNO-J-JED-2-EDR-V1.0
            cur_path = [cur_path , 'JNO-J-JED-2-EDR-V1.0\'];
        case 32 % JNO-J-JED-3-CDR-V1.0
            cur_path = [cur_path , 'JNO-J-JED-3-CDR-V1.0\'];
        case 41 % JNO-E_J_SS-WAV-2-EDR-V1.0        
            cur_path = [cur_path , 'JNO-E_J_SS-WAV-2-EDR-V1.0\'];
        case 42 % JNO-E_J_SS-WAV-3-CDR-BSTFULL-V2.0
            cur_path = [cur_path , 'JNO-E_J_SS-WAV-3-CDR-BSTFULL-V2.0\'];
        case 43 % JNO-E_J_SS-WAV-3-CDR-SRVFULL-V2.0
            cur_path = [cur_path , 'JNO-E_J_SS-WAV-3-CDR-SRVFULL-V2.0\DATA\'];
            [valid , filefullpath] = Juno_WAV_FileSearch_43(cur_path,year,dayofyear,reserv_word);
        otherwise
            fprintf('Juno_search_file_assembly_V1 err2, 错误的 subpackage_idx\n');
            return;
    end
   
end


%JNO-J-3-FGM-CAL-V1.0, FGM-1Hz 直流  
function [valid , filefullpath] = Juno_FGM_FileSearch_11(cur_path,year,dayofyear,reserv_word)
%{
    输入参数:
        cur_path        : .\JNO-J-3-FGM-CAL-V1.0\DATA\JUPITER\   的本地全路径  char or string
        year            : 年份     , 2016-2021
        dayofyear       : 年份日积数   , 1-366
        reserv_word     : 保留字,表示参考系, 'PC','PL'或者'SS',当reserv_word为空时取默认值'PL'.
    输出参数:
        valid           : 0 查找成功  1 查找失败
        filefullpath    : 文件全路径(以cell形式存放)
%}

    valid = 0;
    filefullpath = [];
    
    if isempty(reserv_word)
        reserv_word = 'PL';
    end
    dstdir = [ cur_path, reserv_word , '\'];
    
    keywords = ['fgm_jno_l3_', num2str(year) , num2str(dayofyear,'%03d') , '*', 'r1s' ,'*' ];
    for ii = 0:34
        curdir = [dstdir, 'PERI-',num2str(ii,'%02d'),'\'];
        curfilelist = dir([curdir,keywords]);
        if ~isempty(curfilelist)
            valid = 1;
            break;
        end
    end
    
    if valid == 0
        fprintf('Juno_FGM_FileSearch_11 err, Please Check input year = %d, dayofyear = %d \n',year,dayofyear);
        return;
    else
        for ii = 1:length(curfilelist)
            filefullpath{ii} = [curdir,curfilelist(ii).name];
        end
    end

end

%JNO-J-3-FGM-CAL-V1.0, FGM-1/64Hz 直流
function [valid , filefullpath] = Juno_FGM_FileSearch_12(cur_path,year,dayofyear,reserv_word)
%{
    输入参数:
        cur_path        : .\JNO-J-3-FGM-CAL-V1.0\DATA\JUPITER\   的本地全路径  char or string
        year            : 年份     , 2016-2021
        dayofyear       : 年份日积数   , 1-366
        reserv_word     : 保留字,表示参考系, 'PC','PL'或者'SS',当reserv_word为空时取默认值'PL'.
    输出参数:
        valid           : 0 查找成功  1 查找失败
        filefullpath    : 文件全路径(以cell形式存放)
%}

    valid = 0;
    filefullpath = [];
    
    if isempty(reserv_word)
        reserv_word = 'PL';
    end
    dstdir = [ cur_path, reserv_word , '\'];
    
    keywords = ['fgm_jno_l3_', num2str(year) , num2str(dayofyear,'%03d') , '*', 'r60s' ,'*' ];
    for ii = 0:32
        curdir = [dstdir, 'PERI-',num2str(ii,'%02d'),'\'];
        curfilelist = dir([curdir,keywords]);
        if ~isempty(curfilelist)
            valid = 1;
            break;
        end
    end
    
    if valid == 0
        fprintf('Juno_FGM_FileSearch_12 err, Please Check input year = %d, dayofyear = %d \n',year,dayofyear);
        return;
    else
        for ii = 1:length(curfilelist)
            filefullpath{ii} = [curdir,curfilelist(ii).name];
        end
    end

end



%JNO-J-3-FGM-CAL-V1.0, FGM-1/64Hz 直流
function [valid , filefullpath] = Juno_FGM_FileSearch_13(cur_path,year,dayofyear,reserv_word)
%{
    输入参数:
        cur_path        : .\JNO-J-3-FGM-CAL-V1.0\DATA\JUPITER\   的本地全路径  char or string
        year            : 年份     , 2016-2021
        dayofyear       : 年份日积数   , 1-366
        reserv_word     : 保留字,表示参考系, 'PC','PL'或者'SS',当reserv_word为空时取默认值'PL'.
    输出参数:
        valid           : 0 查找成功  1 查找失败
        filefullpath    : 文件全路径(以cell形式存放)
%}

    valid = 0;
    filefullpath = [];
    
    if isempty(reserv_word)
        reserv_word = 'PL';
    end
    dstdir = [ cur_path, reserv_word , '\'];
    
    keywords = ['fgm_jno_l3_', num2str(year) , num2str(dayofyear,'%03d') , '*'];
    for ii = 0:32
        curdir = [dstdir, 'PERI-',num2str(ii,'%02d'),'\'];
        curfilelist = dir([curdir,keywords]);
        if ~isempty(curfilelist)
            valid = 1;
            break;
        end
    end
    
    if valid == 0
        fprintf('Juno_FGM_FileSearch_13 err, Please Check input year = %d, dayofyear = %d \n',year,dayofyear);
        return;
    else
        kk = 1;
        for ii = 1:length(curfilelist)
            if ~isempty(strfind(curfilelist(ii).name,'r1s')) || ~isempty(strfind(curfilelist(ii).name,'r60s'))
                continue;
            else
                filefullpath{kk} = [curdir,curfilelist(ii).name]    ;
                kk               = kk + 1                           ;
            end
        end
    end

end





%JNO-E_J_SS-WAV-3-CDR-SRVFULL-V2.0
function [valid , filefullpath] = Juno_WAV_FileSearch_43(cur_path,year,dayofyear,reserv_word)
%{
    输入参数:
        cur_path        : .\JNO-E_J_SS-WAV-3-CDR-SRVFULL-V2.0\DATA 的本地全路径  char or string
        year            : 年份     , 2016-2021
        dayofyear       : 年份日积数   , 1-366
        reserv_word     : 保留字,表示数据采样模式, 'WAVES_BURST'或者'WAVES_SURVEY',若reserv_word为空则取默认值'WAVES_SURVEY'.(事实上目前只有WAVES_BURST的数据 2021.11.30 YQW)
    输出参数:
        valid           : 0 查找成功  1 查找失败
        filefullpath    : 文件全路径(以cell形式存放)
%}

    valid = 0;
    filefullpath = [];
    
    if isempty(reserv_word)
        reserv_word = 'WAVES_SURVEY';
    end
    
    dstdir = [ cur_path, reserv_word , '\'];
    dirlist = dir([dstdir,'*_ORBIT_*']);
    
    %WAV_2016189T000000_B_V02
    %WAV_2016189T000000_E_V02
    keywords = ['WAV_',num2str(year),num2str(dayofyear,'%03d'),'*V02*'];
    for ii = 1:length(dirlist)
        curdir = [dstdir,dirlist(ii).name,'\'];
        curfilelist = dir([curdir,keywords]);
        
        if length(curfilelist)
            valid = 1;
            break;
        end
    end

	if valid == 0
        fprintf('Juno_WAV_FileSearch_43 err, Please Check input year = %d, dayofyear = %d \n',year,dayofyear);
        return;
    else
        kk = 1;
        for ii = 1:length(curfilelist)
            tmpFileName = curfilelist(ii).name;
            if regexp(tmpFileName,'_[EB]_') >0
                filefullpath{kk} = [curdir,curfilelist(ii).name];
                kk = kk + 1;
            end
        end
    end
end
