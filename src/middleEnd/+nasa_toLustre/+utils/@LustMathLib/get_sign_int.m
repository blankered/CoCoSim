%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
function [node, external_nodes_i, opens, abstractedNodes] = get_sign_int(varargin)
    import nasa_toLustre.lustreAst.*
    opens = {};
    abstractedNodes = {};
    external_nodes_i = {};
    bodyElts{1} = LustreEq(...
        VarIdExpr('y'), ...
        IteExpr.nestedIteExpr(...
        {BinaryExpr(BinaryExpr.GT, VarIdExpr('x'), IntExpr('0')), ...
        BinaryExpr(BinaryExpr.LT, VarIdExpr('x'), IntExpr('0'))}, ...
        {IntExpr('1'), IntExpr('-1'), IntExpr('0')})...
        );
    node = LustreNode();
    node.setName('sign_int');
    node.setInputs(LustreVar('x', 'int'));
    node.setOutputs(LustreVar('y', 'int'));
    node.setBodyEqs(bodyElts);
    node.setIsMain(false);
end
