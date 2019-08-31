"Apply many functions to the same argument"
mapf(fs, val) = map(f->f(val), fs)
mapf(fs) = val -> mapf(fs, val)

"mapf without return value"
foreachf(fs, val) = foreach(fs)
foreachf(fs) = val -> foreach(fs, val)
