using LCMGL
using Test

for i = 1:1e4
    LCMGLClient("test") do lcmgl
		color(lcmgl, rand(3)...)
		begin_mode(lcmgl, LCMGL.LINES)
		vertex(lcmgl, rand(3)...)
		vertex(lcmgl, rand(3)...)
		end_mode(lcmgl)
    end
end

for i = 1:1e3
    LCMGLClient("test") do lcmgl
        color(lcmgl, rand(4)...)
        sphere(lcmgl, (rand(3) .+ 1), 0.1, 20, 20)
        switch_buffer(lcmgl)
    end
end

lcmgl = LCMGLClient("test2")
for i = 1:1e3
    color(lcmgl, rand(4)...)
    sphere(lcmgl, rand(3), 0.1, 20, 20)
    switch_buffer(lcmgl)
end

let
    lcm = LCM()
    LCMGLClient(lcm, "test3") do lcmgl
        draw_axes(lcmgl)
        draw_axes(lcmgl)
        push_matrix(lcmgl)
        translate(lcmgl, 0.1, 0.2, 1)
        rotate(lcmgl, 90, 0, 0, 1)
        scale_axes(lcmgl, 0.5, 2.0, 4.0)
        draw_axes(lcmgl)
        begin_mode(lcmgl, LCMGL.TRIANGLES)
        normal(lcmgl, 0, 0, 1)
        vertex(lcmgl, 0, 0)
        normal(lcmgl, 0, 0, 1)
        vertex(lcmgl, 0, 1)
        normal(lcmgl, 0, 0, 1)
        vertex(lcmgl, 1, 0)
        end_mode(lcmgl)

        point_size(lcmgl, 5)
        begin_mode(lcmgl, LCMGL.POINTS)
        vertex(lcmgl, 1, 1, 1)
        end_mode(lcmgl)

        line_width(lcmgl, 2)
        begin_mode(lcmgl, LCMGL.LINES)
        vertex(lcmgl, 0, 0, 0)
        vertex(lcmgl, 1, 1, 1)
        end_mode(lcmgl)

        pop_matrix(lcmgl)
        switch_buffer(lcmgl)
    end
end
