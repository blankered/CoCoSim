function [node, external_nodes, opens, abstractedNodes] = getIntToInt(dt)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    import nasa_toLustre.lustreAst.*
    opens = {};
    abstractedNodes = {};
    v_max = double(intmax(dt));% we need v_max as double variable
    v_min = double(intmin(dt));% we need v_min as double variable
    nb_int = (v_max - v_min + 1);
    node_name = strcat('int_to_', dt);
    
    % format = 'node %s (x: int)\nreturns(y:int);\nlet\n\t';
    % format = [format, 'y= if x > v_max then v_min + rem_int_int((x - v_max - 1),nb_int) \n\t'];
    % format = [format, 'else if x < v_min then v_max + rem_int_int((x - (v_min) + 1),nb_int) \n\telse x;\ntel\n\n'];
    % node = sprintf(format, node_name, v_max, v_min, v_max, nb_int,...
    %     v_min, v_max, v_min, nb_int);
    
    conds{1} = BinaryExpr(BinaryExpr.GT, ...
        VarIdExpr('x'), ...
        IntExpr(v_max));
    conds{2} = BinaryExpr(BinaryExpr.LT, ...
        VarIdExpr('x'), ...
        IntExpr(v_min));
    %  %d + rem_int_int((x - %d - 1),%d)
    thens{1} = BinaryExpr(...
        BinaryExpr.PLUS, ...
        IntExpr(v_min),...
        NodeCallExpr('rem_int_int',...
        {BinaryExpr.BinaryMultiArgs(BinaryExpr.MINUS,...
        {VarIdExpr('x'), IntExpr(v_max), IntExpr(1)}),...
        IntExpr(nb_int)}));
    %d + rem_int_int((x - (%d) + 1),%d)
    if v_min == 0, neg_vmin = 0; else, neg_vmin = -v_min; end
    thens{2} = BinaryExpr(...
        BinaryExpr.PLUS, ...
        IntExpr(v_max),...
        NodeCallExpr('rem_int_int', ...
        {BinaryExpr.BinaryMultiArgs(...
        BinaryExpr.PLUS,...
        {VarIdExpr('x'),...
        IntExpr(neg_vmin),...
        IntExpr(1)}),...
        IntExpr(nb_int)}));
    thens{3} = VarIdExpr('x');
    bodyElts{1} = LustreEq(...
        VarIdExpr('y'), ...
        IteExpr.nestedIteExpr(conds, thens));
    
    
    node = LustreNode();
    node.setName(node_name);
    node.setInputs(LustreVar('x', 'int'));
    node.setOutputs(LustreVar('y', 'int'));
    node.setBodyEqs(bodyElts);
    node.setIsMain(false);
    external_nodes = {strcat('LustMathLib_', 'rem_int_int')};
    
end