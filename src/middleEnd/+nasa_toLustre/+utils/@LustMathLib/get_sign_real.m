%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
function [node, external_nodes_i, opens, abstractedNodes] = get_sign_real(varargin)
    import nasa_toLustre.lustreAst.*
    opens = {};
    abstractedNodes = {};
    external_nodes_i = {};
    bodyElts{1} = LustreEq(...
        VarIdExpr('y'), ...
        IteExpr.nestedIteExpr(...
        {BinaryExpr(BinaryExpr.GT, VarIdExpr('x'), RealExpr('0.0')), ...
        BinaryExpr(BinaryExpr.LT, VarIdExpr('x'), RealExpr('0.0'))}, ...
        {RealExpr('1.0'), RealExpr('-1.0'), RealExpr('0.0')})...
        );
    node = LustreNode();
    node.setName('sign_real');
    node.setInputs(LustreVar('x', 'real'));
    node.setOutputs(LustreVar('y', 'real'));
    node.setBodyEqs(bodyElts);
    node.setIsMain(false);
end
