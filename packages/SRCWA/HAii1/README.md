# SRCWA.jl
Scatter-matrix Rigorously Coupled Wave Analysis implemented in Julia

This solves Maxwell's equations for periodically patterned multilayers of optically isotropic materials, currently supporting the computation of reflection, transmission and layerwise absorption for arbitrary plane wave incidence. 

## Usage

### Defining a reciprocal space grid
```julia
using SRCWA
Nx=Ny=3#maximum order of the reciprocal space vector in x and y
nx,ny,dnx,dny=grid_n(Nx,Ny)#create grids in reciprocal space
```
SRCWA solves Maxwell equtions in reciprocal space. All electric and magnetic fields are dealt with in terms of frequency $k_0$, reciprocal space x and y wavevector $k_x$ and $k_y$, and real space z coordinate $z$. Nx and Ny define the highes index of the reciprocal lattice vector, so Nx=0 gives only zeroth order and a one-element vector while Nx=1 gives the three-element vector (-1,0,1). Higher orders give higher accuracy in the result at the cost of higher computation time. When dealing with structures that are homeogenous in one or both lateral directions, the resulting order can be left at zero. 

### Scaling the grid to the desired frequency and periodicity
```julia
theta=1E-5#incident angle in degrees between propagation direction and surface normal
phi=0#azimuth angle in degrees
lambda=1000#wavelength
ax=ay=1000#uni cell size in x and y
epsilon_ref=1#reflection halfspace (space above the device) relative permittivity
k0,Kx,Ky,kin=grid_k(nx,ny,theta,phi,lambda,ax,ay,epsilon_ref)
```
In order to obtain the reciprocal lattice vectors, one has to define the incident wavelength and real space unit cell size and scale the grid by these. This RCWA implementation works for arbitrary plane wave incidence conditions. However, $\theta$ should not be set to zero in order to avoid numerical singularities. One can find a sufficiently small angle where other numerical errors overshadow the problem of imperfectly normal incidence. The choice of the length units for wavelength and cell size is arbitrary, but must be consistent.

The returned values are the free-space wavevector aka frequency $k_0$ and diagonal matrices of the lateral reciprocal wave vectors Kx and Ky. kin is the incident wave vector required for the calculation of the normalized field components of the impinging plane wave. 

### Reflection and Transmission halfspace
```julia

epsilon_tra=4#transmission halfspace relative permittivity
refspace=halfspace(Kx,Ky,epsilon_ref)#reflection halfspace effective impedance and modes
traspace=halfspace(Kx,Ky,epsilon_tra)#transmission halfspace effective impedance and modes
V0,Kz0=modes_freespace(Kx,Ky)#free space effective impedance and modes for normalization
Sref=matrix_ref(refspace,V0)#scattering matrix of the reflection halfspace
Stra=matrix_tra(traspace,V0)#scattering matrix of the transmission halfspace
```
Any SRCWA computation will require the scattering matrices of the halfspaces above (reflection) and below (transmission) the device of interest. They are modeled with zero thickness, corresponding to the measurement of the plane wave directly at the device, without additional propagation losses or phase shift. The computation is done in two steps. Firstly the effective impedance of the halfspaces is calculated, then it is normalized with that of free space. A minimal simulation model, which basically just yields the same as Fresnel's equation, is comprised of a transmission and reflection layer.

### Building a device layer by layer
```julia
t1=100#thickness, same units as wavelength
eps1=2#relative permittivity
l1=layer_plain(Kx,Ky,k0,t1,eps1)#compute modes of a plain layer
S1=matrix_layer(l1,V0)#compute the scattering matrix of l1

eps2a=2#permittivity inside the inclusion of layer 2
eps2b=3+1im#permittivity outside the inclusion of layer 2
fill_x=fill_y=.5#fill factor of inclusion in x and y
F=circft(fill_x,dnx,dny)# Fourier transform of a circular inclusion in real space into reciprocal space
F=ellipft(fill_x,fill_y,dnx,dny)# Fourier transform of an elliptic inclusion in real space into reciprocal space
F=rectft(fill_x,fill_y,dnx,dny)# Fourier transform of a rectangular inclusion in real space into reciprocal space

using LinearAlgebra
eps2=eps2a*F+eps2b*(I-F)#the permittivity distribution of layer 2 in reciprocal space
t2=200#thickness of layer 2
l2=layer_patterned(Kx,Ky,k0,t2,eps2)#compute modes of a patterned layer
S2=matrix_layer(l2,V0)#compute the scattering matrix of l2

S=concatenate([Sref,S1,S2,Stra])
```
Plain layers with a homogenous relative permittivity can be constructed in a simple way, similar to the transmission and reflection halfspaces. In addition to their different relative impedance, they incorporate absorption and phase shift. 

For patterned layers, the permittivity is given as a function of the reciprocal space vector, obtained by Fourier transform. This will make the waves different reciprocal lattice vectors propagate with different effective permittivities, and couple with each other at interfaces. 

The scattering matrix of the full device can then be obtained from the individual scattering matrices.

### Reflection and transmission

```julia
a0te,a0tm=prepare_source(kin,refspace.W,Nx,Ny)#calculate the amplitudes of the impinging plane wave for te or tm polarization
aRte=S.S11*a0te#reflected wave for incident TE
Rte=a2p(aRte,refspace,Kx,Ky,kin[3])#reflected power for incident TE
aTte=S.S21*a0te#transmitted wave for incident TE
Tte=a2p(aTte,traspace,Kx,Ky,kin[3])#transmitted power for incident TE
aRtm=S.S11*a0tm#reflected wave for incident TM
Rtm=a2p(aRtm,refspace,Kx,Ky,kin[3])#reflected power for incident TM
aTtm=S.S21*a0tm#transmitted wave for incident TM
Ttm=a2p(aTtm,traspace,Kx,Ky,kin[3])#transmitted power for incident TM
```
With the scattering matrix constructed, it is easy to compute transmitted and reflected wave amplitudes and power for TE and TM incident polarizations.

### Absorption

```julia
Sabove=concatenate([Sref,S1])#scatter matrix of the layers above the layer of interest
Sint=S2#layer of interest
Sbelow=Stra#scatter matrix of the layers below the layer of interest
Ate=absorption(Sabove,Sint,Sbelow,V0,a0te,kin[3])#Absorption in layer 2 for TE incidence
Atm=absorption(Sabove,Sint,Sbelow,V0,a0tm,kin[3])#Absorption in layer 2 for TM incidence
```
This simple method calculates the absorption of a layer from the difference in the power of the electromagnetic wave entering and leaving the layer.

### Electric and magnetic fields

```julia
realgrid=grid_xy_square(51)#create a grid in real space for the data
Sabove=concatenate([Sref,S1])#scatter matrix of the layers above the layer of interest
Sint=S2#layer of interest
Sbelow=Stra#scatter matrix of the layers below the layer of interest
ain,aout,bin,bout=stackamp(Sabove,Sint,Sbelow,a0tm)#the amplitude vectors going into and out of the layer for tm incidence
e1h=field_expansion(ain,aout,bin,bout,l2,V0,100,Kx,Ky,Kz0,k0,nx,ny,realgrid)#calculate the fields in real space
```
The actual electric and magnetic fields inside the layers can be computed from the amplitudes using the eigenmodes of the layers. For this, the amplitudes of the plane wave components are transformed into the eigenstates of the layer, in order to compute the amplitude at each z-component. This is then converted to the components of the electric and magnetic field and transformed to real space with a given grid. 

## References

1. D. M. Whittaker and I. S. Culshaw, Scattering-matrix treatment of patterned multilayer photonic structures, Phys. Rev. B60(1999), 2610–2618.1

2. Marco Liscidini, Dario Gerace, Lucio Claudio Andreani, and J. E. Sipe, Scattering-matrix analysis of periodically patterned multilayers with asymmetric unit cells and birefringent media,Phys. Rev. B77(2008), 035324.1

3. Raymond Rumpf, Improved formulation of scattering matrices for semi-analytical methods thatis consistent with convention, Progress In Electromagnetics Research B35(2011), 241–261.1
