
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
function node_name = getCondActionName(T)
    
    src = T.Source;
    if isempty(src)
        isDefaultTrans = true;
    else
        isDefaultTrans = false;
    end
    transition_prefix = ...
        nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.getUniqueName(T, src, isDefaultTrans);
    node_name = sprintf('%s_Cond', transition_prefix);
end
