/*  Copyright 2016 Vidrio Technologies, LLC */
#ifndef H_SCANIMAGETIFFREADER_API_V10
#define H_SCANIMAGETIFFREADER_API_V10

#include <stddef.h>
#include "nd.h"

/* Declare symbols for export to dll */
#if defined(_MSC_VER)
#define EXPORT __declspec(dllexport)
#else
#define EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

    struct ScanImageTiffReader {
        void *handle;        /**< A pointer to the (abstract) file context */
        const char *log;     /**< If not NULL, there was an error and this points to a NULL-terminate char string with additional information. */
    };
    typedef struct ScanImageTiffReader ScanImageTiffReader;

    EXPORT ScanImageTiffReader ScanImageTiffReader_Open                             (const char* filename);
    EXPORT void                ScanImageTiffReader_Close                            (ScanImageTiffReader *r);
    EXPORT int                 ScanImageTiffReader_GetImageDescriptionCount         (ScanImageTiffReader *r);
    EXPORT size_t              ScanImageTiffReader_GetImageDescriptionSizeBytes     (ScanImageTiffReader *r, int iframe);
    EXPORT int                 ScanImageTiffReader_GetImageDescription              (ScanImageTiffReader *r, int iframe, char* buf,size_t bytes_of_buf);
    EXPORT size_t              ScanImageTiffReader_GetAllImageDescriptionsSizeBytes (ScanImageTiffReader *r);
    EXPORT int                 ScanImageTiffReader_GetAllImageDescriptions          (ScanImageTiffReader *r, char* buf,size_t bytes_of_buf);
    EXPORT size_t              ScanImageTiffReader_GetMetadataSizeBytes             (ScanImageTiffReader *r);
    EXPORT int                 ScanImageTiffReader_GetMetadata                      (ScanImageTiffReader *r, char* buf,size_t bytes_of_buf);
    EXPORT size_t              ScanImageTiffReader_GetDataSizeBytes                 (ScanImageTiffReader *r);
    EXPORT int                 ScanImageTiffReader_GetData                          (ScanImageTiffReader *r, char* buf,size_t bytes_of_buf);
    EXPORT struct nd           ScanImageTiffReader_GetShape                         (ScanImageTiffReader *r);
	EXPORT const char*         ScanImageTiffReader_APIVersion();

#ifdef __cplusplus
} /* end extern "C" */
#endif

#if defined(_MSC_VER)
#undef EXPORT
#endif

#endif /* header guard */
