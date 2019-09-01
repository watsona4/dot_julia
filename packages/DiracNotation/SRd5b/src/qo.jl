using QuantumOptics

function dirac(io::IO, state::Union{Ket, Bra}, statename="ψ"; header::Bool=false)
    header && summary(io, state)
    data = state.data
    shape = reverse(state.basis.shape)
    if _islatex && isdefined(Main, :IJulia) && Main.IJulia.inited # for IJulia rendering
        if statename == "ψ"
            statename = "\\psi"
        end
        if state isa Ket
            str = "\$" * sprint(io -> print_dirac(io, data, shape, statename)) * "\$"
        else
            str = "\$" * sprint(io -> print_dirac(io, transpose(data), shape, statename)) * "\$"
        end
        display("text/markdown", str)
    else
        if state isa Ket
            print_dirac(io, data, shape, statename)
        else
            print_dirac(io, transpose(data), shape, statename)
        end
    end
end
dirac(state::Union{Ket, Bra}, statename="ψ"; header::Bool=false) = dirac(stdout, state, statename, header=header)


function dirac(io::IO, state::Union{DenseOperator, SparseOperator}, statename="ρ"; header::Bool=false)
    if header
        summary(io, state)
        println(io)
    end
    data = state.data
    lshape = reverse(state.basis_l.shape)
    rshape = reverse(state.basis_r.shape)
    if _islatex && isdefined(Main, :IJulia) && Main.IJulia.inited # for IJulia rendering
        if statename == "ρ"
            statename = "\\rho"
        end
        str = "\$" * sprint(io -> print_dirac(io, data, lshape, rshape, statename)) * "\$"

        display("text/markdown", str)
    else
        print_dirac(io, data, lshape, rshape, statename)
    end
end
dirac(state::Union{DenseOperator, SparseOperator}, statename="ρ"; header::Bool=false) = dirac(stdout, state, statename, header=header)
