# This file is part of Kpax3. License is MIT.

"""
  readfasta(ifile::String, protein::Bool, miss::Vector{UInt8}, l::Int,
verbose::Bool, verbosestep::Int)

Read data in FASTA format and convert it to an integer matrix. Sequences are
required to be aligned. Only polymorphic columns are stored.

## Arguments

- `ifile` Path to the input data file
- `protein` `true` if reading protein data or `false` if reading DNA data
- `miss` Characters (as `UInt8`) to be considered missing. Use
`miss = zeros(UInt8, 1)` if all characters are to be considered valid. Default
characters for `miss` are:

    - DNA data: _?, \\*, #, -, b, d, h, k, m, n, r, s, v, w, x, y, j, z_
    - Protein data: _?, \\*, #, -, b, j, x, z_

- `l` Sequence length. If unknown, it is better to choose a value which is
surely greater than the real sequence length. If `l` is found to be
insufficient, the array size is dynamically increased (not recommended from a
performance point of view). Default value should be sufficient for most
datasets
- `verbose` If `true`, print status reports
- `verbosestep` Print a status report every `verbosestep` read sequences

## Details

When computing evolutionary distances, don't put the gap symbol `-` among the
missing values. Indeed, indels are an important piece of information for
genetic distances.

FASTA data is encoded as standard 7-bit ASCII codes. The only exception is
Uracil which is given the same value 84 of Thymidine, i.e. each 'u' is silently
converted to 't' when reading DNA data. Conversion tables are the following:

+----------------------------------------+
|         Conversion table (DNA)         |
+----------------------------------------+
|          Nucleotide |  Code |  Integer |
+---------------------+-------+----------+
|           Adenosine |   A   |    97    |
|            Cytosine |   C   |    99    |
|             Guanine |   G   |   103    |
|           Thymidine |   T   |   116    |
|              Uracil |   U   |   116    |
|     Purine (A or G) |   R   |   114    |
| Pyrimidine (C or T) |   Y   |   121    |
|                Keto |   K   |   107    |
|               Amino |   M   |   109    |
|  Strong Interaction |   S   |   115    |
|    Weak Interaction |   W   |   119    |
|               Not A |   B   |    98    |
|               Not C |   D   |   100    |
|               Not G |   H   |   104    |
|          Not T or U |   V   |   118    |
|                 Any |   N   |   110    |
|                 Gap |   -   |    45    |
|              Masked |   X   |   120    |
+----------------------------------------+

+------------------------------------------------+
|           Conversion table (PROTEIN)           |
+------------------------------------------------+
|                  Amino Acid |  Code |  Integer |
+-----------------------------+-------+----------+
|                     Alanine |   A   |    97    |
|                    Arginine |   R   |   114    |
|                  Asparagine |   N   |   110    |
|               Aspartic acid |   D   |   100    |
|                    Cysteine |   C   |    99    |
|                   Glutamine |   Q   |   113    |
|               Glutamic acid |   E   |   101    |
|                     Glycine |   G   |   103    |
|                   Histidine |   H   |   104    |
|                  Isoleucine |   I   |   105    |
|                     Leucine |   L   |   108    |
|                      Lysine |   K   |   107    |
|                  Methionine |   M   |   109    |
|               Phenylalanine |   F   |   102    |
|                     Proline |   P   |   112    |
|                 Pyrrolysine |   O   |   111    |
|              Selenocysteine |   U   |   117    |
|                      Serine |   S   |   115    |
|                   Threonine |   T   |   116    |
|                  Tryptophan |   W   |   119    |
|                    Tyrosine |   Y   |   121    |
|                      Valine |   V   |   118    |
| Asparagine or Aspartic acid |   B   |    98    |
|  Glutamine or Glutamic acid |   Z   |   122    |
|       Leucine or Isoleucine |   J   |   106    |
|                         Gap |   -   |    45    |
|            Translation stop |   *   |    42    |
|                         Any |   X   |   120    |
+------------------------------------------------+

## Value

A tuple containing the following variables:

- `data` Multiple Sequence Alignment (MSA) encoded as a UInt8 matrix
- `id` Units' ids
- `ref` Reference sequence, i.e. a vector of the same length of the original
sequences storing the values of homogeneous sites. SNPs are instead represented
by a value of 46 ('.')
"""
function readfasta(ifile::String,
                   protein::Bool,
                   miss::Vector{UInt8},
                   l::Int,
                   verbose::Bool,
                   verbosestep::Int)
  # we read the file twice
  # the first time we check the total number of sequences, if each sequence
  # has the same length and at what location the SNPs are
  # the second time we store the data, keeping only the SNPs

  # note: this function has been written with a huge dataset in mind
  f = open(ifile, "r")

  s = strip(readuntil(f, '>', keep=true))
  if length(s) == 0
    close(f)
    throw(KFASTAError("No sequence was found."))
  elseif length(s) > 1
    close(f)
    throw(KFASTAError("First non empty row is not a sequence id."))
  end

  # we now know that there is a first sequence to read... but is the ID empty?
  sid = strip(readuntil(f, '\n'))

  if length(sid) == 0
    close(f)
    throw(KFASTAError("Missing sequence identifier. Sequence: 1."))
  end

  if !isascii(sid)
    close(f)
    throw(KFASTAError("FASTA file is not ASCII encoded."))
  end

  seqlen = 0
  tmpseqref = zeros(UInt8, l)
  tmpmissseqref = falses(length(tmpseqref))

  # support variables
  c = '\0'
  w = 0
  u = 0x00

  # start reading the first sequence
  keepgoing = true
  while keepgoing
    s = strip(readline(f))

    if !isascii(s)
      throw(KFASTAError("FASTA file is not ASCII encoded."))
    end

    if length(s) > 0
      if s[1] != '>'
        w = seqlen + length(s)

        # do we have enough space to store the first sequence?
        if w > length(tmpseqref)
          tmpseqref = copyto!(zeros(UInt8, w + l), tmpseqref)
          tmpmissseqref = copyto!(falses(w + l), tmpmissseqref)
        end

        for c in s
          u = UInt8(lowercase(c))

          if !((u == UInt8(32)) || (UInt8(9) <= u <= UInt8(13))) # skip blanks
            seqlen += 1

            if !in(u, miss)
              tmpseqref[seqlen] = u
              tmpmissseqref[seqlen] = false
            else
              tmpseqref[seqlen] = 0x00
              tmpmissseqref[seqlen] = true
            end
          end
        end
      else
        keepgoing = false
      end
    elseif eof(f)
      keepgoing = false
    end
  end

  if seqlen == 0
    close(f)
    throw(KFASTAError("Missing sequence. Sequence: 1."))
  end

  # at least a sequence has been found
  n = 1

  seqref = copyto!(zeros(UInt8, seqlen), 1, tmpseqref, 1, seqlen)
  missseqref = copyto!(falses(seqlen), 1, tmpmissseqref, 1, seqlen)

  if s[1] == '>'
    if length(s) > 1
      sid = lstrip(s, '>')
    else
      # there is only the '>' character
      close(f)
      throw(KFASTAError("Missing sequence identifier. Sequence: 2."))
    end
  end

  curlen = 0

  snp = falses(seqlen)
  seq = zeros(UInt8, seqlen)
  missseq = falses(seqlen)

  for line in eachline(f)
    s = strip(line)

    if !isascii(s)
      throw(KFASTAError("FASTA file is not ASCII encoded."))
    end

    if length(s) > 0
      if s[1] != '>'
        for c in s
          u = UInt8(lowercase(c))

          if !((u == UInt8(32)) || (UInt8(9) <= u <= UInt8(13))) # skip blanks
            curlen += 1

            if curlen > seqlen
              close(f)
              throw(KFASTAError(string("Different sequence length: sequence ",
                                       n + 1, " (", sid, ") ", "is longer ",
                                       "than expected.")))
            end

            if !in(u, miss)
              seq[curlen] = u
              missseq[curlen] = false
            else
              seq[curlen] = 0x00
              missseq[curlen] = true
            end
          end
        end
      else
        # we just finished scanning the previous sequence
        if curlen != seqlen
          close(f)
          throw(KFASTAError(string("Different sequence length: sequence ",
                                   n + 1, " (", sid, ") ", "is shorter than ",
                                   "expected.")))
        end

        n += 1

        for b in 1:seqlen
          if !missseq[b]
            if missseqref[b]
              # this sequence has a non-missing value where it is missing in
              # the reference sequence
              seqref[b] = seq[b]
              missseqref[b] = false
            else
              # to be compared, both values must be non-missing
              snp[b] = snp[b] || (seq[b] != seqref[b])
            end
          end
        end

        if verbose && (n % verbosestep == 0)
          println(n, " sequences have been pre-processed.")
        end

        if length(s) > 1
          sid = lstrip(s, '>')
          curlen = 0
        else
          # there is only the '>' character
          close(f)
          throw(KFASTAError(string("Missing identifier at sequence ", n + 1,
                                   ".")))
        end
      end
    end
  end

  # by construction, the last sequence has not been pre-processed
  if curlen != seqlen
    close(f)
    throw(KFASTAError(string("Different sequence length: sequence ", n + 1,
                             "(", sid, ") ", "is shorter than expected.")))
  end

  n += 1

  for b in 1:seqlen
    if !missseq[b]
      if missseqref[b]
        # this sequence has a non-missing value where it is missing in the
        # reference sequence
        seqref[b] = seq[b]
        missseqref[b] = false
      else
        # to be compared, both values must be non-missing
        snp[b] = snp[b] || (seq[b] != seqref[b])
      end
    end
  end

  m = 0
  for b in 1:seqlen
    if snp[b]
      m += 1
    end
  end

  if verbose
    println("Found ", n, " sequences: ", m, " SNPs out of ", seqlen,
            " total sites.\nProcessing data...")
  end

  data = zeros(UInt8, m, n)
  id = Array{String}(undef, n)
  enc = zeros(UInt8, 127)

  h1 = 0
  h2 = 0
  missing = false

  for h1 in 1:127
    missing = false
    h2 = 1

    while !missing && (h2 <= length(miss))
      missing = (UInt8(h1) == miss[h2])
      h2 += 1
    end

    enc[h1] = !missing ? UInt8(h1) : UInt8('?')
  end

  if !protein
    enc[Int('u')] = UInt8('t')
  end

  # go back at the beginning of the file and start again
  seekstart(f)

  # we already checked that the first non-empty element is the id
  i = 1

  s = strip(readuntil(f, '>'))
  id[i] = strip(readuntil(f, '\n'))

  i1 = 0
  i2 = 0
  for line in eachline(f)
    s = strip(line)

    if length(s) > 0
      if s[1] != '>'
        for c in s
          u = UInt8(lowercase(c))

          if !((u == UInt8(32)) || (UInt8(9) <= u <= UInt8(13))) # skip blanks
            i1 += 1

            if snp[i1]
              i2 += 1
              data[i2, i] = enc[u]
            end
          end
        end
      else
        i += 1

        if verbose && (i % verbosestep == 0)
          println(i, " sequences have been processed.")
        end

        # move on with the next sequence
        id[i] = lstrip(s, '>')

        i1 = 0
        i2 = 0
      end
    end
  end

  if verbose
    println("All ", i, " sequences have been processed.")
  end

  close(f)

  ref = fill(UInt8('.'), seqlen)
  for b in 1:seqlen
    if !snp[b]
      ref[b] = seqref[b]
    end
  end

  (data, id, ref)
end

function countfields(string::String,
                     delim::Char)
  ncol = 0

  idx = search(string, delim)
  while idx > 0
    ncol += 1
    idx = search(string, delim, idx + 1)
  end

  ncol
end

function readdata(ifile::String,
                  delim::Char,
                  miss::Vector{String},
                  verbose::Bool,
                  verbosestep::Int)
  # characters to strip from data values
  chars = ['"', ' ', '\t', '\n', '\r']

  f = open(ifile, "r")

  # find the first sequence (skip initial blank lines)
  s = ""
  keepgoing = true
  while keepgoing
    s = strip(readline(f))

    if length(s) > 0 || eof(f)
        keepgoing = false
    end
  end

  if length(s) == 0
    close(f)
    throw(KCSVError("No observation was found."))
  end

  obsref = map(x -> String(strip(x, chars)), split(s, ','))

  p = length(obsref)

  if p == 1
    close(f)
    throw(KCSVError(string("Delimiter '",  delim,
                           "' was not found in the first observation.")))
  end

  # at least a sequence has been found
  n = 1

  # polymorphic columns
  pol = falses(p)

  # missing values
  missobs = indexin(obsref, miss) .!= nothing

  # count the observations and check that they are all the same length
  for line in eachline(f)
    s = strip(line)

    if length(s) > 0
      obs = map(x -> String(strip(x, chars)), split(s, ','))

      if p != length(obs)
        close(f)
        throw(KCSVError(string("Different length. Failed at observation ",
                               n + 1, " (", obs[1], ").")))
      end

      for b in 2:p
        if !(obs[b] in miss)
          if missobs[b]
            # this observation has a non-missing value where it is missing in
            # the reference observation
            obsref[b] = obs[b]
            missobs[b] = false
          else
            # to be compared, both values must be non-missing
            pol[b] = pol[b] || (obs[b] != obsref[b])
          end
        end
      end

      n += 1

      if verbose && (n % verbosestep == 0)
        println(n, " observations have been pre-processed.")
      end
    end
  end

  m = 0
  for b in 2:p
    if pol[b]
      m += 1
    end
  end

  if verbose
    println("Found ", n, " observations: ", m, " polymorphisms out of ",
            p - 1, " total columns.\nProcessing data...")
  end

  data = Array{String}(undef, m, n)
  id = Array{String}(undef, n)

  # go back at the beginning of the file and start again
  seekstart(f)

  i = 0
  for line in eachline(f)
    s = strip(line)

    if length(s) > 0
      obs = map(x -> String(strip(x, chars)), split(s, ','))

      i += 1

      j = 0
      for b in 2:p
        if pol[b]
          data[j += 1, i] = !(obs[b] in miss) ? obs[b] : ""
        end
      end

      id[i] = obs[1]

      if verbose && (i % verbosestep == 0)
        println(i, " observations have been processed.")
      end
    end
  end

  if verbose
    println("All ", i, " sequences have been processed.")
  end

  close(f)

  ref = fill(".", p - 1)
  for a in 2:p
    if !pol[a]
      ref[a - 1] = obsref[a]
    end
  end

  (data, id, ref)
end
