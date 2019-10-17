classdef BusCreator_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre
    %BusCreator_To_Lustre translates the BusCreator block.
    %We inline signals, so Bus creator is just passing the input signals,
    %if there is a Bus object, it is inlined as well. The generated Lustre
    %code will be without records or Bus types.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, ~, ~, main_sampleTime, varargin)
            
            [outputs, outputs_dt] = ...
               nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace, main_sampleTime);
            obj.addVariable(outputs_dt);
            [inputs] =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk);
            
            nb_outputs = numel(outputs);
            % everything is inlined
            codes = arrayfun( @(i)  nasa_toLustre.lustreAst.LustreEq(outputs{i}, inputs{i}), ...
                (1:nb_outputs),'UniformOutput', 0);

            
            obj.addCode( codes );
        end
        
        function options = getUnsupportedOptions(obj, ~, ~, varargin)
            
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

