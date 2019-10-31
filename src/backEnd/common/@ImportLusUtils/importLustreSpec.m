function [new_model_path, status] = importLustreSpec(...
        current_openedSS,...
        lus_json_path,...
        fret_trace_file, ...
        createNewFile, ...
        organize_blocks)
    %new_model_path = importLustreSpec(model_path, contract_path)
    % Inputs:
    % model_path : the path of Simulink model
    % lus_json_path : the Json that contains the lustre represenation
    % generated by Lustrec.
    % Outputs:
    % new_model_path: the path of the new Simulink model that has the
    % Spec of the associated model.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    narginchk(3,4);
    status = 0;
    [coco_dir, ~, ~] = fileparts(lus_json_path);
    model_path = get_param(bdroot(current_openedSS), 'FileName');
    [model_dir, base_name, ~] = fileparts(model_path);
    
    use_traceability = true;
    if nargin < 3 || isempty(fret_trace_file)
        fret_trace_file = '';
        use_traceability = false;
    end
    if nargin < 4
        createNewFile = 0;
    end
    if ~exist('organize_blocks', 'var') || isempty(organize_blocks)
        organize_blocks = true;
    end
    try
        if bdIsLoaded(base_name)
            save_system(model_path)
        end
        bdclose('all')
        new_model_path = '';
        data = BUtils.read_json(lus_json_path);
        
        
        
        if createNewFile
            % we add a Postfix to differentiate it with the original Simulink model
            new_model_name = strcat(base_name,'_with_contracts');
            new_name = fullfile(model_dir,strcat(new_model_name,'.slx'));
            
            display_msg(['Cocospec path: ' new_name ], MsgType.INFO, 'importLustreSpec', '');
            
            if exist(new_name,'file')
                if bdIsLoaded(new_model_name)
                    close_system(new_model_name,0)
                end
                delete(new_name);
            end
            
            %we load the original model
            load_system(model_path);
            try close_system(new_name,0), catch, end
            %we save it as the output model
            save_system(model_path,new_name, 'OverwriteIfChangedOnDisk', true);
        else
            new_model_name = base_name;
            new_name = model_path;
        end
        
        %get tracability
        if use_traceability
            mapping_json = BUtils.read_json(fret_trace_file);
        end
        nb_coco = 0;
        
        
        [status, translated_nodes_path, ~]  = lus2slx(lus_json_path, coco_dir, [], [], organize_blocks);
        if status
            return;
        end
        [~, translated_nodes, ~] = fileparts(translated_nodes_path);
        load_system(translated_nodes_path);
        load_system(new_name);
        nodes = data.nodes;
        for node = fieldnames(nodes)'
            skip_linking = false;
            node_name = node{1};
            node_struct = nodes.(node_name);
            original_name = node_struct.original_name;
            if ~(isfield(node_struct, 'contract') ...
                    && strcmp(node_struct.contract, 'true'))
                %Support only contracts
                continue;
            end
            if use_traceability ...
                    && isfield(mapping_json, original_name) ...
                    && isfield(mapping_json.(original_name), 'model_path')
                simulink_block_name = mapping_json.(original_name).model_path;
                simulink_block_name = renamePath(simulink_block_name, base_name, new_model_name);
                isBdRoot = strcmp(get_param(simulink_block_name, 'Type'), 'block_diagram');
                if ~isBdRoot && getSimulinkBlockHandle(simulink_block_name) == -1
                    % model_path in traceability file does not exist.
                    simulink_block_name = renamePath(current_openedSS, base_name, new_model_name);
                    skip_linking = true;
                    display_msg(...
                        sprintf('Model path "%s" for contract %s can not be found. Linking Should be done manually.', ...
                        mapping_json.(original_name).model_path, original_name), MsgType.WARNING, 'importLustreSpec', '');
                    
                end
            else
                % Give the current opened Subsystem
                simulink_block_name = renamePath(current_openedSS, base_name, new_model_name);
                skip_linking = true;
            end
            if strcmp(simulink_block_name, '')
                continue;
            end
            isBdRoot = strcmp(get_param(simulink_block_name, 'Type'), 'block_diagram');
            if isBdRoot
                simulink_block_name = strcat(new_model_name,'/',base_name);
            end
            parent_block_name = fileparts(simulink_block_name);
            %for having a good order of blocks
            
            if isBdRoot
                position  = BUtils.get_obs_position(new_model_name);
            else
                position  = get_param(simulink_block_name,'Position');
            end
            x = position(1);
            y = position(2)+250;
            
            %Adding the cocospec subsystem related with the Simulink subsystem
            %"simulink_block_name"
            cocospec_block_path = strcat(simulink_block_name,'_', original_name);
            n = 1;
            while getSimulinkBlockHandle(cocospec_block_path) ~= -1
                cocospec_block_path = strcat(cocospec_block_path, num2str(n));
                n = n + 1;
                y = y+250;
            end
            node_subsystem = strcat(translated_nodes, '/', BUtils.adapt_block_name(node_name));
            add_block(node_subsystem,...
                cocospec_block_path,...
                'Position',[(x+100) y (x+250) (y+150)]);
            ImportLusUtils.set_mask_parameters(cocospec_block_path);
            nb_coco = nb_coco + 1;
            
            %we plot the invariant of the block
            scope_block_path = strcat(simulink_block_name,'_scope',num2str(n));
            scopeHandle = add_block('simulink/Commonly Used Blocks/Scope',...
                scope_block_path,...
                'MakeNameUnique', 'on', ...
                'Position',[(x+300) y (x+350) (y+50)]);
            
            %we link the Scope with cocospec block
            SrcBlkH = get_param(cocospec_block_path, 'PortHandles');
            DstBlkH = get_param(scopeHandle, 'PortHandles');
            add_line(parent_block_name, SrcBlkH.Outport(1), DstBlkH.Inport(1), 'autorouting', 'on');
            if use_traceability && ~skip_linking
                try
                    node_inputs = node_struct.inputs;
                    mapping_inputs = mapping_json.(original_name).Inputs;
                    mapping_inputs_names = arrayfun(@(x) x.variable_name, mapping_inputs, 'UniformOutput', 0);
                    %link inputs to the subsystem.
                    for node_idx=1:numel(node_inputs)
                        json_index = find(strcmp(node_inputs(node_idx).original_name, mapping_inputs_names), 1);
                        if isempty(json_index)
                            continue;
                        end
                        input_block_name = mapping_inputs(json_index).variable_path;
                        input_block_name = renamePath(input_block_name, base_name, new_model_name);
                        ImportLusUtils.link_block_with_its_cocospec(cocospec_block_path, ...
                            input_block_name, simulink_block_name, ...
                            parent_block_name, node_idx, isBdRoot);
                    end
                    mapping_outputs = mapping_json.(original_name).Outputs;
                    mapping_outputs_names = arrayfun(@(x) x.variable_name, mapping_outputs, 'UniformOutput', 0);
                    node_outputs = node_struct.outputs;
                    %link outputs to the subsystem.
                    for node_idx=1:numel(mapping_outputs)
                        try
                            json_index = find(strcmp(node_outputs(node_idx).original_name, mapping_outputs_names), 1);
                            if isempty(json_index)
                                continue;
                            end
                            output_block_name = renamePath(...
                                mapping_outputs(json_index).variable_path,...
                                base_name, new_model_name);
                            ImportLusUtils.link_block_with_its_cocospec(cocospec_block_path, ...
                                output_block_name, simulink_block_name, ...
                                parent_block_name, node_idx + length(node_inputs), isBdRoot);
                        catch
                            % ignore linking if something wrong happened.
                        end
                    end
                catch me
                    % linking failed.
                    display_msg(me.getReport(), MsgType.DEBUG, 'importLustreSpec', '');
                    display_msg(...
                        sprintf('Linking failed between contract "%s" and block "%s". Linking Should be done manually.', ...
                        original_name, cocospec_block_path), MsgType.WARNING, 'importLustreSpec', '');
                end
            end
        end
        
        if nb_coco == 0
            warndlg('No cocospec contracts were generated','CoCoSim: Warning');
            return;
        end
        save_system(new_name);
        new_model_path = new_name;
        open(new_name);
        save_system(new_name,[],'OverwriteIfChangedOnDisk',true);
        close_system(translated_nodes,0)
    catch ME
        display_msg(ME.message, MsgType.ERROR, 'importLustreSpec', '');
        display_msg(ME.getReport(), MsgType.DEBUG, 'importLustreSpec', '');
        rethrow(ME);
    end
end

function new_blockPath = renamePath(blkPath, oldModelName, NewModelName)
    if MatlabUtils.contains(blkPath, '/')
        new_blockPath = regexprep(blkPath, strcat('^',oldModelName,'/(\w)'),strcat(NewModelName,'/$1'));
    else
        new_blockPath = NewModelName;
    end
end

