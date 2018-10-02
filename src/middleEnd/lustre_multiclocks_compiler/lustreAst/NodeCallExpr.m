classdef NodeCallExpr < LustreExpr
    %NodeCallExpr
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        nodeName;
        args;
    end
    
    methods 
        function obj = NodeCallExpr(nodeName, args)
            obj.nodeName = nodeName;
            obj.args = args;
        end
        
        function args = getArgs(obj)
            args = obj.args;
        end
        function  setArgs(obj, arg)
            obj.args = arg;
        end
        
         function new_obj = deepCopy(obj)
            if iscell(obj.args)
                new_args = cellfun(@(x) x.deepCopy(), obj.args, 'UniformOutput', 0);
            else
                new_args = obj.args.deepCopy();
            end
            new_obj = NodeCallExpr(obj.nodeName, new_args);
         end
         function new_obj = changeArrowExp(obj, cond)
            if iscell(obj.args)
                new_args = cellfun(@(x) x.changeArrowExp(cond), obj.args, 'UniformOutput', 0);
            else
                new_args = obj.args.changeArrowExp(cond);
            end
            new_obj = NodeCallExpr(obj.nodeName, new_args);
         end
        
        function code = print(obj, backend)
            %TODO: check if LUSTREC syntax is OK for the other backends.
            code = obj.print_lustrec(backend);
        end
        
        function code = print_lustrec(obj, backend)
            
            code = sprintf('%s(%s)', ...
                obj.nodeName, ...
                NodeCallExpr.getArgsStr(obj.args, backend));
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
        function args_str = getArgsStr(args, backend)
            if numel(args) > 1 || iscell(args)
                if iscell(args{1})
                    args_cell = cellfun(@(x) x{1}.print(backend), args, 'UniformOutput', 0);
                else
                    args_cell = cellfun(@(x) x.print(backend), args, 'UniformOutput', 0);
                end
                args_str = MatlabUtils.strjoin(args_cell, ', ');
            elseif numel(args) == 1
                args_str = args.print(backend);
            else
                args_str = '';
            end
        end
        function new_callObj = NodeCallExpr.deepCopy(callObj)
            
        end
    end
end

