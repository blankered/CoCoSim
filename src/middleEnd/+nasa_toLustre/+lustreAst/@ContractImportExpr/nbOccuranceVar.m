function nb_occ = nbOccuranceVar(obj, var)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
    nb_occ = obj.inputs.nbOccuranceVar(var) + obj.outputs.nbOccuranceVar(var);
end
