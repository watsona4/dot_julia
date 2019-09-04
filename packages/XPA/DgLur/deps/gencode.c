/*
 * gencode.c --
 *
 * Generate constants definitions for Julia.
 *
 *------------------------------------------------------------------------------
 *
 * This file is part of XPA.jl released under the MIT "expat" license.
 * Copyright (C) 2016-2018, Éric Thiébaut (https://github.com/emmt/XPA.jl).
 */

#include <stdlib.h>
#include <stdio.h>
#include <xpa.h>

/*
 * Determine the offset of a field in a structure.
 */
#define OFFSET(type, field) (int)((char*)&((type*)0)->field - (char*)0)

/*
 * Define a Julia constant with the offset (in bytes) of a field of a
 * C-structure.
 */
#define DEF_OFFSETOF(ident, type, field)                \
  fprintf(output, "const _offsetof_" ident " = %3ld\n", \
          (long)OFFSET(type, field))

int main(int argc, char* argv[])
{
  FILE* output = stdout;

  fprintf(output,
          "# This file has been automatically generated, do not edit it\n"
          "# but rather run `make deps.jl` from the shell or execute\n"
          "# `Pkg.build(\"XPA\") from julia.\n");

#ifndef XPA_DLL
  /*
   * Basic check, also makes sure the executable is linked against the XPA
   * library.  This is only needed if XPA_DLL is not defined with the full path
   * of the XPA dynamic library.
   */
  if (XPAClientValid(NULL) != 0) {
    fprintf(stderr, "%s: unexpected failure of `XPAClientValid(NULL)`!\n",
            argv[0]);
    exit(1);
  }
#endif /* XPA_DLL */

  fprintf(output, "\n");
  fprintf(output, "\"`XPA_VERSION` is the version of the XPA library.\"\n");
  fprintf(output, "const XPA_VERSION = v\"%s\"\n", XPA_VERSION);

  fprintf(output, "\n");
  fprintf(output, "# Access mode bits for XPA requests.\n");
  fprintf(output, "const SET    = UInt(%d)\n", XPA_SET);
  fprintf(output, "const GET    = UInt(%d)\n", XPA_GET);
  fprintf(output, "const INFO   = UInt(%d)\n", XPA_INFO);
  fprintf(output, "const ACCESS = UInt(%d)\n", XPA_ACCESS);

#if 0 /* not yet needed */
  fprintf(output, "\n");
  fprintf(output, "# Comm modes.\n");
  fprintf(output, "const COMM_RESERVED = Cint(%d)\n", COMM_RESERVED);
  fprintf(output, "const COMM_CONNECT  = Cint(%d)\n", COMM_CONNECT);
#endif

  fprintf(output, "\n");
  fprintf(output, "# Sizes.\n");
  fprintf(output, "const SZ_LINE = %d\n", SZ_LINE);
  fprintf(output, "const XPA_NAMELEN = %d\n", XPA_NAMELEN);

  fprintf(output, "\n");
  fprintf(output, "# Field offsets in main XPARec structure.\n");
  DEF_OFFSETOF("class    ", XPARec, xclass);
  DEF_OFFSETOF("name     ", XPARec, name);
  DEF_OFFSETOF("send_mode", XPARec, send_mode);
  DEF_OFFSETOF("recv_mode", XPARec, receive_mode);
  DEF_OFFSETOF("method   ", XPARec, method);
  DEF_OFFSETOF("sendian  ", XPARec, sendian);
  DEF_OFFSETOF("comm     ", XPARec, comm);

  fprintf(output, "\n");
  fprintf(output, "# Field offsets in XPACommRec structure.\n");
  DEF_OFFSETOF("comm_status ", XPACommRec, status);
  DEF_OFFSETOF("comm_cmdfd  ", XPACommRec, cmdfd);
  DEF_OFFSETOF("comm_datafd ", XPACommRec, datafd);
  DEF_OFFSETOF("comm_cendian", XPACommRec, cendian);
  DEF_OFFSETOF("comm_ack    ", XPACommRec, ack);
  DEF_OFFSETOF("comm_buf    ", XPACommRec, buf);
  DEF_OFFSETOF("comm_len    ", XPACommRec, len);

  fprintf(output, "\n");
  fprintf(output, "# Path to the XPA dynamic library.\n");
#ifdef XPA_DLL
  fprintf(output, "const libxpa = \"%s\"\n", XPA_DLL);
#endif /* XPA_DLL */

  return 0;
}
