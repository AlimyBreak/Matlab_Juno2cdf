%{
    Juno_search_file_assembly_V2: YQW/2022.01.05
    alimy1990@foxmail.com
    +1. ������FGM-r1s �ļ��������߼�
       *��ʾ�Ѿ�ʵ��(subpackage_idx,��Ӧ���ݰ����)
       *11  :   JNO-J-3-FGM-CAL-V1.0
                FGM   -   1Hz(r1s)        ֱ���ų� (�����ļ�����Ϊ2��4ʱ�źϷ�,һ��lbl�ļ�һ��sts�ļ����Ӧ)    
       *12  :   JNO-J-3-FGM-CAL-V1.0
                FGM   -   1/60Hz(r60s)    ֱ���ų�
       *13  :   JNO-J-3-FGM-CAL-V1.0
                FGM   -   64Hz            ��Ƶ�ų�
        21  : JNO-J/SW-JAD-2-UNCALIBRATED-V1.0
        22  : JNO-J/SW-JAD-3-CALIBRATED-V1.0 
        31  : JNO-J-JED-2-EDR-V1.0 
        32  : JNO-J-JED-3-CDR-V1.0
        41  : JNO-E/J/SS-WAV-2-EDR-V1.0 
        42  : JNO-E/J/SS-WAV-3-CDR-BSTFULL-V2.0
       *43  : JNO-E/J/SS-WAV-3-CDR-SRVFULL-V2.0
    �������:
        root_dir            : ������վĿ¼����ڱ���ʱ�ĸ�Ŀ¼
        instrument_name     : ������,�����ĸ�('FGM','JAD','JEDI','WAV'),Ŀǰ�Ѿ�ʵ��FGM��WAV(SRVFULL).
        subpackage_idx      : ���ݰ����
        reserv_word         : ������, ��Ҫ��subpackage_idx���˵������,
            ��subpackage_idx ==  11,12��13ʱ,���ڸ�������ϵ(�Ϸ�ֵΪ'PL','SS','PC',��'', ''Ĭ��Ϊ'PL')
        year                : ���,2016~2021
        dayofyear           : ����ջ���,1~366
    �������
        valid               : ���ҽ��, 0 ����ʧ�� , 1 ���ҳɹ�
        filefullpath        : ��valid==1ʱ,��cell��ʽ���ȫ·��
        
-----------------------------------------------------------------------------------
    Juno_search_file_assembly_V1: YQW/2021.11.30  
       *��ʾ�Ѿ�ʵ��(subpackage_idx,���ݰ����)
       *11  : FGM   -   1Hz     ֱ��
        21  : JNO-J/SW-JAD-2-UNCALIBRATED-V1.0
        22  : JNO-J/SW-JAD-3-CALIBRATED-V1.0 
        31  : JNO-J-JED-2-EDR-V1.0 
        32  : JNO-J-JED-3-CDR-V1.0
        41  : JNO-E/J/SS-WAV-2-EDR-V1.0 
        42  : JNO-E/J/SS-WAV-3-CDR-BSTFULL-V2.0
       *43  : JNO-E/J/SS-WAV-3-CDR-SRVFULL-V2.0
    �������:
        root_dir            : ������վĿ¼����ڱ���ʱ�ĸ�Ŀ¼
        instrument_name     : ������,�����ĸ�('FGM','JAD','JEDI','WAV'),Ŀǰ�Ѿ�ʵ��FGM��WAV(SRVFULL).
        subpackage_idx      : ���ݰ����
        reserv_word         : ������, ��Ҫ��subpackage_idx���˵������
        year                : ���,2016~2021
        dayofyear           : ����ջ���,1~366
    �������
        valid               : ���ҽ��, 0 ����ʧ�� , 1 ���ҳɹ�
        filefullpath        : ��valid==1ʱ,��cell��ʽ���ȫ·��
        
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
        fprintf('Juno_search_file_assembly_V1 err1, ����� instrument_name\n');
        return;
    end
    
    switch subpackage_idx
        case 11 % JNO-J-3-FGM-CAL-V1.0  1Hz     �ļ��������ַ��� "r1s"
            cur_path = [cur_path , 'JNO-J-3-FGM-CAL-V1.0\DATA\JUPITER\'];
            [valid , filefullpath] = Juno_FGM_FileSearch_11(cur_path,year,dayofyear,reserv_word);
        case 12 % JNO-J-3-FGM-CAL-V1.0  1/60Hz  �ļ��������ַ��� "r60s"
            cur_path = [cur_path , 'JNO-J-3-FGM-CAL-V1.0\DATA\JUPITER\'];
            [valid , filefullpath] = Juno_FGM_FileSearch_12(cur_path,year,dayofyear,reserv_word);        
        case 13 % JNO-J-3-FGM-CAL-V1.0  64Hz    �ļ�������ǰ�������,���� "r*s" ���ַ���
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
            fprintf('Juno_search_file_assembly_V1 err2, ����� subpackage_idx\n');
            return;
    end
   
end


%JNO-J-3-FGM-CAL-V1.0, FGM-1Hz ֱ��  
function [valid , filefullpath] = Juno_FGM_FileSearch_11(cur_path,year,dayofyear,reserv_word)
%{
    �������:
        cur_path        : .\JNO-J-3-FGM-CAL-V1.0\DATA\JUPITER\   �ı���ȫ·��  char or string
        year            : ���     , 2016-2021
        dayofyear       : ����ջ���   , 1-366
        reserv_word     : ������,��ʾ�ο�ϵ, 'PC','PL'����'SS',��reserv_wordΪ��ʱȡĬ��ֵ'PL'.
    �������:
        valid           : 0 ���ҳɹ�  1 ����ʧ��
        filefullpath    : �ļ�ȫ·��(��cell��ʽ���)
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

%JNO-J-3-FGM-CAL-V1.0, FGM-1/64Hz ֱ��
function [valid , filefullpath] = Juno_FGM_FileSearch_12(cur_path,year,dayofyear,reserv_word)
%{
    �������:
        cur_path        : .\JNO-J-3-FGM-CAL-V1.0\DATA\JUPITER\   �ı���ȫ·��  char or string
        year            : ���     , 2016-2021
        dayofyear       : ����ջ���   , 1-366
        reserv_word     : ������,��ʾ�ο�ϵ, 'PC','PL'����'SS',��reserv_wordΪ��ʱȡĬ��ֵ'PL'.
    �������:
        valid           : 0 ���ҳɹ�  1 ����ʧ��
        filefullpath    : �ļ�ȫ·��(��cell��ʽ���)
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



%JNO-J-3-FGM-CAL-V1.0, FGM-1/64Hz ֱ��
function [valid , filefullpath] = Juno_FGM_FileSearch_13(cur_path,year,dayofyear,reserv_word)
%{
    �������:
        cur_path        : .\JNO-J-3-FGM-CAL-V1.0\DATA\JUPITER\   �ı���ȫ·��  char or string
        year            : ���     , 2016-2021
        dayofyear       : ����ջ���   , 1-366
        reserv_word     : ������,��ʾ�ο�ϵ, 'PC','PL'����'SS',��reserv_wordΪ��ʱȡĬ��ֵ'PL'.
    �������:
        valid           : 0 ���ҳɹ�  1 ����ʧ��
        filefullpath    : �ļ�ȫ·��(��cell��ʽ���)
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
    �������:
        cur_path        : .\JNO-E_J_SS-WAV-3-CDR-SRVFULL-V2.0\DATA �ı���ȫ·��  char or string
        year            : ���     , 2016-2021
        dayofyear       : ����ջ���   , 1-366
        reserv_word     : ������,��ʾ���ݲ���ģʽ, 'WAVES_BURST'����'WAVES_SURVEY',��reserv_wordΪ����ȡĬ��ֵ'WAVES_SURVEY'.(��ʵ��Ŀǰֻ��WAVES_BURST������ 2021.11.30 YQW)
    �������:
        valid           : 0 ���ҳɹ�  1 ����ʧ��
        filefullpath    : �ļ�ȫ·��(��cell��ʽ���)
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
