#!/usr/bin/env julia

if length(ARGS) < 2
    println("Usage: ./royprefit.jl DETX HDF5FILE OUTFILE")
    exit(1)
end


using LinearAlgebra
using NeRCA
using HDF5
using ProgressMeter


function main()
    detx, filename, outfile = ARGS
    if isfile(outfile)
        println("Output file already exists, aborting...")
        exit(1)
    end

    outf = open(outfile, "w")
    write(outf, "group_id,dx,dy,dz,x,y,z,v,t0\n")

    @showprogress 1 for event in NeRCA.EventReader(filename, detx)
        hits = calibrate(event.hits, event.calib)
        sort!(hits, by=h->h.t)
        sort!(hits, by=h->h.dom_id)
        NeRCA.count_multiplicities!(hits)

        shits = filter(h->h.multiplicity.count >= 4, hits)
        doms = unique(map(h->h.dom_id, shits))
        track = NeRCA.prefit(shits)
        dir = Direction(normalize(track.dir))
        v = norm(track.dir)
        write(outf, "$(event.info.group_id),$(dir.x),$(dir.y),$(dir.z),$(track.pos.x),$(track.pos.y),$(track.pos.z),$(v),$(track.time)\n")
    end

    close(outf)
end

main()
