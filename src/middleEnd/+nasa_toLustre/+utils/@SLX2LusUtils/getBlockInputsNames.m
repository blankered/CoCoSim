
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%% get block inputs names. E.g subsystem taking input signals from differents blocks.
% We need to go over all linked blocks and get their output names
% in the corresponding port number.
% Read PortConnectivity documentation for more information.
function [inputs, inputs_var] = getBlockInputsNames(parent, blk, Port)
    % get only inports, we don't take enable/reset/trigger, outputs
    % ports.
    srcPorts = blk.PortConnectivity(...
        arrayfun(@(x) ~isempty(x.SrcBlock) ...
        &&  ~isempty(str2num(x.Type)) , blk.PortConnectivity));
    if nargin >= 3 && ~isempty(Port)
        srcPorts = srcPorts(Port);
    end
    inputs = {};
    inputs_var = {};
    for b=srcPorts'
        srcPort = b.SrcPort;
        srcHandle = b.SrcBlock;
        src = get_struct(parent, srcHandle);
        if isempty(src)
            continue;
        end
        [n_i, n_dt_i] = nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, src, srcPort);
        %TODO: use inputs{i} = ... But make sure all functions calling this
        function use the same convention: inputs is a cell array of cell arrays.
        inputs = [inputs, n_i];
        inputs_var = [inputs_var, n_dt_i];
    end
end
