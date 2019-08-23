classdef CompareToZero_Test < Block_Test
    %CompareToZero_Test generates test automatically.
    
    properties(Constant)
        fileNamePrefix = 'CompareToZero_TestGen';
        blkLibPath = 'simulink/Logic and Bit Operations/Compare To Zero';
    end
    
    properties
        % properties that will participate in permutations
        OutDataTypeStr = {'uint8','boolean'};
        inpDataType = {...
            'double','single','int8','uint8','int16','uint16','int32',...
            'uint32','fixdt(1,16,0)',...
            'fixdt(1,16,2^0,0)','boolean'};        
        relop = {'==','~=','<','<=','>=','>'};

    end
    
    properties
        % other properties
        ZeroCross = {'off','on'};  
    end
    
    methods
        function status = generateTests(obj, outputDir, deleteIfExists)
            if ~exist('deleteIfExists', 'var')
                deleteIfExists = true;
            end
            status = 0;
            params = obj.getParams();    
            fstInDims = {'1', '1', '1', '1', '1', '3', '[2,3]'};             
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
                    inputDataType = s.inpDataType;
                    s = rmfield(s,'inpDataType');
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
                    set_param(inport_list{1}, ...
                        'OutDataTypeStr',inputDataType);
                    
                    dim_Idx = mod(i, length(fstInDims)) + 1;
                    set_param(inport_list{1}, ...
                        'PortDimensions', fstInDims{dim_Idx});

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
            for pRelop = 1 : numel(obj.relop)
                for pOutDataTypeStr = 1 : numel(obj.OutDataTypeStr)
                    iInType = mod(length(params), ...
                        length(obj.inpDataType)) + 1;
                    s = struct();
                    s.OutDataTypeStr = obj.OutDataTypeStr{pOutDataTypeStr};
                    s.relop = obj.relop{pRelop};
                    s.inpDataType = obj.inpDataType{iInType};
                    params{end+1} = s;
                end
                
            end
            
        end

    end
end

