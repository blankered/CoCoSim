classdef BusAssignment_To_Lustre < Block_To_Lustre
    %BusAssignment_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, varargin)
            isInsideContract = SLX2LusUtils.isContractBlk(parent);
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            if ~isInsideContract, obj.addVariable(outputs_dt);end
            widths = blk.CompiledPortWidths.Inport;
            inputs = cell(1, numel(widths));
            for i=1:numel(widths)
                inputs{i} = SLX2LusUtils.getBlockInputsNames(parent, blk, i);
            end
            
            % everything is inlined
            InportDimensions = blk.CompiledPortDimensions.Inport;
            InputSignals = blk.InputSignals;
            AssignedSignals = regexp(blk.AssignedSignals, ',', 'split');
            inputSignalsInlined = BusSelector_To_Lustre.inlineInputSignals(InputSignals);
            if InportDimensions(1) == -2
                % case of virtual bus
                inport_cell_dimension =...
                    Assignment_To_Lustre.getInputMatrixDimensions(InportDimensions);
                if numel(inport_cell_dimension) > numel(inputSignalsInlined)
                    inport_cell_dimension = inport_cell_dimension(1:numel(inputSignalsInlined));
                end
            else
                InportDT = blk.CompiledPortDataTypes.Inport{1};
                try
                    isBus = evalin('base', sprintf('isa(%s, ''Simulink.Bus'')',char(InportDT)));
                catch
                    isBus = false;
                end
                if isBus
                    % case of bus object
                    inport_cell_dimension = SLX2LusUtils.getDimensionsFromBusObject(InportDT);
                else
                    display_msg(sprintf('Block %s with type %s is not supported.', ...
                        blk.Origin_path,InportDT ),...
                        MsgType.ERROR, 'BusSelector_To_Lustre', '');
                    return;
                end
            end
            [SignalsInputsMap, status] = BusSelector_To_Lustre.signalInputsUsingDimensions(...
                inport_cell_dimension, inputSignalsInlined, inputs{1});
            if status
                display_msg(sprintf('Block %s is not supported.', blk.Origin_path),...
                    MsgType.ERROR, 'BusSelector_To_Lustre', '');
                return;
            end
            modifiedInputs = inputs{1};
            for i=1:numel(AssignedSignals)
                if isKey(SignalsInputsMap, AssignedSignals{i})
                    inputs_i = SignalsInputsMap(AssignedSignals{i});
                else
                    display_msg(sprintf('Block %s with type %s is not supported.',...
                        blk.Origin_path, AssignedSignals{i}),...
                        MsgType.ERROR, 'BusSelector_To_Lustre', '');
                    continue;
                end
                for j=1:numel(inputs_i)
                    idx = BusAssignment_To_Lustre.findIdx(modifiedInputs, inputs_i{j});
                    modifiedInputs{idx} = ...
                        inputs{i+1}{j};
                end
            end
            codes = cell(1, numel(outputs));
            for i=1:numel(outputs)
                codes{i} = LustreEq(outputs{i}, modifiedInputs{i});
            end
            obj.setCode( codes );
        end
        
        function options = getUnsupportedOptions(obj,  varargin)
            options = obj.unsupported_options;
        end
    end
  
    methods(Static)
        function idx = findIdx(VarIds, var)
           varNames = cellfun(@(x) x.getId(), VarIds, 'UniformOutput', 0); 
           varName = var.getId();
           idx = strcmp(varNames, varName);
        end
    end
    
end

