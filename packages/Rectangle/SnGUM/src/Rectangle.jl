__precompile__()

module Rectangle

export  Line,
            isHorizontal, isVertical, length, parallelogram_area,
            ratio, intersects, merge_axis_aligned, sx, sy, ex, ey,
            intersect_axis_aligned, start, endof, horiz_desc, vert_asc,
        Rect,
            x, y, lx, ly, rx, ry, w, h, area, perimeter, hlines,
            vlines, lines, olines,
            union, intersects, inside, cg,
            to_plot_shape,
            projectX, projectY,
            visibleX, visibleY,
            has_x_overlap, has_y_overlap,
            avg_min_dist, min_dist,
            vline_xsection, hline_xsection,
        OrderedRectMapX, OrderedRectMapY,
            create_ordered_map, get_intersect_data, insert_rect!, delete_rect!,
        pcTol,
        AbstractBST, RBTree, BinarySearchTree, Iterator, IntervalTree, Interval,
        intersects

include("utils.jl")
include("Line.jl")
include("bst.jl")
include("interval.jl")
include("Rect.jl")

end # module
