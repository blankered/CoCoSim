function extNode =  get_wrapper_node(...
    ~,blk,inputs,outputs,preLookUpExtNode,blkParams)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % PreLookup
    blk_name =nasa_toLustre.utils.SLX2LusUtils.node_name_format(blk);
              
    % wrapper header
    wrapper_header.NodeName = sprintf('%s_PreLookup_wrapper_ext_node',blk_name);
    % wrapper inputs
    wrapper_header_input_name{1} = ...
        nasa_toLustre.lustreAst.VarIdExpr('coord_input');
    wrapper_header.Inputs = nasa_toLustre.lustreAst.LustreVar(...
        wrapper_header_input_name{1}, 'real');
    
    % wrapper outputs
%     output1DataType = blk.CompiledPortDataTypes.Outport{1};
%     lus_out1_type =...
%         nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(output1DataType);
    wrapper_output_names{1} = ...
        nasa_toLustre.lustreAst.VarIdExpr(outputs{1}.id);
    wrapper_output_vars{1} = nasa_toLustre.lustreAst.LustreVar(...
        wrapper_output_names{1}, 'int');

    % preLookupOut
    prelookup_out{1} = ...
        nasa_toLustre.lustreAst.VarIdExpr('inline_index_bound_node_1');
    local_vars{1} = nasa_toLustre.lustreAst.LustreVar(...
        prelookup_out{1}, 'int');
    
    if ~blkParams.OutputIndexOnly
        %         output2DataType = blk.CompiledPortDataTypes.Outport{2};
        %         lus_out2_type =...
        %             nasa_toLustre.utils.SLX2LusUtils.get_lustre_dt(output2DataType);
        wrapper_output_names{2} = ...
            nasa_toLustre.lustreAst.VarIdExpr(outputs{2}.id);
        wrapper_output_vars{2} = ...
            nasa_toLustre.lustreAst.LustreVar(...
            wrapper_output_names{2}, 'real');
        
        % prelookup out puts
        prelookup_out{2} = ...
            nasa_toLustre.lustreAst.VarIdExpr('shape_bound_node_1');
        prelookup_out{3} = ...
            nasa_toLustre.lustreAst.VarIdExpr('inline_index_bound_node_2');
        prelookup_out{4} = ...
            nasa_toLustre.lustreAst.VarIdExpr('shape_bound_node_2');
        local_vars{2} = nasa_toLustre.lustreAst.LustreVar(...
            prelookup_out{2}, 'real');
        local_vars{3} = nasa_toLustre.lustreAst.LustreVar(...
            prelookup_out{3}, 'int');
        local_vars{4} = nasa_toLustre.lustreAst.LustreVar(...
            prelookup_out{4}, 'real');                
    end
    wrapper_header.Outputs = wrapper_output_vars;       
    % call prelookup
    body{1} = ...
        nasa_toLustre.lustreAst.LustreEq(prelookup_out, ...
        nasa_toLustre.lustreAst.NodeCallExpr(...
        preLookUpExtNode.name, wrapper_header_input_name));
    % defining k, which is index - 1
    body{2} = nasa_toLustre.lustreAst.LustreEq(...
        wrapper_output_names{1}, ...
        nasa_toLustre.lustreAst.BinaryExpr(...
        nasa_toLustre.lustreAst.BinaryExpr.MINUS,...
        prelookup_out{1},...
        nasa_toLustre.lustreAst.IntExpr(1)));
    if ~blkParams.OutputIndexOnly
        % defining fraction, which is shape value at node 2
        body{3} = ...
            nasa_toLustre.lustreAst.LustreEq(wrapper_output_names{2}, ...
            prelookup_out{4});  
    end

    extNode = nasa_toLustre.lustreAst.LustreNode();
    extNode.setName(wrapper_header.NodeName)
    extNode.setInputs(wrapper_header.Inputs);
    extNode.setOutputs( wrapper_header.Outputs);
    extNode.setLocalVars(local_vars);
    extNode.setBodyEqs(body);
    extNode.setMetaInfo('external node code wrapper for doing PreLookup');

end

