function [new_file_path, status] = cocosim_pp(file_path, varargin)
% COCOSIM_PP pre-process complexe blocks in Simulink model into basic ones. 
% This is a generic function that use pp_config as a configuration file that decides
% which libraries to use and in which order to call the blocks functions.
% See pp_config for more details.
% Inputs:
% file_path: The full path to Simulink model.
% varargin: User defined inputs. 
%   'nodisplay': to disable the display mode of the model.
%   'verif': to create a verification model that contains both the original
%   model and pre-processed model. In order to prove the pre-processing is
%   correct.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global cocosim_pp_gen_verif  cocosim_pp_gen_verif_dir;

nodisplay = 0;
cocosim_pp_gen_verif = 0;
cocosim_pp_gen_verif_dir = '';
for i=1:numel(varargin)
    if strcmp(varargin{i}, 'nodisplay')
        nodisplay = 1;
    elseif strcmp(varargin{i}, 'verif')
        cocosim_pp_gen_verif = 1;
    end
end

%% Creat the new model name
[model_parent, model, ext] = fileparts(file_path);
already_pp = 0;
if strcmp(model(end-2:end), '_PP')
    load_system(file_path);
    annotations = find_system(model,'FindAll','on','Type','annotation','MarkupType', 'markup', 'Name', 'cocosim_pp');
    if isempty(annotations)
        new_model_base = strcat(model,'_PP');
        new_file_path = fullfile(model_parent,strcat(new_model_base, ext));
    else
        already_pp = 1;
        new_model_base = model;
        new_file_path = file_path;
    end
else
    new_model_base = strcat(model,'_PP');
    new_file_path = fullfile(model_parent,strcat(new_model_base, ext));
end
%close it without saving it
close_system(new_model_base,0);
if ~already_pp; delete(new_file_path); end

%% If generation of verification template for each block pre-processed was 
% asked
addpath(model_parent);
if cocosim_pp_gen_verif
    cocosim_pp_gen_verif_dir = fullfile(model_parent ,strcat(model, 'PP_Validation'));
    if ~exist(cocosim_pp_gen_verif_dir,'dir')
        mkdir(cocosim_pp_gen_verif_dir);
    end
    addpath(cocosim_pp_gen_verif_dir);
end


%% Creating a cache copy to process
if ~already_pp; copyfile(file_path, new_file_path); end
display_msg(['Loading ' new_file_path ], MsgType.INFO, 'PP', '');
load_system(new_file_path);
if ~already_pp
    add_block('built-in/Note', ...
    strcat(new_model_base, '/cocosim_pp'), ...
    'MarkupType', 'markup')
end

display_msg('Loading library', MsgType.INFO, 'PP', '');
if ~bdIsLoaded('gal_lib'); load_system('gal_lib.slx'); end





%% Order functions
global ordered_pp_functions;
if isempty(ordered_pp_functions)
    pp_config;
end
%% sort functions calls
oldDir = pwd;

for i=1:numel(ordered_pp_functions)
    [dirname, func_name, ~] = fileparts(ordered_pp_functions{i});
    cd(dirname);
    fh = str2func(func_name);
    try
        display_msg(['runing ' func2str(fh)], MsgType.INFO, 'PP', '');
        fh(new_model_base);
    catch me
        display_msg(['can not run ' func2str(fh)], MsgType.ERROR, 'PP', '');
        display_msg(me.getReport(), MsgType.DEBUG, 'PP', '');
    end
    
end
cd(oldDir);
%% Make sure model compile
status = compile_process( new_model_base );
if status
    return;
end
% Exporting the model to the mdl CoCoSim compatible file format

display_msg('Saving simplified model', MsgType.INFO, 'PP', '');
display_msg(['Simplified model path: ' new_file_path], MsgType.INFO, 'PP', '');


save_system(new_model_base,new_file_path,'OverwriteIfChangedOnDisk',true);
if ~nodisplay
    open(new_file_path);
end
    

display_msg('Done with the simplification', MsgType.INFO, 'PP', '');
end