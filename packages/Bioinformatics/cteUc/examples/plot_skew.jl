include("../src/Bioinformatics.jl")

seq = Bioinformatics.Sequence("CATGGGCATCGGCCATACGCC", "DNA")
plot = Bioinformatics.skew_plot(seq)

display(plot)
read(stdin, Char)
