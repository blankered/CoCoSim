classdef Concatenate_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    % Concatenate_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, ~, ~, main_sampleTime, varargin)
            
            [outputs, outputs_dt] = ...
                nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace, main_sampleTime);
            [inputs,widths] = ...
                nasa_toLustre.blocks.Concatenate_To_Lustre.getBlockInputsNames_convInType2AccType(obj, parent, blk);
            [blkParams,in_matrix_dimension] = nasa_toLustre.blocks.Concatenate_To_Lustre.readBlkParams(blk);
            nb_inputs = numel(widths);
            if blkParams.isVector
                [codes] = nasa_toLustre.blocks.Concatenate_To_Lustre.concatenateVector(nb_inputs, inputs, outputs);
            else
                [ConcatenateDimension, ~, status] = ...
                    nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, blk.ConcatenateDimension);
                if status
                    display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                        blk.ConcatenateDimension, HtmlItem.addOpenCmd(blk.Origin_path)), ...
                        MsgType.ERROR, 'Concatenate_To_Lustre', '');
                    return;
                end
                %% Hamza's method
                args = {};
                % reshape inputs to their original dimensions
                for i=1:length(inputs)
                    dims = in_matrix_dimension{i}.dims;
                    if length(dims) == 1
                        if ConcatenateDimension == 1
                            dims = [1 dims];
                        else
                            dims = [dims 1];
                        end
                    end
                    args{i} = reshape(inputs{i}, dims);
                end
                % concatenate them
                A = cat(ConcatenateDimension, args{:});
                A_inlined = reshape(A, [length(outputs) 1]);
                codes = arrayfun(@(i) nasa_toLustre.lustreAst.LustreEq(outputs{i},...
                    A_inlined{i}), (1:length(outputs)), 'UniformOutput', 0);
                %% Khanh's method
                %                 if numel(in_matrix_dimension) > 7
                %                     display_msg(sprintf('More than 7 dimensions is not supported in block %s ',...
                %                         HtmlItem.addOpenCmd(blk.Origin_path)), ...
                %                         MsgType.ERROR, 'Concatenate_To_Lustre', '');
                %                     return;
                %                 end
                %                 if ConcatenateDimension == 2    %concat matrix in row direction
                %                     [codes] = nasa_toLustre.blocks.Concatenate_To_Lustre.concatenateDimension2(inputs, outputs,in_matrix_dimension);
                %                 elseif ConcatenateDimension == 1    %concat matrix in column direction
                %                     [codes] = nasa_toLustre.blocks.Concatenate_To_Lustre.concatenateDimension1(inputs, outputs,in_matrix_dimension);
                %                 else
                %                     display_msg(sprintf('ConcatenateDimension > 2 in block %s',...
                %                         HtmlItem.addOpenCmd(blk.Origin_path)), ...
                %                         MsgType.ERROR, 'Constant_To_Lustr', '');
                %                     return;
                %                 end
            end
            
            obj.addCode( codes );
            obj.addVariable(outputs_dt);
        end
        
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            
            [~, ~, status] = ...
                nasa_toLustre.blocks.Constant_To_Lustre.getValueFromParameter(parent, blk, blk.ConcatenateDimension);
            if status
                obj.addUnsupported_options(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.ConcatenateDimension, HtmlItem.addOpenCmd(blk.Origin_path)));
            end
%             if ConcatenateDimension > 2
%                 obj.addUnsupported_options(sprintf('ConcatenateDimension > 2 in block %s',...
%                     HtmlItem.addOpenCmd(blk.Origin_path)));
%             end
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
    methods(Static)
        
        [blkParams,in_matrix_dimension] = readBlkParams(blk)
        
        [codes] = concatenateDimension1(inputs, outputs,in_matrix_dimension)
        
        [inputs,widths] = getBlockInputsNames_convInType2AccType(obj, parent, blk)
        
        [codes] = concatenateDimension2(inputs, outputs,in_matrix_dimension)
        
        [codes] = concatenateVector(nb_inputs, inputs, outputs)
        
    end
    
end

