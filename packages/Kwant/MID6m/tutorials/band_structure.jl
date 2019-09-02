# Tutorial 2.4.1. Band structure calculations
# ===========================================
#
# Physics background
# ------------------
#  band structure of a simple quantum wire in tight-binding approximation
#
# Kwant features highlighted
# --------------------------
#  - Computing the band structure of a finalized lead.


function make_lead(a=1, t=1.0, W=10)
    # Start with an empty lead with a single square lattice
    lat = kwant.lattice.square(a)

    sym_lead = kwant.TranslationalSymmetry((-a, 0))
    lead = kwant.Builder(sym_lead)

    # build up one unit cell of the lead, and add the hoppings
    # to the next unit cell
    for j in range(0,length=W)
        lead[lat(0, j)] = 4 * t

        if j > 0
            lead[lat(0, j), lat(0, j - 1)] = -t
        end
        lead[lat(1, j), lat(0, j)] = -t
    end

    return lead
end
