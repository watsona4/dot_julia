# PhotoOrganizer

[![Build Status](https://travis-ci.org/GlenHertz/PhotoOrganizer.jl.svg?branch=master)](https://travis-ci.org/GlenHertz/PhotoOrganizer.jl)

[![Coverage Status](https://coveralls.io/repos/GlenHertz/PhotoOrganizer.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/GlenHertz/PhotoOrganizer.jl?branch=master)

[![codecov.io](http://codecov.io/github/GlenHertz/PhotoOrganizer.jl/coverage.svg?branch=master)](http://codecov.io/github/GlenHertz/PhotoOrganizer.jl?branch=master)

PhotoOrganizer is designed to organize photos (and videos) into a fixed directory structure archive (since manually managing photos is a waste of time).

# Usage:

    organize_photos(src_dirs, dst_root, rm_src, dry_run)

Move and rename photos in `src_dirs` source directories to an organized `dst_root` destination directory.

The destination directory is organized as follows:

    <root>/YYYY/<season>/YYYYMMDD_HHMMSS.SSS_<camera_model>.<extension>

where `season` is `Spring`, `Summer`, `Fall` or `Winter` (depending of photo's date).

## Arguments

- `src_dirs::Vector{String}`: dirctories containing photos to organize.
- `dst_root:String`: the destination directory of organized photos.
- `rm_src::Bool`: delete source photo if true.  Useful if coming from SD card.
- `dry_run::Bool`: if true then don't change anything, just print what would happen.

## Example
```julia
julia> rm_src=false
julia> dry_run=true
julia> organize_photos(["/media/hertz/NIKON/DCIM"], "/home/hertz/Pictures/Pictures", rm_src, dry_run)
```

## Dependencies

The binary `exiftool` is required and it can be installed on Ubuntu with `apt-get install libimage-exiftool-perl`.
