%{
    main_juno_fgm_r1s_toCDF_V01 YQW/2022.01.07
    alimy1990@foxmail.com
    ������ JNO-J-3-FGM-CAL-V1.0.zip �� *_r1s_* �ļ�תΪcdf�ļ�.
    ע��:
    1. ��Ҫ���õĲ���ֻ��  root_dir(27��) �� reserv_word(30��) ;
    2. �洢����ļ�����Ҫ�����½���, ���½��ڱ������ļ����ڵ�Ŀ¼�£�����ļ�����Ϊ 2016 2017 2018 2019 2020
    2021 ;
    3. ����Ҫ�� ��Ҫ Matlab R2020a �����ϰ汾;
    4. ����˵���� �������ԣ���ȡ�ʹ���һ������ݴ�Լ��Ҫ80s, �����Բ��㹻ǿ�� , ���Խ� parfor(36��)��Ϊ for .
    ȱ��:
    1. д��cdf�ļ���ֻ�����ֺ�����, û��д��ע�ͻ�������Ϣ(��֪����ôд), ��ʵ�Ѿ���ȡ���� com_info_s.*.DESCRIPTION �� pj_info_s.*.DESCRIPTION
    �У�����ͨ����com_info_s��pj_info_s���������������(DFS)��ȡ��ЩDESCRIPTION��Ϣ.
    
    
    �����ļ�:
        Juno_search_file_assembly_V2.m
        juno_fgm_r1s_lbl_byday_V01.m
        juno_fgm_r1s_sts_byday_V01.m

%}

close all;
clear;
clc;

% ������������
root_dir        =   'D:\DATA\Juno_ForDraw'  ;   % �¼�Ŀ¼���뺬�� \FGM\JNO-J-3-FGM-CAL-V1.0\DATA\
instrument_name =   'FGM'                   ;     
subpackage_idx  =   11                      ;
reserv_word     =   'PC'                    ;   % ����ϵ,������ 'PC', 'PL' ���� 'SS'

% ��ݱ���
for year = 2021:2021
    
    % �������������д���
    parfor dayofyear = 54:180
    
        % չʾ��ǰ�ڴ��������, ��������
        fprintf('current year = %d , current day = % \n', year, dayofyear);
    
        % ���Ҷ�Ӧ���������к��� _r1s_ ���ļ�.
        [valid_11,filefullpath_11] = Juno_search_file_assembly_V2(                      ...
                                                                    root_dir        ,   ...
                                                                    instrument_name ,   ...
                                                                    subpackage_idx  ,   ...
                                                                    reserv_word     ,   ...
                                                                    year            ,   ...
                                                                    dayofyear           ...
                                                                 );
                                                                 
        % 0��ʾɶҲû�ҵ� 1��ʾ�ҵ���
        if ~valid_11    
            continue;
        end
        
        % �Ϸ������ļ�����ֻ����2����4
        if (length(filefullpath_11) ~= 2) && (length(filefullpath_11)~= 4)
            fid = fopen([reserv_word,'����ϵ_��������.txt'],'a');
            fprintf(fid, 'err file: year = %d, doy = %d\n', year , dayofyear);
            fclose(fid);
            continue;
        end

        % ��ȡlbl��Ϣ��sts�ļ���Ϣ
        [ com_info_s , pj_info_s ] = juno_fgm_r1s_lbl_byday_V01(filefullpath_11);
        [ com_data_s , pj_data_s ] = juno_fgm_r1s_sts_byday_V01(filefullpath_11, com_info_s, pj_info_s);
         
        
        % ����ȡ������Ϣд�뵽cdf�ļ�����ŵ���ݶ�Ӧ�ļ�, ����ļ�����Ҫ�Ѿ��½���
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

% ����Ķ����ᱻ����.









































































fid = fopen('�ļ���Ϣ.csv','w');
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

%fid = fopen('��ͼ��Ϣ.txt','a');
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
        
        fprintf('year = %d ��dayofyear = %d , �Ѿ��õ� %f mins \n', year, dayofyear, toc/60 );
        %fprintf(fid,'year = %d ��dayofyear = %d , �Ѿ��õ� %f mins \n', year, dayofyear, toc/60 );
        Juno_EB_Overview_V2(fgm_file_1s,wav_b_file,wav_e_file,year,dayofyear); 
    end
end


%fclose(fid);