const TensorSubGrid = ProductGrid{<:NTuple{N,GRID}} where N where {GRID<:AbstractSubGrid}
function tensorproductbitarray(vectors::Union{BitVector,Vector{Bool}}...)
	N = length(vectors)
	R = falses(map(length, vectors))
	for i in CartesianIndices(size(R))
		R[i] = reduce(&,map(k->vectors[k][i.I[k]],1:length(vectors)))
	end
	R
end

mask(grid::TensorSubGrid) = tensorproductbitarray(map(mask, elements(grid))...)
subindices(grid::TensorSubGrid) = findall(mask(grid))
supergrid(grid::TensorSubGrid) = ProductGrid(map(supergrid, elements(grid))...)
issubindex(i, g::TensorSubGrid) = all(map(issubindex, i, elements(g)))
issubindex(i::CartesianIndex, g::TensorSubGrid) = issubindex(i.I, g)
