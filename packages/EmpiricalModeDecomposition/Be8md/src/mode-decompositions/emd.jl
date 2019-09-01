## Setting Struct

"Store the settings required for performing the EMD."
struct EMDSetting
    "Number of siftings"
    num_siftings::Int64
    "S number"
    s_num::Int64
    "Number of IMFS"
    m::Int64
    function EMDSetting(n::Int64, num_siftings::Int64, s_num::Int64, m::Int64) 
        if (s_num == 0 && num_siftings == 0) || (num_siftings < 0 || s_num < 0)
            throw(DomainError("Invalid EMD Settings."))
        end

        if m <= 0
            @warn "Invalid number of IMFs, will set to a default number."
            m = num_imfs(n)
        end
        

        return new(num_siftings, s_num, m)
    end
end

## Main Function

"""
    emd(input::Vector{Float64}, s::EMDSetting)

Compute EMD of the input signal with given settings.
"""
function emd(input_::Vector{Float64}, s::EMDSetting)
    input = deepcopy(input_)
    residue = deepcopy(input_)
    n = length(residue)

    output = zeros(n, s.m)

    for j = 1:s.m-1
        if j != 1
            input = deepcopy(residue)
        end

        sift!(input, s)

        residue -= input
        output[:,j] += input
    end

    output[:,s.m] += residue

    return output
end


## Helper functions

"""
    sift!(input::Vector{Float64}, s::EMDSetting)

Return the IMF that satisfies the given settings. In particular, it returns
an IMF that satisifes the S number criterion that is found within the set
number of siftings.
"""
function sift!(input::Vector{Float64}, s::EMDSetting)
    n = length(input)
    max_spline = zeros(n)
    min_spline = zeros(n)
    max_x = zeros(n)
    max_y = zeros(n)
    min_x = zeros(n)
    min_y = zeros(n)
    sift_counter = 0
    s_counter = 0

    num_max = -1
    num_min = -1
    num_zc = -1
    prev_num_max = -1
    prev_num_min = -1
    prev_num_zc = -1
    
    while (s.num_siftings == 0 || sift_counter < s.num_siftings)
        sift_counter += 1
        prev_num_max = num_max
        prev_num_min = num_min
        prev_num_zc = num_zc
        num_max, num_min, num_zc = find_extrema!(input, max_x, max_y,
                                                    min_x, min_y)

        if (s.s_num != 0)
            max_diff = num_max - prev_num_max
            min_diff = num_min - prev_num_min
            zc_diff = num_zc - prev_num_zc
            if abs(max_diff) + abs(min_diff) + abs(zc_diff) <= 1
                s_counter += 1
                if s_counter >= s.s_num
                    num_diff = num_min + num_max - 4 - num_zc
                    if abs(num_diff) <= 1
                        break;
                    end
                end
            end
        else
            s_counter = 0
        end
    end

    max_spline = evaluate_spline(max_x, max_y, num_max)
    min_spline = evaluate_spline(min_x, min_y, num_min)

    for i in eachindex(input)
        global input[i] -= 0.5(max_spline[i] + min_spline[i])
    end
end


"""
    find_extrema!(x::Vector{Float64}, max_x::Vector{Float64}, max_y::Vector{Float64},
                  min_x::Vector{Float64}, min_y::Vector{Float64})

Return the number of maxima, minima, and zero crossings of x after modifying max_x,
max_y, min_x, min_y to contain the maxima and minima of x.
"""
function find_extrema!(x::Vector{Float64},
                          max_x::Vector{Float64}, max_y::Vector{Float64},
                          min_x::Vector{Float64}, min_y::Vector{Float64})
    N = length(x)
    num_max = 1
    num_min = 1
    num_zc = 1
    
    if N == 0
        return num_max-1, num_min-1, num_zc-1
    end

    global max_x[1] = 1
    global max_y[1] = x[1]
    num_max += 1
    global min_x[1] = 1
    global min_y[1] = x[1]
    num_min += 1

    if N == 1
        return num_max-1, num_min-1, num_zc-1
    end

    prev_slope = 0
    prev_sign = (x[1] < 0) ? -1 : ((x[1] > 0) ? 1 : 0)
    flat_counter = 0

    for i=1:N-1
        if x[i+1] > x[i]
            if prev_slope == -1
                global min_x[num_min] = convert(Float64, i) - convert(Float64, flat_counter/2)
                global min_y[num_min] = x[i]
                num_min += 1
            end
            if prev_sign == -1 && x[i+1] > 0
                num_zc += 1
                prev_sign = 1
            elseif prev_sign == 0 && x[i+1] > 0
                prev_sign = 1
            end
            prev_slope = 1
            flat_counter = 0
        elseif x[i+1] < x[i]
            if prev_slope == 1
                global max_x[num_max] = convert(Float64, i) - convert(Float64, flat_counter/2)
                global max_y[num_max] = x[i]
                num_max +=1
            end
            if prev_sign == 1 && x[i+1] < 0
                num_zc += 1
                prev_sign = -1
            elseif prev_sign == 0 && x[i+1] < 0
                prev_sign = -1
            end
            prev_slope = -1
            flat_counter = 0
        else 
            flat_counter += 1
        end
    end

    global max_x[num_max] = N
    global max_y[num_max] = x[N]
    num_max += 1

    global min_x[num_min] = N
    global min_y[num_min] = x[N]
    num_min += 1

    if num_max >= 4
        max_el = linear_extrapolate(max_x[2], max_y[2], max_x[3], max_y[3], 0)
        if max_el > max_y[1]
            global max_y[1] = max_el
        end
        max_er = linear_extrapolate(max_x[num_max-3], max_y[num_max-3], max_x[num_max-2], max_y[num_max-2], N)
        if max_er > max_y[num_max]
            global max_y[num_max-1] = max_er
        end
    end
    if num_min >= 4
        min_el = linear_extrapolate(min_x[2], min_y[2], min_x[3], min_y[3], 0)
        if min_el < min_y[1]
            global min_y[1] = min_el
        end
        min_er = linear_extrapolate(min_x[num_min-3], min_y[num_min-3], min_x[num_min-2], min_y[num_min-2], N)
        if min_er < min_y[num_min]
            global min_y[num_min-1] = min_er
        end
    end

    return num_max-1, num_min-1, num_zc-1
end


"""
    linear_extrapolate(x_0::Float64, y_0::Float64, x_1::Float64, y_1::Float64, x::Int64)

Return the linear extrapolation of x based on x_0, x_1, y_0, y_1.
"""
function linear_extrapolate(x_0::Float64, y_0::Float64, x_1::Float64, y_1::Float64, x::Int64)
    if x_0 == x_1
        throw(DomainError(x_1, "x_1 can not equal x_0"))
    end

    return y_0 + (y_1 - y_0)*(x - x_0)/(x_1 - x_0)
end


"""
    evaluate_spline(x::Vector{Float64}, y::Vector{Float64}, n::Int64)

Return spline generated by the first n elements of (x,y).
"""
function evaluate_spline(x::Vector{Float64}, y::Vector{Float64}, n::Int64)
    max_j = x[n]
    N = length(x)
    
    if n <= 1
        throw(DomainError(n, "Not enough points for a spline."))
    end

    spline_y = zeros(N)

	if n == 2
        spl = Spline1D(x[1:n], y[1:n]; k=1)
        for j=1:Int(max_j)
			spline_y[j] = spl(j)
		end

		return spline_y
	elseif n == 3
        spl = Spline1D(x[1:n], y[1:n]; k=2)
        for j=1:Int(max_j)
			spline_y[j] = spl(j)
		end

		return spline_y
	end

    sys_size::Int32 = n-2
	diag = zeros(sys_size)
	sup_diag = zeros(sys_size-1)
	sub_diag = zeros(sys_size-1)
	g = zeros(sys_size)

	h_0 = x[2] - x[1]
	h_1 = x[3] - x[2]
	h_nm1 = x[n] - x[n-1]
	h_nm2 = x[n-1] - x[n-2]

	diag[1] = h_0 + 2*h_1
	sup_diag[1] = h_1 - h_0
	g[1] = 3/(h_0 + h_1)*((y[3] - y[2]) - (h_1/h_0)*(y[2] - y[1]))

	for i=3:n-2
		h_i = x[i+1] - x[i]
		h_im1 = x[i] - x[i-1]

		sub_diag[i-2] = h_im1
		diag[i-1] = 2*(h_im1 + h_i)
		sup_diag[i-1] = h_i
		g[i-1] = 3*((y[i+1] - y[i])/h_i - (y[i] - y[i-1])/h_im1)
	end

	sub_diag[sys_size-1] = h_nm2 - h_nm1
	diag[sys_size] = 2*h_nm2 + h_nm1
	g[sys_size] = 3/(h_nm1 + h_nm2)*((h_nm2/h_nm1)*(y[n]-y[n-1]) - (y[n-1] - y[n-2]))

	LAPACK.gtsv!(sub_diag, diag, sup_diag, g)

	c = zeros(n)

	for i=2:n-1
		c[i] = g[i-1]
	end

	c[1] = c[2] + (h_0/h_1)*(c[2]-c[3])
	c[n] = c[n-1] + (h_nm1/h_nm2)*(c[n-1]-c[n-2])

	i = 1
    for j=1:Int(max_j)
		if (j > x[i+1])
			i += 1
            if i >= n
                throw(DomainError(i, "exceeded spline boundary."))
            end
		end

		dx = j - x[i]

		if dx == 0
            spline_y[j] = y[i]
			continue
		end

		h_i = x[i+1] - x[i]
        a_i = y[i]
		b_i = (y[i+1] - y[i])/h_i - (h_i/3)*(c[i+1] + 2*c[i])
		c_i = c[i]
		d_i = (c[i+1] - c[i])/(3*h_i)
        spline_y[j] = a_i + dx*(b_i + dx*(c_i + dx*d_i))
	end

	return spline_y
end
