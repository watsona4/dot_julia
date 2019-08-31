module ErrTests

 include("../src/AndersonMoore.jl")
using .AndersonMoore

function noErrors()::Bool

    hh = [0.  0.   0.  0. -1.1  0.  0.  0.  1.  1.  0.  0.;
          0. -0.4  0.  0.  0.   1. -1.  0.  0.  0.  0.  0.;
          0.  0.   0.  0.  0.   0.  1.  0.  0.  0.  0.  0.;
          0.  0.   0. -1.  0.   0.  0.  1.  0.  0.  0.  0.]::Array{Float64, 2}

    e = "AndersonMoore: unique solution."
    
    (bnow,rtsnow,ia,nexact,nnumeric,lgroots,AMAcode) = 
        AndersonMooreAlg(hh, 4, 1, 1, 1.0e-8, 1.0 + 1.0e-8)

    err(AMAcode) == e
    
end # noErrors()

function tooManyRoots()::Bool

    hh = [0.  0.  0.  0. -1.1  0.  0.  0.  1.  1.  0.  0.;
          0.  4.  0.  0.  0.   1. -1.  0.  0.  0.  0.  0.;
          0.  0.  0.  0.  0.   0.  1.  0.  0.  0.  0.  0.;
          0.  0.  0. -1.  0.   0.  0.  1.  0.  0.  0.  0.]::Array{Float64, 2}

    e = "AndersonMoore: too many big roots."
    
    (bnow, rtsnow, ia, nexact, nnumeric, lgroots, AMAcode) =   
        AndersonMooreAlg(hh, 4, 1, 1, 1.0e-8, 1.0 + 1.0e-8)

    err(AMAcode) == e

end # tooManyRoots()

function tooFewRoots()::Bool

    hh = [0.  0.   0.  0. -0.9  0.  0.  0.  1.  1.  0.  0.;
          0. -0.4  0.  0.  0.   1. -1.  0.  0.  0.  0.  0.;
          0.  0.   0.  0.  0.   0.  1.  0.  0.  0.  0.  0.;
          0.  0.   0. -1.  0.   0.  0.  1.  0.  0.  0.  0.]::Array{Float64, 2}

    e = "AndersonMoore: too few big roots."
    
    (bnow, rtsnow, ia, nexact, nnumeric, lgroots, AMAcode) =   
        AndersonMooreAlg(hh, 4, 1, 1, 1.0e-8, 1.0 + 1.0e-8)

    err(AMAcode) == e
    
end # tooFewRoots()

function tooManyExactShifts()::Bool

    hh = [0.  0.   0.  0.  0.  0.  0.  0.  0.  0.  0.  0.;
          0. -0.4  0.  0.  0.  1. -1.  0.  0.  0.  0.  0.;
          0.  0.   0.  0.  0.  0.  1.  0.  0.  0.  0.  0.;
          0.  0.   0. -1.  0.  0.  0.  1.  0.  0.  0.  0.]::Array{Float64, 2}

    e = "AndersonMoore: too many exact shiftrights."

    (bnow, rtsnow, ia, nexact, nnumeric, lgroots, AMAcode) =   
        AndersonMooreAlg(hh, 4, 1, 1, 1.0e-8, 1.0 + 1.0e-8)

    err(AMAcode) == e
    
end # tooManyExactShifts()    


function tooManyNumericShifts()::Bool

    hh = [0.  0.  0.  0.  -2.2  0.  0.  0.  2.  2.  0.  0.;
          0.  0.  0.  0.  -1.1  0.  0.  0.  1.  1.  0.  0.;
          0.  0.  0.  0.  -1.1  0.  1.  0.  1.  1.  0.  0.;
          0.  0.  0. -1.  -1.1  0.  0.  1.  1.  1.  0.  0.]::Array{Float64, 2}

    e = "AndersonMoore: too many numeric shiftrights."
    
    (bnow, rtsnow, ia, nexact, nnumeric, lgroots, AMAcode) = 
        AndersonMooreAlg(hh, 4, 1, 1, 1.0e-8, 1.0 + 1.0e-8)

    err(AMAcode) == e
    
end # tooManyNumericShifts()

function spurious()::Bool

    e = "AndersonMoore: return code not properly specified"

    err(975) == e

end # spurious

end # module
