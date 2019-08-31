import NearestNeighbors: KDTree, BallTree, BruteTree

KDTree(E::AbstractEmbedding,
        metric = Euclidean(); kwargs...) =
    NearestNeighbors.KDTree(E.points, metric; kwargs...)

BallTree(E::AbstractEmbedding,
        metric = Euclidean(); kwargs...) =
    NearestNeighbors.BallTree(E.points, metric; kwargs...)

BruteTree(E::AbstractEmbedding,
        metric = Euclidean(); kwargs...) =
    NearestNeighbors.BruteTree(E.points, metric; kwargs...)

export KDTree, BallTree, BruteTree
