classdef ZeroOrderHold_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %ZeroOrderHold_To_Lustre translates the ZeroOrderHold block.

    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, ~, ~, main_sampleTime, varargin)
            
            [outputs, outputs_dt] =nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace, main_sampleTime);
            obj.addVariable(outputs_dt);
            [inputs] =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk);
            outputDataType = blk.CompiledPortDataTypes.Outport{1};
            % calculated by rateTransition_ir_pp
            OutportCompiledSampleTime = blk.OutportCompiledSampleTime;
            outTs = OutportCompiledSampleTime(1);
            outTsOffset = OutportCompiledSampleTime(2);
            period = outTs/main_sampleTime(1);
            phase = outTsOffset/main_sampleTime(1);
            if nasa_toLustre.utils.SLX2LusUtils.isIgnoredSampleTime(period, phase)
                codes = arrayfun(@(i) nasa_toLustre.lustreAst.LustreEq(outputs{i}, inputs{i}), ...
                    (1:numel(outputs)), 'UniformOutput', 0);
            else
                clockName =nasa_toLustre.utils.SLX2LusUtils.clockName(period, phase);
%                 codes = arrayfun(@(i) ...
%                     nasa_toLustre.lustreAst.LustreEq(outputs{i}, ...
%                     nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.WHEN, ...
%                     inputs{i}, ...
%                     nasa_toLustre.lustreAst.VarIdExpr(clockName))), ...
%                     (1:numel(outputs)), 'UniformOutput', 0);
                clockVar = nasa_toLustre.lustreAst.VarIdExpr(clockName);
                init_cond =nasa_toLustre.utils.SLX2LusUtils.getInitialOutput(parent, blk,...
                    '0', outputDataType, length(outputs));
                codes = cell(1, length(outputs));
                for i=1:length(outputs)
                    % Out = if C then In else (0.0 -> (pre Out));
                    lhs = nasa_toLustre.lustreAst.IteExpr(clockVar, ...
                        inputs{i}, ...
                        nasa_toLustre.lustreAst.BinaryExpr(...
                            nasa_toLustre.lustreAst.BinaryExpr.ARROW, ...
                            init_cond{i}, ...
                            nasa_toLustre.lustreAst.UnaryExpr(...
                                nasa_toLustre.lustreAst.UnaryExpr.PRE, ...
                                outputs{i})...
                            ));
                    codes{i} = nasa_toLustre.lustreAst.LustreEq(outputs{i}, lhs);
                end
            end
            
            obj.addCode( codes );
        end
        %%
        function options = getUnsupportedOptions(obj,~, blk, lus_backend, varargin)
            options = obj.unsupported_options;
        end
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

