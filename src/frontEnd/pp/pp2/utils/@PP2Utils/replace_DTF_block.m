function [] = replace_DTF_block(blk, U_dims_blk,num,denum, blkType )
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %     For discrete-time transfer functions, it is highly recommended to
    %     make the length of the numerator and denominator equal to ensure
    %     correct results.
    if numel(denum) < numel(num)
        tempDenum = zeros(1,length(num));
        if strcmp(blkType, 'DiscreteTransferFcn')
            % add zeros on the left of denumerator
            tempDenum(length(num) - length(denum) + 1:end) = denum;
        elseif strcmp(blkType, 'DiscreteFilter') ...
                || strcmp(blkType, 'DiscreteFIRFilter')
            % add zeros on the right of denumerator
            tempDenum(1:length(denum)) = denum;
        else
            tempDenum = denum;
        end
        denum = tempDenum;
    end
    
    if numel(num) < numel(denum)
        tempNum = zeros(1,length(denum));
        if strcmp(blkType, 'DiscreteTransferFcn')
            % add zeros on the left of numerator
            tempNum(length(denum) - length(num) + 1:end) = num;
        elseif strcmp(blkType, 'DiscreteFilter') ...
                || strcmp(blkType, 'DiscreteFIRFilter')
            % add zeros on the right of numerator
            tempNum(1:length(num)) = num;
        else
            tempNum = num;
        end
        num = tempNum;
    end
    
    % Computing state space representation
    [A,B,C,D]=tf2ss(num,denum);
    if isempty(A)
        A = '0';
    else
        A = mat2str(A);
    end
    if isempty(B)
        B = '0';
    else
        B = mat2str(B);
    end
    if isempty(C)
        C = '0';
    else
        C = mat2str(C);
    end
    if isempty(D)
        D = '0';
    else
        D = mat2str(D);
    end
    
    [n,~] = size(num);
    mutliNumerator = 0;
    if n>1
        mutliNumerator = 1;
    end
    
    InitialStates = get_param(blk,'InitialStates');
    outputDataType = get_param(blk, 'OutDataTypeStr');
    if strcmp(outputDataType, 'Inherit: Same as input')
        outputDataType = 'Inherit: Same as first input';
    end
    RndMeth = get_param(blk, 'RndMeth');
    ST = get_param(blk,'SampleTime');
    SaturateOnIntegerOverflow = get_param(blk,'SaturateOnIntegerOverflow');
    OutMin = get_param(blk, 'OutMin');
    OutMax = get_param(blk, 'OutMax');
    
    % replacing
    PP2Utils.replace_one_block(blk,'pp_lib/DTF');
    %restoring info
    set_param(strcat(blk,'/DTFScalar/A'),...
        'Value',A);
    set_param(strcat(blk,'/DTFScalar/B'),...
        'Value',B);
    set_param(strcat(blk,'/DTFScalar/C'),...
        'Value',C);
    set_param(strcat(blk,'/DTFScalar/D'),...
        'Value',D);
    if mutliNumerator
        OutputHandles = get_param(strcat(blk,'/Y'), 'PortHandles');
        DTFHandles = get_param(strcat(blk,'/DTFScalar'), 'PortHandles');
        delete_block(strcat(blk,'/ReverseReshape'));
        line = get_param(OutputHandles.Inport(1), 'line');
        delete_line(line);
        line = get_param(DTFHandles.Outport(1), 'line');
        delete_line(line);
        add_line(blk, DTFHandles.Outport(1), OutputHandles.Inport(1), 'autorouting', 'on');
    else
        set_param(strcat(blk,'/ReverseReshape'),...
            'OutputDimensions',mat2str(U_dims_blk));
    end
    set_param(strcat(blk,'/DTFScalar/FinalSum'),...
        'RndMeth',RndMeth);
    set_param(strcat(blk,'/DTFScalar/FinalSum'),...
        'OutDataTypeStr',outputDataType);
    set_param(strcat(blk,'/DTFScalar/FinalSum'),...
        'SaturateOnIntegerOverflow',SaturateOnIntegerOverflow);
    try
        set_param(strcat(blk,'/DTFScalar/X0'),...
            'InitialCondition',InitialStates);
    catch
        set_param(strcat(blk,'/DTFScalar/X0'),...
            'X0',InitialStates);
    end
    set_param(strcat(blk,'/DTFScalar/X0'),...
        'SampleTime',ST);
    set_param(strcat(blk,'/U'),...
        'SampleTime',ST);
    
    set_param(strcat(blk,'/Y'), 'OutMin', OutMin);
    set_param(strcat(blk,'/Y'), 'OutMax', OutMax);
end

