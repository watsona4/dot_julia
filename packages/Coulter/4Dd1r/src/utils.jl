"""
    repvec(orig, reps)

Repeats the items in the first vector by the corresponding number of
times in the second vector. Essentially the inverse operation of `hist`
"""
function repvec(orig::Vector{T}, reps::Vector{Int}) where T
    (length(orig) != length(reps)) && error("Provided vectors have to be of same length")
    data = Array{T}(undef, sum(reps))
    j = 1
    for i in 1:length(orig)
        if reps[i] > 0
            data[j:(j+reps[i]-1)] .= orig[i]
            j += reps[i]
        end
    end
    data
end

"""
    volume(diameter)

Given the `diameter` of a sphere, return its volume
"""
volume(diameter::Number) = 4/3*π*(diameter/2)^3

"""
    diameter(volume)

Given the `volume` of a sphere, compute its diameter
"""
diameter(volume::Number) = 2*(3/4*volume/π)^(1/3)

"""
    load_folder(folder)

Loads all coulter runs in a folder into a dictionary where the keys are the
first parts of the filenames separated by an underscore.
"""
function load_folder(folder)
    runs = DefaultDict{String, Array{Coulter.CoulterCounterRun}}([])

    files = readdir(folder)
    filter!(x -> splitext(x)[2] == ".=#Z2", files)

    for measurement in files
        catname = split(measurement, "_")[1]
        push!(runs[catname], loadZ2(joinpath(folder, measurement), String(catname)))
    end

    for (catname, samples) in runs
        sort!(samples, by=i->i.timepoint)
    end

    runs
end
