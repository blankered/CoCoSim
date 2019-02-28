%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
function [node, external_nodes_i, opens, abstractedNodes] = get_rem_int_int(varargin)
    import nasa_toLustre.lustreAst.*
    opens = {};
    abstractedNodes = {};
    external_nodes_i = {strcat('LustMathLib_', 'abs_int')};
    % format = 'node rem_int_int (x, y: int)\nreturns(z:int);\nlet\n\t';
    % format = [format, 'z = if (y = 0 or x = 0) then 0\n\t\telse\n\t\t (x mod y) - (if (x mod y <> 0 and x <= 0) then abs_int(y) else 0);\ntel\n\n'];
    % node = sprintf(format);
    cond = nasa_toLustre.lustreAst.BinaryExpr(...
        nasa_toLustre.lustreAst.BinaryExpr.OR, ...
        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.EQ, nasa_toLustre.lustreAst.VarIdExpr('y'), nasa_toLustre.lustreAst.IntExpr(0)), ...
        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.EQ, nasa_toLustre.lustreAst.VarIdExpr('x'), nasa_toLustre.lustreAst.IntExpr(0)));
    cond2 = nasa_toLustre.lustreAst.BinaryExpr(...
        nasa_toLustre.lustreAst.BinaryExpr.AND, ...
        nasa_toLustre.lustreAst.BinaryExpr( nasa_toLustre.lustreAst.BinaryExpr.NEQ,...
        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MOD, nasa_toLustre.lustreAst.VarIdExpr('x'), nasa_toLustre.lustreAst.VarIdExpr('y')),...
        nasa_toLustre.lustreAst.IntExpr(0)), ...
        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.LTE, nasa_toLustre.lustreAst.VarIdExpr('x'), nasa_toLustre.lustreAst.IntExpr(0)));
    elseExp =  nasa_toLustre.lustreAst.BinaryExpr(...
        nasa_toLustre.lustreAst.BinaryExpr.MINUS, ...
        nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.MOD, nasa_toLustre.lustreAst.VarIdExpr('x'), nasa_toLustre.lustreAst.VarIdExpr('y')),...
        nasa_toLustre.lustreAst.IteExpr(cond2, ...
        nasa_toLustre.lustreAst.NodeCallExpr('abs_int',  nasa_toLustre.lustreAst.VarIdExpr('y')),...
        nasa_toLustre.lustreAst.IntExpr(0),...
        true)...
        );
    rhs = nasa_toLustre.lustreAst.IteExpr(cond, nasa_toLustre.lustreAst.IntExpr(0), elseExp);
    bodyElts{1} = nasa_toLustre.lustreAst.LustreEq(...
        nasa_toLustre.lustreAst.VarIdExpr('z'), ...
        rhs...
        );
    node = nasa_toLustre.lustreAst.LustreNode();
    node.setName('rem_int_int');
    node.setInputs({nasa_toLustre.lustreAst.LustreVar('x', 'int'), nasa_toLustre.lustreAst.LustreVar('y', 'int')});
    node.setOutputs(nasa_toLustre.lustreAst.LustreVar('z', 'int'));
    node.setBodyEqs(bodyElts);
    node.setIsMain(false);
end
