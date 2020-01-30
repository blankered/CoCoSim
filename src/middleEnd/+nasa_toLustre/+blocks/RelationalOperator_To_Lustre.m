classdef RelationalOperator_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %RelationalOperator_To_Lustre translates a RelationalOperator block
    %to Lustre.

    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, ~, ~, main_sampleTime, varargin)
            
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace, main_sampleTime);
            
            
            widths = blk.CompiledPortWidths.Inport;
            max_width = max(widths);
            outputDataType = blk.CompiledPortDataTypes.Outport{1};
            [lus_outputDT, zero, one] =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(...
                outputDataType);
            lus_in1_dt =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(...
                blk.CompiledPortDataTypes.Inport(1));
            lus_in2_dt =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(...
                blk.CompiledPortDataTypes.Inport(2));
            thewantedDataType = 'int';
            if strcmp(lus_in1_dt, 'real') || strcmp(lus_in2_dt, 'real')
                thewantedDataType = 'real';
            end
            inputs = cell(1, numel(widths));
            for i=1:numel(widths)
                inputs{i} =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                if numel(inputs{i}) < max_width
                    inputs{i} = arrayfun(@(x) {inputs{i}{1}}, (1:max_width));
                end
                inport_dt =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Inport(i));
                %converts the input data type(s) to
                %its accumulator data type
                if ~strcmp(inport_dt, thewantedDataType)
                    [external_lib, conv_format] =nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(inport_dt, thewantedDataType);
                    if ~isempty(conv_format)
                        obj.addExternal_libraries(external_lib);
                        inputs{i} = cellfun(@(x) ...
                           nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format,x),...
                            inputs{i}, 'un', 0);
                    end
                end
            end
            
            op = blk.Operator;
            if strcmp(op, '==')
                op = nasa_toLustre.lustreAst.BinaryExpr.EQ;
            elseif strcmp(op, '~=')
                op = nasa_toLustre.lustreAst.BinaryExpr.NEQ;
            elseif strcmp(op, 'isInf') || strcmp(op, 'isNaN') ...
                    ||strcmp(op, 'isFinite')
                display_msg(sprintf('Operator %s in blk %s is not supported',...
                    blk.Operator, HtmlItem.addOpenCmd(blk.Origin_path)), ...
                    MsgType.ERROR, 'RelationalOperator_To_Lustre', '');
                return;
            end
            codes = cell(1, numel(outputs));
            for j=1:numel(outputs)
                code = nasa_toLustre.lustreAst.BinaryExpr(op, inputs{1}{j}, inputs{2}{j});
                if strcmp(lus_outputDT, 'bool')
                    codes{j} = nasa_toLustre.lustreAst.LustreEq(outputs{j}, code);
                else
                    codes{j} = nasa_toLustre.lustreAst.LustreEq(outputs{j}, ...
                        nasa_toLustre.lustreAst.IteExpr(code, one, zero));
                end
            end
            obj.addCode( codes );
            obj.addVariable(outputs_dt);
        end
        
        function options = getUnsupportedOptions(obj, ~, blk,  varargin)
            % add your unsuported options list here
            op = blk.Operator;
           if strcmp(op, 'isInf') || strcmp(op, 'isNaN') ...
                    ||strcmp(op, 'isFinite')
                obj.addUnsupported_options(...
                    sprintf('Operator %s in blk %s is not supported',...
                    blk.Operator, HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

