using Plots

struct Line
    pos
    dir
    len
end

@recipe function f(line::Line)
    # layout := (2, 2)

    @series begin
        # subplot := 1
        [line.pos[1], line.pos[1] + line.dir[1] * line.len],
        [line.pos[2], line.pos[2] + line.dir[2] * line.len]
    end
end


line = Line([0,0,0], [1,10,1], 10)

plot(line)

plot( plot([1, 2], [3, 4]), plot([2, 4], [1, 4]) )
