
using MolecularTopologies

using Test

topology = open(gro_topology, "test.gro")

@test topology.atom_names[60] == "C2C"
@test topology.residue_indices[60] == 2
@test topology.residue_names[60] == "DLPC"

@test topology.atom_names[71050] == "OW"
@test topology.residue_indices[71050] == 17028
@test topology.residue_names[71050] == "SOL"

len = length(topology)
@test len == 71400
