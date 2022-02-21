%{
    juno_fgm_r1s_lbl_byday_V01: YQW/2022.01.05
    alimy1990@foxmail.com
    用于分析label文件的信息,返回值用于后续文件的读取.
    ※表示已经支持的lbl文件
    ※fgm_jno_l3_*pc_r1s_v01.lbl
    ※fgm_jno_l3_*pc_r1s_v02.lbl
    ※fgm_jno_l3_*pl_r1s_v01.lbl
    ※fgm_jno_l3_*pl_r1s_v02.lbl
    ※fgm_jno_l3_*ss_r1s_v01.lbl
    ※fgm_jno_l3_*ss_r1s_v02.lbl
    ※fgm_jno_l3_*pc_pj*_r1s_v02.lbl    
    ※fgm_jno_l3_*pl_pj*_r1s_v02.lbl    
    ※fgm_jno_l3_*ss_pj*_r1s_v02.lbl
      pj  denotes the perijove(近木点)
      pj* denotes the the perijove number
    输入:
        fullpath_list    :   当天所有*r1s*.lbl和*r1s*.sts的全路径列表(cell) 
    输出:
        com_info_s       :   一般情况下返回信息结构体(详细操作见 juno_fgm_r1s_clbl 函数) common
        pj_info_s        :   pj情况下返回信息结构体(详细操作见 juno_fgm_r1s_pjlbl 函数) perijove
    
referneces:
    JNO-J-3-FGM-CAL-V1.0\DOCUMENT\VOLSIS.PDF
    JNO-J-3-FGM-CAL-V1.0\DOCUMENT\SIS-addendum.PDF
%}


function [ com_info_s , pj_info_s ] = juno_fgm_r1s_lbl_byday_V01( fullpath_list )


    com_info_s = {};
    pj_info_s  = {};
    
    if length(fullpath_list) == 2
        [ com_info_s ] = juno_fgm_r1s_clbl(fullpath_list{1}); % common
    elseif length(fullpath_list) == 4
        [ com_info_s ] = juno_fgm_r1s_clbl(fullpath_list{3}); % common
        [ pj_info_s  ] = juno_fgm_r1s_pjlbl(fullpath_list{1});% near perijove
    else
        % 兜底入口检测
        fprintf('juno_fgm_r1s_lbl_byday_V01 error01 : err input \n');
        return;
    end
    
end



% common lbl file process
function [ com_info_s ] = juno_fgm_r1s_clbl(fullpath_lbl)
    com_info_s = {};
    % 入口检测
    if ~endsWith(fullpath_lbl,'.lbl')
        fprintf('juno_fgm_r1s_lbl_byday_V01(juno_fgm_r1s_clbl) error01 : error input\n');
        return;
    end
    fid = fopen(fullpath_lbl);
    OBJECT_ind = 0;
    OBJECT_class_name = [];
    while ~feof(fid)
       cur_line             =   strrep(strtrim(fgetl(fid)),'-','_');
       cur_line_cells       =   split(cur_line,'=');
       if strcmp('OBJECT', strtrim(cur_line_cells{1})) 
           OBJECT_ind       = OBJECT_ind + 1;
           OBJECT_class_name{OBJECT_ind}  = strtrim(cur_line_cells{2});
           continue;
       end    
       %cur_line_cells
       if strcmp('END_OBJECT', strtrim(cur_line_cells{1})) % && strcmp(OBJECT_class_name(OBJECT_ind),strtrim(cur_line_cells{2}))
           OBJECT_class_name{OBJECT_ind} = [];
           OBJECT_ind = OBJECT_ind - 1;
           continue;
       end
       
       if strcmp('BYTES', strtrim(cur_line_cells{1}))
           temp_str = ['com_info_s'];
           for iii = 1:OBJECT_ind
               temp_str = [temp_str,'.',OBJECT_class_name{iii}];
           end
           temp_str = [temp_str,'.BYTES','=',cur_line_cells{2},';'];
           eval(temp_str);
           continue;
       end
       
       
        if strcmp('NAME', strtrim(cur_line_cells{1}))
           temp_str = strtrim(cur_line_cells{2});
           temp_str = strrep(temp_str,'"','');
           temp_str = strrep(temp_str,' ','_');
           OBJECT_class_name{OBJECT_ind} = temp_str;
           temp_str = ['com_info_s'];
           for iii = 1:OBJECT_ind
               temp_str = [temp_str,'.' OBJECT_class_name{iii}];
           end
           temp_str = [temp_str,'=[]',';'];
           eval(temp_str);
           continue;
        end
       
        if strcmp('UNIT',strtrim(cur_line_cells{1}))
            temp_str = ['com_info_s'];
            for iii = 1:OBJECT_ind
                temp_str = [temp_str,'.' OBJECT_class_name{iii}];
            end
           temp_str = [temp_str,'.UNIT','=',cur_line_cells{2},';'];
           eval(temp_str);
            continue
        end
        
        if strcmp('START_BYTE',strtrim(cur_line_cells{1}))
            temp_str = ['com_info_s'];
            for iii = 1:OBJECT_ind
                temp_str = [temp_str,'.' OBJECT_class_name{iii}];
            end
            temp_str = [temp_str,'.START_BYTE','=',cur_line_cells{2},';'];
            eval(temp_str);
            continue
        end
        
        if strcmp('ROWS',strtrim(cur_line_cells{1}))
            temp_str = ['com_info_s'];
            for iii = 1:OBJECT_ind
                temp_str = [temp_str,'.' OBJECT_class_name{iii}];
            end
            temp_str = [temp_str,'.ROWS','=',cur_line_cells{2},';'];
            eval(temp_str);
            continue
        end
        
        if strcmp('ROW_BYTES',strtrim(cur_line_cells{1}))
            temp_str = ['com_info_s'];
            for iii = 1:OBJECT_ind
                temp_str = [temp_str,'.' OBJECT_class_name{iii}];
            end
            temp_str = [temp_str,'.ROW_BYTES','=',cur_line_cells{2},';'];
            eval(temp_str);
            continue
        end
        
        if strcmp('DESCRIPTION',strtrim(cur_line_cells{1})) && OBJECT_ind > 0
            DESCRIPTION_str = [];
            if strcmp('"',strtrim(cur_line_cells{2}))
                while 1
                    line = strtrim(fgetl(fid));
                    if endsWith(line,'"')
                        DESCRIPTION_str = [DESCRIPTION_str,line(1:end-1)];
                        break;
                    else
                        DESCRIPTION_str = [DESCRIPTION_str,line];
                    end
                end
            end
            
            temp_str = ['com_info_s'];
            for iii = 1:OBJECT_ind
                temp_str = [temp_str,'.' OBJECT_class_name{iii}];
            end
            temp_str = [temp_str,'.DESCRIPTION','=DESCRIPTION_str',';'];
            eval(temp_str);
        
            continue;
        end
        
        
    end
    fclose(fid);
end


% pj lbl file process
function [ pj_info_s  ] = juno_fgm_r1s_pjlbl (fullpath_lbl)
    pj_info_s = {};
    % 入口检测
    if ~endsWith(fullpath_lbl,'.lbl')
        fprintf('juno_fgm_r1s_lbl_byday_V01(juno_fgm_r1s_pjlbl) error01 : error input\n');
        return;
    end

    fid = fopen(fullpath_lbl);    
    OBJECT_ind = 0;
    OBJECT_class_name = [];
    while ~feof(fid)
       cur_line         =   (strtrim(fgetl(fid)));
       cur_line_cells   =   split(cur_line,'=');
       if strcmp('OBJECT', strtrim(cur_line_cells{1})) 
           OBJECT_ind       = OBJECT_ind + 1;
           OBJECT_class_name{OBJECT_ind}  = strtrim(cur_line_cells{2});
           continue;
       end
       
       %cur_line_cells
       if strcmp('END_OBJECT', strtrim(cur_line_cells{1})) % && strcmp(OBJECT_class_name(OBJECT_ind),strtrim(cur_line_cells{2}))
           OBJECT_class_name{OBJECT_ind} = [];
           OBJECT_ind = OBJECT_ind - 1;
           continue;
       end
       
       if strcmp('BYTES', strtrim(cur_line_cells{1}))
           temp_str = ['pj_info_s'];
           for iii = 1:OBJECT_ind
               temp_str = [temp_str,'.',strrep(OBJECT_class_name{iii},'-','_')];
           end
           temp_str = [temp_str,'.BYTES','=',cur_line_cells{2},';'];
           eval(temp_str);
           continue;
       end
       
       
        if strcmp('NAME', strtrim(cur_line_cells{1}))
           temp_str = strtrim(cur_line_cells{2});
           temp_str = strrep(temp_str,'"','');
           temp_str = strrep(temp_str,' ','_');
           temp_str = strrep(temp_str,'-','_');
           OBJECT_class_name{OBJECT_ind} = temp_str;
           temp_str = ['pj_info_s'];
           for iii = 1:OBJECT_ind
               temp_str = [temp_str,'.' OBJECT_class_name{iii}];
           end
           temp_str = [temp_str,'=[]',';'];
           eval(temp_str);
           continue;
        end
       
        if strcmp('UNIT',strtrim(cur_line_cells{1}))
            temp_str = ['pj_info_s'];
            for iii = 1:OBJECT_ind
                temp_str = [temp_str,'.' OBJECT_class_name{iii}];
            end
           temp_str = [temp_str,'.UNIT','=',cur_line_cells{2},';'];
           eval(temp_str);
            continue
        end

        if strcmp('START_BYTE',strtrim(cur_line_cells{1}))
            temp_str = ['pj_info_s'];
            for iii = 1:OBJECT_ind
                temp_str = [temp_str,'.' OBJECT_class_name{iii}];
            end
            temp_str = [temp_str,'.START_BYTE','=',cur_line_cells{2},';'];
            eval(temp_str);
            continue
        end

        if strcmp('ROWS',strtrim(cur_line_cells{1}))
            temp_str = ['pj_info_s'];
            for iii = 1:OBJECT_ind
                temp_str = [temp_str,'.' OBJECT_class_name{iii}];
            end
            temp_str = [temp_str,'.ROWS','=',cur_line_cells{2},';'];
            eval(temp_str);
            continue
        end

        if strcmp('ROW_BYTES',strtrim(cur_line_cells{1}))
            temp_str = ['pj_info_s'];
            for iii = 1:OBJECT_ind
                temp_str = [temp_str,'.' OBJECT_class_name{iii}];
            end
            temp_str = [temp_str,'.ROW_BYTES','=',cur_line_cells{2},';'];
            eval(temp_str);
            continue
        end
        
        if strcmp('ROW_BYTES',strtrim(cur_line_cells{1}))
            temp_str = ['pj_info_s'];
            for iii = 1:OBJECT_ind
                temp_str = [temp_str,'.' OBJECT_class_name{iii}];
            end
            temp_str = [temp_str,'.ROW_BYTES','=',cur_line_cells{2},';'];
            eval(temp_str);
            continue
        end
        
        if strcmp('DESCRIPTION',strtrim(cur_line_cells{1})) && OBJECT_ind > 0
            DESCRIPTION_str = [];
            if strcmp('"',strtrim(cur_line_cells{2}))
                while 1
                    line = strtrim(fgetl(fid));
                    if endsWith(line,'"')
                        DESCRIPTION_str = [DESCRIPTION_str,line(1:end-1)];
                        break;
                    else
                        DESCRIPTION_str = [DESCRIPTION_str,line];
                    end
                end
            end
            
            temp_str = ['pj_info_s'];
            for iii = 1:OBJECT_ind
                temp_str = [temp_str,'.' OBJECT_class_name{iii}];
            end
            temp_str = [temp_str,'.DESCRIPTION','=DESCRIPTION_str',';'];
            eval(temp_str);
            continue;
        end
    end
    fclose(fid);
end