%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%

function [tree, expr] = parseMinus(expr)
    regex = '^-';
    match = regexp(expr, regex, 'match', 'once');
    if ~isempty(match)
        tree = match;
        expr = regexprep(expr, regex,'');
    else
        tree = '';
    end
end

