"""
    function frequency(seq::Sequence)

Count bases / amino acids for given sequence.
"""
function frequency(seq::Sequence)
    freqs = Dict([c => 0 for c in alphabets[seq.type]])
    for s in seq.seq
        freqs[s] += 1
    end
    return freqs
end

"""
    function gc_content(seq::Sequence)

Calculate GC-content of given sequence.
"""
function gc_content(seq::Sequence)
    gc_count = 0
    for s in seq.seq
        if s in "GC"
            gc_count += 1
        end
    end
    return gc_count / length(seq)
end

"""
    function gc_content(seq::Sequence, window_size::Int64)

Calculate GC-content of given sequence using a window.
"""
function gc_content(seq::Sequence, window_size::Int64)
    gc_contents = Float64[]
    for i in 1:(length(seq)-window_size)
        window = Sequence(seq[i:(i+window_size)], seq.type)
        push!(gc_contents, gc_content(window))
    end
    return gc_contents
end

"""
    function skew(seq::Sequence)

Calculate the skew values of sequence.
"""
function skew(seq::Sequence)
    len = length(seq)
    skew = Int[]
    current_skew = 0
    for i in 1:len
        if seq[i] == 'G'
            current_skew += 1
        elseif seq[i] == 'C'
            current_skew -= 1
        end
        push!(skew, current_skew)
    end
    return skew
end

"""
    function minimum_skew(seq::Sequence)

Find genome positions where the skew is minimum.
"""
function minimum_skew(seq::Sequence)
    skew_values = skew(seq)
    return findall(a -> a == minimum(skew_values), skew_values)
end

"""
    function protein_mass(seq::Sequence, type = "monoisotopic")

Calculate mass of given amino acid sequence.
"""
function protein_mass(seq::Sequence, type = "monoisotopic")
    if seq.type != "AA"
        error("Sequence must be a protein sequence.")
    end
    if type == "monoisotopic"
        mass = 18.01524
    else
        mass = 18.01056
    end
    for aa in seq.seq
        mass += aa_mass[type][aa]
    end
    return mass
end

"""
    function extinction_coeff(n_tyr, n_trp, n_cys::Int64)

The extinction coefficient indicates how much light a protein absorbs at a
certain wavelength. It is useful to have an estimation of this coefficient
for following a protein which a spectrophotometer when purifying it.

See also: https://web.expasy.org/protparam/protparam-doc.html.
"""
function extinction_coeff(n_tyr, n_trp, n_cys::Int64)
    return 1490 * n_tyr + 5500 * n_trp + 125 * n_cys
end

"""
    function instability_index(seq::Sequence)

The instability index provides an estimate of the stability of your protein in a test tube.

See also: https://web.expasy.org/protparam/protparam-doc.html.
"""
function instability_index(seq::Sequence)
    if seq.type != "AA"
        error("Sequence must be a protein sequence.")
    end
    ii = 10 / length(seq) *
         sum([instability_values[seq[i:(i+1)]] for i in 1:(length(seq)-1)])
    return ii
end

"""
    function aliphatic_index(x_ala, x_val, x_ile, x_leu::Float64)

The aliphatic index of a protein is defined as the relative volume occupied by
aliphatic side chains (alanine, valine, isoleucine, and leucine).

See also: https://web.expasy.org/protparam/protparam-doc.html.
"""
function aliphatic_index(x_ala, x_val, x_ile, x_leu::Float64)
    return x_ala + 2.9 * x_val + 3.9 * (x_ile + x_leu)
end

"""
    function gravy(seq::Sequence)

The GRAVY value for a peptide or protein is calculated as the sum of hydropathy
values of all the amino acids, divided by the number of residues in the
sequence.

See also: https://web.expasy.org/protparam/protparam-doc.html.
"""
function gravy(seq::Sequence)
    if seq.type != "AA"
        error("Sequence must be a protein sequence.")
    end
    return sum([hydropathicity[aa] for aa in seq.seq]) / length(seq)
end

"""
    function isoelectric_point(seq::Sequence)

The isoelectric point, is the pH at which a molecule carries no net electrical
charge or is electrically neutral in the statistical mean.

See also: https://web.expasy.org/protparam/protparam-doc.html,
http://isoelectric.org/algorithms.html.
"""
function isoelectric_point(seq::Sequence)
    if seq.type != "AA"
        error("Sequence must be a protein sequence.")
    end
    counts = Dict(
        'D' => 0,
        'E' => 0,
        'C' => 0,
        'Y' => 0,
        'H' => 0,
        'K' => 0,
        'R' => 0
    )
    for aa in seq.seq
        if haskey(counts, aa)
            counts[aa] += 1
        end
    end

    NQ = 0.0
    QN1 = 0
    QN2 = 0
    QN3 = 0
    QN4 = 0
    QN5 = 0
    QP1 = 0
    QP2 = 0
    QP3 = 0
    QP4 = 0

    pH = 6.5
    pHprev = 0.0
    pHnext = 14.0
    X = 0.0
    E = 0.01
    temp = 0.0

    while true
        QN1 = -1 / (1 + 10^(3.65 - pH))
        QN2 = -counts['D'] / (1 + 10^(3.9 - pH))
        QN3 = -counts['E'] / (1 + 10^(4.07 - pH))
        QN4 = -counts['C'] / (1 + 10^(8.18 - pH))
        QN5 = -counts['Y'] / (1 + 10^(10.46 - pH))
        QP1 = counts['H'] / (1 + 10^(pH - 6.04))
        QP2 = 1 / (1 + 10^(pH - 8.2))
        QP3 = counts['K'] / (1 + 10^(pH - 10.54))
        QP4 = counts['R'] / (1 + 10^(pH - 12.48))

        NQ = QN1 + QN2 + QN3 + QN4 + QN5 + QP1 + QP2 + QP3 + QP4
        if pH >= 14.0
            error("pH is higher than 14!")
        end
        if NQ < 0
            temp = pH
            pH -= (pH - pHprev) / 2
            pHnext = temp
        else
            temp = pH
            pH += (pHnext - pH) / 2
            pHprev = temp
        end
        if (pH - pHprev < E) && (pHnext - pH < E)
            break
        end
    end
    return pH
end

"""
    function protparam(seq::Sequence)

Computes various physico-chemical properties that can be deduced from a
protein sequence.

See also: https://web.expasy.org/protparam/protparam-doc.html.
"""
function protparam(seq::Sequence)
    statistics = Dict()
    statistics["Number of amino acids"] = length(seq)
    statistics["Molecular weight"] = protein_mass(seq, "average")
    statistics["Amino acid composition"] = frequency(seq)
    statistics["# of negatively charged residues"] = statistics["Amino acid composition"]['D'] +
                                                     statistics["Amino acid composition"]['E']
    statistics["# of positively charged residues"] = statistics["Amino acid composition"]['R'] +
                                                     statistics["Amino acid composition"]['K']
    statistics["Extinction coefficient"] = extinction_coeff(
        statistics["Amino acid composition"]['Y'],
        statistics["Amino acid composition"]['W'],
        statistics["Amino acid composition"]['C']
    )
    statistics["Instability index"] = instability_index(seq)
    statistics["Aliphatic index"] = aliphatic_index(
        100 * statistics["Amino acid composition"]['A'] /
        statistics["Number of amino acids"],
        100 * statistics["Amino acid composition"]['V'] /
        statistics["Number of amino acids"],
        100 * statistics["Amino acid composition"]['I'] /
        statistics["Number of amino acids"],
        100 * statistics["Amino acid composition"]['L'] /
        statistics["Number of amino acids"]
    )
    statistics["Grand average of hydropathicity (GRAVY)"] = gravy(seq)
    return statistics
end
