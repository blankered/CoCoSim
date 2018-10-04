function [status, errors_msg] = Saturation_pp(model)
% SATURATION_PP changes Saturation block to Min/Max blocks.
% if Upper limit or Lower limit are Infinite "Inf" they are ignored.
status = 0;
errors_msg = {};

saturation_list = find_system(model,'BlockType','Saturate');
if ~ ( isempty( saturation_list ) )
    display_msg('Processing Saturation blocks...', Constants.INFO,...
        'Saturation_pp', '');
    for i=1:length(saturation_list)
        display_msg(saturation_list{i}, Constants.INFO, ...
            'Saturation_pp', '');
        try
            lower_limit = get_param(saturation_list{i},'LowerLimit');
            upper_limit = get_param(saturation_list{i},'UpperLimit');
            outputDataType = get_param(saturation_list{i}, 'OutDataTypeStr');
            
            try
                l = evalin('base', lower_limit);
                u = evalin('base', upper_limit);
                %calling all twise in the case of l or u are N-D arrays
                UpperIsInf = all(all(isinf(u)));
                LowerIsInf = all(all(isinf(l)));
            catch
                UpperIsInf= false;
                LowerIsInf = false;
            end
            if UpperIsInf && LowerIsInf
                replace_one_block(saturation_list{i},'pp_lib/saturation_upper_and_lower_is_Inf');
            elseif UpperIsInf
                replace_one_block(saturation_list{i},'pp_lib/saturation_upper_is_Inf');
            elseif LowerIsInf
                replace_one_block(saturation_list{i},'pp_lib/saturation_lower_is_Inf');
            else
                replace_one_block(saturation_list{i},'pp_lib/saturation');
            end
            set_param(saturation_list{i}, 'LinkStatus', 'inactive');
            if ~LowerIsInf
                set_param(strcat(saturation_list{i},'/lower_limit'),...
                    'Value',lower_limit);
            end
            if ~UpperIsInf
                set_param(strcat(saturation_list{i},'/upper_limit'),...
                    'Value',upper_limit);
            end
            if ~contains(outputDataType, 'Same as input')
                if ~UpperIsInf
                    set_param(strcat(saturation_list{i},'/upper_limit'),...
                        'OutDataTypeStr',outputDataType);
                end
                if ~LowerIsInf
                    set_param(strcat(saturation_list{i},'/lower_limit'),...
                        'OutDataTypeStr',outputDataType);
                end
            else
                %Inherit: Inherit via back propagation
                if ~UpperIsInf
                    set_param(strcat(saturation_list{i},'/upper_limit'),...
                        'OutDataTypeStr','Inherit: Inherit via back propagation');
                end
                if ~LowerIsInf
                    set_param(strcat(saturation_list{i},'/lower_limit'),...
                        'OutDataTypeStr','Inherit: Inherit via back propagation');
                end
            end
        catch
            status = 1;
            errors_msg{end + 1} = sprintf('saturation pre-process has failed for block %s', saturation_list{i});
            continue;
        end
    end
    display_msg('Done\n\n', Constants.INFO, 'Saturation_pp', '');
end
end
