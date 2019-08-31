"""
# module Find

# Examples

```jldoctest
julia>
```
"""
module Find

using BisectPy: bisect_left, bisect_right

function index(a, x)
    i = bisect_left(a, x)
    (i != length(a) && a[i] == x) ? i : error("Index not found!")
end

end