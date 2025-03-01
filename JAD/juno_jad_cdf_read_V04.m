%{

    juno_jad_cdf_read_V04.m/YQW 2025年3月1日 14:41:48
    输入: jad_cdf_file_path:
    test_mainV04_L*_generateCDF(uno_jad_analyse_dat_V04.m
    juno_jad_analyse_lable_V04.m) 生成的cdf文件
    输出: data_s, 包含各个object的结构体。


%}
function [data_s] = juno_jad_cdf_read_V04(jad_cdf_file_path)
    data_s  = struct();
    info = spdfcdfinfo(jad_cdf_file_path);
    var_list  = {info.Variables{:,1}};
    data_temp = spdfcdfread(jad_cdf_file_path,'Variables',var_list);

    for ii = 1:length(var_list)
        temp_str = ['data_s.', var_list{ii}, '=data_temp{ii};'];
        eval(temp_str);
    end

    fileds = fieldnames(data_s);
    epoch_length = size(data_s.DIM0_UTC,3);
    for ii = 1:length(fileds)
        cur_field = getfield(data_s,fileds{ii});
        cur_field_se = squeeze(cur_field);
        cur_set = cur_field_se;
        if length(size(cur_field_se)) > 1
            if ii == 3
                bbb  = 1;
            end
            % 把epoch循环放到最前维度
            sz = size(cur_field_se);
            if epoch_length == sz(end)
                I = length(sz);
            else
                continue;
            end
            new_mute = flip(1:length(size(cur_field_se)));
            new_mute(new_mute==I) = [];
            new_mute(end+1) = I;
            new_mute = flip(new_mute);
            cur_set = permute(cur_field_se,new_mute);
        end

        temp_str = ['data_s.', fileds{ii}, '=cur_set;'];
        eval(temp_str)
    end
end
