
# v0.6

- Drop support for Julia < 0.6

- Bugfix for rounding of wrapped MPFR functions


# v0.5

- API change: Functions are **automatically defined again, but no longer exported**.
Use e.g. `CRlibm.sin(0.5, RoundDown)`.

- It is now possible to use `CRlibm.sin(0.5)` instead of `CRlibm.sin(0.5, RoundNearest)`.

- It is no longer necessary to call `CRlibm.setup()`.


# v0.4

- API change: Doing `using CRlibm` **no longer defines the rounded functions**.
You must explicitly call `CRlibm.setup()`

# v0.3.1

- Now works correctly on Windows by wrapping MPFR

# v0.3
f
- Source code now included in the Julia package

## v0.2.4

- Remove 0.5 deprecation warnings; some code clean-up

## v0.2.3

- Removed failure when running on Windows; defaults to shadowing MPFR functions

# v0.2

- Added MPFR wrappers
