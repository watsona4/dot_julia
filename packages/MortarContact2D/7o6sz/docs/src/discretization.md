# Discretization and numerical integration of projection matrices

[//]: # (This may be the most platform independent comment, and also 80 chars.)

In theoretical studies, we have a continuum setting where we evaluate the
mandatory [line integral](https://en.wikipedia.org/wiki/Line_integral).
When going towards a numerical implementation, this integral must be
calculated in discretized setting, which is arising some practical questions.
For example, displacement is defined using local coordinate system for each
element. Thus, we need to find all master-slave pairs, contact segments, which 
are giving contribution to the contact virtual work. Discretization of the 
contact interface follows standard isoparametric approach. First we define 
finite dimensional subspaces $\boldsymbol{\mathcal{U}}_{h}^{\left(i\right)}$
and $\boldsymbol{\mathcal{V}}_{h}^{\left(i\right)}$,
which are approximations of $\boldsymbol{\mathcal{U}}^{\left(i\right)}$ and 
$\boldsymbol{\mathcal{V}}^{\left(i\right)}$. Geometry and displacement 
interpolation then goes as a following way:
\begin{align}
\boldsymbol{x}_{h}^{\left(1\right)} &
=\sum_{k=1}^{n^{\left(1\right)}}N_{k}^{\left(1\right)}\boldsymbol{x}_{k}^{\left(1\right)}, & \boldsymbol{x}_{h}^{\left(2\right)} &
=\sum_{l=1}^{n^{\left(2\right)}}N_{l}^{\left(2\right)}\boldsymbol{x}_{l}^{\left(2\right)}, \\\\
\boldsymbol{u}_{h}^{\left(1\right)} &
=\sum_{k=1}^{n^{\left(1\right)}}N_{k}^{\left(1\right)}\boldsymbol{d}_{k}^{\left(1\right)}, & \boldsymbol{u}_{h}^{\left(2\right)} &
=\sum_{l=1}^{n^{\left(2\right)}}N_{l}^{\left(2\right)}\boldsymbol{d}_{l}^{\left(2\right)}.
\end{align}

Moreover, we need also to interpolate Lagrange multipliers in the interface:
\begin{equation}
\boldsymbol{\lambda}_{h}=\sum_{j=1}^{m^{\left(1\right)}}\Phi_{j}\boldsymbol{\lambda}_{j}.
\end{equation}

```julia
function f(x)
    return x
end
```

Substituting interpolation polynomials to contact virtual work $\delta\mathcal{W}_{\mathrm{co}}$
yields
\begin{align}
-\delta\mathcal{W}_{\mathrm{co}} & =\int_{\gamma_{\mathrm{c}}^{\left(1\right)}}\boldsymbol{\lambda}\cdot\left(\delta\boldsymbol{u}^{\left(1\right)}-\delta\boldsymbol{u}^{\left(2\right)}\circ\chi\right)\,\mathrm{d}a\nonumber \\
 & \approx\int_{\gamma_{\mathrm{c},h}^{\left(1\right)}}\boldsymbol{\lambda}_{h}\cdot\left(\delta\boldsymbol{u}_{h}^{\left(1\right)}-\delta\boldsymbol{u}_{h}^{\left(2\right)}\circ\chi_{h}\right)\,\mathrm{d}a\nonumber \\
 & =\int_{\gamma_{\mathrm{c},h}^{\left(1\right)}}\left(\sum_{j=1}^{m^{\left(1\right)}}\Phi_{j}\boldsymbol{\lambda}_{j}\right)\cdot\left(\sum_{k=1}^{n^{\left(1\right)}}N_{k}^{\left(1\right)}\delta\boldsymbol{d}_{k}^{\left(1\right)}-\sum_{l=1}^{n^{\left(2\right)}}\left(N_{l}^{\left(2\right)}\circ\chi_{h}\right)\delta\boldsymbol{d}_{l}^{\left(2\right)}\right)\,\mathrm{d}a\nonumber \\
 & =\sum_{j=1}^{m^{\left(1\right)}}\sum_{k=1}^{n^{\left(1\right)}}\boldsymbol{\lambda}_{j}\cdot\int_{\gamma_{\mathrm{c},h}^{\left(1\right)}}\Phi_{j}N_{k}^{\left(1\right)}\delta\boldsymbol{d}_{k}^{\left(1\right)}\,\mathrm{d}a-\sum_{j=1}^{m^{\left(1\right)}}\sum_{l=1}^{n^{\left(2\right)}}\boldsymbol{\lambda}_{j}\cdot\int_{\gamma_{\mathrm{c},h}^{\left(1\right)}}\Phi_{j}\left(N_{l}^{\left(2\right)}\circ\chi_{h}\right)\delta\boldsymbol{d}_{l}^{\left(2\right)}\,\mathrm{d}a\nonumber \\
 & =\sum_{j=1}^{m^{\left(1\right)}}\sum_{k=1}^{n^{\left(1\right)}}\boldsymbol{\lambda}_{j}^{\mathrm{T}}\left(\int_{\gamma_{\mathrm{c},h}^{\left(1\right)}}\Phi_{j}N_{k}^{\left(1\right)}\,\mathrm{d}a\right)\delta\boldsymbol{d}_{k}^{\left(1\right)}-\sum_{j=1}^{m^{\left(1\right)}}\sum_{l=1}^{n^{\left(2\right)}}\boldsymbol{\lambda}_{j}^{\mathrm{T}}\left(\int_{\gamma_{\mathrm{c},h}^{\left(1\right)}}\Phi_{j}\left(N_{l}^{\left(2\right)}\circ\chi_{h}\right)\,\mathrm{d}a\right)\delta\boldsymbol{d}_{l}^{\left(2\right)}.\label{2d_projection:eq:discretized_contact_virtual_work}
\end{align}

Here, $\chi_{h}:\gamma_{\mathrm{c},h}^{\left(1\right)}\mapsto\gamma_{\mathrm{c},h}^{\left(2\right)}$
is a discrete mapping from the slave surface to the master surface.
From the equation \ref{2d_projection:eq:discretized_contact_virtual_work},
we find the so called mortar matrices, commonly denoted as $\boldsymbol{D}$
and $\boldsymbol{M}$:
\begin{align}
\boldsymbol{D}\left[j,k\right] & =D_{jk}\boldsymbol{I}_{\mathrm{ndim}}=\int_{\gamma_{\mathrm{c},h}^{\left(1\right)}}\Phi_{j}N_{k}^{\left(1\right)}\,\mathrm{d}a\boldsymbol{I}_{\mathrm{ndim}}, & j=1,\ldots,m^{\left(1\right)}, & k=1,\ldots,n^{\left(1\right)},\\
\boldsymbol{M}\left[j,l\right] & =M_{jl}\boldsymbol{I}_{\mathrm{ndim}}=\int_{\gamma_{\mathrm{c},h}^{\left(1\right)}}\Phi_{j}\left(N_{l}^{\left(2\right)}\circ\chi_{h}\right)\,\mathrm{d}a\boldsymbol{I}_{\mathrm{ndim}}, & j=1,\ldots,m^{\left(1\right)}, & l=1,\ldots,n^{\left(2\right)}.
\end{align}

The process of discretizing mesh tie virtual work 
$\delta\mathcal{W}_{\mathrm{mt}}$,
is identical to what is now presented, with a difference that integrals
are evaluated in reference configuration instead of current configuration.
Also, when considering linearized kinematic and small deformations,
integration can be done in reference configuration. For mesh tie contact,
the discretized contact virtual work is
\begin{align}
-\delta\mathcal{W}_{\mathrm{mt},h}= & \sum_{j=1}^{m^{\left(1\right)}}\sum_{k=1}^{n^{\left(1\right)}}\boldsymbol{\lambda}_{j}^{\mathrm{T}}\left(\int_{\Gamma_{\mathrm{c},h}^{\left(1\right)}}\Phi_{j}N_{k}^{\left(1\right)}\,\mathrm{d}A_{0}\right)\delta\boldsymbol{d}_{k}^{\left(1\right)}\nonumber \\
 & -\sum_{j=1}^{m^{\left(1\right)}}\sum_{l=1}^{n^{\left(2\right)}}\boldsymbol{\lambda}_{j}^{\mathrm{T}}\left(\int_{\Gamma_{\mathrm{c},h}^{\left(1\right)}}\Phi_{j}\left(N_{l}^{\left(2\right)}\circ\chi_{h}\right)\,\mathrm{d}A_{0}\right)\delta\boldsymbol{d}_{l}^{\left(2\right)}.\label{eq:2d_projection:discretized_virtual_work}
\end{align}