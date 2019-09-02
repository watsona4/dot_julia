module PhotoOrganizer

export organize_photos

using Dates

struct Photo
   src::String
   dt::Union{Missing,DateTime}
   dst::Union{Missing,String}
   backuped::Bool
   err
end

function Base.show(io::IO, ph::Photo)
   println(io, "Photo:")
   for (i, field) in enumerate(fieldnames(ph))
      f = getfield(ph, field)
      print(io, " - $field: $f")
      if i != length(fieldnames(ph))
         println(io)
      end
   end
end

function get_photo_dst_dir(dt::DateTime, dst_root::String)
   y, m, d = yearmonthday(dt)
   spring = Date(y, 3, 20)
   summer = Date(y, 6, 21)
   fall   = Date(y, 9, 22)
   winter = Date(y,12, 21)
   if dt < spring
      return joinpath(dst_root, string(y), "Winter")
   elseif dt < summer
      return joinpath(dst_root, string(y), "Spring")
   elseif dt < fall
      return joinpath(dst_root, string(y), "Summer")
   elseif dt < winter
      return joinpath(dst_root, string(y), "Fall")
   elseif dt >= winter
      # Consider part of next year's winter
      return joinpath(dst_root, string(y+1), "Winter")
   end
   error("Could not find season for $dt")
end

function _organize_photos(mount::String, dst_root::String, rm_src::Bool, dry_run::Bool)
   album = Vector{Photo}()
   dt0 = now()
   ms_in_year = Dates.Millisecond(daysinyear(Dates.year(dt0)) * 24 * 60 * 60 * 1000)
   if !isdir(mount)
       @warn "Mount doesn't exist, skipping:" mount
       return album
   end
   if dry_run
      @info("Reading from dir (DRY RUN): $mount")
   else
      @info("Reading from dir: $mount")
   end
   for line in eachline(Cmd(`exiftool -T -directory -filename -CreateDate -SubSecTime -modifydate -filemodifydate -model -r $mount`, ignorestatus=true))
      dir, fname, date, subsec, modifydate, filemodifydate, camera = split(line, ['\t'])
      if dir == "-"
         @warn("Bad SourceFile from exiftool: $line")
         continue
      end
      src = joinpath(dir, fname)
      dtnull = missing
      dstnull = missing
      backuped = false
      errmsg = missing
      print(src)
      if date == "-"
         date = modifydate
      end
      if date == "-"
         date = filemodifydate
      end
      fields = split(date, [':', ' ', '-', '+', 'Z'])
         yr, m, d, H, M, S = (0, 0, 0, 0, 0, 0)
      try
         yr, m, d, H, M, S = map(str -> parse(Int, str), fields[1:6])
      catch err
         errmsg = "Could not parse date: $fields, $err"
         @warn(errmsg)
         push!(album, Photo(src, dtnull, dstnull, backuped, errmsg))
         continue
      end
      if !(1990 < yr < 2100)
         errmsg = "year out of range ($yr), skipping: $line"
         @warn(errmsg)
         push!(album, Photo(src, dtnull, dstnull, backuped, errmsg))
         continue
      end
      if !(0 <= H <= 23)
         errmsg = "hour out of range ($H), skipping: $line"
         @warn(errmsg)
         push!(album, Photo(src, dtnull, dstnull, backuped, errmsg))
         continue
      end
      if !(0 <= M <= 59)
         errmsg = "minute out of range ($M), skipping: $line"
         @warn(errmsg)
         push!(album, Photo(src, dtnull, dstnull, backuped, errmsg))
         continue
      end
      if !(0 <= S <= 59)
         errmsg = "second out of range ($S), skipping: $line"
         @warn(errmsg)
         push!(album, Photo(src, dtnull, dstnull, backuped, errmsg))
         continue
      end
      MS = 0
      if all(isnumeric, subsec)
         try
            MS = round(Int, parse(Float64, "0.$(subsec)")*1000)
         catch err
            @warn("Could not parse ms: $subsec, $err")
            push!(album, Photo(src, dtnull, dstnull, backuped, errmsg))
            continue
         end
      end
      dt = DateTime(yr, m, d, H, M, S, MS)
      # Normalize name of new photo:
      ext = splitext(src)[2]
      new_dir = get_photo_dst_dir(dt, dst_root)
      if camera == "-"
         camera = ""
      else
         camera = string("_", replace(camera, " " => "_"))
      end
      froot = string(lpad(yr, 4, "0"), lpad(m, 2, "0"), lpad(d, 2, "0"), "_", 
                     lpad(H,  2, "0"), lpad(M, 2, "0"), lpad(S, 2, "0"), ".",
                     lpad(MS, 3, "0"), camera)
      is_actual_dup = false
      is_rename_needed = false
      local dst
      for uniq_suffix in ["", map(v->string("_v$v"), 2:200)...]
         dst = joinpath(new_dir, string(froot, uniq_suffix, ext))
         if isfile(dst)
            if stat(src).size == stat(dst).size
               is_actual_dup = true
               break
            else 
               is_rename_needed = true
               if length(uniq_suffix) == 0
                   printstyled(" renaming", color=:yellow)
               else
                   printstyled(" $uniq_suffix", color=:yellow)
               end
            end
         else
            break
         end
      end
      if is_rename_needed
         printstyled(" $uniq_suffix", color=:yellow)
      end
      if isfile(new_dir) && !isdir(new_dir)
          error("Expected directory but found a file:\n - $new_dir")
      end
      if !isdir(new_dir)
          printstyled(" mkdir -p $new_dir", color=:orange)
          if !dry_run
              run(`mkdir -p $new_dir`)
          end
      end
      backuped=false
      if !isfile(dst) && !is_actual_dup
          printstyled(" cp $dst", color=:green)
          if !dry_run
              try
                 #cp(src, dst, follow_symlinks=true)
                 run(`cp -dR --preserve=all $src $dst`)
                 backuped=true
              catch err
                 @warn("Cound not copy file: $src\n$err")
                 continue
              end
          end
      else
         printstyled(" Skipping dup (already backed up)", color=:green)
         backuped=true
      end
      age_in_years = (dt0 - dt) / ms_in_year
      if rm_src
          print(" rm src")
          if !dry_run
              try
                 rm(src)
              catch err
                 printstyled(" rm src failed: $err", bold=true, color=:red)
              end 
          end
      end
      println()
      push!(album, Photo(src, dt, dst, backuped, errmsg))
   end
   return album
end 

struct MountStat
   mount
   photos::Vector{Photo}
end

function report_missing(mount_stats::Vector{MountStat})
   open("missing.log", "w") do f
     printstyled("The following files were not backed up (see missing.log):\n", bold=true, color=:red)
     for mount_stat in mount_stats
        src_dir = mount_stat.mount
        if !isdir(src_dir)
           @warn("Source directory doesn't exist, skipping: $src_dir")
           continue
        end
        for file in eachline(`find $(src_dir) -type f`)
           if any(regex->occursin(regex, file), [r"Picasa\.ini$", r"album.txt", r"\.json$", r"\.DS_Store$", r"Thumbs\.db$", r"CardThumb\.db$", r"\.nomedia$"])
              continue  # non-important file
           end
           matching_photo_idx = findfirst(photo-> photo.src == file, mount_stat.photos)
           if matching_photo_idx != 0 
              photo = mount_stat.photos[matching_photo_idx]
              if !photo.backuped 
                 print(file)
                 print(f, file)
                 printstyled(" !backuped", color=:red)
                 print(f, " !backuped")
                 if !ismissing(photo.err)
                    msg = get(photo.err)
                    printstyled(" $msg", color=:red)
                    print(f, " $msg")
                 end
                 println()
                 println(f)
              end
           else
              print(file)
              print(f, file)
              printstyled(" missing", color=:red)
              print(f, " missing")
              println()
              println(f)
           end
        end
     end
   end
end

"""
    organize_photos(src_dirs, dst_root, rm_src, dry_run)

Move and rename photos in `src_dirs` source directories to an organized `dst_root` destination directory.

The destination directory is organized as follows:

    <root>/YYYY/<season>/YYYYMMDD_HHMMSS.SSS_<camera_model>.<extension>

where `season` is `Spring`, `Summer`, `Fall` or `Winter` (depending of photo's date).

# Arguments
- `src_dirs::Vector{String}`: dirctories containing photos to organize
- `dst_root:String`: the destination directory of organized photos 
- `rm_src::Bool`: delete source photos if true 
- `dry_run::Bool`: if true then don't change anything, just print what would happen

# Examples
```julia-repl
julia> organize_photos(["/home/hertz/Documents.local/Pictures"], "/home/hertz/Pictures/Pictures", 9999, true)
```
"""
function organize_photos(src_dirs::Vector{String}, dst_root::String, rm_src::Bool, dry_run::Bool)
    if dry_run
       @warn("DRY RUN: only printing what would happen")
    end
    mount_stats = Vector{MountStat}()
    for dir in src_dirs
       mount_stat = MountStat(dir, Photo[])
       for photo in _organize_photos(dir, dst_root, rm_src, dry_run)
          push!(mount_stat.photos, photo)
       end
       push!(mount_stats, mount_stat)
    end
    @info("backed up photos from the following mounts:")
    for stat in mount_stats
       @info(" $(length(stat.photos)): $(stat.mount)")
    end
    total = sum(length(stat.photos) for stat in mount_stats)
    @info(" $total photos in total")
    report_missing(mount_stats)
    if dry_run
       @warn("DRY RUN: only printing what would happen")
    end
end

function organize_photos(src_dir::String, args...)
    organize_photos([src_dir], args...)
end

end # module
