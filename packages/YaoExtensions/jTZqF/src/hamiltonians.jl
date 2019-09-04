export heisenberg

"""
    heisenberg(nbit::Int; periodic::Bool=true)

heisenberg hamiltonian, for its ground state, refer `PRB 48, 6141`.
"""
function heisenberg(nbit::Int; periodic::Bool=true)
    sx = i->put(nbit, i=>X)
    sy = i->put(nbit, i=>Y)
    sz = i->put(nbit, i=>Z)
    map(1:(periodic ? nbit : nbit-1)) do i
        j=i%nbit+1
        sx(i)*sx(j)+sy(i)*sy(j)+sz(i)*sz(j)
    end |> sum
end
