module Perf
using PhaseSpaceIO
using PhaseSpaceIO.Testing
using BenchmarkTools

path = IAEAPath(tempname())
iaea_writer(path, IAEAHeader{0,0}()) do w
    P = IAEAParticle{0,0}
    ps = [arbitrary(P) for _ in 1:10^6]
    for p in ps
        write(w, p)
    end
end

display(@benchmark phsp_iterator(collect, path))
end
