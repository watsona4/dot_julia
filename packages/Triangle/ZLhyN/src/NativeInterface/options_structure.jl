#=
/* Switches for the triangulator.                                            */

-p Triangulates a Planar Straight Line Graph (.poly file).
-r Refines a previously generated mesh.
-q Quality mesh generation with no angles smaller than 20 degrees. An alternate minimum angle may be specified after the `q'.
-a Imposes a maximum triangle area constraint. A fixed area constraint (that applies to every triangle) may be specified after the `a', or varying area constraints may be read from a .poly file or .area file.
-u Imposes a user-defined constraint on triangle size.
-A Assigns a regional attribute to each triangle that identifies what segment-bounded region it belongs to.
-c Encloses the convex hull with segments.
-D Conforming Delaunay: use this switch if you want all triangles in the mesh to be Delaunay, and not just constrained Delaunay; or if you want to ensure that all Voronoi vertices lie within the triangulation.
-j Jettisons vertices that are not part of the final triangulation from the output .node file (including duplicate input vertices and vertices ``eaten'' by holes).
-e Outputs (to an .edge file) a list of edges of the triangulation.
-v Outputs the Voronoi diagram associated with the triangulation. Does not attempt to detect degeneracies, so some Voronoi vertices may be duplicated.
-n Outputs (to a .neigh file) a list of triangles neighboring each triangle.
-g Outputs the mesh to an Object File Format (.off) file, suitable for viewing with the Geometry Center's Geomview package.
-B Suppresses boundary markers in the output .node, .poly, and .edge output files.
-P Suppresses the output .poly file. Saves disk space, but you lose the ability to maintain constraining segments on later refinements of the mesh.
-N Suppresses the output .node file.
-E Suppresses the output .ele file.
-I Suppresses mesh iteration numbers.
-O Suppresses holes: ignores the holes in the .poly file.
-X Suppresses exact arithmetic.
-z Numbers all items starting from zero (rather than one). Note that this switch is normally overrided by the value used to number the first vertex of the input .node or .poly file. However, this switch is useful when calling Triangle from another program.
-o2 Generates second-order subparametric elements with six nodes each.
-Y Prohibits the insertion of Steiner points on the mesh boundary. If specified twice (-YY), it prohibits the insertion of Steiner points on any segment, including internal segments.
-S Specifies the maximum number of added Steiner points.
-i Uses the incremental algorithm for Delaunay triangulation, rather than the divide-and-conquer algorithm.
-F Uses Steven Fortune's sweepline algorithm for Delaunay triangulation, rather than the divide-and-conquer algorithm.
-l Uses only vertical cuts in the divide-and-conquer algorithm. By default, Triangle uses alternating vertical and horizontal cuts, which usually improve the speed except with vertex sets that are small or short and wide. This switch is primarily of theoretical interest.
-s Specifies that segments should be forced into the triangulation by recursively splitting them at their midpoints, rather than by generating a constrained Delaunay triangulation. Segment splitting is true to Ruppert's original algorithm, but can create needlessly small triangles. This switch is primarily of theoretical interest.
-C Check the consistency of the final mesh. Uses exact arithmetic for checking, even if the -X switch is used. Useful if you suspect Triangle is buggy.
-Q Quiet: Suppresses all explanation of what Triangle is doing, unless an error occurs.
-V Verbose: Gives detailed information about what Triangle is doing. Add more `V's for increasing amount of detail. `-V' gives information on algorithmic progress and detailed statistics.
-h Help: Displays complete instructions.

/*  If the size of the object file is important to you, you may wish to      */
/*  generate a reduced version of triangle.o.  The REDUCED symbol gets rid   */
/*  of all features that are primarily of research interest.  Specifically,  */
/*  the -DREDUCED switch eliminates Triangle's -i, -F, -s, and -C switches.  */
/*  The CDT_ONLY symbol gets rid of all meshing algorithms above and beyond  */
/*  constrained Delaunay triangulation.  Specifically, the -DCDT_ONLY switch */
/*  eliminates Triangle's -r, -q, -a, -u, -D, -Y, -S, and -s switches.       */
=#

mutable struct TriangulateOptions
    pslg::Bool #p
    regionattrib::Bool # A
    convex::Bool # c
    jettison::Bool # j
    firstnumberiszero::Bool # z
    edgesout::Bool # e
    voronoi::Bool # v
    neighbors::Bool # n
    nobound::Bool # B
    nopolywritten::Bool # P
    nonodewritten::Bool # N
    noelewritten::Bool # E
    noiterationnum::Bool # I
    noholes::Bool # O
    noexactaritmetic::Bool # X
    order::Bool # o
    orderHow::Int64 # 1...2...3
    dwyer::Bool # l
    quiet::Bool # Q
    verbose::Bool # V
    TriangulateOptions() = new(false, 
    false, false, false, false, false, false, false,
    # No_xyz_ selector(s)
    true, true, false, false, true, false, false, 
    # order
    false, 0, 
    false, 
    # Quiet Verbose
    true, false)
end

function getTriangulateStringOptions(self::TriangulateOptions)
    output_stri = ""

    if self.pslg
        output_stri = output_stri * "p"
    end

    if self.regionattrib
        output_stri = output_stri * "A"
    end
    
    if self.convex
        output_stri = output_stri * "c"
    end

    if self.jettison
        output_stri = output_stri * "j"
    end

    if self.firstnumberiszero
        output_stri = output_stri * "z"
    end

    if self.edgesout
        output_stri = output_stri * "e"
    end

    if self.voronoi
        output_stri = output_stri * "v"
    end

    if self.neighbors
        output_stri = output_stri * "n"
    end

    if self.nobound
        output_stri = output_stri * "B"
    end

    if self.nopolywritten
        output_stri = output_stri * "P"
    end

    if self.nonodewritten
        output_stri = output_stri * "N"
    end

    if self.noelewritten
        output_stri = output_stri * "E"
    end

    if self.noiterationnum
        output_stri = output_stri * "I"
    end

    if self.noholes
        output_stri = output_stri * "O"
    end

    if self.noexactaritmetic
        output_stri = output_stri * "X"                                                
    end

    if self.order && self.orderHow > 0
        output_stri = output_stri * "o" * string(self.orderHow) 
    end    

    if self.dwyer
        output_stri = output_stri * "l"
    end

    if self.quiet
        output_stri = output_stri * "Q"                                                
    end

    if self.verbose
        output_stri = output_stri * "V"                                                
    end

    return output_stri
end