%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [resetCode, status] = getResetCode(...
        resetType, resetDT, resetInput, zero )
    %
    %
    status = 0;
    if strcmp(resetDT, 'bool')
        b = resetInput;
    else
        b = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.GT, resetInput, zero);
    end
    if strcmpi(resetType, 'rising')
        resetCode = ...
            nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.ARROW, ...
                       nasa_toLustre.lustreAst.BoolExpr('false'),...
                       nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.AND,...
                                  b, ...
                                  nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.NOT, ...
                                            nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.PRE, b)...
                                            )...
                                 )...
                      );

    elseif strcmpi(resetType, 'falling')
        resetCode = ...
            nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.ARROW, ...
                       nasa_toLustre.lustreAst.BoolExpr('false'),...
                       nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.AND,...
                                  nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.NOT, b), ...
                                  nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.PRE, b)...
                                 )...
                      );
    elseif strcmpi(resetType, 'either')
        resetCode = ...
            nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.ARROW, ...
                       nasa_toLustre.lustreAst.BoolExpr('false'),...
                       nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.OR,...
                                  nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.AND,...
                                              b, ...
                                              nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.NOT, ...
                                                        nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.PRE, b)...
                                                        )...
                                             ),...
                                  nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.AND,...
                                              nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.NOT, b), ...
                                              nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.PRE, b)...
                                             )...
                                  )...
                      );
    elseif strcmpi(resetType, 'level')

        if strcmp(resetDT, 'bool')
            b = resetInput;
        else
            b = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.NEQ, resetInput, zero);
        end
        % Reset in either of these cases:
        % when the reset signal is nonzero at the current time step
        % when the reset signal value changes from nonzero at the previous time step to zero at the current time step
        resetCode = ...
            nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.ARROW, ...
                       nasa_toLustre.lustreAst.BoolExpr('false'),...
                       nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.OR,...
                                  b,...
                                  nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.AND,...
                                            nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.PRE, b),...
                                            nasa_toLustre.lustreAst.UnaryExpr(nasa_toLustre.lustreAst.UnaryExpr.NOT, b) ...
                                            )...
                                  )... 
                      );
    elseif strcmpi(resetType, 'level hold')

        if strcmp(resetDT, 'bool')
            b = resetInput;
        else
            b = nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.NEQ, resetInput, zero);
        end
        %Reset when the reset signal is nonzero at the current time step
        resetCode = ...
            nasa_toLustre.lustreAst.BinaryExpr(nasa_toLustre.lustreAst.BinaryExpr.ARROW, ...
                       nasa_toLustre.lustreAst.BoolExpr('false'),...
                       b);              
    elseif strcmpi(resetType, 'function-call')
        resetCode = resetInput;
    else
        resetCode = nasa_toLustre.lustreAst.VarIdExpr('');
        status = 1;
        return;
    end
end
