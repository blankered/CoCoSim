
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%get_InnerTransitionsNode
function [transitionNode, external_libraries] = ...
        get_InnerTransitionsNode(state, data_map)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    transitionNode = {};
    external_libraries = {};
    parentPath = state.Path;
    stateParent = fileparts(state.Path);
    if isempty(stateParent)
        %main chart
        return;
    end
    T = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.orderObjects(...
        state.InnerTransitions, 'ExecutionOrder');
    isDefaultTrans = false;
    node_name = ...
        nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getStateInnerTransNodeName(state);
    comment = nasa_toLustre.lustreAst.LustreComment(...
        sprintf('Inner transitions of state %s', state.Origin_path), true);
    [transitionNode, external_libraries] = ...
        nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.getTransitionsNode(T, data_map, parentPath, ...
        isDefaultTrans, ...
        node_name, comment);
end
