function splice_splines(left_spline::Schumaker, right_spline::Schumaker, splice_point::Real)
    end_in_left_spline = searchsortedlast(left_spline.IntStarts_, splice_point)
    left_starts        = left_spline.IntStarts_[1:end_in_left_spline]
    left_coefficients  = left_spline.coefficient_matrix_[1:end_in_left_spline,:]

    start_in_right     = searchsortedlast(right_spline.IntStarts_, splice_point)
    right_starts       = right_spline.IntStarts_[start_in_right:length(right_spline.IntStarts_)]
    right_coefficients = right_spline.coefficient_matrix_[start_in_right:length(right_spline.IntStarts_),:]

    # As the splice_point is probably not an interval start in the right_spline we need to adjust.
    G                       = splice_point - right_starts[1]
    a                       = right_coefficients[1,1]
    b                       = right_coefficients[1,2]
    c                       = right_coefficients[1,3]
    right_starts[1]         = splice_point
    right_coefficients[1,2] = 2*G*a + b
    right_coefficients[1,3] = a*(G^2) + b*G + c

    IntStarts = vcat(left_starts, right_starts)
    Coeffs    = vcat(left_coefficients, right_coefficients)
    return Schumaker(IntStarts, Coeffs)
end
