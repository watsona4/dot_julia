include("../src/Bioinformatics.jl")

s1 = Bioinformatics.Sequence("CGATATAGATT", "DNA")
s2 = Bioinformatics.Sequence("TATATAGTAT", "DNA")

mat = Bioinformatics.dotmatrix(s1, s2)
plot = Bioinformatics.plot_dotmatrix(mat)

display(plot)
read(stdin, Char)
