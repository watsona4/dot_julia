flbl = ARGS[1]
fout = ARGS[2]

using EMIRT

lbl = readseg(flbl)

add_lbl_boundary!( lbl )

saveseg(fout, lbl, "main")
