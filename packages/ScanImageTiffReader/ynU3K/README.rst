.. image:: https://gitlab.com/vidriotech/scanimagetiffreader-julia/badges/master/pipeline.svg
   :target: https://gitlab.com/vidriotech/scanimagetiffreader-julia/commits/master
   :alt: Pipeline status

.. image:: https://gitlab.com/vidriotech/scanimagetiffreader-julia/badges/master/coverage.svg
   :target: https://gitlab.com/vidriotech/scanimagetiffreader-julia/commits/master
   :alt: Coverage

About
=====

For more information see the documentation_.

The ScanImageTiffReader is a Julia_ library for extracting data from Tiff_ and BigTiff_ files recorded using ScanImage_.  It is a very fast tiff reader and provides access to ScanImage-specific metadata.  It should read most tiff files, but as of now we don't support compressed or tiled data. This is the Julia_ interface.  It is also available as a Matlab_, Python_,  or `C library`_.  There's also a `command-line interface`_.

Both ScanImage_ and this reader are products of `Vidrio Technologies`_.  If you
have questions or need support feel free to `submit an issue`_ or `contact us`_.

Examples
========

Install via the package manager:

.. code-block:: julia

    (v1.0) pkg> add ScanImageTiffReader

Read a volume.  The `open` function opens a file context, executes the `data` method and then closes the file context.  See the documentation_ for more.

.. code-block:: julia

    using ScanImageTiffReader
    vol = ScanImageTiffReader.open("my.tif") do io
        data(io)
    end

.. _Core: https://vidriotech.gitlab.io/scanimage-tiff-reader
.. _`C library`: Core_
.. _`command-line interface`: Core_
.. _Tiff: https://en.wikipedia.org/wiki/Tagged_Image_File_Format
.. _BigTiff: http://bigtiff.org/
.. _ScanImage: http://scanimage.org
.. _scanimage.org: http://scanimage.org
.. _Python: https://vidriotech.gitlab.io/scanimagetiffreader-python/
.. _Matlab: https://vidriotech.gitlab.io/scanimagetiffreader-matlab/
.. _Julia: https://julialang.org
.. _`Vidrio Technologies`: http://vidriotechnologies.com/
.. _`contact us`: https://vidriotechnologies.com/contact-support/
.. _`submit an issue`: https://gitlab.com/vidriotech/scanimagetiffreader-julia/issues
.. _documentation: https://vidriotech.gitlab.io/scanimagetiffreader-julia/
