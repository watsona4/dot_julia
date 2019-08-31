struct Embedding
    embedding::AbstractArray{Float64, 2}
end

function random_embedding(npts::Int)
    dist = Normal()
    # Create an uncorrelated source and target
    invariant_embedding_found = false
    while !invariant_embedding_found
        ts = rand(dist, npts, 1)

        embedd = hcat(ts[1:(end - 2)], ts[2:(end - 1)], ts[3:end])

        if invariantset(embedd)
            invariant_embedding_found = true
            return Embedding(embedd)
        end
    end
end


function gaussian_embedding(npts::Int; covariance::Float64 = 0.4)
    dist = Normal()
    # Create an uncorrelated source and target
    invariant_embedding_found = false
    while !invariant_embedding_found
        source = rand(dist, npts, 1)
        dest = covariance .* source[1:end] .+ (1.0 - covariance) .* rand(dist, npts, 1)
        # Embedding
        embedd = hcat(source[1:end-1], source[2:end], dest[2:end])

        if invariantset(embedd)
            invariant_embedding_found = true
            return Embedding(embedd)
        end
    end
end


function gaussian_embedding(npts::Int, covariance::Float64)
    dist = Normal()
    # Create an uncorrelated source and target
    invariant_embedding_found = false
    while !invariant_embedding_found
        source = rand(dist, npts, 1)
        dest = covariance .* source[1:end] .+ (1.0 - covariance) .* rand(dist, npts, 1)
        # Embedding
        embedd = hcat(source[1:end-1], source[2:end], dest[2:end])

        if invariantset(embedd)
            invariant_embedding_found = true
            return Embedding(embedd)
        end
    end
end

function gaussian_embedding_arr(npts::Int; covariance::Float64 = 0.4)
    dist = Normal()
    # Create an uncorrelated source and target
    invariant_embedding_found = false
    while !invariant_embedding_found
        source = rand(dist, npts, 1)
        dest = covariance .* source[1:end] .+ (1.0 - covariance) .* rand(dist, npts, 1)
        # Embedding
        embedd = hcat(source[1:end-1], source[2:end], dest[2:end])

        if invariantset(embedd)
            invariant_embedding_found = true
            return embedd
        end
    end
end

"""
    embed(ts::Vector{Float64}, E::Int, tau::Int)

Embed a time series `ts` in `E` dimensions with embedding lag `tau`.
"""
function embed(ts::Vector{Float64}, E::Int, tau::Int)
  n::Int = length(ts)

  # Initialize
  embedded_ts = zeros(Float64, E, n - ((E - 1) * tau))
  l::Int = n - ((E - 1) * tau)

  for i in 1:E
    start_index = 1 + (i - 1) * tau
    stop_index  = start_index + l - 1
    embedded_ts[i, :] = ts[start_index:stop_index]
  end
  return copy(transpose(embedded_ts))
end

"""
    embed(ts::Vector{Float64}, E::Int, tau::Int)

Embed a time series `ts` in `E` dimensions with embedding lag `tau`.
"""
function embedding(ts::Vector{Float64}, E::Int, tau::Int)
  n::Int = length(ts)

  # Initialize
  embedded_ts = zeros(Float64, E, n - ((E - 1) * tau))
  l::Int = n - ((E - 1) * tau)

  for i in 1:E
    start_index = 1 + (i - 1) * tau
    stop_index  = start_index + l - 1
    embedded_ts[i, :] = ts[start_index:stop_index]
  end
  return Embedding(copy(transpose(embedded_ts)))
end

"""
    embedding_example(n_points::Int, m::Int, tau::Int)

Create an example embedding consisting of `n_points` points in `E` dimension space,
using embedding lag `tau`.
"""
function embedding_example(n_points::Int, E::Int, tau::Int)
  ts = randn(n_points)
  embedding = embed(ts, E, tau)
end

"""
    embedding_example(n_points::Int, m::Int, tau::Int)

Create an example embedding consisting of `n_points` points in `E` dimension space,
using embedding lag `tau`.
"""
function embedding_ex(n_points::Int, E::Int, tau::Int)
  ts = randn(n_points)
  embedding = embedding(ts, E, tau)
end
