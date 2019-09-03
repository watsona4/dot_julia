import scipy.special

# Old sph_* removed in SciPy 1.0:
# https://docs.scipy.org/doc/scipy/reference/release.1.0.0.html#backwards-incompatible-changes
old_special_funcs = [
    'sph_jn',
    'sph_yn',
    'sph_jnyn',
    'sph_in',
    'sph_kn',
    'sph_inkn',
]


original_version = scipy.__version__
try:

    # Fool how PyDSTool checks SciPy's version number:
    scipy.__version__ = '0.9'

    # PyDSTool tries to access `scipy.special.sph_*`; let's not fail
    # by that by setting them to None.  Those functions won't be
    # usable, but at least (hopefully) other PyDSTool functionalities
    # are usable:
    for name in old_special_funcs:
        if not hasattr(scipy.special, name):
            setattr(scipy.special, name, None)

    import PyDSTool
finally:
    scipy.__version__ = original_version
    for name in old_special_funcs:
        if getattr(scipy.special, name) is None:
            delattr(scipy.special, name)
