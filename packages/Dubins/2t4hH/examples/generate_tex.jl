using Dubins

q0 = [0.0, 0.0, 0.0]
q1 = [3.0, 3.0, 0.0]
ρ = 1.0

errcode, path = dubins_shortest_path(q0, q1, ρ)
path_length = dubins_path_length(path)

sample_times = linspace(0, path_length, 100)

f = open("./sample.tex", "w")
write(f,"\\documentclass[10pt]{standalone}\n\\usepackage[T1]{fontenc}\n\\usepackage{pgfplots}\n\\pgfplotsset{compat=newest}
\\begin{document}
\\begin{tikzpicture}
\\begin{axis}[axis equal,grid=both,title={Dubins' Path}]
\\addplot[only marks, mark=*,color=red] plot coordinates {
($(q0[1]), $(q0[2])) ($(q1[1]), $(q1[2]))};
\\addplot[smooth, mark=none,color=red] plot coordinates {\n ($(q0[1]), $(q0[2]))  ")

for t in sample_times
    q = dubins_path_sample(path, t)
    write(f,"($(q[1]), $(q[2])) ")
end
write(f,"($(q1[1]), $(q1[2]))")
write(f,"};\n\\end{axis}\n\\end{tikzpicture}\n\\end{document}")
