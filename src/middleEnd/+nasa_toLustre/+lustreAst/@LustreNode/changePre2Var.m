%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%% This functions are used for ForIterator block
function [new_obj, varIds] = changePre2Var(obj)
    varIds = {};
    new_bodyEqs = cell(numel(obj.bodyEqs),1);
    for i=1:numel(obj.bodyEqs)
        [new_bodyEqs{i}, vId] = obj.bodyEqs{i}.changePre2Var();
        varIds = [varIds, vId];
    end
    new_obj = nasa_toLustre.lustreAst.LustreNode(obj.metaInfo, obj.name, obj.inputs, ...
        obj.outputs, obj.localContract, obj.localVars, new_bodyEqs, ...
        obj.isMain, obj.isImported);
end
