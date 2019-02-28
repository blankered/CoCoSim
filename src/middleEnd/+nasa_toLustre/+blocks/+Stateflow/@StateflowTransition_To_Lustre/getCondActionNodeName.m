
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function node_name = getCondActionNodeName(T, src, isDefaultTrans)
    import nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre
    if nargin < 2
        src = T.Source;
    end
    if nargin < 3
        if isempty(src)
            isDefaultTrans = true;
        else
            isDefaultTrans = false;
        end
    end
    transition_prefix = ...
        nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.getUniqueName(T, src, isDefaultTrans);
    node_name = sprintf('%s_Cond_Act', transition_prefix);
end
