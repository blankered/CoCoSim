classdef LogicalOperator_Test < Block_Test
    %LogicalOperator_Test generates test automatically.
    
    properties(Constant)
        fileNamePrefix = 'LogicalOperator_TestGen';
        blkLibPath = 'simulink/Logic and Bit Operations/Logical Operator';
    end
    
    properties
        % properties that will participate in permutations
        Operator = {'AND','OR','NAND','NOR','XOR','NXOR','NOT'};
        Inputs =  {'2','3','4'};           
        OutDataTypeStr = {...
            %'Inherit: Logical (see Configuration Parameters: Optimization)',...
            'boolean'};
        inputDataType = {'double', 'single','int8',...
            'uint8','int16','uint16','int32', ...
            'uint32','boolean'};   
    end
    
    properties
        % other properties
        IconShape = {'rectangular','distinctive'};
        AllPortsSameDT = {'off','on'};
        SampleTime = {'1'};
    end
    
    methods
        function status = generateTests(obj, outputDir, deleteIfExists)
            if ~exist('deleteIfExists', 'var')
                deleteIfExists = true;
            end
            status = 0;
            params = obj.getParams();             
            fstInDims = {'1', '1', '1', '1', '1', '3','[2,3]'};          
            nb_tests = length(params);
            condExecSSPeriod = floor(nb_tests/length(Block_Test.condExecSS));
            for i=1 : nb_tests
                skipTests = [];
                if ismember(i,skipTests)
                    continue;
                end
                try
                    s = params{i};
                    %% creat new model
                    mdl_name = sprintf('%s%d', obj.fileNamePrefix, i);
                    addCondExecSS = (mod(i, condExecSSPeriod) == 0);
                    condExecSSIdx = int32(i/condExecSSPeriod);
                    [blkPath, mdl_path, skip] = Block_Test.create_new_model(...
                        mdl_name, outputDir, deleteIfExists, addCondExecSS, ...
                        condExecSSIdx);
                    if skip
                        continue;
                    end
                    
                    %% remove parametres that does not belong to block params
                    inpDataType = s.inputDataType;
                    s = rmfield(s,'inputDataType');
                    %% add the block

                    Block_Test.add_and_connect_block(obj.blkLibPath, blkPath, s);
                    
                    %% go over inports
                    try
                        blk_parent = get_param(blkPath, 'Parent');
                    catch
                        blk_parent = fileparts(blkPath);
                    end
                    inport_list = find_system(blk_parent, ...
                        'SearchDepth',1, 'BlockType','Inport');
                    
                    % rotate over input data type for U
                    for i=1:numel(inport_list)
                        if s.AllPortsSameDT                        
                            set_param(inport_list{i}, ...
                                'OutDataTypeStr',s.OutDataTypeStr);     
                        else
                            set_param(inport_list{i}, ...
                                'OutDataTypeStr', inpDataType);
                        end
                        dim_Idx = mod(i, length(fstInDims)) + 1;
                        set_param(inport_list{i}, ...
                            'PortDimensions', fstInDims{dim_Idx});
                    end

                    failed = Block_Test.setConfigAndSave(mdl_name, mdl_path);
                    if failed, display(s), end
                
                    
                catch me
                    display(s);
                    display_msg(['Model failed: ' mdl_name], ...
                        MsgType.DEBUG, 'generateTests', '');
                    display_msg(me.getReport(), MsgType.ERROR, 'generateTests', '');
                    bdclose(mdl_name)
                end
            end
        end
        
        function params2 = getParams(obj)
            
            params1 = obj.getPermutations();
            params2 = cell(1, length(params1));
            for p1 = 1 : length(params1)
                s = params1{p1};                
                params2{p1} = s;
            end
        end
        
        function params = getPermutations(obj)
            params = {};       
            for pOperator = 1 : numel(obj.Operator)
                for pInputs = 1 : numel(obj.Inputs)
                    pOutDataTypeStr = ...
                        mod(length(params), ...
                        length(obj.OutDataTypeStr))...
                        + 1;
                    pAllPortsSameDT = mod(length(params), ...
                        length(obj.AllPortsSameDT))+ 1;
                    pinputDataType = mod(length(params), ...
                        length(obj.inputDataType))+ 1;
                    s = struct();
                    s.Inputs = obj.Inputs{pInputs};
                    s.Operator = obj.Operator{pOperator};
                    s.OutDataTypeStr = obj.OutDataTypeStr{pOutDataTypeStr};
                    s.AllPortsSameDT = obj.AllPortsSameDT{pAllPortsSameDT};
                    s.inputDataType = obj.inputDataType{pinputDataType};
                    params{end+1} = s;
                end
            end
        end

    end
end

