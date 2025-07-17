%{
	juno_jad_analyse_lable_V03: YQW/2022.10.22
	׼��֧��
		JAD_L30_HRS_ELC_ALL_CNT_*_V04.lbl
		JAD_L30_HRS_ELC_TWO_CNT_*_V04.lbl
		JAD_L30_LRS_ELC_ANY_CNT_*_V04.lbl
        JAD_L30_HLS_ION_LOG_CNT_*_V04.lbl
        JAD_L30_HRS_ION_ANY_CNT_*_V04.lbl
        JAD_L30_LRS_ION_ANY_CNT_*_V04.lbl

    juno_jad_analyse_lable_V1: YQW/2021.12.07
    ���ڷ���lable�ļ���Ϣ,����ֵ���ں���dat�ļ���ȡ.
    Ԥ��֧�ֵ�*.lbl�ļ�����(����ͷ��ʾ�Ѿ�֧����)
    ����
        ��JAD_L30_HRS_ELC_ALL_CNT_*_V03.lbl
        ��JAD_L30_HRS_ELC_TWO_CNT_*_V03.lbl
        ��JAD_L30_LRS_ELC_ANY_CNT_*_V03.lbl
    ����(δ�����Ƿ����)
        JAD_L30_HLS_ION_LOG_CNT_*_V02.lbl
        JAD_L30_HRS_ION_ANY_CNT_*_V02.lbl
        JAD_L30_LRS_ION_ANY_CNT_*_V02.lbl
        JAD_L30_HLS_ION_TOF_CNT_*_V02.lbl
    ����:
        fullpath_lbl        :   *.lbl ��ȫ·��
    ���:
        block_size          :   һ�����Ӧ�Ĵ�С(Bytes)
        block_objects_num   :   һ�����г�Ա����ĸ���
        block_objects_name  :   һ�����г�Ա���������
        block_objects_dims  :   ά�ȳߴ�(�������reshape)
        block_fmt           :   �ַ�������cell(���ڶ�dat�ļ����з���)
        block_num           :   ������(��Ӧ*.dat�ļ����ж��ٸ�block_size��С�Ŀ�)
                
References:
1. https://stackoverflow.com/questions/66686265/importing-dat-files-in-python-without-knowing-how-it-is-structured
2. https://gist.github.com/boyank/d9640e9c4dc3877012b8fb4dc9f6c053

%}


function [ lbl_info_s ] = juno_jad_analyse_lable_V05( fullpath_lbl )
    
	lbl_info_s 				=	[]	;
    block_size              =   0   ;
    block_objects_num       =   0   ;
    block_objects_name      =   0   ;
    block_fmt               =   {}  ;
    block_num               =   0   ;
    block_objects_dims      =   {}   ;
    
    fid_lbl =   fopen(fullpath_lbl,'r')    ;
    rjws    =   {}                          ;
    kk      =   1                           ;
    while ~feof(fid_lbl)    
        line = fgetl(fid_lbl);  % ��ȡһ��
        
%         if startsWith(line,'RECORD_BYTES =')
%            str_temp = split(line,'=');
%            block_size = str2double(str_temp{2});
%            continue;
%         end
        
        if startsWith(line,'FILE_RECORDS =')
           str_temp     =   split(line,'=')         ;
           block_num    =   str2double(str_temp{2}) ;
           continue;
        end
        
        if startsWith(line,'/* RJW')
            str_temp    =   split(line,{'\n','/','*'})  ;
            rjws{kk}    =   strtrim(str_temp{3})        ;
            kk          =   kk + 1                      ;
        end
    end
    fclose(fid_lbl);
    
    %% obtain block information
    BYTES_PER_RECORD_str    =   rjws(1)                             ;
    temp_str                =   split(BYTES_PER_RECORD_str,',')     ;
    block_size              =   str2double(strtrim(temp_str(3)))    ;
    OBJECTS_PER_RECORD_str  =   rjws(2)                             ;
    temp_str                =   split(OBJECTS_PER_RECORD_str,',')   ;
    block_objects_num       =   str2double(strtrim(temp_str(3)))    ;
    
    %% format information
    % exclude first 2 RJW comments related to file itself
    rjws_new    = rjws(3:end);
    kk          = 0;
    names       = {};
    %FMT = '=';
    FMT         = {};
    for ii = 1:length(rjws_new)
        str_temp = rjws_new(ii);
        temp = split(str_temp,{', '});
    
        name        =   temp{2}     ;
        fmt         =   temp{3}     ;
        num_dim     =   temp{4}     ;
        dims        =   temp(5:end) ; %���ݽṹ���ܲ�ֻһά
        kk          =   kk + 1      ;
        names{kk}   =   name        ;
        mulvalue    =   1           ;
        for jj = 1:length(dims) %
            mulvalue = mulvalue*str2double(dims(jj));  
        end
        FMT_temp    =   [num2str(mulvalue),fmt] ;
        FMT{ii}     =   FMT_temp                ;
        
        % 2022-10-22 23:32:52 YQW add, �����ά����ߴ�λ����һ��������,��Ҫ������ ION_TOF ������
        for ooo = 1:length(dims)
            odummy = str2num(dims{ooo});
            odummy = num2str(odummy,'%03d');
            dims{ooo} = odummy;
        end      
        block_objects_dims{1,ii} = str2num(num_dim);
        block_objects_dims{2,ii} = str2double(string(cell2mat(dims)))';
    end
    
    block_fmt = FMT;
    block_objects_name = names;
    
    %У��鳤��
    block_bytes = 0;
    for ii = 1:length(block_fmt)

        str_temp = block_fmt{ii};
        switch str_temp(end)
            case 'c'
                str_temp = strrep(str_temp,'c','*1');
            case 'b'
                str_temp = strrep(str_temp,'b','*1');
            case 'B'
                str_temp = strrep(str_temp,'B','*1');
            case 'h'
                str_temp = strrep(str_temp,'h','*2');
            case 'H'
                str_temp = strrep(str_temp,'H','*2');
            case 'i'
                str_temp = strrep(str_temp,'i','*4');
            case 'I'
                str_temp = strrep(str_temp,'I','*4');
            case 'f'
                str_temp = strrep(str_temp,'f','*4');
        end
        block_bytes = block_bytes + eval(str_temp);
    end

    if block_size == block_bytes
        fprintf('block_size == block_bytes, congratulations. \n');
    else
        fprintf('block_size ~= block_bytes, Please check \n');
    end
	
	
    lbl_info_s.block_size              =   block_size            ;
    lbl_info_s.block_objects_num       =   block_objects_num     ;
    lbl_info_s.block_objects_name      =   block_objects_name    ;
    lbl_info_s.block_fmt               =   block_fmt             ;
    lbl_info_s.block_num               =   block_num             ;
    lbl_info_s.block_objects_dims      =   block_objects_dims    ;
	
end