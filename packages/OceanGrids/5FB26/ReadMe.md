<a href="https://gist.github.com/briochemc/10e891bdb7da49fc4bf5467a5876434f">
  <img src="https://user-images.githubusercontent.com/4486578/59238897-0a004c80-8c43-11e9-861c-5fe00069af92.png", align="right", width="50%">
</a>

# OceanGrids

<p>
  <img src="https://img.shields.io/badge/stability-experimental-orange.svg">
</p>
<p>
  <a href="https://travis-ci.com/briochemc/OceanGrids.jl">
    <img alt="Build Status" src="https://travis-ci.com/briochemc/OceanGrids.jl.svg?branch=master">
  </a>
  <a href='https://coveralls.io/github/briochemc/OceanGrids.jl'>
    <img src='https://coveralls.io/repos/github/briochemc/OceanGrids.jl/badge.svg' alt='Coverage Status' />
  </a>
</p>
<p>
  <a href="https://ci.appveyor.com/project/briochemc/OceanGrids-jl">
    <img alt="Build Status" src="https://ci.appveyor.com/api/projects/status/6egisrrfgqnyu43n?svg=true">
  </a>
  <a href="https://codecov.io/gh/briochemc/OceanGrids.jl">
    <img src="https://codecov.io/gh/briochemc/OceanGrids.jl/branch/master/graph/badge.svg" />
  </a>
</p>

This package is a dependency of [AIBECS](https://github.com/briochemc/AIBECS.jl.git).
It defines types for grids used by AIBECS.

The goal of [OceanGrids](https://github.com/briochemc/OceanGrids.jl.git) is to standardize the format of grids in order for AIBECS to avoid confusion when swapping the circulation it uses for another.

For example, units for the grid data in the Ocean Circulation Inverse Model (OCIM, see [*DeVries et al*., 2014](https://doi.org/10.1002/2013GB004739)) products are not documented, so that it is easy to get confused and carry dimensional inconsistencies in one's model.
[OceanGrids](https://github.com/briochemc/OceanGrids.jl.git) attempts to fix these discrepancies by always using the same format and provide tests to ensure some level of consistency.
