using PyCall

const kwant = PyNULL()
const plotter = PyNULL()
const operator = PyNULL()
const physics = PyNULL()

function __init__()
    copy!(kwant, pyimport("kwant"))
    copy!(plotter, pyimport("kwant.plotter"))
    copy!(operator, pyimport("kwant.operator"))
    copy!(physics, pyimport("kwant.physics"))
end
