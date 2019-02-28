classdef IteExpr < nasa_toLustre.lustreAst.LustreExpr
    %IteExpr
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        condition;
        thenExpr;
        ElseExpr;
        OneLine;% to print it in one line
    end
    
    methods
        function obj = IteExpr(condition, thenExpr, ElseExpr, OneLine)
            if iscell(condition)
                obj.condition = condition{1};
            else
                obj.condition = condition;
            end
            if iscell(thenExpr)
                obj.thenExpr = thenExpr{1};
            else
                obj.thenExpr = thenExpr;
            end
            if iscell(ElseExpr)
                obj.ElseExpr = ElseExpr{1};
            else
                obj.ElseExpr = ElseExpr;
            end
            if nargin < 4
                obj.OneLine = false;
            else
                obj.OneLine = OneLine;
            end
        end
        %% getters
        function c = getCondition(obj)
            c = obj.condition;
        end
        function c = getThenExpr(obj)
            c = obj.thenExpr;
        end
        function c = getElseExpr(obj)
            c = obj.ElseExpr;
        end
        
        %%
        function new_obj = deepCopy(obj)
            new_obj = nasa_toLustre.lustreAst.IteExpr(...
                obj.condition.deepCopy(),...
                obj.thenExpr.deepCopy(),...
                obj.ElseExpr.deepCopy(),...
                obj.OneLine);
        end
        
        %% simplify expression
        function new_obj = simplify(obj)
            import nasa_toLustre.lustreAst.*
            new_cond = obj.condition.simplify();
            new_then = obj.thenExpr.simplify();
            new_else = obj.ElseExpr.simplify();
            % simplify trivial if-and-else
            % if true then x else y => x
            if isa(obj.condition, 'BooleanExpr')
                if obj.condition.getValue()
                    new_obj = new_then;
                else
                    new_obj = new_else;
                end
                return;
                
            end
            new_obj = nasa_toLustre.lustreAst.IteExpr(new_cond, new_then, new_else, obj.OneLine);
            
        end
        
         %% substituteVars 
        function new_obj = substituteVars(obj, oldVar, newVar)
            new_obj = nasa_toLustre.lustreAst.IteExpr(...
                obj.condition.substituteVars(oldVar, newVar),...
                obj.thenExpr.substituteVars(oldVar, newVar),...
                obj.ElseExpr.substituteVars(oldVar, newVar),...
                obj.OneLine);
        end
        %% This function is used in substitute vars in LustreNode
        function all_obj = getAllLustreExpr(obj)
            all_obj = [...
                {obj.condition}; obj.condition.getAllLustreExpr();...
                {obj.thenExpr}; obj.thenExpr.getAllLustreExpr();...
                {obj.ElseExpr}; obj.ElseExpr.getAllLustreExpr()];
        end
        
        %% nbOccurance
        function nb_occ = nbOccuranceVar(obj, var)
            nb_occ = obj.condition.nbOccuranceVar(var) ...
                + obj.thenExpr.nbOccuranceVar(var)...
                + obj.ElseExpr.nbOccuranceVar(var);
        end
        
        %% This functions are used for ForIterator block
        function [new_obj, varIds] = changePre2Var(obj)
            [cond, vcondId] = obj.condition.changePre2Var();
            [then, thenCondId] = obj.thenExpr.changePre2Var();
            [elseE, elseCondId] = obj.ElseExpr.changePre2Var();
            varIds = [vcondId, thenCondId, elseCondId];
            new_obj = nasa_toLustre.lustreAst.IteExpr(cond, then, elseE, obj.OneLine);
        end
        function new_obj = changeArrowExp(obj, cond)
            new_obj = nasa_toLustre.lustreAst.IteExpr(obj.condition.changeArrowExp(cond),...
                obj.thenExpr.changeArrowExp(cond),...
                obj.ElseExpr.changeArrowExp(cond),...
                obj.OneLine);
        end
        %% This function is used by Stateflow function SF_To_LustreNode.getPseudoLusAction
        function varIds = GetVarIds(obj)
            vcondId = obj.condition.GetVarIds();
            thenCondId = obj.thenExpr.GetVarIds();
            elseCondId = obj.ElseExpr.GetVarIds();
            varIds = [vcondId, thenCondId, elseCondId];
        end
        % This function is used in Stateflow compiler to change from imperative
        % code to Lustre
        function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft)
            new_obj = nasa_toLustre.lustreAst.IteExpr(obj.condition.pseudoCode2Lustre(outputs_map, false),...
                obj.thenExpr.pseudoCode2Lustre(outputs_map, false),...
                obj.ElseExpr.pseudoCode2Lustre(outputs_map, false),...
                obj.OneLine);
        end
        function [new_obj, outputs_map] = pseudoCode2Lustre_OnlyElseExp(obj, outputs_map, old_outputs_map)
            new_obj = nasa_toLustre.lustreAst.IteExpr(obj.condition.pseudoCode2Lustre(old_outputs_map, false),...
                obj.thenExpr.pseudoCode2Lustre(old_outputs_map, false),...
                obj.ElseExpr.pseudoCode2Lustre(outputs_map, false),...
                obj.OneLine);
        end
        %% This function is used by KIND2 LustreProgram.print()
        function nodesCalled = getNodesCalled(obj)
            nodesCalled = {};
            function addNodes(objects)
                nodesCalled = [nodesCalled, objects.getNodesCalled()];
            end
            addNodes(obj.condition);
            addNodes(obj.thenExpr);
            addNodes(obj.ElseExpr);
        end
        
        
        
        %%
        function code = print(obj, backend)
            %TODO: check if LUSTREC syntax is OK for the other backends.
            code = obj.print_lustrec(backend);
        end
        
        
        function code = print_lustrec(obj, backend)
            if obj.OneLine
                code = sprintf('(if %s then %s else %s)', ...
                    obj.condition.print(backend),...
                    obj.thenExpr.print(backend), ...
                    obj.ElseExpr.print(backend));
            else
                code = sprintf('if %s then\n\t\t%s\n\t    else %s', ...
                    obj.condition.print(backend),...
                    obj.thenExpr.print(backend), ...
                    obj.ElseExpr.print(backend));
            end
            
        end
        
        function code = print_kind2(obj)
            code = obj.print_lustrec(LusBackendType.KIND2);
        end
        function code = print_zustre(obj)
            code = obj.print_lustrec(LusBackendType.ZUSTRE);
        end
        function code = print_jkind(obj)
            code = obj.print_lustrec(LusBackendType.JKIND);
        end
        function code = print_prelude(obj)
            code = obj.print_lustrec(LusBackendType.PRELUDE);
        end
    end
    methods(Static)
        % This function return the IteExpr object
        % representing nested if-else.
        exp = nestedIteExpr(conds, thens)
        
        [conds, thens] = getCondsThens(exp)
    end
end

