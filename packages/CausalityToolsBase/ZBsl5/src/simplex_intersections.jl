
"""
    SimplexIntersectionType

An abstract type for different types of simplex intersections.
""" 
abstract type SimplexIntersectionType end

"""
    ExactIntersection

A type indicating that simplex intersections should be computed exactly.
""" 
struct ExactIntersection <: SimplexIntersectionType end

"""
    ApproximateIntersection

A type indicating that simplex intersections should be computed exactly.
""" 
struct ApproximateIntersection <: SimplexIntersectionType end

export 
SimplexIntersectionType, 
ExactIntersection, 
ApproximateIntersection