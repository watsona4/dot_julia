# JeszenszkiBasis

Bosonic occupation basis using algorithms from [Szabados et al., 2012](http://dx.doi.org/10.1016/j.chemphys.2011.10.003) ([preprint](http://coulson.chem.elte.hu/surjan/PREPRINTS/181.pdf)).

Tested with Julia 1.0.


## Installation

```
pkg> add JeszenszkiBasis
```


## Examples

```julia
julia> using JeszenszkiBasis
```

2 sites, 3 particles:
```julia
julia> basis = Szbasis(2, 3);
julia> join([to_str(v) for v in basis], ", ")
"3 0, 2 1, 1 2, 0 3"
julia> length(basis)
4
```

4 sites, 4 particles:
```julia
julia> basis = Szbasis(4, 4);
julia> v = basis[8];
julia> to_str(v)
"1 2 1 0"
julia> serial_num(basis, v)
8
julia> sub_serial_num(basis, v[1:2])
9
```

3 sites, 3 particles, 2 maximum:
```julia
julia> basis = RestrictedSzbasis(3, 3, 2);
julia> join([to_str(v) for v in basis], ", ")
"2 1 0, 1 2 0, 2 0 1, 1 1 1, 0 2 1, 1 0 2, 0 1 2"
julia> sz"2 1 0" in basis
true
julia> sz"3 0 0" in basis
false
```


## Caveats

* Indexing returns a view into the vector array:

  ```julia
  julia> basis = Szbasis(2, 1);
  julia> join([to_str(v) for v in basis], ", ")
  "1 0, 0 1"
  julia> basis[1][1] = 11;
  julia> join([to_str(v) for v in basis], ", ")
  "11 0, 0 1"
  ```


## Testing

To run all the tests, activate the package before calling `test`:
```
pkg> activate .
(JeszenszkiBasis) pkg> test
```


## Acknowledgements

Thanks to [Roger Melko](http://www.science.uwaterloo.ca/~rgmelko/) for getting me up to speed and providing a reference implementation!


## License

Provided under the terms of the MIT license.
See `LICENSE` for more information.
