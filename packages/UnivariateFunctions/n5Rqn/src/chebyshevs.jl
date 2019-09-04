const number_of_chebyshevs_to_compile_into_binaries = 10

function next_chebyshev(previous::Sum_Of_Functions, two_previous::Sum_Of_Functions)
    return PE_Function(2.0,0.0,0.0,1) * previous - two_previous
end

first_kind_chebyshevs = Array{Sum_Of_Functions}(undef, number_of_chebyshevs_to_compile_into_binaries)
first_kind_chebyshevs[1] = Sum_Of_Functions([PE_Function(1.0,0.0,0.0,0)])
first_kind_chebyshevs[2] = Sum_Of_Functions([PE_Function(1.0,0.0,0.0,1)])
for i in 3:number_of_chebyshevs_to_compile_into_binaries
    first_kind_chebyshevs[i] = next_chebyshev(first_kind_chebyshevs[i-1], first_kind_chebyshevs[i-2])
end

second_kind_chebyshevs = Array{Sum_Of_Functions}(undef, number_of_chebyshevs_to_compile_into_binaries)
second_kind_chebyshevs[1] = Sum_Of_Functions([PE_Function(1.0,0.0,0.0,0)])
second_kind_chebyshevs[2] = Sum_Of_Functions([PE_Function(2.0,0.0,0.0,1)])
for i in 3:number_of_chebyshevs_to_compile_into_binaries
    second_kind_chebyshevs[i] = next_chebyshev(second_kind_chebyshevs[i-1], second_kind_chebyshevs[i-2])
end

function get_chevyshevs_up_to(num::Int, first_kind::Bool = true)
    chebyshevs = Array{Sum_Of_Functions}(undef, num)
    if num >= number_of_chebyshevs_to_compile_into_binaries
        if first_kind
            chebyshevs[1:number_of_chebyshevs_to_compile_into_binaries] = first_kind_chebyshevs
        else
            chebyshevs[1:number_of_chebyshevs_to_compile_into_binaries] = second_kind_chebyshevs
        end
        for i in (number_of_chebyshevs_to_compile_into_binaries+1):num
            chebyshevs[i] = next_chebyshev(chebyshevs[i-1], chebyshevs[i-2])
        end
    else
        if first_kind
            chebyshevs[1:num] = first_kind_chebyshevs[1:num]
        else
            chebyshevs[1:num] = second_kind_chebyshevs[1:num]
        end
    end
    return chebyshevs
end

function get_chebyshev(num::Int, first_kind::Bool = true)
    chebyshevs = get_chevyshev_up_to(num, first_kind)
    return chebyshevs[num]
end
