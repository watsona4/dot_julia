module matrices
using LinearAlgebra
using ..layers
export ScatterMatrix,matrix_layer,matrix_ref,matrix_tra,concatenate
struct ScatterMatrix
    S11::Array{Complex{Float64},2}
    S12::Array{Complex{Float64},2}
    S21::Array{Complex{Float64},2}
    S22::Array{Complex{Float64},2}
end

function matrix_layer(V,W,X,V0)
    A=(Matrix(W)\I+(Matrix(V)\I)*V0)#*.5
    B=(Matrix(W)\I-(Matrix(V)\I)*V0)#*.5
    Ai=I/A
    S11=S22=(A-X*B*Ai*X*B)\(X*B*Ai*X*A-B)
    S12=S21=(A-X*B*Ai*X*B)\X*(A-B*Ai*B)
    return ScatterMatrix(S11,S12,S21,S22)
end

function matrix_layer(l::Layer,V0)
    return matrix_layer(l.V,l.W,l.X,V0)
end
    

function matrix_ref(V,W,V0)
    A=W+V0\Matrix(V)
    B=W-V0\Matrix(V)
    Ai=I/A
    S11=-Ai*B
    S12=2*Ai
    S21=.5*(A-B*Ai*B)
    S22=B*Ai
    return ScatterMatrix(S11,S12,S21,S22)
end

function matrix_ref(l::Halfspace,V0)
    return matrix_ref(l.V,l.W,V0)
end

function matrix_tra(V,W,V0)
    A=W+V0\Matrix(V)
    B=W-V0\Matrix(V)
    Ai=I/A
    S11=B*Ai
    S12=.5*(A-B*Ai*B)
    S21=2*Ai
    S22=-Ai*B
    return ScatterMatrix(S11,S12,S21,S22)
end

function matrix_tra(l::Halfspace,V0)
    return matrix_tra(l.V,l.W,V0)
end
    
function concatenate(S11a,S12a,S21a,S22a,S11b,S12b,S21b,S22b)
    S11=S11a+(S12a/(I-S11b*S22a))*S11b*S21a
    S12=(S12a/(I-S11b*S22a))*S12b
    S21=(S21b/(I-S22a*S11b))*S21a
    S22=S22b+(S21b/(I-S22a*S11b))*S22a*S12b
    return S11,S12,S21,S22
end
    
function concatenate(S1,S2)
    S11,S12,S21,S22=concatenate(S1.S11,S1.S12,S1.S21,S1.S22,S2.S11,S2.S12,S2.S21,S2.S22)
    return ScatterMatrix(S11,S12,S21,S22)
end

function concatenate(Sin::Array{ScatterMatrix,1})
    Sout=Sin[1]
    for i=2:length(Sin)
        Sout=concatenate(Sout,Sin[i])
    end
    return Sout
end

end
