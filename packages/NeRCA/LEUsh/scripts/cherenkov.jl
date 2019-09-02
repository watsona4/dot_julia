using Plots
using NeRCA
using BenchmarkTools

# pyplot()

dom_positions = [NeRCA.Position(0, 0, z)
                 for z in range(120, length=18, stop=800)]

track = NeRCA.Track([0, 1, 0], [0, 500, 500], 0)

plot(dom_positions, track)
plot!(dom_positions, NeRCA.Track([0,0,-1], [0,0,800]))
plot!(dom_positions, NeRCA.Track([0,-1,0], [0,1000,400]))


function eventplot(dom_positions, track::NeRCA.Track)
        plot3d([p.x for p in dom_positions],
               [p.y for p in dom_positions],
               [p.z for p in dom_positions],
               marker=2)
        plot3d!(
            [track.pos.x, track.pos.x + track.dir.x * 1000],
            [track.pos.y, track.pos.y + track.dir.y * 1000],
            [track.pos.z, track.pos.z + track.dir.z * 1000],
        )
end

eventplot(dom_positions, track)
