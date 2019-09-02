#!/usr/bin/env julia

if length(ARGS) < 2
    println("Usage: ./royfit.jl DETX HDF5FILE OUTFILE")
    exit(1)
end


using LinearAlgebra
using NeRCA
using HDF5
using ProgressMeter


function main()
    detx, filename, outfile = ARGS
    if isfile(outfile)
        print("Output file already exists. Do you want to overwrite it? [y/N]")
        readline() != "y" && exit(1)
    end

    outf = open(outfile, "w")
    write(outf, "group_id,dx,dy,dz,x,y,z,t0\n")

    @showprogress 1 for event in NeRCA.EventReader(filename, detx)
        hits = calibrate(event.hits, event.calib)
        triggered_hits = filter(h -> h.triggered, hits);
        prefit_track = NeRCA.prefit(triggered_hits)
        t = triggered_hits[1].t - 500
        Δd = norm(prefit_track.dir) * t
        shifted_pos = prefit_track.pos + normalize(prefit_track.dir) * Δd
        shifted_prefit_track = NeRCA.Track(prefit_track.dir, shifted_pos, t)
        first_hits = unique(h->h.dom_id, triggered_hits)
        final_track = NeRCA.multi_du_fit(prefit_track, first_hits)
        dir = final_track.dir
        pos = final_track.pos

        write(outf, "$(event.info.group_id),$(dir.x),$(dir.y),$(dir.z),$(pos.x),$(pos.y),$(pos.z),$(final_track.time)\n")
    end

    close(outf)
end

main()



