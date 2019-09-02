function next_chebyshev(previous::Sum_Of_Functions, two_previous::Sum_Of_Functions, dim_name::Symbol)
    return PE_Function(2.0,Dict{Symbol,PE_Unit}(dim_name => PE_Unit(0.0,0.0,1))) * previous - two_previous
end

function get_first_kind_Chebyshevs(num::Int, dim_name::Symbol)
    if num < 1
        error("Select a positive number of Chebyshevs to return")
    else
        first_kind_chebyshevs = Array{Sum_Of_Functions}(undef, num)
        first_kind_chebyshevs[1] = Sum_Of_Functions([PE_Function(1.0,Dict{Symbol,PE_Unit}(dim_name => PE_Unit(0.0,0.0,0)))])
        if num > 1
            first_kind_chebyshevs[2] = Sum_Of_Functions([PE_Function(1.0,Dict{Symbol,PE_Unit}(dim_name => PE_Unit(0.0,0.0,1)))])
        end
        for n in 3:num
            first_kind_chebyshevs[n] = next_chebyshev(first_kind_chebyshevs[n-1], first_kind_chebyshevs[n-2], dim_name)
        end
        return first_kind_chebyshevs
    end
end
function get_second_kind_Chebyshevs(num::Int, dim_name::Symbol)
    if num < 1
        error("Select a positive number of Chebyshevs to return")
    else
        second_kind_chebyshevs = Array{Sum_Of_Functions}(undef, num)
        second_kind_chebyshevs[1] = Sum_Of_Functions([PE_Function(1.0,Dict{Symbol,PE_Unit}(dim_name => PE_Unit(0.0,0.0,0)))])
        if num > 1
            second_kind_chebyshevs[2] = Sum_Of_Functions([PE_Function(2.0,Dict{Symbol,PE_Unit}(dim_name => PE_Unit(0.0,0.0,1)))])
        end
        for n in 3:num
            second_kind_chebyshevs[n] = next_chebyshev(second_kind_chebyshevs[n-1], second_kind_chebyshevs[n-2], dim_name)
        end
        return second_kind_chebyshevs
    end
end

"""
    get_chevyshevs_up_to(num::Int, first_kind::Bool = true; dim_name::Symbol = default_symbol)
    Output all chebyshev polynomials up to degree num.
"""
function get_chevyshevs_up_to(num::Int, first_kind::Bool = true; dim_name::Symbol = default_symbol)
    if first_kind
        return get_first_kind_Chebyshevs(num,dim_name)
    else
        return get_second_kind_Chebyshevs(num,dim_name)
    end
end
