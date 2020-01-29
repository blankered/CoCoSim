%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
function code = print(obj, backend, inPreludeFile)
    % inPreludeFile is true if the code is printed in plu file.
    % backend can be PRELUDE but printed in "lus" file for the monoperiodic
    % nodes implementation. They should respect some restriction as no starting
    % with underscore in variable/node names.
    if ~exist('inPreludeFile', 'var')
        inPreludeFile = false;
    end
    lines = {};
    %% metaInfo
    if ~isempty(obj.metaInfo)
        if ischar(obj.metaInfo)
            if LusBackendType.isPRELUDE(backend) && inPreludeFile
                lines{end + 1} = sprintf('--%s\n',...
                    strrep(obj.metaInfo, newline, '--'));
            else
                lines{end + 1} = sprintf('(*\n%s\n*)\n',...
                    obj.metaInfo);
            end
        else
            lines{end + 1} = obj.metaInfo.print(backend);
        end
    end
    %% PRELUDE for main node
    if LusBackendType.isPRELUDE(backend) ...
            && inPreludeFile...
            && obj.isMain
        for i=1:length(obj.inputs)
            lines{end + 1} = sprintf('sensor %s wcet 1;\n', obj.inputs{i}.getId());
        end
        for i=1:length(obj.outputs)
            lines{end + 1} = sprintf('actuator %s wcet 1;\n', obj.outputs{i}.getId());
        end
    end
    %%    
    if obj.isImported
        isImported_str = 'imported';
    else
        isImported_str = '';
    end
    semicolon =';';
    if LusBackendType.isPRELUDE(backend) && inPreludeFile
        semicolon = '';
    end
    nodeName = obj.name;
    %PRELUDE does not support "_" in the begining of the word.
    if LusBackendType.isPRELUDE(backend) ...
            && MatlabUtils.startsWith(nodeName, '_')
        nodeName = sprintf('x%s', nodeName);
    end
    lines{end + 1} = sprintf('node %s %s(%s)\nreturns(%s)%s\n', ...
        isImported_str, ...
        nodeName, ...
        nasa_toLustre.lustreAst.LustreAst.listVarsWithDT(obj.inputs, backend, true), ...
        nasa_toLustre.lustreAst.LustreAst.listVarsWithDT(obj.outputs, backend, true), ...
        semicolon);
    if ~isempty(obj.localContract) && ~inPreludeFile
        lines{end + 1} = obj.localContract.print(backend);
    end

    if obj.isImported
        code = MatlabUtils.strjoin(lines, '');
        return;
    end

    if ~isempty(obj.localVars)
        lines{end + 1} = sprintf('var %s\n', ...
            nasa_toLustre.lustreAst.LustreAst.listVarsWithDT(obj.localVars, backend));
    end
    lines{end+1} = sprintf('let\n');
    % local Eqs
    for i=1:numel(obj.bodyEqs)
        eq = obj.bodyEqs{i};
        if isempty(eq)
            continue;
        end
        lines{end+1} = sprintf('\t%s\n', ...
            eq.print(backend));

    end
    lines{end+1} = sprintf('tel\n');
    code = MatlabUtils.strjoin(lines, '');
end
