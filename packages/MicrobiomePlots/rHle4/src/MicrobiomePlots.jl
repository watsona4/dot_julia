module MicrobiomePlots

using Microbiome
using RecipesBase
using Colors
import StatPlots: GroupedBar

export
    abundanceplot,
    AnnotationBar,
    annotationbar
    # zeroyplot

include("recipes.jl")

end
