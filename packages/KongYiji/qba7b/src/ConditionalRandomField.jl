
struct LinearChainConditionalRandomField{Tv <: AbstractFloat}
    featurenames::Vector{String}
    scores::Vector{Tv}
    matrix::Matrix{Any}
end

#=
function LinearChainConditionalRandomField(fs=[
    ["Y-1", "Y", "W"],
    ["Y-1", "Y", "P"],
    ["Y-1", "Y", "P-1"],
    ["Y", "W"],
    ["Y", "D"],
    ])
    fnames = ["Y-1", "Y", "P-1", "P", "P-2", "W-1", "W", "W+1", "D"]
    scores = fill(0., 0)

end
=#

function display(model::LinearChainConditionalRandomField)
    nr = size(model.matrix, 1)
    nc = size(model.matrix, 2)
    rows = Vector{Any}(undef, nr)
    for i = 1:nr
        rows[i] = map(x -> ismissing(x) ? "" : string(x), model.matrix[i, :])
        pushfirst!(rows[i], model.featurenames[i])
    end
    pushfirst!(rows, Any["FN\\Score", model.scores...])
    return display(Markdown.MD(Markdown.Table(rows, [:r, fill(:c, nc)...])))
end

function LinearChainConditionalRandomField(
    edgeobservations::Vector{Function},
    nodeobservations::Vector{Function},
    observationfuncs::Vector{Function}
    )
    body
end
function inference(model::LinearChainConditionalRandomField)

end

function estimation(model::LinearChainConditionalRandomField)

end

function edgeobs1(tag::Vector{Int}, poswords::Matrix{String}, i::Int)
    return (tag[i - 1], tag[i], poswords[i])
end
