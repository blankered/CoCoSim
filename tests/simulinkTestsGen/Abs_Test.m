classdef Abs_Test < Block_Test
    %Abs_Test generates test automatically.
    
    properties(Constant)
        fileNamePrefix = 'Abs_TestGen';
        blkLibPath = 'simulink/Math Operations/Abs';
    end
    
    properties
        % properties that will participate in permutations
        % tested 11 elements for OutDataTypeStr
        OutDataTypeStr = {...
            'double','single','int8','uint8','int32',...
            'uint32','fixdt(1,16,0)',...
            'fixdt(1,16,2^0,0)'};
        
        inpDataType = {'single','int8',...
            'uint32','fixdt(1,16,0)','fixdt(1,16,2^0,0)'};
        
    end
    
    properties
        % other properties
        SampleTime = {'-1'};
        OutMin = {'0','.5','5'};
        OutMax = {'0.1','.51','6','8'};
        RndMeth = {'Ceiling', 'Convergent', 'Floor', 'Nearest', ...
            'Round', 'Simplest', 'Zero'};
        SaturateOnIntegerOverflow = {'off', 'on'};
        LockScale = {'off','on'};
        ZeroCross = {'off', 'on'};
              
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
                    
                    % remove parametres that does not belong to block params
                    inputDataType = s.inpDataType;
                    s = rmfield(s,'inpDataType');
                    % add the block

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
                    if failed 
                        display(s); 
                    end
                
                    
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
            inpIsIntCount = 0;
            for pOutType = 1 : numel(obj.OutDataTypeStr)
                for pInType = 1 : numel(obj.inpDataType)
                    if strfind(obj.inpDataType{pInType}, 'int') 
                        inpIsIntCount = inpIsIntCount + 1;
                    end
                    iRound = mod(inpIsIntCount, ...
                        length(obj.RndMeth)) + 1;
                    iSaturate = mod(inpIsIntCount, ...
                        length(obj.SaturateOnIntegerOverflow)) + 1;
                    iOutMin = mod(length(params), ...
                        length(obj.OutMin)) + 1;                    
                    iOutMax = mod(length(params), ...
                        length(obj.OutMax)) + 1;     
                    if iOutMax < iOutMin
                        iOutMax = iOutMin;
                    end
                    s = struct();
                    s.inpDataType = obj.inpDataType{pInType};
                    s.OutDataTypeStr = obj.OutDataTypeStr{pOutType};
                    s.RndMeth = obj.RndMeth{iRound};
                    s.SaturateOnIntegerOverflow = ...
                        obj.SaturateOnIntegerOverflow{iSaturate};
                    rotate2 = mod(length(params), 2) + 1;
                    s.LockScale = obj.LockScale{rotate2};
                    s.ZeroCross = obj.ZeroCross{rotate2};
                    s.OutMin = obj.OutMin{iOutMin};
                    s.OutMax = obj.OutMax{iOutMax};
                    params{end+1} = s;
                end
            end
        end

    end
end

