module MolecularTopologies

export AbstractToplogy, GroTopology
export gro_topology

abstract type AbstractToplogy end

# Gromacs Gro File topology
struct GroTopology <: AbstractToplogy
    atom_names::Vector{String}
    residue_indices::Vector{Int}
    residue_names::Vector{String}
end

gro_topology(x) = GroTopology(x)

Base.length(topology::AbstractToplogy) = length(topology.atom_names)

function GroTopology(io::IO)
    lines = readlines(io)
    atom_names = map(lines[3:end-1]) do line
        strip(line[11:15])
    end
    residue_indices = map(lines[3:end-1]) do line
        parse(Int, line[1:5])
    end
    residue_names = map(lines[3:end-1]) do line
        strip(line[6:10])
    end
    GroTopology(atom_names, residue_indices, residue_names)
end


end #module
