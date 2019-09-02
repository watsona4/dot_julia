# This file is part of Kpax3. License is MIT.

function save(ofile::String,
              x::KData)
  # create directory if it does not exist
  dirpath = dirname(ofile)
  if !isdir(dirpath)
    mkpath(dirpath)
  end

  fpo = FileIO.File(FileIO.@format_str("JLD2"), ofile)
  obj = Dict(
    "data" => x.data,
      "id" => x.id,
     "ref" => x.ref,
     "val" => x.val,
     "key" => x.key
  )

  FileIO.save(fpo, obj)

  nothing
end

function loadnt(ifile::String)
  # open ifile for reading and immediately close it. We do this to throw a
  # proper Julia standard exception if something is wrong
  f = open(ifile, "r")
  close(f)

  fpo = FileIO.File(FileIO.@format_str("JLD2"), ifile)
  (d, id, ref, val, key) = FileIO.load(fpo, "data", "id", "ref", "val", "key")

  NucleotideData(d, id, ref, val, key)
end

function loadaa(ifile::String)
  # open ifile for reading and immediately close it. We do this to throw a
  # proper Julia standard exception if something is wrong
  f = open(ifile, "r")
  close(f)

  fpo = FileIO.File(FileIO.@format_str("JLD2"), ifile)
  (d, id, ref, val, key) = FileIO.load(fpo, "data", "id", "ref", "val", "key")

  AminoAcidData(d, id, ref, val, key)
end
