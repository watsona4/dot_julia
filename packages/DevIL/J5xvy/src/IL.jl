const ILenum		= Cuint
const ILboolean		= Cuchar
const ILbitfield	= Cuint
const ILbyte		= Cchar
const ILshort		= Cshort
const ILint			= Cint
const ILsizei		= Csize_t
const ILubyte		= Cuchar
const ILushort		= Cushort
const ILuint		= Cuint
const ILfloat		= Cfloat
const ILclampf		= Cfloat
const ILdouble		= Cdouble
const ILclampd		= Cdouble
const ILint64		= Int64
const ILuint64		= UInt64

const ILchar 		= Cchar
const ILstring 		= Ptr{Cchar}
const ILconst_string 	= 	Ptr{Cchar}

export ILenum, ILboolean, ILbitfield, ILbyte, ILshort, ILint, ILsizei, ILubyte, ILushort, ILuint, ILfloat, ILclampf, ILdouble, ILclampd, ILint64, ILuint64, ILchar, ILstring, ILconst_string

@ilConst IL_FALSE				= 0
@ilConst IL_TRUE				= 1

#  Matches OpenGL's right now.
#! Data formats \link Formats Formats\endlink
@ilConst IL_COLOUR_INDEX     = 0x1900
@ilConst IL_COLOR_INDEX      = 0x1900
@ilConst IL_ALPHA			  = 0x1906
@ilConst IL_RGB              = 0x1907
@ilConst IL_RGBA             = 0x1908
@ilConst IL_BGR              = 0x80E0
@ilConst IL_BGRA             = 0x80E1
@ilConst IL_LUMINANCE        = 0x1909
@ilConst IL_LUMINANCE_ALPHA  = 0x190A

#! Data types \link Types Types\endlink
@ilConst IL_BYTE           = 0x1400
@ilConst IL_UNSIGNED_BYTE  = 0x1401
@ilConst IL_SHORT          = 0x1402
@ilConst IL_UNSIGNED_SHORT = 0x1403
@ilConst IL_INT            = 0x1404
@ilConst IL_UNSIGNED_INT   = 0x1405
@ilConst IL_FLOAT          = 0x1406
@ilConst IL_DOUBLE         = 0x140A
@ilConst IL_HALF           = 0x140B


@ilConst IL_MAX_BYTE		  		= typemax(Cchar)
@ilConst IL_MAX_UNSIGNED_BYTE  	= typemax(Cuchar)
@ilConst IL_MAX_SHORT	  			= typemax(Cshort)
@ilConst IL_MAX_UNSIGNED_SHORT 	= typemax(Cushort)
@ilConst IL_MAX_INT		  		= typemax(Cint)
@ilConst IL_MAX_UNSIGNED_INT   	= typemax(Cuint)

@ilConst IL_VENDOR   = 0x1F00
@ilConst IL_LOAD_EXT = 0x1F01
@ilConst IL_SAVE_EXT = 0x1F02


#
# IL-specific @ilConst's
#

@ilConst IL_VERSION_1_7_8 = 1
@ilConst IL_VERSION       = 178


# Attribute Bits
@ilConst IL_ORIGIN_BIT          = 0x00000001
@ilConst IL_FILE_BIT            = 0x00000002
@ilConst IL_PAL_BIT             = 0x00000004
@ilConst IL_FORMAT_BIT          = 0x00000008
@ilConst IL_TYPE_BIT            = 0x00000010
@ilConst IL_COMPRESS_BIT        = 0x00000020
@ilConst IL_LOADFAIL_BIT        = 0x00000040
@ilConst IL_FORMAT_SPECIFIC_BIT = 0x00000080
@ilConst IL_ALL_ATTRIB_BITS     = 0x000FFFFF


# Palette types
@ilConst IL_PAL_NONE   = 0x0400
@ilConst IL_PAL_RGB24  = 0x0401
@ilConst IL_PAL_RGB32  = 0x0402
@ilConst IL_PAL_RGBA32 = 0x0403
@ilConst IL_PAL_BGR24  = 0x0404
@ilConst IL_PAL_BGR32  = 0x0405
@ilConst IL_PAL_BGRA32 = 0x0406


# Image types
@ilConst IL_TYPE_UNKNOWN = 0x0000
@ilConst IL_BMP          = 0x0420  #!< Microsoft Windows Bitmap - .bmp extension
@ilConst IL_CUT          = 0x0421  #!< Dr. Halo - .cut extension
@ilConst IL_DOOM         = 0x0422  #!< DooM walls - no specific extension
@ilConst IL_DOOM_FLAT    = 0x0423  #!< DooM flats - no specific extension
@ilConst IL_ICO          = 0x0424  #!< Microsoft Windows Icons and Cursors - .ico and .cur extensions
@ilConst IL_JPG          = 0x0425  #!< JPEG - .jpg, .jpe and .jpeg extensions
@ilConst IL_JFIF         = 0x0425  #!<
@ilConst IL_ILBM         = 0x0426  #!< Amiga IFF (FORM ILBM) - .iff, .ilbm, .lbm extensions
@ilConst IL_PCD          = 0x0427  #!< Kodak PhotoCD - .pcd extension
@ilConst IL_PCX          = 0x0428  #!< ZSoft PCX - .pcx extension
@ilConst IL_PIC          = 0x0429  #!< PIC - .pic extension
@ilConst IL_PNG          = 0x042A  #!< Portable Network Graphics - .png extension
@ilConst IL_PNM          = 0x042B  #!< Portable Any Map - .pbm, .pgm, .ppm and .pnm extensions
@ilConst IL_SGI          = 0x042C  #!< Silicon Graphics - .sgi, .bw, .rgb and .rgba extensions
@ilConst IL_TGA          = 0x042D  #!< TrueVision Targa File - .tga, .vda, .icb and .vst extensions
@ilConst IL_TIF          = 0x042E  #!< Tagged Image File Format - .tif and .tiff extensions
@ilConst IL_CHEAD        = 0x042F  #!< C-Style Header - .h extension
@ilConst IL_RAW          = 0x0430  #!< Raw Image Data - any extension
@ilConst IL_MDL          = 0x0431  #!< Half-Life Model Texture - .mdl extension
@ilConst IL_WAL          = 0x0432  #!< Quake 2 Texture - .wal extension
@ilConst IL_LIF          = 0x0434  #!< Homeworld Texture - .lif extension
@ilConst IL_MNG          = 0x0435  #!< Multiple-image Network Graphics - .mng extension
@ilConst IL_JNG          = 0x0435  #!<
@ilConst IL_GIF          = 0x0436  #!< Graphics Interchange Format - .gif extension
@ilConst IL_DDS          = 0x0437  #!< DirectDraw Surface - .dds extension
@ilConst IL_DCX          = 0x0438  #!< ZSoft Multi-PCX - .dcx extension
@ilConst IL_PSD          = 0x0439  #!< Adobe PhotoShop - .psd extension
@ilConst IL_EXIF         = 0x043A  #!<
@ilConst IL_PSP          = 0x043B  #!< PaintShop Pro - .psp extension
@ilConst IL_PIX          = 0x043C  #!< PIX - .pix extension
@ilConst IL_PXR          = 0x043D  #!< Pixar - .pxr extension
@ilConst IL_XPM          = 0x043E  #!< X Pixel Map - .xpm extension
@ilConst IL_HDR          = 0x043F  #!< Radiance High Dynamic Range - .hdr extension
@ilConst IL_ICNS			= 0x0440  #!< Macintosh Icon - .icns extension
@ilConst IL_JP2			= 0x0441  #!< Jpeg 2000 - .jp2 extension
@ilConst IL_EXR			= 0x0442  #!< OpenEXR - .exr extension
@ilConst IL_WDP			= 0x0443  #!< Microsoft HD Photo - .wdp and .hdp extension
@ilConst IL_VTF			= 0x0444  #!< Valve Texture Format - .vtf extension
@ilConst IL_WBMP			= 0x0445  #!< Wireless Bitmap - .wbmp extension
@ilConst IL_SUN			= 0x0446  #!< Sun Raster - .sun, .ras, .rs, .im1, .im8, .im24 and .im32 extensions
@ilConst IL_IFF			= 0x0447  #!< Interchange File Format - .iff extension
@ilConst IL_TPL			= 0x0448  #!< Gamecube Texture - .tpl extension
@ilConst IL_FITS			= 0x0449  #!< Flexible Image Transport System - .fit and .fits extensions
@ilConst IL_DICOM		= 0x044A  #!< Digital Imaging and Communications in Medicine (DICOM) - .dcm and .dicom extensions
@ilConst IL_IWI			= 0x044B  #!< Call of Duty Infinity Ward Image - .iwi extension
@ilConst IL_BLP			= 0x044C  #!< Blizzard Texture Format - .blp extension
@ilConst IL_FTX			= 0x044D  #!< Heavy Metal: FAKK2 Texture - .ftx extension
@ilConst IL_ROT			= 0x044E  #!< Homeworld 2 - Relic Texture - .rot extension
@ilConst IL_TEXTURE		= 0x044F  #!< Medieval II: Total War Texture - .texture extension
@ilConst IL_DPX			= 0x0450  #!< Digital Picture Exchange - .dpx extension
@ilConst IL_UTX			= 0x0451  #!< Unreal (and Unreal Tournament) Texture - .utx extension
@ilConst IL_MP3			= 0x0452  #!< MPEG-1 Audio Layer 3 - .mp3 extension


@ilConst IL_JASC_PAL     = 0x0475  #!< PaintShop Pro Palette


# Error Types
@ilConst IL_NO_ERROR             = 0x0000
@ilConst IL_INVALID_ENUM         = 0x0501
@ilConst IL_OUT_OF_MEMORY        = 0x0502
@ilConst IL_FORMAT_NOT_SUPPORTED = 0x0503
@ilConst IL_INTERNAL_ERROR       = 0x0504
@ilConst IL_INVALID_VALUE        = 0x0505
@ilConst IL_ILLEGAL_OPERATION    = 0x0506
@ilConst IL_ILLEGAL_FILE_VALUE   = 0x0507
@ilConst IL_INVALID_FILE_HEADER  = 0x0508
@ilConst IL_INVALID_PARAM        = 0x0509
@ilConst IL_COULD_NOT_OPEN_FILE  = 0x050A
@ilConst IL_INVALID_EXTENSION    = 0x050B
@ilConst IL_FILE_ALREADY_EXISTS  = 0x050C
@ilConst IL_OUT_FORMAT_SAME      = 0x050D
@ilConst IL_STACK_OVERFLOW       = 0x050E
@ilConst IL_STACK_UNDERFLOW      = 0x050F
@ilConst IL_INVALID_CONVERSION   = 0x0510
@ilConst IL_BAD_DIMENSIONS       = 0x0511
@ilConst IL_FILE_READ_ERROR      = 0x0512  # 05/12/2002: Addition by Sam.
@ilConst IL_FILE_WRITE_ERROR     = 0x0512

@ilConst IL_LIB_GIF_ERROR  = 0x05E1
@ilConst IL_LIB_JPEG_ERROR = 0x05E2
@ilConst IL_LIB_PNG_ERROR  = 0x05E3
@ilConst IL_LIB_TIFF_ERROR = 0x05E4
@ilConst IL_LIB_MNG_ERROR  = 0x05E5
@ilConst IL_LIB_JP2_ERROR  = 0x05E6
@ilConst IL_LIB_EXR_ERROR  = 0x05E7
@ilConst IL_UNKNOWN_ERROR  = 0x05FF


# Origin Definitions
@ilConst IL_ORIGIN_SET        = 0x0600
@ilConst IL_ORIGIN_LOWER_LEFT = 0x0601
@ilConst IL_ORIGIN_UPPER_LEFT = 0x0602
@ilConst IL_ORIGIN_MODE       = 0x0603


# Format and Type Mode Definitions
@ilConst IL_FORMAT_SET  = 0x0610
@ilConst IL_FORMAT_MODE = 0x0611
@ilConst IL_TYPE_SET    = 0x0612
@ilConst IL_TYPE_MODE   = 0x0613


# File definitions
@ilConst IL_FILE_OVERWRITE	= 0x0620
@ilConst IL_FILE_MODE		= 0x0621


# Palette definitions
@ilConst IL_CONV_PAL			= 0x0630


# Load fail definitions
@ilConst IL_DEFAULT_ON_FAIL	= 0x0632


# Key colour and alpha definitions
@ilConst IL_USE_KEY_COLOUR	= 0x0635
@ilConst IL_USE_KEY_COLOR	= 0x0635
@ilConst IL_BLIT_BLEND		= 0x0636


# Interlace definitions
@ilConst IL_SAVE_INTERLACED	= 0x0639
@ilConst IL_INTERLACE_MODE		= 0x063A


# Quantization definitions
@ilConst IL_QUANTIZATION_MODE = 0x0640
@ilConst IL_WU_QUANT          = 0x0641
@ilConst IL_NEU_QUANT         = 0x0642
@ilConst IL_NEU_QUANT_SAMPLE  = 0x0643
@ilConst IL_MAX_QUANT_INDEXS  = 0x0644 #XIX : ILint : Maximum number of colors to reduce to, default of 256. and has a range of 2-256
@ilConst IL_MAX_QUANT_INDICES = 0x0644 # Redefined, since the above @ilConst is misspelled


# Hints
@ilConst IL_FASTEST          = 0x0660
@ilConst IL_LESS_MEM         = 0x0661
@ilConst IL_DONT_CARE        = 0x0662
@ilConst IL_MEM_SPEED_HINT   = 0x0665
@ilConst IL_USE_COMPRESSION  = 0x0666
@ilConst IL_NO_COMPRESSION   = 0x0667
@ilConst IL_COMPRESSION_HINT = 0x0668


# Compression
@ilConst IL_NVIDIA_COMPRESS	= 0x0670
@ilConst IL_SQUISH_COMPRESS	= 0x0671


# Subimage types
@ilConst IL_SUB_NEXT   = 0x0680
@ilConst IL_SUB_MIPMAP = 0x0681
@ilConst IL_SUB_LAYER  = 0x0682


# Compression definitions
@ilConst IL_COMPRESS_MODE = 0x0700
@ilConst IL_COMPRESS_NONE = 0x0701
@ilConst IL_COMPRESS_RLE  = 0x0702
@ilConst IL_COMPRESS_LZO  = 0x0703
@ilConst IL_COMPRESS_ZLIB = 0x0704


# File format-specific values
@ilConst IL_TGA_CREATE_STAMP        = 0x0710
@ilConst IL_JPG_QUALITY             = 0x0711
@ilConst IL_PNG_INTERLACE           = 0x0712
@ilConst IL_TGA_RLE                 = 0x0713
@ilConst IL_BMP_RLE                 = 0x0714
@ilConst IL_SGI_RLE                 = 0x0715
@ilConst IL_TGA_ID_STRING           = 0x0717
@ilConst IL_TGA_AUTHNAME_STRING     = 0x0718
@ilConst IL_TGA_AUTHCOMMENT_STRING  = 0x0719
@ilConst IL_PNG_AUTHNAME_STRING     = 0x071A
@ilConst IL_PNG_TITLE_STRING        = 0x071B
@ilConst IL_PNG_DESCRIPTION_STRING  = 0x071C
@ilConst IL_TIF_DESCRIPTION_STRING  = 0x071D
@ilConst IL_TIF_HOSTCOMPUTER_STRING = 0x071E
@ilConst IL_TIF_DOCUMENTNAME_STRING = 0x071F
@ilConst IL_TIF_AUTHNAME_STRING     = 0x0720
@ilConst IL_JPG_SAVE_FORMAT         = 0x0721
@ilConst IL_CHEAD_HEADER_STRING     = 0x0722
@ilConst IL_PCD_PICNUM              = 0x0723
@ilConst IL_PNG_ALPHA_INDEX 		 = 0x0724 #XIX : ILint : the color in the palette at this index value (0-255) is considered transparent, -1 for no trasparent color
@ilConst IL_JPG_PROGRESSIVE         = 0x0725
@ilConst IL_VTF_COMP                = 0x0726


# DXTC definitions
@ilConst IL_DXTC_FORMAT      = 0x0705
@ilConst IL_DXT1             = 0x0706
@ilConst IL_DXT2             = 0x0707
@ilConst IL_DXT3             = 0x0708
@ilConst IL_DXT4             = 0x0709
@ilConst IL_DXT5             = 0x070A
@ilConst IL_DXT_NO_COMP      = 0x070B
@ilConst IL_KEEP_DXTC_DATA   = 0x070C
@ilConst IL_DXTC_DATA_FORMAT = 0x070D
@ilConst IL_3DC              = 0x070E
@ilConst IL_RXGB             = 0x070F
@ilConst IL_ATI1N            = 0x0710
@ilConst IL_DXT1A            = 0x0711  # Normally the same as IL_DXT1, except for nVidia Texture Tools.

# Environment map definitions
@ilConst IL_CUBEMAP_POSITIVEX = 0x00000400
@ilConst IL_CUBEMAP_NEGATIVEX = 0x00000800
@ilConst IL_CUBEMAP_POSITIVEY = 0x00001000
@ilConst IL_CUBEMAP_NEGATIVEY = 0x00002000
@ilConst IL_CUBEMAP_POSITIVEZ = 0x00004000
@ilConst IL_CUBEMAP_NEGATIVEZ = 0x00008000
@ilConst IL_SPHEREMAP         = 0x00010000


# Values
@ilConst IL_VERSION_NUM           = 0x0DE2
@ilConst IL_IMAGE_WIDTH           = 0x0DE4
@ilConst IL_IMAGE_HEIGHT          = 0x0DE5
@ilConst IL_IMAGE_DEPTH           = 0x0DE6
@ilConst IL_IMAGE_SIZE_OF_DATA    = 0x0DE7
@ilConst IL_IMAGE_BPP             = 0x0DE8
@ilConst IL_IMAGE_BYTES_PER_PIXEL = 0x0DE8
@ilConst IL_IMAGE_BITS_PER_PIXEL  = 0x0DE9
@ilConst IL_IMAGE_FORMAT          = 0x0DEA
@ilConst IL_IMAGE_TYPE            = 0x0DEB
@ilConst IL_PALETTE_TYPE          = 0x0DEC
@ilConst IL_PALETTE_SIZE          = 0x0DED
@ilConst IL_PALETTE_BPP           = 0x0DEE
@ilConst IL_PALETTE_NUM_COLS      = 0x0DEF
@ilConst IL_PALETTE_BASE_TYPE     = 0x0DF0
@ilConst IL_NUM_FACES             = 0x0DE1
@ilConst IL_NUM_IMAGES            = 0x0DF1
@ilConst IL_NUM_MIPMAPS           = 0x0DF2
@ilConst IL_NUM_LAYERS            = 0x0DF3
@ilConst IL_ACTIVE_IMAGE          = 0x0DF4
@ilConst IL_ACTIVE_MIPMAP         = 0x0DF5
@ilConst IL_ACTIVE_LAYER          = 0x0DF6
@ilConst IL_ACTIVE_FACE           = 0x0E00
@ilConst IL_CUR_IMAGE             = 0x0DF7
@ilConst IL_IMAGE_DURATION        = 0x0DF8
@ilConst IL_IMAGE_PLANESIZE       = 0x0DF9
@ilConst IL_IMAGE_BPC             = 0x0DFA
@ilConst IL_IMAGE_OFFX            = 0x0DFB
@ilConst IL_IMAGE_OFFY            = 0x0DFC
@ilConst IL_IMAGE_CUBEFLAGS       = 0x0DFD
@ilConst IL_IMAGE_ORIGIN          = 0x0DFE
@ilConst IL_IMAGE_CHANNELS        = 0x0DFF

@ilConst IL_SEEK_SET	= 0
@ilConst IL_SEEK_CUR	= 1
@ilConst IL_SEEK_END	= 2
@ilConst IL_EOF		= -1


# Functions to export julia callbacks to DevIL with the proper signature

# Callback functions for file reading
ILHANDLE = Ptr{Cvoid}
export ILHANDLE

fCloseRProc(f::Function) 	= cfunction(f, Cvoid, (ILHANDLE,))
fEofProc(f::Function) 		= cfunction(f, ILboolean, (ILHANDLE,))
fGetcProc(f::Function) 		= cfunction(f, ILint, (ILHANDLE,))
fOpenRProc(f::Function) 	= cfunction(f, ILHANDLE, (ILconst_string,))
fReadProc(f::Function) 		= cfunction(f, ILint, (Ptr{Cvoid}, ILuint, ILuint, ILHANDLE))
fSeekRProc(f::Function) 	= cfunction(f, ILint, (ILHANDLE, ILint, ILint))
fTellRProc(f::Function) 	= cfunction(f, ILint, (ILHANDLE,))

# Callback functions for file writing
fCloseWProc(f::Function)	= cfunction(f, Cvoid, (ILHANDLE,))
fOpenWProc(f::Function)		= cfunction(f, ILHANDLE, (ILconst_string,))
fPutcProc(f::Function)      = cfunction(f, ILint, (ILubyte, ILHANDLE))
fSeekWProc(f::Function)     = cfunction(f, ILint, (ILHANDLE, ILint, ILint))
fTellWProc(f::Function)     = cfunction(f, ILint, (ILHANDLE,))
fWriteProc(f::Function)     = cfunction(f, ILint, (Ptr{Cvoid}, ILuint, ILuint, ILHANDLE))

# Callback functions for allocation and deallocation
mAlloc(f::Function)         = cfunction(f, Ptr{Cvoid}, (ILsizei,))
mFree(f::Function)          = cfunction(f, Cvoid, (Ptr{Cvoid},))

# Registered format procedures
IL_LOADPROC(f::Function)	= cfunction(f, ILenum, (ILconst_string,))
IL_SAVEPROC(f::Function)	= cfunction(f, ILenum, (ILconst_string,))

# ImageLib Functions
@ilFunc ilActiveFace(Number::ILuint)::ILboolean
@ilFunc ilActiveImage(Number::ILuint)::ILboolean
@ilFunc ilActiveLayer(Number::ILuint)::ILboolean
@ilFunc ilActiveMipmap(Number::ILuint)::ILboolean
@ilFunc ilApplyPal(FileName::ILconst_string)::ILboolean
@ilFunc ilApplyProfile(InProfile::ILstring, OutProfile::ILstring)::ILboolean
@ilFunc ilBindImage(Image::ILuint)::Cvoid
@ilFunc ilBlit(Source::ILuint, DestX::ILint, DestY::ILint, DestZ::ILint, SrcX::ILuint, SrcY::ILuint, SrcZ::ILuint, Width::ILuint, Height::ILuint, Depth::ILuint)::ILboolean
@ilFunc ilClampNTSC()::ILboolean
@ilFunc ilClearColour(Red::ILclampf, Green::ILclampf, Blue::ILclampf, Alpha::ILclampf)::Cvoid
@ilFunc ilClearImage()::ILboolean
@ilFunc ilCloneCurImage()::ILuint
@ilFunc ilCompressDXT(Data::Ptr{ILubyte}, Width::ILuint, Height::ILuint, Depth::ILuint, DXTCFormat::ILenum, DXTCSize::Ptr{ILuint})::Ptr{ILubyte}
@ilFunc ilCompressFunc(Mode::ILenum)::ILboolean
@ilFunc ilConvertImage(DestFormat::ILenum , DestType::ILenum)::ILboolean
@ilFunc ilConvertPal(DestFormat::ILenum)::ILboolean
@ilFunc ilCopyImage(Src::ILuint)::ILboolean
@ilFunc ilCopyPixels(XOff::ILuint, YOff::ILuint, ZOff::ILuint, Width::ILuint, Height::ILuint, Depth::ILuint, Format::ILenum, Type::ILenum, Data::Ptr{Cvoid})::ILuint
@ilFunc ilCreateSubImage(Type::ILenum, Num::ILuint)::ILuint
@ilFunc ilDefaultImage()::ILboolean
@ilFunc ilDeleteImage(Num::ILuint)::Cvoid
@ilFunc ilDeleteImages(Num::ILsizei, Images::Ptr{ILuint})::Cvoid
@ilFunc ilDetermineType(FileName::ILconst_string)::ILenum
@ilFunc ilDetermineTypeF(File::ILHANDLE)::ILenum
@ilFunc ilDetermineTypeL(Lump::Ptr{Cvoid}, Size::ILuint)::ILenum
@ilFunc ilDisable(Mode::ILenum)::ILboolean
@ilFunc ilDxtcDataToImage()::ILboolean
@ilFunc ilDxtcDataToSurface()::ILboolean
@ilFunc ilEnable(Mode::ILenum)::ILboolean
@ilFunc ilFlipSurfaceDxtcData()::Cvoid
@ilFunc ilFormatFunc(Mode::ILenum)::ILboolean
@ilFunc ilGenImages(Num::ILsizei, Images::Ptr{ILuint})::Cvoid
@ilFunc ilGenImage()::ILuint
@ilFunc ilGetAlpha(Type::ILenum)::Ptr{ILubyte}
@ilFunc ilGetBoolean(Mode::ILenum)::ILboolean
@ilFunc ilGetBooleanv(Mode::ILenum, Param::Ptr{ILboolean})::Cvoid
@ilFunc ilGetData()::Ptr{ILubyte}
@ilFunc ilGetDXTCData(Buffer::Ptr{Cvoid}, BufferSize::ILuint, DXTCFormat::ILenum)::ILuint
@ilFunc ilGetError()::ILenum
@ilFunc ilGetInteger(Mode::ILenum)::ILint
@ilFunc ilGetIntegerv(Mode::ILenum, Param::Ptr{ILint})::Cvoid
@ilFunc ilGetLumpPos()::ILuint
@ilFunc ilGetPalette()::Ptr{ILubyte}
@ilFunc ilGetString(StringName::ILenum)::ILconst_string
@ilFunc ilHint(Target::ILenum, Mode::ILenum)::Cvoid
@ilFunc ilInvertSurfaceDxtcDataAlpha()::ILboolean
@ilFunc ilInit()::Cvoid
@ilFunc ilImageToDxtcData(Format::ILenum)::ILboolean
@ilFunc ilIsDisabled(Mode::ILenum)::ILboolean
@ilFunc ilIsEnabled(Mode::ILenum)::ILboolean
@ilFunc ilIsImage(Image::ILuint)::ILboolean
@ilFunc ilIsValid(Type::ILenum, FileName::ILconst_string)::ILboolean
@ilFunc ilIsValidF(Type::ILenum, File::ILHANDLE)::ILboolean
@ilFunc ilIsValidL(Type::ILenum, Lump::Ptr{Cvoid}, Size::ILuint)::ILboolean
@ilFunc ilKeyColour(Red::ILclampf, Green::ILclampf, Blue::ILclampf, Alpha::ILclampf)::Cvoid
@ilFunc ilLoad(Type::ILenum, FileName::ILconst_string)::ILboolean
@ilFunc ilLoadF(Type::ILenum, File::ILHANDLE)::ILboolean
@ilFunc ilLoadImage(FileName::ILconst_string)::ILboolean
@ilFunc ilLoadL(Type::ILenum, Lump::Ptr{Cvoid}, Size::ILuint)::ILboolean
@ilFunc ilLoadPal(FileName::ILconst_string)::ILboolean
@ilFunc ilModAlpha(AlphaValue::ILdouble)::Cvoid
@ilFunc ilOriginFunc(Mode::ILenum)::ILboolean
@ilFunc ilOverlayImage(Source::ILuint, XCoord::ILint, YCoord::ILint, ZCoord::ILint)::ILboolean
@ilFunc ilPopAttrib()::Cvoid
@ilFunc ilPushAttrib(Bits::ILuint)::Cvoid
@ilFunc ilRegisterFormat(Format::ILenum)::Cvoid
@ilFunc ilRegisterMipNum(Num::ILuint)::ILboolean
@ilFunc ilRegisterNumFaces(Num::ILuint)::ILboolean
@ilFunc ilRegisterNumImages(Num::ILuint)::ILboolean
@ilFunc ilRegisterOrigin(Origin::ILenum)::Cvoid
@ilFunc ilRegisterPal(Pal::Ptr{Cvoid}, Size::ILuint, Type::ILenum)::Cvoid
@ilFunc ilRegisterType(Type::ILenum)::Cvoid
@ilFunc ilRemoveLoad(Ext::ILconst_string)::ILboolean
@ilFunc ilRemoveSave(Ext::ILconst_string)::ILboolean
@ilFunc ilResetMemory()::Cvoid  # Deprecated
@ilFunc ilResetRead()::Cvoid
@ilFunc ilResetWrite()::Cvoid
@ilFunc ilSave(Type::ILenum, FileName::ILconst_string)::ILboolean
@ilFunc ilSaveF(Type::ILenum, File::ILHANDLE)::ILuint
@ilFunc ilSaveImage(FileName::ILconst_string)::ILboolean
@ilFunc ilSaveL(Type::ILenum, Lump::Ptr{Cvoid}, Size::ILuint)::ILuint
@ilFunc ilSavePal(FileName::ILconst_string)::ILboolean
@ilFunc ilSetAlpha(AlphaValue::ILdouble)::ILboolean
@ilFunc ilSetData(Data::Ptr{Cvoid})::ILboolean
@ilFunc ilSetDuration(Duration::ILuint)::ILboolean
@ilFunc ilSetInteger(Mode::ILenum, Param::ILint)::Cvoid
@ilFunc ilSetPixels(XOff::ILint, YOff::ILint, ZOff::ILint, Width::ILuint, Height::ILuint, Depth::ILuint, Format::ILenum, Type::ILenum, Data::Ptr{Cvoid})::Cvoid
@ilFunc ilSetString(Mode::ILenum, String::Ptr{Cchar})::Cvoid
@ilFunc ilShutDown()::Cvoid
@ilFunc ilSurfaceToDxtcData(Format::ILenum)::ILboolean
@ilFunc ilTexImage(Width::ILuint, Height::ILuint, Depth::ILuint, NumChannels::ILubyte, Format::ILenum, Type::ILenum, Data::Ptr{Cvoid})::ILboolean
@ilFunc ilTexImageDxtc(w::ILint, h::ILint, d::ILint, DxtFormat::ILenum, data::Ptr{ILubyte})::ILboolean
@ilFunc ilTypeFromExt(FileName::ILconst_string)::ILenum
@ilFunc ilTypeFunc(Mode::ILenum)::ILboolean
@ilFunc ilLoadData(FileName::ILconst_string, Width::ILuint, Height::ILuint, Depth::ILuint, Bpp::ILubyte)::ILboolean
@ilFunc ilLoadDataF(File::ILHANDLE, Width::ILuint, Height::ILuint, Depth::ILuint, Bpp::ILubyte)::ILboolean
@ilFunc ilLoadDataL(Lump::Ptr{Cvoid}, Size::ILuint, Width::ILuint, Height::ILuint, Depth::ILuint, Bpp::ILubyte)::ILboolean
@ilFunc ilSaveData(FileName::ILconst_string)::ILboolean

@ilFunc ilRegisterLoad(Ext::ILconst_string, Load::Ptr{Cvoid})::ILboolean
@ilFunc ilRegisterSave(Ext::ILconst_string, Save::Ptr{Cvoid})::ILboolean
@ilFunc ilSetMemory(Alloc::Ptr{Cvoid}, Free::Ptr{Cvoid})::Cvoid
@ilFunc ilSetRead(Open::Ptr{Cvoid}, Close::Ptr{Cvoid}, Eof::Ptr{Cvoid}, Getc::Ptr{Cvoid}, Read::Ptr{Cvoid}, Seek::Ptr{Cvoid}, Tell::Ptr{Cvoid})::Cvoid
@ilFunc ilSetWrite(Open::Ptr{Cvoid}, Close::Ptr{Cvoid}, Putc::Ptr{Cvoid}, Seek::Ptr{Cvoid}, Tell::Ptr{Cvoid}, Write::Ptr{Cvoid})::Cvoid

ilRegisterLoad(Ext::ILconst_string, Load::Function) = ilRegisterLoad(Ext, IL_LOADPROC(Load))
ilRegisterSave(Ext::ILconst_string, Save::Function) = ilRegisterSave(Ext, IL_SAVEPROC(Save))
ilSetMemory(Alloc::Function, Free::Function) = ilSetMemory(mAlloc(Alloc), mFree(Free))
ilSetRead(Open::Function, Close::Function, Eof::Function, Getc::Function, Read::Function, Seek::Function, Tell::Function) = ilSetRead(fOpenRProc(Open), fCloseRProc(Close), fEofProc(Eof), fGetcProc(Getc), fReadProc(Read), fSeekRProc(Seek), fTellRProc(Tell))
ilSetWrite(Open::Function, Close::Function, Putc::Function, Seek::Function, Tell::Function, Write::Function) = ilSetWrite(fOpenWProc(Open), fCloseWProc()Close, fPutcProc(Putc), fSeekWProc(Seek), fTellWProc(Tell), fWriteProc(Write))

# For all those weirdos that spell "colour" without the 'u'.
ilClearColor(r, g, b, a) = ilClearColour(r, g, b, a)
ilKeyColor(r, g, b, a) = ilKeyColour(r, g, b, a)

export ilClearColor, ilKeyColor
