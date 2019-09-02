# Rectangle

[![Build Status](https://travis-ci.org/sambitdash/Rectangle.jl.svg?branch=master)](https://travis-ci.org/sambitdash/Rectangle.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/vt9i3v1mndie7nkw?svg=true)](https://ci.appveyor.com/project/sambitdash/rectangle-jl)
[![codecov.io](http://codecov.io/github/sambitdash/Rectangle.jl/coverage.svg?branch=master)](http://codecov.io/github/sambitdash/Rectangle.jl?branch=master)

This is a simplified rectangle library for simple tasks with 2-D rectangles.
While the library will be enhanced for further functionalities, this will not be made to
work for higher dimensions. The numeric data types for most operations are preserved to the
extent practicable. However, where there is a natural affinity for the results to be `Float`
those are given emphasis. Currently the following methods are available.

## Methods for 2-D Rectangles

* `w(r)` - Width
* `h(r)` - Height
* `area(r)` - Area
* `perimeter(r)` - Perimeter
* Lines methods for rectangle ABCD
  * `vlines(r)` - returns line segments (AB, DC)
  * `hlines(r)` - returns line segments (AD, BC)
  * `lines(r)`  - returns line segments [AB, DC, AD, BC]
  * `olines(r)` - returns line segments [AB, BC, CD, DA]
  * `diags(r)`  - returns line segments [AC, BD]
* `union(r1, r2)` - Union of two rectangles resulting in a larger rectangle.
* `intersect(r1, r2)` - Intersection of two rectangles.
* `intersects(r1, r2)` - If rectangle `r1` and `r2` intersect each other.
* `intersects(r, l)` - If rectangle `r` and line `l` intersect each other.
* `inside(p, r)` - Point `p` is inside rectangle `r`
* `inside(ri, ro)` - Rectangle `ri` is fully enclosed in `ro`
* `cg(r)` - Center of gravity of the rectangle `r`
* `to_plot_shape(r)` - `Shape` object to be used in `Plots` library.
* `projectX(r1, r2)` - Find overlap regions when projected onto X-axis.
* `projectY(r1, r2)` - Find overlap regions when projected onto Y-axis
* `visibleX(r1, r2)`, `visibleY(r1, r2)` - Projects the rectangles along the X-axis
(Y-axis) and returns a rectangle area which is completely visible from both rectangles.
* `has_x_overlap(r1, r2)`, `has_y_overlap(r1, r2)` - If rectangles have overlap along the
x-direction (y-direction).
* `avg_min_dist(r1, r2)` - Rectangles are essentially point sets. Hence, one can
perceive existence of a minimum distance of one point in `r1` from `r2`. Similar, distance
would also exist for every point in `r2` from `r1`.
* `min_dist(r1, r2)` - The gap between two rectangular regions. If there is overlap along a
specific direction 0 will be returned.
* `create_ordered_map(rects, values; dir=1, reverseMax=zero(T))` - Ordered list of
  rectangles and associate data values. `dir=1` orders the rectangles
  by `x-axis` first and `2` by `y-axis`. `reverseMax` parameter provides the primary index
  to be sorted by reverse order. If the value of `reverseMax > zero(T)` then the ranges are
  subtracted from the range parameters so that they are sorted in a reverse order. This is 
  particularly useful to return values of intersect in a reverse order from top to bottom 
  or right to left.
* `intersect(ordered_rect_map, rect)` - Return all the values for rectangles that intersect
with `rect`.
* `insert_rect!(ordered_rect_map, rect, value)` - Insert value associated with the `rect`.
* `delete_rect!(ordered_rect_map, rect)` - Delete associated value for the `rect`. Returns
the associated value.
* `vline_xsection(rect, vlines)` - Given a Rectangle and a set of already 
sorted set of vertical lines ordered left to right, provides the indices that 
intersect the rectangle.
* `hline_xsection(rect, hlines)` - Given a Rectangle and a set of a sorted set 
of horizontal lines ordered top to bottom, provides the indices that intersect 
the rectangle.

## Methods for 2-D Lines

* `Line` - Representation of a line in 2-D.
* `isHorizontal(l)`, `isVertical(l)` - Returns if the line are horizontal or vertical
* `length(l)` - Length of the line
* `reverse(l)` - for a line AB returns line BA.
* `parallelogram_area(l, p)` - The area formed by the parallelogram formed by the line and
a point.
* `ratio(l,p)` - if point `p` lies on line `l`, then it will divide the line at a ratio 
`r : (1-r)` otherwise `nothing`
* `div(l, r)` - the point that divides the line `l` at ratio `r : (1-r)`
* `intersects(l1, l2)` - if line `l1` intersects `l2`. 
* `vert_asc(l1, l2)` - `isless` function  that can be used to sort vertical lines
in ascending order (left to right).
* `horiz_desc(l1, l2)` - `isless` function  that can be used to sort horizonal 
lines in descending order (top to bottom).

## Methods for Commonly Used Data Structures

Searching and sorting the data are very common with simple geometrical objects like lines
and rectangles in 2-D. Hence, simplified implementations of the following data structures
are provided here. If you are looking out for more elaborate packages you can look at 
`DataStructures.jl` or other such advanced data structure packages. Currently, only 
`insert!` and `delete!` operations are supported. 

### Binary Search Tree
### Red and Black Tree
### Interval Tree

## Contribution

Pull Requests and Issues are ways to submit changes and enhancements.
