classdef PreLookup_To_Lustre < nasa_toLustre.frontEnd.Block_To_Lustre ...
        & nasa_toLustre.blocks.BaseLookup
    % PreLookup_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
  
        function  write_code(obj, parent, blk, xml_trace, lus_backend, varargin)
            blkParams = ...
                nasa_toLustre.blocks.Lookup_nD_To_Lustre.getInitBlkParams(blk);            
            blkParams = obj.readBlkParams(parent,blk,blkParams);    
            
            [outputs, ~] = ...
                nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, ...
                blk, [], xml_trace);
            
            % get block inputs
%             [inputs,~] = ...
%                 nasa_toLustre.blocks.Lookup_nD_To_Lustre.getBlockInputsNames_convInType2AccType(...
%                 obj, parent,...
%                 blk);

            widths = blk.CompiledPortWidths.Inport;
            numInputs = numel(widths);
            max_width = max(widths);
            RndMeth = blkParams.RndMeth;
            SaturateOnIntegerOverflow = blkParams.SaturateOnIntegerOverflow;          
            inputs = cell(1, numInputs);
            for i=1:numInputs
                inputs{i} =nasa_toLustre.utils.SLX2LusUtils.getBlockInputsNames(parent, blk, i);
                Lusinport_dt =nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(blk.CompiledPortDataTypes.Inport{i});
                if numel(inputs{i}) < max_width
                    inputs{i} = arrayfun(@(x) {inputs{i}{1}}, (1:max_width));
                end
                %converts the input data type(s) to real if not real
                if ~strcmp(Lusinport_dt, 'real')
                    [external_lib, conv_format] = ...
                       nasa_toLustre.utils.SLX2LusUtils.dataType_conversion(Lusinport_dt, 'real', RndMeth, SaturateOnIntegerOverflow);
                    if ~isempty(conv_format)
                        obj.addExternal_libraries(external_lib);
                        inputs{i} = cellfun(@(x) ...
                           nasa_toLustre.utils.SLX2LusUtils.setArgInConvFormat(conv_format,x),...
                            inputs{i}, 'un', 0);
                    end
                end
            end            
            
            obj.addExternal_libraries({'LustMathLib_abs_real'});
            obj.create_lookup_nodes(blk,lus_backend,blkParams,outputs,inputs);

        end
        
        %%
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            options = obj.unsupported_options;
        end
        
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
        
        blkParams = readBlkParams(obj,parent,blk,blkParams)
        
        create_lookup_nodes(obj,blk,lus_backend,blkParams,outputs,inputs)
        
        extNode =  get_wrapper_node(obj,blk,...
            inputs,outputs,preLookUpExtNode,blkParams)
        
%         extNode =  get_wrapper_retrieval_node(obj,blk,...
%             blkParams,inputs,outputs,preLookUpExtNode,interpolationExtNode)        
        
    end
    
    methods(Static)
        
%         blkParams = ...
%             readBlkParams_PreLookup(parent,blk,inputs,blkParams)
%         
%         [body, vars] = addFinalCode_PreLookup(...
%         outputs,inputs,indexDataType,blk_name,blkParams,N_shape_node,...
%         lusInport_dt,index_node, lus_backend)

        [mainCode, main_vars] = ...
            getMainCode(inputs,preLookupWrapperExtNode,blkParams)
        
        extNode =  get_wrapper_ext_node(...
            blk,inputs,outputs,preLookUpExtNode,blkParams)

    end
    
end

