"""
    function dotmatrix(s1::Sequence, s2::Sequence)

Calculate the dotplot matrix for given two sequences.
"""
function dotmatrix(s1::Sequence, s2::Sequence)
    mat = zeros(Int8, (length(s1), length(s2)))
    for i in 1:length(s1)
        for j in 1:length(s2)
            if s1[i] == s2[j]
                mat[i, j] = 1
            end
        end
    end
    return mat
end

"""
    function global_alignment_linear_gap(seq1, seq2, sm, d)

Needleman-Wunsch algorithm with linear gap penalty.
"""
function global_alignment_linear_gap(seq1::Sequence, seq2::Sequence, sm, d)
    m = length(seq1) + 1
    n = length(seq2) + 1
    mat = zeros(m, n)
    for i in 1:m
        mat[i, 1] = -(i - 1) * d
    end
    for j in 1:n
        mat[1, j] = -(j - 1) * d
    end
    for j in 2:n
        for i in 2:m
            s1 = mat[i-1, j-1] + sm[(seq1[i-1], seq2[j-1])]
            s2 = mat[i-1, j] - d
            s3 = mat[i, j-1] - d
            mat[i, j] = max(s1, s2, s3)
        end
    end
    return mat
end
