classdef StateflowState_To_Lustre
    %StateflowState_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods(Static)
        %%
        function options = getUnsupportedOptions(state, varargin)
            options = {};
        end
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
        
        %% State Actions and DefaultTransitions Nodes
        function  [external_nodes, external_libraries ] = ...
                write_ActionsNodes(state, data_map)
            external_nodes = {};
            external_libraries = {};
            % Create transitions actions as external nodes that will be called by the states nodes.
            function addNodes(t, isDefaultTrans)
                % Transition actions
                [transition_nodes_j, external_libraries_j ] = ...
                    StateflowTransition_To_Lustre.get_Actions(t, data_map, state, ...
                    isDefaultTrans);
                external_nodes = [external_nodes, transition_nodes_j];
                external_libraries = [external_libraries, external_libraries_j];
            end
            
            % Default Transitions
            T = state.Composition.DefaultTransitions;
            for i=1:numel(T)
                addNodes(T{i}, true)
            end
            [node,  external_libraries_i] = ...
                StateflowTransition_To_Lustre.get_DefaultTransitionsNode(state, data_map);
            if ~isempty(node)
                external_nodes{end+1} = node;
            end
            external_libraries = [external_libraries, external_libraries_i];
            
            % Create State actions as external nodes that will be called by the states nodes.
            [action_nodes,  external_libraries_i] = ...
                StateflowState_To_Lustre.get_state_actions(state, data_map);
            external_nodes = [external_nodes, action_nodes];
            external_libraries = [external_libraries, external_libraries_i];
            
            
            T = state.InnerTransitions;
            for i=1:numel(T)
                addNodes(T{i}, false)
            end
            T = state.OuterTransitions;
            for i=1:numel(T)
                addNodes(T{i}, false)
            end
            
        end
        
        %% InnerTransitions and  OuterTransitions Nodes
        function  [external_nodes, external_libraries ] = ...
                write_TransitionsNodes(state, data_map)
            external_nodes = {};
            [node, external_libraries] = ...
                StateflowTransition_To_Lustre.get_InnerTransitionsNode(state, data_map);
            if ~isempty(node)
                external_nodes{end+1} = node;
            end
            
            [node,  external_libraries_i] = ...
                StateflowTransition_To_Lustre.get_OuterTransitionsNode(state, data_map);
            if ~isempty(node)
                external_nodes{end+1} = node;
            end
            external_libraries = [external_libraries, external_libraries_i];
        end
        
        %% State Node
        function main_node  = write_StateNode(state)
            global SF_STATES_NODESAST_MAP;
            main_node = {};
            
            [outputs, inputs, body, variables] = ...
                StateflowState_To_Lustre.write_state_body(state);
            if isempty(body)
                %no code is required
                return;
            end
            %create the node
            node_name = ...
                StateflowState_To_Lustre.getStateNodeName(state);
            main_node = LustreNode();
            main_node.setName(node_name);
            comment = LustreComment(...
                sprintf('Main node of state %s',...
                state.Origin_path), true);
            main_node.setMetaInfo(comment);
            main_node.setBodyEqs(body);
            outputs = LustreVar.uniqueVars(outputs);
            inputs = LustreVar.uniqueVars(inputs);
            if isempty(inputs)
                inputs{1} = ...
                    LustreVar(SF_To_LustreNode.virtualVarStr(), 'bool');
            elseif numel(inputs) > 1
                inputs = LustreVar.removeVar(inputs, SF_To_LustreNode.virtualVarStr());
            end
            main_node.setOutputs(outputs);
            main_node.setInputs(inputs);
            main_node.setLocalVars(variables);
            SF_STATES_NODESAST_MAP(node_name) = main_node;
        end
        
        %% Chart Node
        function [main_node, external_nodes]  = write_ChartNode(parent, blk, chart, dataAndEvents, events)
            global SF_STATES_NODESAST_MAP;
            external_nodes = {};
            Scopes = cellfun(@(x) x.Scope, ...
                events, 'UniformOutput', false);
            inputEvents = SF_To_LustreNode.orderObjects(...
                events(strcmp(Scopes, 'Input')), 'Port');
            if ~isempty(inputEvents)
                %create a node that do the multi call for each event
                eventNode  = ...
                    StateflowState_To_Lustre.write_ChartNodeWithEvents(...
                    chart, inputEvents);
                external_nodes{1} = eventNode;
            end
            [outputs, inputs, variable, body] = ...
                StateflowState_To_Lustre.write_chart_body(parent, blk, chart, dataAndEvents, inputEvents);
           
            %create the node
            node_name = ...
                SLX2LusUtils.node_name_format(blk);
            main_node = LustreNode();
            main_node.setName(node_name);
            comment = LustreComment(sprintf('Chart Node: %s', chart.Origin_path),...
                true);
            main_node.setMetaInfo(comment);
            main_node.setBodyEqs(body);            
            main_node.setOutputs(outputs);
            if isempty(inputs)
                inputs{1} = ...
                    LustreVar(SF_To_LustreNode.virtualVarStr(), 'bool');
            end
            main_node.setInputs(inputs);
            
            main_node.setLocalVars(variable);
            SF_STATES_NODESAST_MAP(node_name) = main_node;
        end
        
        function main_node  = write_ChartNodeWithEvents(chart, inputEvents)
            global SF_STATES_NODESAST_MAP;
            main_node = {};
            
            [outputs, inputs, body] = ...
                StateflowState_To_Lustre.write_ChartNodeWithEvents_body(chart, inputEvents);
            if isempty(body)
                %no code is required
                return;
            end
            %create the node
            node_name = ...
                StateflowState_To_Lustre.getChartEventsNodeName(chart);
            main_node = LustreNode();
            main_node.setName(node_name);
            comment = LustreComment(...
                sprintf('Executing Events of state %s',...
                chart.Origin_path), true);
            main_node.setMetaInfo(comment);
            main_node.setBodyEqs(body);
            outputs = LustreVar.uniqueVars(outputs);
            inputs = LustreVar.uniqueVars(inputs);
            if isempty(inputs)
                inputs{1} = ...
                    LustreVar(SF_To_LustreNode.virtualVarStr(), 'bool');
            elseif numel(inputs) > 1
                inputs = LustreVar.removeVar(inputs, SF_To_LustreNode.virtualVarStr());
            end
            main_node.setOutputs(outputs);
            main_node.setInputs(inputs);
            SF_STATES_NODESAST_MAP(node_name) = main_node;
        end
        
        
        %% State actions
        function [action_nodes,  external_libraries] = ...
                get_state_actions(state, data_map)
            action_nodes = {};
            %write_entry_action
            [entry_action_node, external_libraries] = ...
                StateflowState_To_Lustre.write_entry_action(state, data_map);
            if ~isempty(entry_action_node)
                action_nodes{end+1} = entry_action_node;
            end
            %write_exit_action
            [exit_action_node, ext_lib] = ...
                StateflowState_To_Lustre.write_exit_action(state, data_map);
            if ~isempty(exit_action_node)
                action_nodes{end+1} = exit_action_node;
            end
            %write_during_action
            external_libraries = [external_libraries, ext_lib];
            [during_action_node, ext_lib2] = ...
                StateflowState_To_Lustre.write_during_action(state, data_map);
            if ~isempty(during_action_node)
                action_nodes{end+1} = during_action_node;
            end
            external_libraries = [external_libraries, ext_lib2];
        end
        %% ENTRY ACTION
        function [main_node, external_libraries] = ...
                write_entry_action(state, data_map)
            global SF_STATES_NODESAST_MAP SF_STATES_PATH_MAP;
            external_libraries = {};
            main_node = {};
            body = {};
            outputs = {};
            inputs = {};
            %set state as active
            parentName = fileparts(state.Path);
            isChart = false;
            if isempty(parentName)
                %main chart
                isChart = true;
            end
            if ~isChart
                if ~isKey(SF_STATES_PATH_MAP, parentName)
                    ME = MException('COCOSIM:STATEFLOW', ...
                        'COMPILER ERROR: Not found state "%s" in SF_STATES_PATH_MAP', parentName);
                    throw(ME);
                end
                state_parent = SF_STATES_PATH_MAP(parentName);
                idParentName = StateflowState_To_Lustre.getStateIDName(state_parent);
                [stateEnumType, childName] = ...
                    StateflowState_To_Lustre.addStateEnum(state_parent, state);
                body{1} = LustreComment('set state as active');
                body{2} = LustreEq(VarIdExpr(idParentName), childName);
                outputs{1} = LustreVar(idParentName, stateEnumType);
                
                %isInner variable that tells if the transition that cause this
                %exit action is an inner Transition
                isInner = VarIdExpr(StateflowState_To_Lustre.isInnerStr());
                inputs{end + 1} = LustreVar(isInner, 'bool');
                %actions code
                actions = SFIRPPUtils.split_actions(state.Actions.Entry);
                nb_actions = numel(actions);
                for i=1:nb_actions
                    try
                        [lus_action, outputs_i, inputs_i, external_libraries_i] = ...
                            getPseudoLusAction(actions{i}, data_map);
                        if isa(lus_action, 'LustreEq')
                            body{end+1} = LustreEq(lus_action.getLhs(), ...
                                IteExpr(UnaryExpr(UnaryExpr.NOT, isInner), ...
                                lus_action.getRhs(), lus_action.getLhs()));
                            outputs = [outputs, outputs_i];
                            inputs = [inputs, inputs_i, outputs_i];
                            external_libraries = [external_libraries, external_libraries_i];
                        elseif ~isempty(lus_action)
                            display_msg(sprintf(...
                                'Action "%s" in state %s should be an assignement (e.g. outputs = f(inputs))',...
                                actions{i}, state.Origin_path), MsgType.ERROR, 'write_entry_action', '');
                        end
                    catch me
                        if strcmp(me.identifier, 'COCOSIM:STATEFLOW')
                            display_msg(me.message, MsgType.ERROR, 'write_entry_action', '');
                        else
                            display_msg(me.getReport(), MsgType.DEBUG, 'write_entry_action', '');
                        end
                        display_msg(sprintf('Entry Action failed for state %s', ...
                            state.Origin_path),...
                            MsgType.ERROR, 'write_entry_action', '');
                    end
                end
            end
            %write children states entry action
            [actions, outputs_i, inputs_i] = ...
                StateflowState_To_Lustre.write_children_actions(state, 'Entry');
            body = [body, actions];
            outputs = [outputs, outputs_i];
            inputs = [inputs, inputs_i];
            %create the node
            act_node_name = ...
                StateflowState_To_Lustre.getEntryActionNodeName(state);
            main_node = LustreNode();
            main_node.setName(act_node_name);
            comment = LustreComment(...
                sprintf('Entry action of state %s',...
                state.Origin_path), true);
            main_node.setMetaInfo(comment);
            main_node.setBodyEqs(body);
            outputs = LustreVar.uniqueVars(outputs);
            inputs = LustreVar.uniqueVars(inputs);
            if isempty(inputs)
                inputs{1} = ...
                    LustreVar(SF_To_LustreNode.virtualVarStr(), 'bool');
            elseif numel(inputs) > 1
                inputs = LustreVar.removeVar(inputs, SF_To_LustreNode.virtualVarStr());
            end
            main_node.setOutputs(outputs);
            main_node.setInputs(inputs);
            SF_STATES_NODESAST_MAP(act_node_name) = main_node;
        end
        %% EXIT ACTION
        function [main_node, external_libraries] = ...
                write_exit_action(state, data_map)
            global SF_STATES_NODESAST_MAP SF_STATES_PATH_MAP;
            external_libraries = {};
            main_node = {};
            body = {};
            outputs = {};
            inputs = {};
            variables = {};
            parentName = fileparts(state.Path);
            if isempty(parentName)
                %main chart
                return;
            end
            %get stateEnumType
            idStateName = StateflowState_To_Lustre.getStateIDName(state);
            [stateEnumType, stateInactive] = ...
                StateflowState_To_Lustre.addStateEnum(state, [], ...
                false, false, true);
            
            % history junctions
            junctions = state.Composition.SubJunctions;
            typs = cellfun(@(x) x.Type, junctions, 'UniformOutput', false);
            hjunctions = junctions(strcmp(typs, 'HISTORY'));
            if ~isempty(hjunctions)
                variables{end+1} = LustreVar('_HistoryJunction', stateEnumType);
                body{end+1} = LustreEq(VarIdExpr('_HistoryJunction'),...
                    VarIdExpr(idStateName));
            end
            %write children states exit action
            [actions, outputs_i, inputs_i] = ...
                StateflowState_To_Lustre.write_children_actions(state, 'Exit');
            body = [body, actions];
            outputs = [outputs, outputs_i];
            inputs = [inputs, inputs_i];
            
            %isInner variable that tells if the transition that cause this
            %exit action is an inner Transition
            isInner = VarIdExpr(StateflowState_To_Lustre.isInnerStr());
            
            %actions code
            actions = SFIRPPUtils.split_actions(state.Actions.Exit);
            nb_actions = numel(actions);
            for i=1:nb_actions
                try
                    [lus_action, outputs_i, inputs_i, external_libraries_i] = ...
                        getPseudoLusAction(actions{i}, data_map);
                    if isa(lus_action, 'LustreEq')
                        body{end+1} = LustreEq(lus_action.getLhs(), ...
                            IteExpr(UnaryExpr(UnaryExpr.NOT, isInner), ...
                            lus_action.getRhs(), lus_action.getLhs()));
                        outputs = [outputs, outputs_i];
                        inputs = [inputs, inputs_i, outputs_i];
                        external_libraries = [external_libraries, external_libraries_i];
                    elseif ~isempty(lus_action) 
                        display_msg(sprintf(...
                            'Action "%s" in state %s should be an assignement (e.g. outputs = f(inputs))',...
                            actions{i}, state.Origin_path), MsgType.ERROR, 'write_exit_action', '');
                    end
                catch me
                    if strcmp(me.identifier, 'COCOSIM:STATEFLOW')
                        display_msg(me.message, MsgType.ERROR, 'write_exit_action', '');
                    else
                        display_msg(me.getReport(), MsgType.DEBUG, 'write_exit_action', '');
                    end
                    display_msg(sprintf('Exit Action failed for state %s', ...
                        state.Origin_path),...
                        MsgType.ERROR, 'write_exit_action', '');
                end
            end
            
            %set state as inactive
            if ~isKey(SF_STATES_PATH_MAP, parentName)
                ME = MException('COCOSIM:STATEFLOW', ...
                    'COMPILER ERROR: Not found state "%s" in SF_STATES_PATH_MAP', parentName);
                throw(ME);
            end
            
            
            state_parent = SF_STATES_PATH_MAP(parentName);
            idParentName = StateflowState_To_Lustre.getStateIDName(state_parent);
            [parentEnumType, parentInactive] = ...
                    StateflowState_To_Lustre.addStateEnum(state_parent, [], ...
                    false, false, true);
            body{end + 1} = LustreComment('set state as inactive');
            % idParentName = if (not isInner) then 0 else idParentName;
            body{end + 1} = LustreEq(VarIdExpr(idParentName), ...
                IteExpr(UnaryExpr(UnaryExpr.NOT, isInner), ...
                parentInactive, VarIdExpr(idParentName)));
            outputs{end + 1} = LustreVar(idParentName, parentEnumType);
            inputs{end + 1} = LustreVar(idParentName, parentEnumType);
            % add isInner input
            inputs{end + 1} = LustreVar(isInner, 'bool');
            % set state children as inactive
            
            if ~isempty(state.Composition.Substates)  
                if ~isempty(hjunctions)
                    body{end+1} = LustreEq(VarIdExpr(idStateName), ...
                        VarIdExpr('_HistoryJunction'));
                else
                    body{end+1} = LustreEq(VarIdExpr(idStateName), stateInactive);
                    outputs{end+1} = LustreVar(idStateName, stateEnumType);
                end
            end
            
            %create the node
            act_node_name = ...
                StateflowState_To_Lustre.getExitActionNodeName(state);
            main_node = LustreNode();
            main_node.setName(act_node_name);
            comment = LustreComment(...
                sprintf('Exit action of state %s',...
                state.Origin_path), true);
            main_node.setMetaInfo(comment);
            main_node.setBodyEqs(body);
            outputs = LustreVar.uniqueVars(outputs);
            inputs = LustreVar.uniqueVars(inputs);
            main_node.setOutputs(outputs);
            main_node.setInputs(inputs);
            SF_STATES_NODESAST_MAP(act_node_name) = main_node;
        end
        function v = isInnerStr()
            v = '_isInner';
        end
        %% DURING ACTION
        function [main_node, external_libraries] = ...
                write_during_action(state, data_map)
            global SF_STATES_NODESAST_MAP;
            external_libraries = {};
            main_node = {};
            body = {};
            outputs = {};
            inputs = {};
            
            parentName = fileparts(state.Path);
            if isempty(parentName)
                %main chart
                return;
            end
            
            %actions code
            actions = SFIRPPUtils.split_actions(state.Actions.During);
            nb_actions = numel(actions);
            
            for i=1:nb_actions
                try
                    [body{end+1}, outputs_i, inputs_i, external_libraries_i] = ...
                        getPseudoLusAction(actions{i}, data_map);
                    outputs = [outputs, outputs_i];
                    inputs = [inputs, inputs_i];
                    external_libraries = [external_libraries, external_libraries_i];
                catch me
                    if strcmp(me.identifier, 'COCOSIM:STATEFLOW')
                        display_msg(me.message, MsgType.ERROR, 'write_during_action', '');
                    else
                        display_msg(me.getReport(), MsgType.DEBUG, 'write_during_action', '');
                    end
                    display_msg(sprintf('During Action failed for state %s', ...
                        state.Origin_path),...
                        MsgType.ERROR, 'write_during_action', '');
                end
            end
            if isempty(body)
                return;
            end
            %create the node
            act_node_name = ...
                StateflowState_To_Lustre.getDuringActionNodeName(state);
            main_node = LustreNode();
            main_node.setName(act_node_name);
            comment = LustreComment(...
                sprintf('During action of state %s',...
                state.Origin_path), true);
            main_node.setMetaInfo(comment);
            main_node.setBodyEqs(body);
            outputs = LustreVar.uniqueVars(outputs);
            inputs = LustreVar.uniqueVars(inputs);
            if isempty(inputs)
                inputs{1} = ...
                    LustreVar(SF_To_LustreNode.virtualVarStr(), 'bool');
            elseif numel(inputs) > 1
                inputs = LustreVar.removeVar(inputs, SF_To_LustreNode.virtualVarStr());
            end
            main_node.setOutputs(outputs);
            main_node.setInputs(inputs);
            SF_STATES_NODESAST_MAP(act_node_name) = main_node;
        end
        
        %% write_children_actions
        function [actions, outputs, inputs] = ...
                write_children_actions(state, actionType)
            actions = {};
            outputs = {};
            inputs = {};
            global SF_STATES_NODESAST_MAP;
            childrenNames = state.Composition.Substates;
            nb_children = numel(childrenNames);
            childrenIDs = state.Composition.States;
            if isequal(state.Composition.Type, 'PARALLEL_AND')
                for i=1:nb_children
                    if isequal(actionType, 'Entry')
                        k=i;
                        action_node_name = ...
                            StateflowState_To_Lustre.getEntryActionNodeName(...
                            childrenNames{k}, childrenIDs{k});
                    else
                        k=nb_children - i + 1;
                        action_node_name = ...
                            StateflowState_To_Lustre.getExitActionNodeName(...
                            childrenNames{k}, childrenIDs{k});
                    end
                    if ~isKey(SF_STATES_NODESAST_MAP, action_node_name)
                        ME = MException('COCOSIM:STATEFLOW', ...
                            'COMPILER ERROR: Not found node name "%s" in SF_STATES_NODESAST_MAP', ...
                            action_node_name);
                        throw(ME);
                    end
                    actionNodeAst = SF_STATES_NODESAST_MAP(action_node_name);
                    [call, oututs_Ids] = actionNodeAst.nodeCall(...
                        true, BooleanExpr(false));
                    actions{end+1} = LustreEq(oututs_Ids, call);
                    outputs = [outputs, actionNodeAst.getOutputs()];
                    inputs = [inputs, actionNodeAst.getInputs()];
                end
            else
                concurrent_actions = {};
                idStateVar = VarIdExpr(...
                    StateflowState_To_Lustre.getStateIDName(state));
                [stateEnumType, stateInactiveEnum] = ...
                    StateflowState_To_Lustre.addStateEnum(state, [], ...
                    false, false, true);
                if nb_children >= 1
                    inputs{end+1} = LustreVar(idStateVar, stateEnumType);
                end
                default_transition = state.Composition.DefaultTransitions;
                if isequal(actionType, 'Entry')...
                        && ~isempty(default_transition)
                    % we need to get the default condition code, as the
                    % default transition decides what sub-state to enter while.
                    % entering the state. This is the case where stateId ==
                    % 0;
                    %get_initial_state_code
                    node_name = ...
                        StateflowState_To_Lustre.getStateDefaultTransNodeName(state);
                    cond = BinaryExpr(BinaryExpr.EQ, ...
                        idStateVar, stateInactiveEnum);
                    if isKey(SF_STATES_NODESAST_MAP, node_name)
                        actionNodeAst = SF_STATES_NODESAST_MAP(node_name);
                        [call, oututs_Ids] = actionNodeAst.nodeCall();
                        
                        concurrent_actions{end+1} = LustreEq(oututs_Ids, ...
                            IteExpr(cond, call, TupleExpr(oututs_Ids)));
                        outputs = [outputs, actionNodeAst.getOutputs()];
                        inputs = [inputs, actionNodeAst.getOutputs()];
                        inputs = [inputs, actionNodeAst.getInputs()];
                    else
                        ME = MException('COCOSIM:STATEFLOW', ...
                            'COMPILER ERROR: Not found node name "%s" in SF_STATES_NODESAST_MAP', ...
                            node_name);
                        throw(ME);
                    end
                end
                isOneChildEntry = isequal(actionType, 'Entry') ...
                    && (nb_children == 1) && isempty(default_transition);
                for i=1:nb_children
                    % TODO: optimize the number of calls for nodes with the same output signature
                    if isequal(actionType, 'Entry')
                        action_node_name = ...
                            StateflowState_To_Lustre.getEntryActionNodeName(...
                            childrenNames{i}, childrenIDs{i});
                    else
                        action_node_name = ...
                            StateflowState_To_Lustre.getExitActionNodeName(...
                            childrenNames{i}, childrenIDs{i});
                    end
                    if ~isKey(SF_STATES_NODESAST_MAP, action_node_name)
                        ME = MException('COCOSIM:STATEFLOW', ...
                            'COMPILER ERROR: Not found node name "%s" in SF_STATES_NODESAST_MAP', ...
                            action_node_name);
                        throw(ME);
                    end
                    actionNodeAst = SF_STATES_NODESAST_MAP(action_node_name);
                    [call, oututs_Ids] = actionNodeAst.nodeCall(...
                        true, BooleanExpr(false));
                    if isOneChildEntry
                        concurrent_actions{end+1} = LustreEq(oututs_Ids, call);
                        outputs = [outputs, actionNodeAst.getOutputs()];
                        inputs = [inputs, actionNodeAst.getInputs()];
                    else
                        childName = SF_To_LustreNode.getUniqueName(...
                            childrenNames{i}, childrenIDs{i});
                        [~, childEnum] = ...
                            StateflowState_To_Lustre.addStateEnum(...
                            state, childName);
                        cond = BinaryExpr(BinaryExpr.EQ, ...
                            idStateVar, childEnum);
                        concurrent_actions{end+1} = LustreEq(oututs_Ids, ...
                            IteExpr(cond, call, TupleExpr(oututs_Ids)));
                        outputs = [outputs, actionNodeAst.getOutputs()];
                        inputs = [inputs, actionNodeAst.getOutputs()];
                        inputs = [inputs, actionNodeAst.getInputs()];
                    end
                    
                end
                if isequal(actionType, 'Entry') ...
                        && nb_children == 0 && ...
                        (~isempty(state.InnerTransitions)...
                        || ~isempty(state.Composition.DefaultTransitions))
                    %State that contains only transitions and junctions
                    %inside
                    [stateEnumType, stateInnerTransEnum] = ...
                        StateflowState_To_Lustre.addStateEnum(state, [], ...
                        true, false, false);
                    concurrent_actions{end+1} = LustreEq(idStateVar,...
                        stateInnerTransEnum);
                    inputs{end+1} = LustreVar(idStateVar, stateEnumType);
                    outputs{end+1} = LustreVar(idStateVar, stateEnumType);
                end
                
                if ~isempty(concurrent_actions)
                    actions{1} = ConcurrentAssignments(concurrent_actions);
                end
            end
        end
        
        %% state body
        function [outputs, inputs, body, variables] = write_state_body(state)
            global SF_STATES_NODESAST_MAP ;%SF_STATES_PATH_MAP;
            outputs = {};
            inputs = {};
            variables = {};
            body = {};
            children_actions = {};
            parentPath = fileparts(state.Path);
            isChart = false;
            if isempty(parentPath)
                isChart = true;
            end
            idStateVar = VarIdExpr(...
                    StateflowState_To_Lustre.getStateIDName(state));
            [idStateEnumType, idStateInactiveEnum] = ...
                    StateflowState_To_Lustre.addStateEnum(state, [], ...
                    false, false, true);    
            if ~isChart
                %parent = SF_STATES_PATH_MAP(parentPath);   
                %1st step: OuterTransition code
                cond_prefix = {};
                outerTransNodeName = ...
                    StateflowState_To_Lustre.getStateOuterTransNodeName(state);
                if isKey(SF_STATES_NODESAST_MAP, outerTransNodeName)
                    nodeAst = SF_STATES_NODESAST_MAP(outerTransNodeName);
                    [call, oututs_Ids] = nodeAst.nodeCall();
                    body{end+1} = LustreEq(oututs_Ids, call);
                    outputs = [outputs, nodeAst.getOutputs()];
                    inputs = [inputs, nodeAst.getInputs()];
                    cond_name = ...
                        StateflowTransition_To_Lustre.getValidPathCondName();
                    if VarIdExpr.ismemberVar(cond_name, oututs_Ids)
                        outputs = LustreVar.removeVar(outputs, cond_name);
                        variables{end+1} = LustreVar(cond_name, 'bool');
                        cond_prefix = UnaryExpr(UnaryExpr.NOT,...
                            VarIdExpr(cond_name));
                    end
                end
                
                %2nd step: During actions
                
                
                during_act_node_name = ...
                    StateflowState_To_Lustre.getDuringActionNodeName(state);
                if isKey(SF_STATES_NODESAST_MAP, during_act_node_name)
                    nodeAst = SF_STATES_NODESAST_MAP(during_act_node_name);
                    
                    [call, oututs_Ids] = nodeAst.nodeCall();
                    if isempty(cond_prefix)
                        body{end+1} = LustreEq(oututs_Ids, call);
                    else
                        body{end+1} = LustreEq(oututs_Ids, ...
                            IteExpr(cond_prefix, call, TupleExpr(oututs_Ids)));
                        inputs = [inputs, nodeAst.getOutputs()];
                    end
                    outputs = [outputs, nodeAst.getOutputs()];
                    inputs = [inputs, nodeAst.getInputs()];
                end
                
                %3rd step: Inner transitions
                innerTransNodeName = ...
                    StateflowState_To_Lustre.getStateInnerTransNodeName(state);
                if isKey(SF_STATES_NODESAST_MAP, innerTransNodeName)
                    nodeAst = SF_STATES_NODESAST_MAP(innerTransNodeName);
                    [call, oututs_Ids] = nodeAst.nodeCall();
                    outputs = [outputs, nodeAst.getOutputs()];
                    inputs = [inputs, nodeAst.getInputs()];
                    cond_name = ...
                        StateflowTransition_To_Lustre.getValidPathCondName();
                    if VarIdExpr.ismemberVar(cond_name, oututs_Ids)
                        outputs = LustreVar.removeVar(outputs, cond_name);
                    end
                    if isempty(cond_prefix)
                        body{end+1} = LustreEq(oututs_Ids, call);
                        if VarIdExpr.ismemberVar(cond_name, oututs_Ids)
                            variables{end+1} = LustreVar(cond_name, 'bool');
                            cond_prefix = UnaryExpr(UnaryExpr.NOT,...
                                VarIdExpr(cond_name));
                        end
                    else
                        if VarIdExpr.ismemberVar(cond_name, oututs_Ids)
                            new_cond_name = strcat(cond_name, '_INNER');
                            variables{end+1} = LustreVar(new_cond_name, 'bool');
                            lhs_oututs_Ids = ...
                                StateflowState_To_Lustre.changeVar(...
                                oututs_Ids, cond_name, new_cond_name);
                            rhs_oututs_Ids = ...
                                StateflowState_To_Lustre.changeVar(...
                                oututs_Ids, cond_name, 'false');
                            body{end+1} = LustreEq(lhs_oututs_Ids, ...
                                IteExpr(cond_prefix, call, TupleExpr(rhs_oututs_Ids)));
                            inputs = [inputs, nodeAst.getOutputs()];
                            inputs = LustreVar.removeVar(inputs, cond_name);
                            %add Inner termination condition
                            cond_prefix = UnaryExpr(UnaryExpr.NOT,...
                                BinaryExpr(BinaryExpr.OR, ...
                                VarIdExpr(cond_name), VarIdExpr(new_cond_name)));
                        else
                            body{end+1} = LustreEq(oututs_Ids, ...
                                IteExpr(cond_prefix, call, TupleExpr(oututs_Ids)));
                            inputs = [inputs, nodeAst.getOutputs()];
                        end
                    end
                end
            else
                
                entry_act_node_name = ...
                    StateflowState_To_Lustre.getEntryActionNodeName(state);
                if isKey(SF_STATES_NODESAST_MAP, entry_act_node_name)
                    nodeAst = SF_STATES_NODESAST_MAP(entry_act_node_name);
                    [call, oututs_Ids] = nodeAst.nodeCall(true, BooleanExpr(false));
                    cond = BinaryExpr(BinaryExpr.EQ,...
                        idStateVar, idStateInactiveEnum);
                    children_actions{end+1} = LustreEq(oututs_Ids, ...
                        IteExpr(cond, call, TupleExpr(oututs_Ids)));
                    outputs = [outputs, nodeAst.getOutputs()];
                    inputs = [inputs, nodeAst.getOutputs()];
                    inputs = [inputs, nodeAst.getInputs()];
                    inputs{end + 1} = LustreVar(idStateVar, idStateEnumType);
                    %remove isInner input from the node inputs
                    inputs_name = cellfun(@(x) x.getId(), ...
                        inputs, 'UniformOutput', false);
                    inputs = inputs(~strcmp(inputs_name, ...
                        StateflowState_To_Lustre.isInnerStr()));
                end
                cond_prefix = BinaryExpr(BinaryExpr.NEQ,...
                    idStateVar, idStateInactiveEnum);
                %cond_prefix = {};
            end
            
            %4th step: execute the active child
            children = StateflowState_To_Lustre.getSubStatesObjects(state);
            number_children = numel(children);
            isParallel = isequal(state.Composition.Type, 'PARALLEL_AND');
            if number_children > 0 && ~isParallel
                inputs{end + 1} = LustreVar(idStateVar, idStateEnumType);
            end
            for i=1:number_children
                child = children{i};
                if isParallel
                    cond = cond_prefix;
                else
                    [~, childEnum] = ...
                        StateflowState_To_Lustre.addStateEnum(state, child);
                    cond = BinaryExpr(BinaryExpr.EQ, ...
                        idStateVar, childEnum);
                    if ~isempty(cond_prefix) && ~isChart
                        cond = ...
                            BinaryExpr(BinaryExpr.AND, cond, cond_prefix);
                    end
                end
                child_node_name = ...
                    StateflowState_To_Lustre.getStateNodeName(child);
                if isKey(SF_STATES_NODESAST_MAP, child_node_name)
                    nodeAst = SF_STATES_NODESAST_MAP(child_node_name);
                    [call, oututs_Ids] = nodeAst.nodeCall();
                    if isempty(cond)
                        children_actions{end+1} = LustreEq(oututs_Ids, call);
                        outputs = [outputs, nodeAst.getOutputs()];
                        inputs = [inputs, nodeAst.getInputs()];
                    else
                        children_actions{end+1} = LustreEq(oututs_Ids, ...
                            IteExpr(cond, call, TupleExpr(oututs_Ids)));
                        outputs = [outputs, nodeAst.getOutputs()];
                        inputs = [inputs, nodeAst.getOutputs()];
                        inputs = [inputs, nodeAst.getInputs()];
                    end
                end
            end
            if ~isempty(children_actions)
                if isParallel
                    if isChart
                        % entry action condition is concurrent with
                        % substates nodes call.
                        body = MatlabUtils.concat(children_actions(2:end),...
                            children_actions(1));
                    else
                        body = [body, children_actions];
                    end
                else
                    body{end+1} = ConcurrentAssignments(children_actions);
                end
            end
        end
        
        %% chart body
        function [outputs, inputs, variables, body] = write_chart_body(...
                parent, blk, chart, dataAndEvents, inputEvents)
            global SF_STATES_NODESAST_MAP;
            body = {};
            variables = {};
            
            %create inputs
            Scopes = cellfun(@(x) x.Scope, ...
                dataAndEvents, 'UniformOutput', false);
            inputsData = SF_To_LustreNode.orderObjects(...
                dataAndEvents(strcmp(Scopes, 'Input')), 'Port');
            inputs = cellfun(@(x) LustreVar(x.Name, x.LusDatatype), ...
                inputsData, 'UniformOutput', false);
            
            %create outputs
            outputsData = SF_To_LustreNode.orderObjects(...
                dataAndEvents(strcmp(Scopes, 'Output')), 'Port');
            outputs = cellfun(@(x) LustreVar(x.Name, x.LusDatatype), ...
                outputsData, 'UniformOutput', false);
            
            %get chart node AST
            if isempty(inputEvents)
                chartNodeName = ...
                    StateflowState_To_Lustre.getStateNodeName(chart);
            else
                chartNodeName = ...
                    StateflowState_To_Lustre.getChartEventsNodeName(chart);
            end
            if ~isKey(SF_STATES_NODESAST_MAP, chartNodeName)
                display_msg(...
                    sprintf('%s not found in SF_STATES_NODESAST_MAP',...
                    chartNodeName), ...
                    MsgType.ERROR, 'StateflowTransition_To_Lustre', '');
                return;
            end
            nodeAst = SF_STATES_NODESAST_MAP(chartNodeName);
            [node_call, nodeCall_outputs_Ids] = nodeAst.nodeCall();
            nodeCall_outputs_Names = cellfun(@(x) x.getId(), ...
                nodeCall_outputs_Ids, 'UniformOutput', false);
            nodeCall_inputs_Ids = node_call.getArgs();
            nodeCall_inputs_Names = cellfun(@(x) x.getId(), ...
                nodeCall_inputs_Ids, 'UniformOutput', false);
            
            %local variables
            for i=1:numel(dataAndEvents)
                d = dataAndEvents{i};
                if isequal(d.Scope, 'Input')
                    continue;
                end
                d_name = d.Name;
                if ~ismember(d_name, nodeCall_outputs_Names) ...
                        &&  ~ismember(d_name, nodeCall_inputs_Names)
                    % not used
                    continue;
                end
                [v, ~, status] = ...
                    Constant_To_Lustre.getValueFromParameter(parent, blk, d.InitialValue);
                if status
                    display_msg(sprintf('InitialOutput %s in Chart %s not found neither in Matlab workspace or in Model workspace',...
                        d.InitialValue, chart.Origin_path), ...
                        MsgType.ERROR, 'Outport_To_Lustre', '');
                    v = 0;
                end
                if isequal(d.Scope, 'Parameter')
                    if isstruct(v) && isfield(v,'Value')
                        v = v.Value;
                    elseif isa(v, 'Simulink.Parameter')
                        v = v.Value;
                    end
                end
                IC_Var = SLX2LusUtils.num2LusExp(v, d.LusDatatype);
                
                if ~isequal(d.Scope, 'Output')
                    variables{end+1,1} = LustreVar(d_name, d.LusDatatype);
                end
                if isequal(d.Scope, 'Output')
                    d_firstName = strcat(d_name, '__1');
                    if ismember(d_name, nodeCall_inputs_Names)
                        body{end+1} = LustreEq(...
                            VarIdExpr(d_firstName), ...
                            BinaryExpr(BinaryExpr.ARROW, IC_Var, ...
                            UnaryExpr(UnaryExpr.PRE, VarIdExpr(d_name))));
                        variables{end+1,1} = LustreVar(d_firstName, d.LusDatatype);
                        nodeCall_inputs_Ids = ...
                            StateflowState_To_Lustre.changeVar(...
                            nodeCall_inputs_Ids, d_name, d_firstName);
                    end
                elseif isequal(d.Scope, 'Local') 
                    d_lastName = strcat(d_name, '__2');
                    if ismember(d_name, nodeCall_outputs_Names)
                        body{end+1} = LustreEq(...
                            VarIdExpr(d_name), ...
                            BinaryExpr(BinaryExpr.ARROW, IC_Var, ...
                            UnaryExpr(UnaryExpr.PRE, VarIdExpr(d_lastName))));
                        variables{end+1,1} = LustreVar(d_lastName, d.LusDatatype);
                        nodeCall_outputs_Ids = ...
                            StateflowState_To_Lustre.changeVar(...
                            nodeCall_outputs_Ids, d_name, d_lastName);
                    else
                        %local variable that was not modified in the chart
                        body{end+1} = LustreEq(VarIdExpr(d_name), IC_Var);
                    end
                elseif isequal(d.Scope, 'Constant')
                    body{end+1} = LustreEq(VarIdExpr(d_name), IC_Var);  
                elseif isequal(d.Scope, 'Parameter')
                    body{end+1} = LustreEq(VarIdExpr(d_name), IC_Var);  
                end
            end
            
            %state IDs
            allVars = [variables; outputs; inputs];
            nodeCall_inputs_Names = cellfun(@(x) x.getId(), ...
                nodeCall_inputs_Ids, 'UniformOutput', false);
            for i=1:numel(nodeCall_inputs_Names)
                v_name = nodeCall_inputs_Names{i};
                if ~VarIdExpr.ismemberVar(v_name, allVars)
                    if MatlabUtils.endsWith(v_name, ...
                            StateflowState_To_Lustre.getStateIDSuffix())
                        %State ID
                        v_type = strrep(v_name, ...
                            StateflowState_To_Lustre.getStateIDSuffix(), ...
                            StateflowState_To_Lustre.getStateEnumSuffix());
                        v_inactive = VarIdExpr(upper(...
                            strrep(v_name, ...
                            StateflowState_To_Lustre.getStateIDSuffix(), ...
                            '_INACTIVE')));
                        variables{end+1,1} = LustreVar(v_name, v_type);
                        if ismember(v_name, nodeCall_outputs_Names)
                            v_lastName = strcat(v_name, '__2');
                            body{end+1} = LustreEq(...
                                VarIdExpr(v_name), ...
                                BinaryExpr(BinaryExpr.ARROW, v_inactive, ...
                                UnaryExpr(UnaryExpr.PRE, VarIdExpr(v_lastName))));
                            variables{end+1,1} = LustreVar(v_lastName, v_type);
                            nodeCall_outputs_Ids = ...
                                StateflowState_To_Lustre.changeVar(...
                                nodeCall_outputs_Ids, v_name, v_lastName);
                        else
                            body{end+1} = LustreEq(VarIdExpr(v_name), v_inactive);
                        end
                    else
                        %UNKNOWN Variable
                        display_msg(sprintf('Variable %s in Chart %s not found',...
                            v_name, chart.Origin_path), ...
                            MsgType.ERROR, 'Outport_To_Lustre', '');
                    end
                end
            end
            %update outputs names
            nodeCall_outputs_Names = cellfun(@(x) x.getId(), ...
                nodeCall_outputs_Ids, 'UniformOutput', false);
            allVars = [variables; outputs; inputs];
            for i=1:numel(nodeCall_outputs_Names)
                v_name = nodeCall_outputs_Names{i};
                if ~VarIdExpr.ismemberVar(v_name, allVars)
                    if MatlabUtils.endsWith(v_name, ...
                            StateflowState_To_Lustre.getStateIDSuffix())
                        v_type = strrep(v_name, ...
                            StateflowState_To_Lustre.getStateIDSuffix(), ...
                            StateflowState_To_Lustre.getStateEnumSuffix());
                        variables{end+1,1} = LustreVar(v_name, v_type);
                    else
                        %UNKNOWN Variable
                        display_msg(sprintf('Variable %s in Chart %s not found',...
                            v_name, chart.Origin_path), ...
                            MsgType.ERROR, 'Outport_To_Lustre', '');
                    end
                end
            end
            %Node Call
            node_call = NodeCallExpr(node_call.getNodeName(), nodeCall_inputs_Ids);
            body{end+1} = LustreEq(nodeCall_outputs_Ids, node_call);
            
            % set unused outputs to their initial values or zero
            body{end+1} = LustreComment('Set unused outputs');
            for i=1:numel(outputsData)
                d = outputsData{i};
                d_name = d.Name;
                if ismember(d_name, nodeCall_outputs_Names) 
                    % it's used
                    continue;
                end
                [v, ~, status] = ...
                    Constant_To_Lustre.getValueFromParameter(parent, blk, d.InitialValue);
                if status
                    display_msg(...
                        sprintf('InitialOutput %s in Chart %s not found neither in Matlab workspace or in Model workspace',...
                        d.InitialValue, chart.Origin_path), ...
                        MsgType.ERROR, 'Outport_To_Lustre', '');
                    v = 0;
                end
                IC_Var = SLX2LusUtils.num2LusExp(v, d.LusDatatype);
                body{end+1} = LustreEq(VarIdExpr(d_name), IC_Var);
            end
            
        end
        
        %
        function [outputs, inputs, body] = ...
                write_ChartNodeWithEvents_body(chart, events)
            global SF_STATES_NODESAST_MAP;
            outputs = {};
            inputs = {};
            body = {};
            Scopes = cellfun(@(x) x.Scope, ...
                events, 'UniformOutput', false);
            inputEvents = SF_To_LustreNode.orderObjects(...
                events(strcmp(Scopes, 'Input')), 'Port');
            inputEventsNames = cellfun(@(x) x.Name, ...
                inputEvents, 'UniformOutput', false);
            inputEventsVars = cellfun(@(x) VarIdExpr(x.Name), ...
                inputEvents, 'UniformOutput', false);
            chartNodeName = ...
                StateflowState_To_Lustre.getStateNodeName(chart);
            if isKey(SF_STATES_NODESAST_MAP, chartNodeName)
                nodeAst = SF_STATES_NODESAST_MAP(chartNodeName);
                [orig_call, oututs_Ids] = nodeAst.nodeCall();
                outputs = [outputs, nodeAst.getOutputs()];
                inputs = [inputs, nodeAst.getOutputs()];
                inputs = [inputs, nodeAst.getInputs()];
                for i=1:numel(inputEventsNames)
                    call = StateflowState_To_Lustre.changeEvents(...
                        orig_call, inputEventsNames, inputEventsNames{i});
                    cond_prefix = VarIdExpr(inputEventsNames{i});
                    body{end+1} = LustreEq(oututs_Ids, ...
                        IteExpr(cond_prefix, call, TupleExpr(oututs_Ids)));
                end
                %NOT CORRECT
                % body{end+1} = LustreComment('If no event occured, time step wakes up the chart');
                % allEventsCond = UnaryExpr(UnaryExpr.NOT, ...
                %     BinaryExpr.BinaryMultiArgs(BinaryExpr.OR, inputEventsVars));
                % body{end+1} = LustreEq(oututs_Ids, ...
                %     IteExpr(allEventsCond, orig_call, TupleExpr(oututs_Ids)));
            else
                display_msg(...
                    sprintf('%s not found in SF_STATES_NODESAST_MAP',...
                    chartNodeName), ...
                    MsgType.ERROR, 'StateflowTransition_To_Lustre', '');
                return;
            end
        end
        function call = changeEvents(call, EventsNames, E)
            args = call.getArgs();
            inputs_Ids = cellfun(@(x) VarIdExpr(x.getId()), ...
                args, 'UniformOutput', false);
            for i=1:numel(inputs_Ids)
                if isequal(inputs_Ids{i}.getId(), E)
                    inputs_Ids{i} = BooleanExpr(true);
                elseif ismember(inputs_Ids{i}.getId(), EventsNames)
                    inputs_Ids{i} = BooleanExpr(false);
                end
            end
            
            call = NodeCallExpr(call.nodeName, inputs_Ids);
        end
        function params = changeVar(params, oldName, newName)
            for i=1:numel(params)
                if isequal(params{i}.getId(), oldName)
                    params{i} = VarIdExpr(newName);
                end
            end
        end
        %% Actions node name
        
        function name = getChartEventsNodeName(state, id)
            if nargin == 2
                state_name = SF_To_LustreNode.getUniqueName(state, id);
            else
                state_name = SF_To_LustreNode.getUniqueName(state);
            end
            name = strcat(state_name, '_EventsNode');
        end
        
        function name = getStateNodeName(state, id)
            if nargin == 2
                state_name = SF_To_LustreNode.getUniqueName(state, id);
            else
                state_name = SF_To_LustreNode.getUniqueName(state);
            end
            name = strcat(state_name, '_Node');
        end
        function name = getStateDefaultTransNodeName(state)
            state_name = SF_To_LustreNode.getUniqueName(state);
            name = strcat(state_name, '_DefaultTrans_Node');
        end
        function name = getStateInnerTransNodeName(state)
            state_name = SF_To_LustreNode.getUniqueName(state);
            name = strcat(state_name, '_InnerTrans_Node');
        end
        function name = getStateOuterTransNodeName(state)
            state_name = SF_To_LustreNode.getUniqueName(state);
            name = strcat(state_name, '_OuterTrans_Node');
        end
        function name = getEntryActionNodeName(state, id)
            if nargin == 2
                state_name = SF_To_LustreNode.getUniqueName(state, id);
            else
                state_name = SF_To_LustreNode.getUniqueName(state);
            end
            name = strcat(state_name, '_EntryAction');
        end
        function name = getExitActionNodeName(state, id)
            if nargin == 2
                state_name = SF_To_LustreNode.getUniqueName(state, id);
            else
                state_name = SF_To_LustreNode.getUniqueName(state);
            end
            name = strcat(state_name, '_ExitAction');
        end
        function name = getDuringActionNodeName(state, id)
            if nargin == 2
                state_name = SF_To_LustreNode.getUniqueName(state, id);
            else
                state_name = SF_To_LustreNode.getUniqueName(state);
            end
            name = strcat(state_name, '_DuringAction');
        end
        
        % State ID functions
        function suf = getStateIDSuffix()
            suf = '__ChildID';
        end
        function idName = getStateIDName(state)
            state_name = lower(...
                SF_To_LustreNode.getUniqueName(state));
            idName = strcat(state_name, ...
                StateflowState_To_Lustre.getStateIDSuffix());
        end
        function suf = getStateEnumSuffix()
            suf = '__Children';
        end
        function idName = getStateEnumType(state)
            state_name = lower(...
                SF_To_LustreNode.getUniqueName(state));
            idName = strcat(state_name, ...
                StateflowState_To_Lustre.getStateEnumSuffix());
        end
        function [stateEnumType, childAst] = ...
                addStateEnum(state, child, isInner, isJunction, inactive)
            global SF_STATES_ENUMS_MAP;
            stateEnumType = StateflowState_To_Lustre.getStateEnumType(state);
            state_name = upper(...
                SF_To_LustreNode.getUniqueName(state));
            if nargin >= 3 && isInner
                childName = strcat(state_name, '_InnerTransition');
            elseif nargin >= 4 && isJunction
                childName = strcat(state_name, '_StoppedInJunction');
            elseif nargin == 5 && inactive
                childName = strcat(state_name, '_INACTIVE');
            elseif ischar(child)
                %child is given using SF_To_LustreNode.getUniqueName
                childName = upper(child);
            else
                childName = upper(...
                    SF_To_LustreNode.getUniqueName(child));
            end
            if ~isKey(SF_STATES_ENUMS_MAP, stateEnumType)
                SF_STATES_ENUMS_MAP(stateEnumType) = {childName};
            elseif ~ismember(childName, SF_STATES_ENUMS_MAP(stateEnumType))
                SF_STATES_ENUMS_MAP(stateEnumType) = [...
                    SF_STATES_ENUMS_MAP(stateEnumType), childName];
            end
            childAst = EnumValueExpr(childName);
        end
        %% Substates objects
        function subStates = getSubStatesObjects(state)
            global SF_STATES_PATH_MAP;
            childrenNames = state.Composition.Substates;
            subStates = cell(numel(childrenNames), 1);
            for i=1:numel(childrenNames)
                childPath = fullfile(state.Path, childrenNames{i});
                if ~isKey(SF_STATES_PATH_MAP, childPath)
                    ME = MException('COCOSIM:STATEFLOW', ...
                        'COMPILER ERROR: Not found state "%s" in SF_STATES_PATH_MAP', childPath);
                    throw(ME);
                end
                subStates{i} = SF_STATES_PATH_MAP(childPath);
            end
        end
    end
    
end

