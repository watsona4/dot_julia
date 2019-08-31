using UnionFind

function floodfill(grid, wrap=false)
    uf = UnionFinder(length(grid))

    height, width = size(grid)
    for x in 1:width
        for y in 1:height
            # Look rightwards.
            if x != width && grid[x, y] == grid[x + 1, y]
                union!(uf, flatten(x, y, grid), flatten(x + 1, y, grid))
            elseif wrap && grid[x, y] == grid[1, y]
                union!(uf, flatten(x, y, grid), flatten(1, y, grid))
            end

            # Look upwards.
            if y != height && grid[x, y] == grid[x, y + 1]
                union!(uf, flatten(x, y, grid), flatten(x, y + 1, grid))
            elseif wrap && grid[x, y] == grid[x, 1]
                union!(uf, flatten(x, y, grid), flatten(x, 1, grid))
            end
        end
    end

    cf = CompressedFinder(uf)
    return reshape(cf.ids, size(grid))
end

flatten(x, y, grid) = y + (x - 1)size(grid)[1]
