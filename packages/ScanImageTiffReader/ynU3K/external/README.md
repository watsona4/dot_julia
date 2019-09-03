
# About
This folder contains pre-build static libraries for different supported 
platforms.  The ScanImageTiffReader python api uses bindings to these libraries.

# Updating

When adding or upgrading a build, use the following recipe:

    1. Copy in the new build folder.  This is the product of building the
       `install` target for the ScanImageTiffReader c library.
    2. Update `MANIFEST.in` to include the required shared library in the source
       distribution.
    3. Modify `setup.py` to copy the shared library into the ScanImageTiffReader
       package directory as required for binary distributions.
    4. Clean up by removing any outdated binaries or unnecessary files.
