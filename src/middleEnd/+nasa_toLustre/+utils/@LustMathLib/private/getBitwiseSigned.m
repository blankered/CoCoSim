function [node, external_nodes, opens, abstractedNodes] = getBitwiseSigned(op, n)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    import nasa_toLustre.lustreAst.*
    opens = {};
    abstractedNodes = {};
    extNode = sprintf('int_to_int%d',n);
    UnsignedNode =  sprintf('_%s_Bitwise_Unsigned_%d',op, n);
    external_nodes = {strcat('LustDTLib_', extNode),...
        strcat('LustMathLib_', UnsignedNode)};
    
    node_name = sprintf('_%s_Bitwise_Signed_%d', op, n);
    v2_pown = 2^(n);
    bodyElts{1} = nasa_toLustre.lustreAst.LustreEq(...
        nasa_toLustre.lustreAst.VarIdExpr('x2'), ...
        nasa_toLustre.lustreAst.IteExpr(...
        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.LT, nasa_toLustre.lustreAst.VarIdExpr('x'), nasa_toLustre.lustreAst.IntExpr('0')), ...
        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.PLUS, nasa_toLustre.lustreAst.IntExpr(v2_pown),nasa_toLustre.lustreAst.VarIdExpr('x')), ...
        nasa_toLustre.lustreAst.VarIdExpr('x'))...
        );
    bodyElts{end + 1} = nasa_toLustre.lustreAst.LustreEq(...
        nasa_toLustre.lustreAst.VarIdExpr('y2'), ...
        nasa_toLustre.lustreAst.IteExpr(...
        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.LT, nasa_toLustre.lustreAst.VarIdExpr('y'), nasa_toLustre.lustreAst.IntExpr('0')), ...
        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.PLUS, nasa_toLustre.lustreAst.IntExpr(v2_pown),nasa_toLustre.lustreAst.VarIdExpr('y')), ...
        nasa_toLustre.lustreAst.VarIdExpr('y'))...
        );
    bodyElts{end + 1} = nasa_toLustre.lustreAst.LustreEq(...
        nasa_toLustre.lustreAst.VarIdExpr('z'), ...
        nasa_toLustre.lustreAst.NodeCallExpr(extNode, ...
        nasa_toLustre.lustreAst.NodeCallExpr(UnsignedNode, ...
        {nasa_toLustre.lustreAst.VarIdExpr('x2'), nasa_toLustre.lustreAst.VarIdExpr('y2')}))...
        );
    node = nasa_toLustre.lustreAst.LustreNode();
    node.setName(node_name);
    node.setInputs({nasa_toLustre.lustreAst.LustreVar('x', 'int'), nasa_toLustre.lustreAst.LustreVar('y', 'int')});
    node.setOutputs(nasa_toLustre.lustreAst.LustreVar('z', 'int'));
    node.setLocalVars({nasa_toLustre.lustreAst.LustreVar('x2', 'int'), nasa_toLustre.lustreAst.LustreVar('y2', 'int')})
    node.setBodyEqs(bodyElts);
    node.setIsMain(false);
end
