%{
    juno_fgm_r1s_sts_byday_V01: YQW/2021.01.05
    alimy1990@foxmail.com
    用于读取r1s的sts文件.
    ※表示已经支持的
    ※fgm_jno_l3_*pc_r1s_v01.sts
    ※fgm_jno_l3_*pl_r1s_v01.sts
    ※fgm_jno_l3_*ss_r1s_v01.sts
    ※fgm_jno_l3_*pc_r1s_v02.sts
    ※fgm_jno_l3_*pl_r1s_v02.sts
    ※fgm_jno_l3_*ss_r1s_v02.sts
    ※fgm_jno_l3_*pc_pj*_r1s_v02.sts
    ※fgm_jno_l3_*pl_pj*_r1s_v02.sts
    ※fgm_jno_l3_*ss_pj*_r1s_v02.sts
      pj  denotes the perijove(近木点)
      pj* denotes the the perijove number
    输入:
        fullpath_list    :   当天所有*r1s*.lbl和*r1s*.sts的全路径列表(cell)
        com_info_s       :   调用juno_fgm_r1s_lbl_byday_V*函数获得
        pj_info_s        :   调用juno_fgm_r1s_lbl_byday_V*函数获得
    输出:
        com_data_s       :  一般情况下返回数据结构体
        pj_data_s        :  pj情况下返回信息结构体
        均包含以下成员:
            datanum_epoch      :  数值类型的epoch,可以直接datetick
            DECIMAL_DAY        :  年积时间,实数类型.
            INSTRUMENT_RANGE   :  代指仪器测量范围, 一般为0, 可不用关注
            
            飞船位置(PL模式下没有):
            X                  :  单位 km
            Y                  :  单位 km
            Z                  :  单位 km
            
            磁感应强度
            BX_***             : ***坐标下的X方向磁感应强度,单位nT
            BY_***             : ***坐标下的Y方向磁感应强度,单位nT
            BZ_***             : ***坐标下的Z方向磁感应强度,单位nT
            ***可以是 PLANETOCENTRIC(PC), PAYLOAD(PL) 或者 SUN_STATE(SS)
            
            磁感应强度(pj时才有该成员,似乎只有PL坐标系才有,不确定) dynamic correction
            BDX_***            : BX的动态校正量, 单位nT
            BDY_***            : BX的动态校正量, 单位nT
            BDZ_***            : BX的动态校正量, 单位nT
            ***可以是 PLANETOCENTRIC(PC), PAYLOAD(PL) 或者 SUN_STATE(SS)
            
            
referneces:
    JNO-J-3-FGM-CAL-V1.0\DOCUMENT\VOLSIS.PDF
    JNO-J-3-FGM-CAL-V1.0\DOCUMENT\SIS-addendum.PDF
%}

function [ com_data_s , pj_data_s ] = juno_fgm_r1s_sts_byday_V01(fullpath_list, com_info_s, pj_info_s)

    com_data_s = [];
    pj_data_s  = [];

    if length(fullpath_list) == 2
        [ com_data_s ] = juno_fgm_r1s_csts(fullpath_list{2},com_info_s); % common
    elseif length(fullpath_list) == 4
        [ com_data_s ] = juno_fgm_r1s_csts(fullpath_list{4},com_info_s); % common
        [ pj_data_s  ] = juno_fgm_r1s_pjsts(fullpath_list{2},pj_info_s); % near perijove 
    else
        % 兜底入口检测
        fprintf('juno_fgm_r1s_sts_byday_V01 error01 : err input \n');
        return;
    end
    
    
    
end



% common sts file process
function [ com_data_s ] = juno_fgm_r1s_csts(fullpath_sts, com_info_s)
    com_data_s = {};
    % 入口检测
    if ~endsWith(fullpath_sts,'.sts')
        fprintf('juno_fgm_r1s_sts_byday_V01(juno_fgm_r1s_csts) error01 : error input\n');
        return;
    end
    
    fid = fopen(fullpath_sts,'r');
    
    [   ROWS_lbl            ,           ...
        ROW_BYTES_lbl       ,           ...
        col_name_lbl        ,           ...
        headerbytes_lbl     ,           ...
        col_start_bytes_lbl ,           ...
        col_bytes_lbl       ,           ...
        col_name_header     ,           ...
        format_str_header               ...
    ] = juno_fgm_r1s_csts_preprocess(fid,com_info_s);
    fseek(fid,headerbytes_lbl,'bof');
    ROWS_sts = 0; 
    while ~feof(fid)
        line_char   = fgetl(fid)    ;
        ROWS_sts    = ROWS_sts + 1  ;
        for iii = 1:length(col_name_lbl)
            ele_name = col_name_lbl{iii};
            if iii == length(col_name_lbl)
                ele_char = line_char(col_start_bytes_lbl(iii):end);
            else
                ele_char = line_char(col_start_bytes_lbl(iii):col_start_bytes_lbl(iii)+col_bytes_lbl(iii)-1);
            end
            if length(ele_char) == 21
                temp_str = ['com_data_s.',ele_name,'{ROWS_sts}' ,'=(ele_char)',';'];
            else
                temp_str = ['com_data_s.',ele_name,'{ROWS_sts}' ,'=str2double(ele_char)',';'];
            end
                eval(temp_str);
        end
    end
    fclose(fid);
    
    if ROWS_sts == ROWS_lbl
       fprintf(['Congratulations, \n the file ',strrep(fullpath_sts,'\','\\'),' is valid! \n']) 
    end
    
    % 时间字符串处理 ---> datenum
    datenum_epoch      = cell(1,ROWS_sts);
    time_format_bytes  = zeros(1,6);
    for ii = 1:6
        time_format_bytes(ii) = str2double(format_str_header{ii}(end));
    end

    for ii = 1:ROWS_sts
        cur_time_str = strtrim(com_data_s.SAMPLE_UTC{ii});
        
         S_ind = 0;
         E_ind = 1;
        for jj = 1:6
            S_ind = E_ind;
            E_ind = E_ind + time_format_bytes(jj)-1;
            temp_str = [col_name_header{jj},'=str2double(cur_time_str(S_ind:E_ind))',';'];
            eval(temp_str);
            E_ind = E_ind + 2;
        end
         datenum_epoch{ii} = datenum(datetime(TIME_YEAR,1,TIME_DOY,TIME_HOUR,TIME_MIN,TIME_SEC,TIME_MSEC));
    end
    
    com_data_s.datenum_epoch = datenum_epoch;
    
    
end



function [  ROWS_lbl            ,           ...
            ROW_BYTES_lbl       ,           ...
            col_name_lbl        ,           ...
            headerbytes_lbl     ,           ...
            col_start_bytes_lbl ,           ...
            col_bytes_lbl       ,           ...
            col_name_header     ,           ...
            format_str_header               ...
         ] = juno_fgm_r1s_csts_preprocess(fid,com_info_s) 
        
        
        
    ROWS_lbl            = [];
    ROW_BYTES_lbl       = [];
    col_name_lbl        = [];
    headerbytes_lbl     = [];
    col_start_bytes_lbl = [];
    col_bytes_lbl       = [];
    col_name_header     = [];
    format_str_header   = [];
    
    headerbytes_lbl     = com_info_s.HEADER.BYTES;
    ROWS_lbl        = com_info_s.MAG_DATA.ROWS;
    ROW_BYTES_lbl   = com_info_s.MAG_DATA.ROW_BYTES;
    
    fileds          = fieldnames(com_info_s.MAG_DATA);
    col_name_lbl    = fileds(4:end);
    
    for ii = 1:length(col_name_lbl)
        %col_name_lbl{ii}
        temp_str = ['col_start_bytes_lbl(ii)=com_info_s.MAG_DATA.',col_name_lbl{ii},'.START_BYTE',';'];
        eval(temp_str);
        temp_str = ['col_bytes_lbl(ii)=com_info_s.MAG_DATA.',col_name_lbl{ii},'.BYTES',';'];
        eval(temp_str);
    end
    
    
    % 从头开始
    frewind(fid);
    OBJECT_ind  = 0;
    OBJECT_name = [];
    header_info_s = {};
    format_str_ind = 0;
    while ftell(fid) < headerbytes_lbl
        line_char = split(strtrim(fgetl(fid)));
        
        if strcmp('OBJECT',line_char{1})
            OBJECT_ind              = OBJECT_ind + 1;
            %OBJECT_ind
            OBJECT_name{OBJECT_ind} = line_char{3};
            continue
        end
        
        if strcmp('END_OBJECT',line_char{1})
            OBJECT_name{OBJECT_ind} = [];
            OBJECT_ind              = OBJECT_ind - 1;
            %OBJECT_ind
        end
        
        if strcmp('NAME',line_char{1})
             OBJECT_name{OBJECT_ind} = line_char{3};
             temp_str = ['header_info_s'];
             for iii = 1:OBJECT_ind
                 temp_str = [ temp_str, '.',OBJECT_name{iii}  ];
             end
             temp_str = [temp_str,'.NAME=line_char{3}',';'];
             eval(temp_str);
             continue;
        end
        
        if strcmp('FORMAT',line_char{1})
             temp_str = ['header_info_s'];
             for iii = 1:OBJECT_ind
                 temp_str = [ temp_str, '.',OBJECT_name{iii}  ];
             end
             temp_str = [temp_str,'.FORMAT=line_char{end}',';'];
             eval(temp_str);
             
             format_str_ind = format_str_ind + 1;
             
             format_str_header{format_str_ind} = line_char{end};
             
            continue;
        end
        
        if strcmp('ALIAS',line_char{1})
             temp_str = ['header_info_s'];
             for iii = 1:OBJECT_ind
                 temp_str = [ temp_str, '.',OBJECT_name{iii}  ];
             end
             temp_str = [temp_str,'.ALIAS=line_char{end}',';'];
             eval(temp_str);
            continue;
        end        
        
        if strcmp('UNITS',line_char{1})
             temp_str = ['header_info_s'];
             for iii = 1:OBJECT_ind
                 temp_str = [ temp_str, '.',OBJECT_name{iii}  ];
             end
             temp_str = [temp_str,'.UNITS=line_char{end}',';'];
             eval(temp_str);
            continue;
        end            
        
    end
    
	% 回到头部
    frewind(fid);
    header_info_s_temp = header_info_s.FILE.RECORD;
    col_name_header = [];
    [col_name_header] = dfs_struct_get_name(header_info_s_temp,'NAME',col_name_header,[],[]); %深度优先遍历

end


%{
    prenodeName2:爷节点的名字
    prenodeName1:父节点的名字
%}
function [ res ] = dfs_struct_get_name( info_s, membertofind,res,prenodeName2,prenodeName1)

    if isstruct(info_s)
        fields = fieldnames(info_s);
    else 
        return ;
    end
    isdeepest = 1;
    for ii = 1:length(fields)
        temp_filed = getfield(info_s,fields{ii});
        res = dfs_struct_get_name(temp_filed,membertofind,res,prenodeName1,fields{ii});
        if isstruct(temp_filed)
            isdeepest = 0;
        end
    end
    
    if isdeepest && isfield(info_s,membertofind)
        res_num = length(res);
        res_num = res_num + 1;
        if ~isempty(prenodeName2)
            res{res_num} = [prenodeName2,'_' getfield(info_s,membertofind)];
        else
            res{res_num} = [ getfield(info_s,membertofind)];
        end
    end
    
    
end







% pj sts file process
function [ pj_data_s ] = juno_fgm_r1s_pjsts(fullpath_sts,pj_info_s)
    pj_data_s = {};
    % 入口检测
    if ~endsWith(fullpath_sts,'.sts')
        fprintf('juno_fgm_r1s_sts_byday_V01(juno_fgm_r1s_pjsts) error01 : error input\n');
        return;
    end
    
    fid = fopen(fullpath_sts,'r');
    
    [   ROWS_lbl            ,           ...
        ROW_BYTES_lbl       ,           ...
        col_name_lbl        ,           ...
        headerbytes_lbl     ,           ...
        col_start_bytes_lbl ,           ...
        col_bytes_lbl       ,           ...
        col_name_header     ,           ...
        format_str_header               ...
    ] = juno_fgm_r1s_csts_preprocess(fid,pj_info_s);
    fseek(fid,headerbytes_lbl,'bof');
    ROWS_sts = 0; 
    while ~feof(fid)
        line_char   = fgetl(fid)    ;
        ROWS_sts    = ROWS_sts + 1  ;
        for iii = 1:length(col_name_lbl)
            ele_name = col_name_lbl{iii};
            if iii == length(col_name_lbl)
                ele_char = line_char(col_start_bytes_lbl(iii):end);
            else
                ele_char = line_char(col_start_bytes_lbl(iii):col_start_bytes_lbl(iii)+col_bytes_lbl(iii)-1);
            end
            if length(ele_char) == 21
                temp_str = ['pj_data_s.',ele_name,'{ROWS_sts}' ,'=(ele_char)',';'];
            else
                temp_str = ['pj_data_s.',ele_name,'{ROWS_sts}' ,'=str2double(ele_char)',';'];
            end
                eval(temp_str);
        end
    end
    fclose(fid);
    
    if ROWS_sts == ROWS_lbl
       fprintf(['Congratulations, \n the file ',strrep(fullpath_sts,'\','\\'),' is valid! \n']) 
    end
    
    % 时间字符串处理 ---> datenum
    datenum_epoch      = cell(1,ROWS_sts);
    time_format_bytes  = zeros(1,6);
    for ii = 1:6
        time_format_bytes(ii) = str2double(format_str_header{ii}(end));
    end

    for ii = 1:ROWS_sts
        cur_time_str = strtrim(pj_data_s.SAMPLE_UTC{ii});
        
         S_ind = 0;
         E_ind = 1;
        for jj = 1:6
            S_ind = E_ind;
            E_ind = E_ind + time_format_bytes(jj)-1;
            temp_str = [col_name_header{jj},'=str2double(cur_time_str(S_ind:E_ind))',';'];
            eval(temp_str);
            E_ind = E_ind + 2;
        end
         datenum_epoch{ii} = datenum(datetime(TIME_YEAR,1,TIME_DOY,TIME_HOUR,TIME_MIN,TIME_SEC,TIME_MSEC));
    end
    
    pj_data_s.datenum_epoch = datenum_epoch;
    
    
end


    