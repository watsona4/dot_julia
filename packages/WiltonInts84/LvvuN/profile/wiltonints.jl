using CompScienceMeshes
using WiltonInts84

const p1 = point(0,0,0)
const p2 = point(1,0,0)
const p3 = point(0,1,0)

const c = point(0.2, 0.2, 0.2)
const r, R = 0.5, 1.3

function payload()
    I,K,G = wiltonints(p1,p2,p3,c,r,R,Val{1})
end

function driver()
    payload()
    Profile.clear_malloc_data()
    payload()
end

driver()
