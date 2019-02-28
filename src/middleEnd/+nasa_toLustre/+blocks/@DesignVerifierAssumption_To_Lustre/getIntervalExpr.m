function exp = getIntervalExpr(x, xDT, interval)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    if interval.lowIncluded
        op1 = nasa_toLustre.lustreAst.BinaryExpr.LTE;
    else
        op1 = nasa_toLustre.lustreAst.BinaryExpr.LT;
    end
    if interval.highIncluded
        op2 = nasa_toLustre.lustreAst.BinaryExpr.LTE;
    else
        op2 = nasa_toLustre.lustreAst.BinaryExpr.LT;
    end
    if strcmp(xDT, 'int')
        vLow = nasa_toLustre.lustreAst.IntExpr(interval.low);
        vHigh = nasa_toLustre.lustreAst.IntExpr(interval.high);
    elseif strcmp(xDT, 'bool')
        vLow = nasa_toLustre.lustreAst.BooleanExpr(interval.low);
        vHigh = nasa_toLustre.lustreAst.BooleanExpr(interval.high);
    else
        vLow = nasa_toLustre.lustreAst.RealExpr(interval.low);
        vHigh = nasa_toLustre.lustreAst.RealExpr(interval.high);
    end
    exp = nasa_toLustre.lustreAst.BinaryExpr(BinaryExpr.AND, ...
        nasa_toLustre.lustreAst.BinaryExpr(op1, vLow, x), ...
        nasa_toLustre.lustreAst.BinaryExpr(op2, x, vHigh));
end
