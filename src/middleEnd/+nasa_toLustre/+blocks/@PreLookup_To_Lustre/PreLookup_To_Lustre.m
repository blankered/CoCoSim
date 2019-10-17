classdef PreLookup_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre ...
        & nasa_toLustre.blocks.BaseLookup
    % PreLookup_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
  
        function  write_code(obj, parent, blk, xml_trace, lus_backend, ~, main_sampleTime, varargin)
                     
            [outputs, outputs_dt] = ...
                nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, ...
                blk, [], xml_trace, main_sampleTime);
            obj.addVariable(outputs_dt);
            
            numInputs = numel(blk.CompiledPortWidths.Inport);
            RndMeth = blk.RndMeth;
            inputs = cell(1, numInputs);
            for i=1:numInputs
                inputs{i} =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                Lusinport_dt =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Inport{i});

                %converts the input data type(s) to real if not real
                if ~strcmp(Lusinport_dt, 'real') 
                    [external_lib, conv_format] = ...
                       nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(Lusinport_dt, 'real', RndMeth);
                    if ~isempty(conv_format)
                        obj.addExternal_libraries(external_lib);
                        inputs{i} = cellfun(@(x) ...
                           nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format,x),...
                            inputs{i}, 'un', 0);
                    end
                end
            end        
            
            blkParams = ...
                nasa_toLustre.blocks.Lookup_nD_To_Lustre.getInitBlkParams(...
                blk, lus_backend);   
            blkParams = obj.readBlkParams(parent,blk, blkParams, inputs); 
            
            % binaryExpr use abs_real to compare to epsilon
            obj.addExternal_libraries({'LustMathLib_abs_real'});
            wrapperNode = obj.create_lookup_nodes(blk, lus_backend, blkParams, outputs, inputs);
            mainCode = obj.getMainCode(blk,outputs,inputs,...
                wrapperNode,blkParams);
            obj.addCode(mainCode);
        end
        
        %%
        function options = getUnsupportedOptions(obj, ~, ~, varargin)
            options = obj.unsupported_options;
        end
        
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
        
        blkParams = readBlkParams(obj,parent,blk,blkParams, inputs)
        
        wrapperNode = create_lookup_nodes(obj,blk,lus_backend,blkParams,outputs,inputs)
        
        extNode =  get_wrapper_node(obj,blk,...
            inputs, outputs, preLookUpExtNode, blkParams)
        
        [mainCode, main_vars] = getMainCode(obj, blk,outputs,inputs,...
            lookupWrapperExtNode,blkParams)     
        
    end

    methods(Static)
        function b = bpIsInputPort(blkParams)
            % return if breakpoints are given through input port or dynamic table
            b = nasa_toLustre.utils.LookupType.isLookupDynamic(blkParams.lookupTableType) || ...
                    (nasa_toLustre.utils.LookupType.isPreLookup(blkParams.lookupTableType) && blkParams.bpIsInputPort);
        end
        
    end
end

