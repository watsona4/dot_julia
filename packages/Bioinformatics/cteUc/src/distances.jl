"""
    function edit_dist(s1::String, s2::String)

Calculate edit distance between two strings.
"""
function edit_dist(s1::String, s2::String)
    m = length(s1)
    n = length(s2)
    distance_mat = zeros(Int64, (m + 1, n + 1))
    for i = 2:(m+1), j = 2:(n+1)
        distance_mat[i, 1] = i - 1
        distance_mat[1, j] = j - 1
    end
    for i = 2:(m+1), j = 2:(n+1)
        if s1[i-1] == s2[j-1]
            cost = 0
        else
            cost = 1
        end
        distance_mat[i, j] = minimum([
            distance_mat[i-1, j] + 1,
            distance_mat[i, j-1] + 1,
            distance_mat[i-1, j-1] + cost
        ])
    end
    return distance_mat[m+1, n+1]
end

"""
    function hamming_dist(s1::String, s2::String)

Calculate Hamming distance between two strings.
"""
function hamming_dist(s1::String, s2::String)
    if length(s1) != length(s2)
        error("Both strings must be have same length.")
    end
    return sum([c1 != c2 for (c1, c2) in zip(s1, s2)])
end
