function [code, exp_dt, dim] = circshiftFun_To_Lustre(tree, args)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    [X, X_dt, X_dim] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(1),args);
    args.expected_lusDT = 'int';
    [Y, ~, ~] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(2),args);
    
    X_reshp = reshape(X, X_dim);
    if isempty(Y) || ~isa(Y{1}, 'nasa_toLustre.lustreAst.RealExpr') ...
            || (length(Y) == 2 && ~isa(Y{2}, 'nasa_toLustre.lustreAst.RealExpr'))
         ME = MException('COCOSIM:TREE2CODE', ...
            'Second argument in function circshift in expression "%s" should be a constant.',...
            tree.text);
        throw(ME);
    end
    if numel(Y) == 1
        Y = Y{1}.getValue();
    elseif numel(Y) == 2
        Y = [Y{1}.getValue() Y{2}.getValue()];
    else
        % TODO support more than 2 dim
        ME = MException('COCOSIM:TREE2CODE', ...
            'Function circshift in expression "%s" second argument is %d-dimension, more than 2 is not supported.',...
            tree.text, numel(Y));
        throw(ME);
    end
    
    if (length(tree.parameters) > 2)
        args.expected_lusDT = 'int';
        [d, ~, ~] = nasa_toLustre.utils.MExpToLusAST.expression_To_Lustre(tree.parameters(3),args);
        code1 = circshift(X_reshp, Y, d{1}.value);
    else
        code1 = circshift(X_reshp, Y);
    end
    exp_dt = X_dt;
    code = reshape(code1, [1 prod(X_dim)]);
    dim = X_dim;
end

