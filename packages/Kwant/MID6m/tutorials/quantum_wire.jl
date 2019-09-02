# First, define the tight-binding system

syst = kwant.Builder()

# Here, we are only working with square lattices
a = 1
lat = kwant.lattice.square(a)

t = 1.0
W = 10
L = 30

# Define the scattering region

for i in range(0,length=L) ## note 1:W not range(W)
    for j in range(0,length=W) ## note 1:W not range(W)
        # On-site Hamiltonian
        syst[lat(i, j)] = 4 * t

        # Hopping in y-direction
        if j > 0
            syst[lat(i,j),lat(i,j-1)] = -t
        end

        # Hopping in x-direction
        if i > 0
            syst[lat(i, j), lat(i - 1, j)] = -t
        end
    end
end

# Then, define and attach the leads:

# First the lead to the left
# (Note: TranslationalSymmetry takes a real-space vector)
sym_left_lead = kwant.TranslationalSymmetry((-a, 0))
left_lead = kwant.Builder(sym_left_lead)

for j in range(0,length=W)
    left_lead[lat(0, j)] = 4 * t
    if j > 0
        left_lead[lat(0, j), lat(0, j - 1)] = -t
    end
    left_lead[lat(1, j), lat(0, j)] = -t
end
syst.attach_lead(left_lead)

# Then the lead to the right
sym_right_lead = kwant.TranslationalSymmetry((a, 0))
right_lead = kwant.Builder(sym_right_lead)

for j in range(0,length=W) ## 1:W not range(W)
    right_lead[lat(0, j)] = 4 * t
    if j > 0 ## note 1-based indexing
        right_lead[lat(0, j), lat(0, j - 1)] = -t
    end
    right_lead[lat(1, j), lat(0, j)] = -t
end
