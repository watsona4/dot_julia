using Images
using ImageView
using EMIRT

println("compare image and segmentation")
println("Usage: julia compare_img_seg.jl /path/of/img.h5 /path/of/seg.h5")
@assert length(ARGS) >= 2

fimg = ARGS[1]
fseg = ARGS[2]

img = readimg(fimg)[:,:,1:64]
seg = readseg(fseg)[:,:,1:64]

include(joinpath(Pkg.dir(), "EMIRT/plugins/show.jl"))

imgc, imgslice = show(img, seg)

#If we are not in a REPL
if (!isinteractive())

    # Create a condition object
    c = Condition()

    # Get the main window (A Tk toplevel object)
    win = toplevel(imgc)

    # Notify the condition object when the window closes
    bind(win, "<Destroy>", e->notify(c))

    # Wait for the notification before proceeding ...
    wait(c)
end
