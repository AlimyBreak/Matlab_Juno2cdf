%{


    juno_jad_analyse_dat_V04:YQW/2025.03.01
    �޸�matlab reshape��bug��% https://blog.csdn.net/qq_32390983/article/details/100568566, ��������˳��(2025��3��1�� 11:39:41)
 
	juno_jad_analyse_dat_V03: YQW/2022.10.22
	(����ʾ�Ѿ�֧����)
		��JAD_L30_HRS_ELC_ALL_CNT_*_V04.dat
		��JAD_L30_HRS_ELC_TWO_CNT_*_V04.dat
		��JAD_L30_LRS_ELC_ANY_CNT_*_V04.dat
		��JAD_L30_HLS_ION_LOG_CNT_*_V04.dat
		��JAD_L30_HRS_ION_ANY_CNT_*_V04.dat
		��JAD_L30_LRS_ION_ANY_CNT_*_V04.dat
		��JAD_L30_HLS_ION_TOF_CNT_*_V04.dat

    ����:
        fullpath_dat        :   *.dat ��ȫ·��
		
        block_size          :   һ�����Ӧ�Ĵ�С(Bytes)
        block_objects_num   :   һ�����г�Ա����ĸ���
        block_objects_name  :   һ�����г�Ա���������
        block_fmt           :   �ַ�������cell(���ڶ�dat�ļ����з���)
        block_num           :   ������(��Ӧ*.dat�ļ����ж��ٸ�block_size��С�Ŀ�)
    ���:
        data_s              :   ��struct����
		
%}

function [ data_s ] = juno_jad_analyse_dat_V05(fullpath_dat,lbl_info_s)
                     
    block_size              =       lbl_info_s.block_size               ;
    block_objects_name      =       lbl_info_s.block_objects_name       ;
    block_fmt               =       lbl_info_s.block_fmt                ;
    block_objects_dims      =       lbl_info_s.block_objects_dims       ;
    block_num               =       lbl_info_s.block_num                ;                                                   
    data_s = [];
    %% 1. ��ڼ��
    % ��ȡ�ļ�length in bytes,�������block_num*block_size
    fid = fopen(fullpath_dat,'rb');
    fseek(fid,0,'eof');
    bytes_of_file = ftell(fid);    
    fclose(fid);
    if bytes_of_file ~= block_num*block_size
        fprintf('juno_jad_analyse_dat_V1 error, Please Check input (file error)\n');
        return;
    else
        fprintf('.dat file is valid , Congratulations. \n');
    end
    
    % 1.1 ׼�����ݽṹ
    data = struct();
    for ii = 1:numel(block_objects_name)
        temp_str = ['data.',block_objects_name{ii},'= [];'];
        eval(temp_str);
    end
    
    %% 2. ��������
    fid = fopen(fullpath_dat,'rb');
    for jj = 1:block_num        
        for ii = 1:numel(block_fmt)
            temp_str = block_fmt{ii};
            type = temp_str(end);
            num  = str2double(temp_str(1:end-1));
            switch type
                case 'c'
                    %str_temp = strrep(str_temp,'c','*1');
                    data_temp = fread(fid,num,'char');
                    data_temp = char(data_temp)';
                case 'b'
                    %str_temp = strrep(str_temp,'b','*1');  
                    data_temp = fread(fid,num,'int8');      %�е�signed byte�涨���� 2�ֽ�,��Ҫע��,�ǳ�����
                case 'B'
                    %str_temp = strrep(str_temp,'B','*1');  
                    data_temp = fread(fid,num,'uint8');      %�е�unsigned byte�涨����2�ֽ�,��Ҫע��,�ǳ�����
                case 'h'
                    %str_temp = strrep(str_temp,'h','*2');
                    data_temp = fread(fid,num,'short');
                case 'H'
                    %str_temp = strrep(str_temp,'H','*2');
                     data_temp = fread(fid,num,'ushort');
                case 'i'
                    %str_temp = strrep(str_temp,'i','*4');
                    data_temp = fread(fid,num,'int32');
                case 'I'
                    %str_temp = strrep(str_temp,'I','*4');
                    data_temp = fread(fid,num,'uint32');
                case 'f'
                    %str_temp = strrep(str_temp,'f','*4');
                    data_temp = fread(fid,num,'float');
                otherwise
                   fprinf('��������δ֧�ֵ�����,������Ӻ���ܴ���\n');
            end
            pos = ftell(fid);
            num_dims    = block_objects_dims{1,ii};
            temp_dims   = block_objects_dims{2,ii};
            %fprintf('ii = %d , jj = %d,pos = %d\n',ii , jj ,pos);
            if num_dims ~= 1
                %data_temp = reshape(data_temp,temp_dims);
                %data_temp = reshape(data_temp,flip(temp_dims))'; 
				data_temp = pagetranspose(reshape(data_temp,flip(temp_dims))); % for Matlab2025a 2025-07-17 10:55:38
            end
            temp_str = ['data_s.',block_objects_name{ii},'{jj}= data_temp;']; %
            eval(temp_str);
        end
    end
    fclose(fid);

end