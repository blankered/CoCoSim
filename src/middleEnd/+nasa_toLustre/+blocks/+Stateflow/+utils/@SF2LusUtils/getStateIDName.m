
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
function idName = getStateIDName(state)
    
    state_name = lower(...
        nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getUniqueName(state));
    idName = strcat(state_name, ...
        nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getStateIDSuffix());
end
