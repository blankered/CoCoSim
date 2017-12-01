function [ new_ir ] = internalRep_pp( new_ir, json_export, output_dir )
%IR_PP pre-process the IR for cocoSim to adapte the IR to the compiler or
%make some analysis in the IR level.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('json_export', 'var')
    json_export = 0;
end
if ~exist('output_dir', 'var')
    output_dir = fileparts(new_ir.meta.file_path);
end
%% apply functions in library folder
[ir_pp_root, ~, ~] = fileparts(mfilename('fullpath'));
lib_dir = fullfile(ir_pp_root, 'lib');
functions = dir(fullfile(lib_dir , '*.m'));
oldDir = pwd;
if isstruct(functions) && isfield(functions, 'name')
    for i=1:numel(functions)
        cd(lib_dir);
        fh = str2func(functions(i).name(1:end-2));
        cd(oldDir);
        new_ir = fh(new_ir);
    end
end


%% export json
if json_export
    ir_encoded = json_encode(new_ir);
    ir_encoded = strrep(ir_encoded,'\/','/');
    mdl_name = '';
    if nargin < 3
        if isfield(new_ir, 'meta') && isfield(new_ir.meta, 'file_path')
            [output_dir, mdl_name, ~] = fileparts(new_ir.meta.file_path);
        else
            output_dir = oldDir;
        end
    else
        if isfield(new_ir, 'meta') && isfield(new_ir.meta, 'file_path')
            [~, mdl_name, ~] = fileparts(new_ir.meta.file_path);
        end
    end
    
    json_name = 'IR_pp_tmp.json';
    json_path = fullfile(output_dir, json_name);
    fid = fopen(json_path, 'w');
    fprintf(fid, '%s\n', ir_encoded);
    fclose(fid);
    
    new_path = fullfile(output_dir, strcat('IR_pp_', mdl_name,'.json'));
    cmd = ['cat ' json_path ' | python -mjson.tool > ' new_path];
    try
        [status, output] = system(cmd);
        if status==0
            system(['rm ' json_path]);
        else
            warning('IR_PP json file couldn''t be formatted see error:\n%s\n',...
                output);
        end
    catch
    end
end
end

