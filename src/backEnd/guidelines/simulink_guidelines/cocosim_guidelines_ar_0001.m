function [results, passed, priority] = cocosim_guidelines_ar_0001(model)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Khanh Trinh <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    % ORION GN&C MATLAB/Simulink Standards
    % ar_0001: Filenames
    
    priority = 1; %Mandatory
    results = {};
    passed = 1;
    totalFail = 0;
    
    [~,name,ext] = fileparts(which(model));
    ext_less_1st_char = ext(2:end);
    
    item_titles = {...
        'no leading digits in name',...
        'no blanks in name',...
        'name allowable characters: [a-zA-Z_0-9]',...
        'cannot have more than one consecutive underscore',...
        'name cannot start with an underscore',...
        'cannot end with an underscore',...
        'no blanks in ext',...
        'ext allowable characters: [a-zA-Z0-9]',...
        'no underscore in ext'...
        };    
    
    searchStr = {...
        name,...
        name,...
        name,...
        name,...
        name,...
        name,...
        ext,...
        ext_less_1st_char,...
        ext...
        };
    
    regexp_str = {...
        '^\d',...
        '\s',...    
        '\W',...
        '__',...
        '^_',...
        '_$',...
        '\s',...
        '\W',...
        '_'...
        };    
    
    subtitles = cell(length(item_titles)+1, 1);
    for i=1:length(item_titles)
        item_title = item_titles{i};
        if(~isempty(regexp(searchStr{i},regexp_str{i}, 'once')))
            fsList = {model};
        else
            fsList = {};
        end                
        [subtitles{i+1}, numFail] = ...
            GuidelinesUtils.process_find_system_results(fsList,item_title,...
            true);
        totalFail = totalFail + numFail;
    end    
  
    if totalFail > 0
        passed = 0;
        color = 'red';
    else
        color = 'green';
    end
        
    %the main guideline
    title = 'ar_0001: Filenames';
    description_text = 'A filename conforms to the following:';
    description = HtmlItem(description_text, {}, 'black', 'black');    
    subtitles{1} = description;
    results{end+1} = HtmlItem(title, subtitles, color, color);    
    
end

