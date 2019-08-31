# API documentation

```@meta
DocTestSetup = quote
    using FEMQuad
end
```

## Index

```@index
```

## Functions

### Gauss-Legendre rules in segments

```@docs
FEMQuad.get_quadrature_points(::Type{Val{:GLSEG1}})
FEMQuad.get_quadrature_points(::Type{Val{:GLSEG2}})
FEMQuad.get_quadrature_points(::Type{Val{:GLSEG3}})
FEMQuad.get_quadrature_points(::Type{Val{:GLSEG4}})
FEMQuad.get_quadrature_points(::Type{Val{:GLSEG5}})
```

### Gauss-Legendre rules in triangles

These rules are from literature.

```@docs
FEMQuad.get_quadrature_points(::Type{Val{:GLTRI1}})
FEMQuad.get_quadrature_points(::Type{Val{:GLTRI3}})
FEMQuad.get_quadrature_points(::Type{Val{:GLTRI3B}})
FEMQuad.get_quadrature_points(::Type{Val{:GLTRI4}})
FEMQuad.get_quadrature_points(::Type{Val{:GLTRI4B}})
FEMQuad.get_quadrature_points(::Type{Val{:GLTRI6}})
FEMQuad.get_quadrature_points(::Type{Val{:GLTRI7}})
FEMQuad.get_quadrature_points(::Type{Val{:GLTRI12}})
```

### Gauss-Legendre rules in quadrangles

These rules are get from 1d quadratures by using tensor production.

```@docs
FEMQuad.get_quadrature_points(::Type{Val{:GLQUAD1}})
FEMQuad.get_quadrature_points(::Type{Val{:GLQUAD4}})
FEMQuad.get_quadrature_points(::Type{Val{:GLQUAD9}})
FEMQuad.get_quadrature_points(::Type{Val{:GLQUAD16}})
FEMQuad.get_quadrature_points(::Type{Val{:GLQUAD25}})
```

### Gauss-Legendre rules in tetrahedrons

These rules are from literature.

```@docs
FEMQuad.get_quadrature_points(::Type{Val{:GLTET1}})
FEMQuad.get_quadrature_points(::Type{Val{:GLTET4}})
FEMQuad.get_quadrature_points(::Type{Val{:GLTET5}})
FEMQuad.get_quadrature_points(::Type{Val{:GLTET15}})
```

### Gauss-Legendre rules in hexahedrons

These rules are get from 1d quadratures by using tensor production.

```@docs
FEMQuad.get_quadrature_points(::Type{Val{:GLHEX1}})
FEMQuad.get_quadrature_points(::Type{Val{:GLHEX8}})
FEMQuad.get_quadrature_points(::Type{Val{:GLHEX27}})
FEMQuad.get_quadrature_points(::Type{Val{:GLHEX64}})
FEMQuad.get_quadrature_points(::Type{Val{:GLHEX125}})
```

### Gauss-Legendre rules in prismatic domain

These rules for wedge are mainly tensor products of triangular domain and 1d domain

```@docs
FEMQuad.get_quadrature_points(::Type{Val{:GLWED6}})
FEMQuad.get_quadrature_points(::Type{Val{:GLWED6B}})
FEMQuad.get_quadrature_points(::Type{Val{:GLWED21}})
```

### Gauss-Legendre rules in pyramidal domains

```@docs
FEMQuad.get_quadrature_points(::Type{Val{:GLPYR5}})
FEMQuad.get_quadrature_points(::Type{Val{:GLPYR5B}})
```

