classdef BinaryExpr < LustreExpr
    %BinaryExpr
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        op;
        left;
        right;
        withPar; %with parentheses
    end
    properties(Constant)
        OR = 'or';
        AND = 'and';
        XOR = 'xor';
        IMPLIES = '=>';
        PLUS = '+';
        MINUS = '-';
        MULTIPLY = '*';
        DIVIDE = '/';
        MOD = 'mod';
        EQ = '=';
        NEQ = '<>';
        GTE = '>=';
        LTE = '<=';
        GT = '>';
        LT = '<';
        ARROW = '->';
        MERGEARROW = '->'; % the arrow used in Merge expressions to indicate the clock Value
        WHEN = 'when';
    end
    methods
        function obj = BinaryExpr(op, left, right, withPar)
            obj.op = op;
            obj.left = left;
            obj.right = right;
            if exist('withPar', 'var')
                obj.withPar = withPar;
            else
                obj.withPar = true;
            end
        end
        
        function new_obj = deepCopy(obj)
            new_obj = BinaryExpr(obj.op,...
                obj.left.deepCopy(),...
                obj.right.deepCopy(), ...
                obj.withPar);
        end
        
        function new_obj = changeArrowExp(obj, cond)
            if isequal(obj.op, BinaryExpr.ARROW)
                new_obj = IteExpr(cond, ...
                    obj.left.changeArrowExp(cond),...
                    obj.right.changeArrowExp(cond), ...
                    true);
            else
                new_obj = BinaryExpr(obj.op,...
                    obj.left.changeArrowExp(cond),...
                    obj.right.changeArrowExp(cond), ...
                    obj.withPar);
            end
        end
        
        function code = print(obj, backend)
            code = obj.print_lustrec(backend);
        end
        function code = print_lustrec(obj, backend)
            if iscell(obj.left) && numel(obj.left) == 1
                obj.left = obj.left{1};
            end
            if iscell(obj.right) && numel(obj.right) == 1
                obj.right = obj.right{1};
            end
            try
                if obj.withPar
                    code = sprintf('(%s %s %s)', ...
                        obj.left.print(backend),...
                        obj.op, ...
                        obj.right.print(backend));
                else
                    code = sprintf('%s %s %s', ...
                        obj.left.print(backend),...
                        obj.op, ...
                        obj.right.print(backend));
                end
            catch me
                me
            end
        end
        
        function code = print_kind2(obj)
            code = obj.print_lustrec(BackendType.KIND2);
        end
        function code = print_zustre(obj)
            code = obj.print_lustrec(BackendType.ZUSTRE);
        end
        function code = print_jkind(obj)
            code = obj.print_lustrec(BackendType.JKIND);
        end
        function code = print_prelude(obj)
            code = obj.print_lustrec(BackendType.PRELUDE);
        end
    end
    
    
    methods(Static)
        % Given many args, this function return the binary operation
        % applied on all arguments.
        function exp = BinaryMultiArgs(op, args, isFirstTime)
            if nargin < 3
                isFirstTime = 1;
            end
            if isempty(args) || numel(args) == 1
                if iscell(args)
                    exp = args{1};
                else
                    exp = args;
                end
            elseif numel(args) == 2
                exp = BinaryExpr(op, ...
                    args{1}, ...
                    args{2},...
                    false);
                if isFirstTime
                    exp = ParenthesesExpr(exp);
                end
            else
                exp = BinaryExpr(op, ...
                    args{1}, ...
                    BinaryExpr.BinaryMultiArgs(op, args(2:end), false), ...
                    false);
                if isFirstTime
                    exp = ParenthesesExpr(exp);
                end
            end
        end
    end
end

