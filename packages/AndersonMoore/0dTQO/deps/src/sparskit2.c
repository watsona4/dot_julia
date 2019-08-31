/* ************************************************************************** */
/* SPARSKIT2 library routines, copyright 1990, 1994 by Yousef Saad.           */
/* Used by permission.  These programs are not to be copied without the       */
/* permission of Yousef Saad.  These programs come with no warranty whatsover.*/
/* Yousef Saad and the contributors to SPARSKIT2 are not liable for any       */
/* loss, damage, or inconvenience caused in the use of these programs or      */
/* any modification of them.                                                  */
/* ************************************************************************** */

/* ************************************************************************** */
/* This subset of the SPARSKIT2 routines is to be used ONLY with the version  */
/* of sparseAim.c created by Gary Anderson at the Federal Reserve Board and   */
/* provided to Intex Solutions, Inc. for inclusion in their distribution of   */
/* the Troll modelling software.  Any other use is subject to the original    */
/* license on the SPARSKIT2 library, which states:                            */
/*                                                                            */
/* IMPORTANT:                                                                 */
/* ----------                                                                 */
/*                                                                            */
/* Copyright 1990,1994 Yousef Saad.                                           */
/* ------------------------------------                                       */
/*                                                                            */
/* Permission to copy all or  part of any  material contained in SPARSKIT     */
/* is only  granted upon approval from Yousef  Saad.  Not  any portion of     */
/* SPARSKIT can   be used  for  commercial  purposes  or  as  part of   a     */
/* commercial package.  This notice should accompany   the package in any     */
/* approved copy.                                                             */
/*                                                                            */
/* Note to contributors: Before  contributing any software be aware  that     */
/* above  note     is   the only    global  limitation    against copying     */
/* software. Eventually this copyright note may be replaced.                  */
/*                                                                            */
/* DISCLAIMER                                                                 */
/* ----------                                                                 */
/*                                                                            */
/* SPARSKIT comes  with no warranty whatsoever.   The author/contributors     */
/* of SPARKSIT are not liable for any loss/damage or inconvenience caused     */
/* in  the use of the software  in  SPARSKIT or any modification thereof.     */
/* ************************************************************************** */

/* ************************************************************************** */
/* 	converted from Fortran to C using f2c (version of 27 June 1990  8:41:01). */
/* ************************************************************************** */

#include "f2c.h"

/* Table of constant values */

static integer c__1 = 1;
static integer c__9 = 9;
static integer c__3 = 3;

/* ----------------------------------------------------------------------c */
/*                          S P A R S K I T                             c */
/* ----------------------------------------------------------------------c */
/*                    FORMAT CONVERSION MODULE                          c */
/* ----------------------------------------------------------------------c */
/* contents:                                                            c */
/* ----------                                                            c */
/* csrdns  : converts a row-stored sparse matrix into the dense format. c */
/* dnscsr  : converts a dense matrix to a sparse storage format.        c */
/* coocsr  : converts coordinate to  to csr format                      c */
/* csrcsc  : converts compressed sparse row format to compressed sparse c */
/*           column format (transposition)                              c */
/* csrcsc2 : rectangular version of csrcsc                              c */
/* ----------------------------------------------------------------------c */
/* ************************************************************************** */
/* SPARSKIT2 library routine, copyright 1990, 1994 by Yousef Saad.            */
/* Used by permission.  This program is not to be copied without the          */
/* permission of Yousef Saad.  This program comes with no warranty whatsover. */
/* Yousef Saad and the contributors to SPARSKIT2 are not liable for any       */
/* loss, damage, or inconvenience caused in the use of this program or        */
/* any modification of it.                                                    */
/* ************************************************************************** */
/* Subroutine */ int csrdns_(nrow, ncol, a, ja, ia, dns, ndns, ierr)
integer *nrow, *ncol;
doublereal *a;
integer *ja, *ia;
doublereal *dns;
integer *ndns, *ierr;
{
    /* System generated locals */
    integer dns_dim1, dns_offset, i_1, i_2;

    /* Local variables */
    static integer i, j, k;

/* -----------------------------------------------------------------------
 */
/* Compressed Sparse Row    to    Dense */
/* -----------------------------------------------------------------------
 */

/* converts a row-stored sparse matrix into a densely stored one */

/* On entry: */
/* ---------- */

/* nrow	= row-dimension of a */
/* ncol	= column dimension of a */
/* a, */
/* ja, */
/* ia    = input matrix in compressed sparse row format. */
/*         (a=value array, ja=column array, ia=pointer array) */
/* dns   = array where to store dense matrix */
/* ndns	= first dimension of array dns */

/* on return: */
/* ----------- */
/* dns   = the sparse matrix a, ja, ia has been stored in dns(ndns,*) */

/* ierr  = integer error indicator. */
/*         ierr .eq. 0  means normal return */
/*         ierr .eq. i  means that the code has stopped when processing */

/*         row number i, because it found a column number .gt. ncol. */

/* -----------------------------------------------------------------------
 */
    /* Parameter adjustments */
    dns_dim1 = *ndns;
    dns_offset = dns_dim1 + 1;
    dns -= dns_offset;
    --ia;
    --ja;
    --a;

    /* Function Body */
    *ierr = 0;
    i_1 = *nrow;
    for (i = 1; i <= i_1; ++i) {
	i_2 = *ncol;
	for (j = 1; j <= i_2; ++j) {
	    dns[i + j * dns_dim1] = 0.;
/* L2: */
	}
/* L1: */
    }

    i_1 = *nrow;
    for (i = 1; i <= i_1; ++i) {
	i_2 = ia[i + 1] - 1;
	for (k = ia[i]; k <= i_2; ++k) {
	    j = ja[k];
	    if (j > *ncol) {
		*ierr = i;
		return 0;
	    }
	    dns[i + j * dns_dim1] = a[k];
/* L3: */
	}
/* L4: */
    }
    return 0;
/* ---- end of csrdns ----------------------------------------------------
 */
/* -----------------------------------------------------------------------
 */
} /* csrdns_ */

/* ************************************************************************** */
/* SPARSKIT2 library routine, copyright 1990, 1994 by Yousef Saad.            */
/* Used by permission.  This program is not to be copied without the          */
/* permission of Yousef Saad.  This program comes with no warranty whatsover. */
/* Yousef Saad and the contributors to SPARSKIT2 are not liable for any       */
/* loss, damage, or inconvenience caused in the use of this program or        */
/* any modification of it.                                                    */
/* ************************************************************************** */
/* ----------------------------------------------------------------------- */
/* Subroutine */ int dnscsr_(nrow, ncol, nzmax, dns, ndns, a, ja, ia, ierr)
integer *nrow, *ncol, *nzmax;
doublereal *dns;
integer *ndns;
doublereal *a;
integer *ja, *ia, *ierr;
{
    /* System generated locals */
    integer dns_dim1, dns_offset, i_1, i_2;

    /* Local variables */
    static integer next, i, j;

/* -----------------------------------------------------------------------
 */
/* Dense		to    Compressed Row Sparse */
/* -----------------------------------------------------------------------
 */

/* converts a densely stored matrix into a row orientied */
/* compactly sparse matrix. ( reverse of csrdns ) */
/* Note: this routine does not check whether an element */
/* is small. It considers that a(i,j) is zero if it is exactly */
/* equal to zero: see test below. */
/* -----------------------------------------------------------------------
 */
/* on entry: */
/* --------- */

/* nrow	= row-dimension of a */
/* ncol	= column dimension of a */
/* nzmax = maximum number of nonzero elements allowed. This */
/*         should be set to be the lengths of the arrays a and ja. */
/* dns   = input nrow x ncol (dense) matrix. */
/* ndns	= first dimension of dns. */

/* on return: */
/* ---------- */

/* a, ja, ia = value, column, pointer  arrays for output matrix */

/* ierr	= integer error indicator: */
/*         ierr .eq. 0 means normal retur */
/*         ierr .eq. i means that the the code stopped while */
/*         processing row number i, because there was no space left in */
/*         a, and ja (as defined by parameter nzmax). */
/* -----------------------------------------------------------------------
 */
    /* Parameter adjustments */
    --ia;
    --ja;
    --a;
    dns_dim1 = *ndns;
    dns_offset = dns_dim1 + 1;
    dns -= dns_offset;

    /* Function Body */
    *ierr = 0;
    next = 1;
    ia[1] = 1;
    i_1 = *nrow;
    for (i = 1; i <= i_1; ++i) {
	i_2 = *ncol;
	for (j = 1; j <= i_2; ++j) {
	    if (dns[i + j * dns_dim1] == 0.) {
		goto L3;
	    }
	    if (next > *nzmax) {
		*ierr = i;
		return 0;
	    }
	    ja[next] = j;
	    a[next] = dns[i + j * dns_dim1];
	    ++next;
L3:
	    ;
	}
	ia[i + 1] = next;
/* L4: */
    }
    return 0;
/* ---- end of dnscsr ----------------------------------------------------
 */
/* -----------------------------------------------------------------------
 */
} /* dnscsr_ */

/* ************************************************************************** */
/* SPARSKIT2 library routines copyright 1990, 1994 by Yousef Saad.            */
/* Used by permission.  This program is not to be copied without the          */
/* permission of Yousef Saad.  This program comes with no warranty whatsover. */
/* Yousef Saad and the contributors to SPARSKIT2 are not liable for any       */
/* loss, damage, or inconvenience caused in the use of this program or        */
/* any modification of it.                                                    */
/* ************************************************************************** */
/* ----------------------------------------------------------------------- */
/* Subroutine */ int dnscsrtol_(nrow, ncol, nzmax, dns, ndns, a, ja, ia, ierr,
	 tol)
integer *nrow, *ncol, *nzmax;
doublereal *dns;
integer *ndns;
doublereal *a;
integer *ja, *ia, *ierr;
doublereal *tol;
{
    /* System generated locals */
    integer dns_dim1, dns_offset, i_1, i_2;
    doublereal d_1;

    /* Local variables */
    static integer next, i, j;

/* -----------------------------------------------------------------------
 */
/* Dense		to    Compressed Row Sparse */
/* -----------------------------------------------------------------------
 */

/* converts a densely stored matrix into a row orientied */
/* compactly sparse matrix. ( reverse of csrdns ) */
/* Note: this routine does not check whether an element */
/* is small. It considers that a(i,j) is zero if it is exactly */
/* equal to zero: see test below. */
/* -----------------------------------------------------------------------
 */
/* on entry: */
/* --------- */

/* nrow	= row-dimension of a */
/* ncol	= column dimension of a */
/* nzmax = maximum number of nonzero elements allowed. This */
/*         should be set to be the lengths of the arrays a and ja. */
/* dns   = input nrow x ncol (dense) matrix. */
/* ndns	= first dimension of dns. */

/* on return: */
/* ---------- */

/* a, ja, ia = value, column, pointer  arrays for output matrix */

/* ierr	= integer error indicator: */
/*         ierr .eq. 0 means normal retur */
/*         ierr .eq. i means that the the code stopped while */
/*         processing row number i, because there was no space left in */
/*         a, and ja (as defined by parameter nzmax). */
/* -----------------------------------------------------------------------
 */
    /* Parameter adjustments */
    --ia;
    --ja;
    --a;
    dns_dim1 = *ndns;
    dns_offset = dns_dim1 + 1;
    dns -= dns_offset;

    /* Function Body */
    *ierr = 0;
    next = 1;
    ia[1] = 1;
    i_1 = *nrow;
    for (i = 1; i <= i_1; ++i) {
	i_2 = *ncol;
	for (j = 1; j <= i_2; ++j) {
	    if ((d_1 = dns[i + j * dns_dim1], abs(d_1)) <= *tol) {
		goto L3;
	    }
	    if (next > *nzmax) {
		*ierr = i;
		return 0;
	    }
	    ja[next] = j;
	    a[next] = dns[i + j * dns_dim1];
	    ++next;
L3:
	    ;
	}
	ia[i + 1] = next;
/* L4: */
    }
    return 0;
/* ---- end of dnscsr ----------------------------------------------------
 */
/* -----------------------------------------------------------------------
 */
} /* dnscsrtol_ */

/* ************************************************************************** */
/* SPARSKIT2 library routine, copyright 1990, 1994 by Yousef Saad.            */
/* Used by permission.  This program is not to be copied without the          */
/* permission of Yousef Saad.  This program comes with no warranty whatsover. */
/* Yousef Saad and the contributors to SPARSKIT2 are not liable for any       */
/* loss, damage, or inconvenience caused in the use of this program or        */
/* any modification of it.                                                    */
/* ************************************************************************** */
/* ----------------------------------------------------------------------- */
/* Subroutine */ int coocsr_(nrow, nnz, a, ir, jc, ao, jao, iao)
integer *nrow, *nnz;
doublereal *a;
integer *ir, *jc;
doublereal *ao;
integer *jao, *iao;
{
    /* System generated locals */
    integer i_1;

    /* Local variables */
    static integer i, j, k;
    static doublereal x;
    static integer k0, iad;

/* -----------------------------------------------------------------------
 */
/* -----------------------------------------------------------------------
 */
/*  Coordinate     to   Compressed Sparse Row */
/* -----------------------------------------------------------------------
 */
/* converts a matrix that is stored in coordinate format */
/*  a, ir, jc into a row general sparse ao, jao, iao format. */

/* on entry: */
/* --------- */
/* nrow	= dimension of the matrix */
/* nnz	= number of nonzero elements in matrix */
/* a, */
/* ir, */
/* jc    = matrix in coordinate format. a(k), ir(k), jc(k) store the nnz 
*/
/*         nonzero elements of the matrix with a(k) = actual real value of
 */
/* 	  the elements, ir(k) = its row number and jc(k) = its column */
/* 	  number. The order of the elements is arbitrary. */

/* on return: */
/* ----------- */
/* ir 	is destroyed */

/* ao, jao, iao = matrix in general sparse matrix format with ao */
/* 	continung the real values, jao containing the column indices, */
/* 	and iao being the pointer to the beginning of the row, */
/* 	in arrays ao, jao. */

/* Notes: */
/* ------ This routine is NOT in place.  See coicsr */

/*-----------------------------------------------------------------------
-*/
    /* Parameter adjustments */
    --iao;
    --jao;
    --ao;
    --jc;
    --ir;
    --a;

    /* Function Body */
    i_1 = *nrow + 1;
    for (k = 1; k <= i_1; ++k) {
	iao[k] = 0;
/* L1: */
    }
/* determine row-lengths. */
    i_1 = *nnz;
    for (k = 1; k <= i_1; ++k) {
	++iao[ir[k]];
/* L2: */
    }
/* starting position of each row.. */
    k = 1;
    i_1 = *nrow + 1;
    for (j = 1; j <= i_1; ++j) {
	k0 = iao[j];
	iao[j] = k;
	k += k0;
/* L3: */
    }
/* go through the structure  once more. Fill in output matrix. */
    i_1 = *nnz;
    for (k = 1; k <= i_1; ++k) {
	i = ir[k];
	j = jc[k];
	x = a[k];
	iad = iao[i];
	ao[iad] = x;
	jao[iad] = j;
	iao[i] = iad + 1;
/* L4: */
    }
/* shift back iao */
    for (j = *nrow; j >= 1; --j) {
	iao[j + 1] = iao[j];
/* L5: */
    }
    iao[1] = 1;
    return 0;
/* ------------- end of coocsr -------------------------------------------
 */
/* -----------------------------------------------------------------------
 */
} /* coocsr_ */

/* ************************************************************************** */
/* SPARSKIT2 library routine, copyright 1990, 1994 by Yousef Saad.            */
/* Used by permission.  This program is not to be copied without the          */
/* permission of Yousef Saad.  This program comes with no warranty whatsover. */
/* Yousef Saad and the contributors to SPARSKIT2 are not liable for any       */
/* loss, damage, or inconvenience caused in the use of this program or        */
/* any modification of it.                                                    */
/* ************************************************************************** */
/* ----------------------------------------------------------------------- */
/* Subroutine */ int csrcsc_(n, job, ipos, a, ja, ia, ao, jao, iao)
integer *n, *job, *ipos;
doublereal *a;
integer *ja, *ia;
doublereal *ao;
integer *jao, *iao;
{
    extern /* Subroutine */ int csrcsc2_();

/* -----------------------------------------------------------------------
 */
/* Compressed Sparse Row     to      Compressed Sparse Column */

/* (transposition operation)   Not in place. */
/* -----------------------------------------------------------------------
 */
/* -- not in place -- */
/* this subroutine transposes a matrix stored in a, ja, ia format. */
/* --------------- */
/* on entry: */
/* ---------- */
/* n	= dimension of A. */
/* job	= integer to indicate whether to fill the values (job.eq.1) of the 
*/
/*         matrix ao or only the pattern., i.e.,ia, and ja (job .ne.1) */

/* ipos  = starting position in ao, jao of the transposed matrix. */
/*        the iao array takes this into account (thus iao(1) is set to ipo
s.)*/
/*        Note: this may be useful if one needs to append the data structu
re*/
/*         of the transpose to that of A. In this case use for example */
/*                call csrcsc (n,1,ia(n+1),a,ja,ia,a,ja,ia(n+2)) */
/* 	  for any other normal usage, enter ipos=1. */
/* a	= real array of length nnz (nnz=number of nonzero elements in input 
*/
/*         matrix) containing the nonzero elements. */
/* ja	= integer array of length nnz containing the column positions */
/* 	  of the corresponding elements in a. */
/* ia	= integer of size n+1. ia(k) contains the position in a, ja of */
/* 	  the beginning of the k-th row. */

/* on return: */
/* ---------- */
/* output arguments: */
/* ao	= real array of size nzz containing the "a" part of the transpose */

/* jao	= integer array of size nnz containing the column indices. */
/* iao	= integer array of size n+1 containing the "ia" index array of */
/* 	  the transpose. */

/* -----------------------------------------------------------------------
 */
    /* Parameter adjustments */
    --iao;
    --jao;
    --ao;
    --ia;
    --ja;
    --a;

    /* Function Body */
    csrcsc2_(n, n, job, ipos, &a[1], &ja[1], &ia[1], &ao[1], &jao[1], &iao[1])
	    ;
	return 0 ;
} /* csrcsc_ */

/* ************************************************************************** */
/* SPARSKIT2 library routine, copyright 1990, 1994 by Yousef Saad.            */
/* Used by permission.  This program is not to be copied without the          */
/* permission of Yousef Saad.  This program comes with no warranty whatsover. */
/* Yousef Saad and the contributors to SPARSKIT2 are not liable for any       */
/* loss, damage, or inconvenience caused in the use of this program or        */
/* any modification of it.                                                    */
/* ************************************************************************** */
/* ----------------------------------------------------------------------- */
/* Subroutine */ int csrcsc2_(n, n2, job, ipos, a, ja, ia, ao, jao, iao)
integer *n, *n2, *job, *ipos;
doublereal *a;
integer *ja, *ia;
doublereal *ao;
integer *jao, *iao;
{
    /* System generated locals */
    integer i_1, i_2;

    /* Local variables */
    static integer next, i, j, k;

/* -----------------------------------------------------------------------
 */
/* Compressed Sparse Row     to      Compressed Sparse Column */

/* (transposition operation)   Not in place. */
/* -----------------------------------------------------------------------
 */
/* Rectangular version.  n is number of rows of CSR matrix, */
/*                       n2 (input) is number of columns of CSC matrix. */

/* -----------------------------------------------------------------------
 */
/* -- not in place -- */
/* this subroutine transposes a matrix stored in a, ja, ia format. */
/* --------------- */
/* on entry: */
/* ---------- */
/* n	= number of rows of CSR matrix. */
/* n2    = number of columns of CSC matrix. */
/* job	= integer to indicate whether to fill the values (job.eq.1) of the 
*/
/*         matrix ao or only the pattern., i.e.,ia, and ja (job .ne.1) */

/* ipos  = starting position in ao, jao of the transposed matrix. */
/*        the iao array takes this into account (thus iao(1) is set to ipo
s.)*/
/*        Note: this may be useful if one needs to append the data structu
re*/
/*         of the transpose to that of A. In this case use for example */
/*                call csrcsc2 (n,n,1,ia(n+1),a,ja,ia,a,ja,ia(n+2)) */
/* 	  for any other normal usage, enter ipos=1. */
/* a	= real array of length nnz (nnz=number of nonzero elements in input 
*/
/*         matrix) containing the nonzero elements. */
/* ja	= integer array of length nnz containing the column positions */
/* 	  of the corresponding elements in a. */
/* ia	= integer of size n+1. ia(k) contains the position in a, ja of */
/* 	  the beginning of the k-th row. */

/* on return: */
/* ---------- */
/* output arguments: */
/* ao	= real array of size nzz containing the "a" part of the transpose */

/* jao	= integer array of size nnz containing the column indices. */
/* iao	= integer array of size n+1 containing the "ia" index array of */
/* 	  the transpose. */

/* -----------------------------------------------------------------------
 */
/* ----------------- compute lengths of rows of transp(A) ----------------
 */
    /* Parameter adjustments */
    --iao;
    --jao;
    --ao;
    --ia;
    --ja;
    --a;

    /* Function Body */
    i_1 = *n2 + 1;
    for (i = 1; i <= i_1; ++i) {
	iao[i] = 0;
/* L1: */
    }
    i_1 = *n;
    for (i = 1; i <= i_1; ++i) {
	i_2 = ia[i + 1] - 1;
	for (k = ia[i]; k <= i_2; ++k) {
	    j = ja[k] + 1;
	    ++iao[j];
/* L2: */
	}
/* L3: */
    }
/* ---------- compute pointers from lengths ------------------------------
 */
    iao[1] = *ipos;
    i_1 = *n2;
    for (i = 1; i <= i_1; ++i) {
	iao[i + 1] = iao[i] + iao[i + 1];
/* L4: */
    }
/* --------------- now do the actual copying -----------------------------
 */
    i_1 = *n;
    for (i = 1; i <= i_1; ++i) {
	i_2 = ia[i + 1] - 1;
	for (k = ia[i]; k <= i_2; ++k) {
	    j = ja[k];
	    next = iao[j];
	    if (*job == 1) {
		ao[next] = a[k];
	    }
	    jao[next] = i;
	    iao[j] = next + 1;
/* L62: */
	}
/* L6: */
    }
/* -------------------------- reshift iao and leave ----------------------
 */
    for (i = *n2; i >= 1; --i) {
	iao[i + 1] = iao[i];
/* L7: */
    }
    iao[1] = *ipos;
	return 0 ;
/* --------------- end of csrcsc2 ----------------------------------------
 */
/* -----------------------------------------------------------------------
 */
} /* csrcsc2_ */

/* unary.f -- translated by f2c (version of 27 June 1990  8:41:01).
   You must link the resulting object file with the libraries:
	-lF77 -lI77 -lm -lc   (in that order)
*/

#include "f2c.h"

/* ----------------------------------------------------------------------c */
/*                          S P A R S K I T                             c */
/* ----------------------------------------------------------------------c */
/*                     UNARY SUBROUTINES MODULE                         c */
/* ----------------------------------------------------------------------c */
/* contents:                                                            c */
/* ----------                                                            c */
/* submat : extracts a submatrix from a sparse matrix.                  c */
/* filter : filters elements from a matrix according to their magnitude.c */
/* transp : in-place transposition routine (see also csrcsc in formats) c */
/* copmat : copy of a matrix into another matrix (both stored csr)      c */
/* getdia : extracts a specified diagonal from a matrix.                c */
/* getu   : extracts upper triangular part                              c */
/* amask  : extracts     C = A mask M                                   c */
/* rperm  : permutes the rows of a matrix (B = P A)                     c */
/* cperm  : permutes the columns of a matrix (B = A Q)                  c */
/* rnrms  : computes the norms of the rows of A                         c */
/* cnrms  : computes the norms of the columns of A                      c */
/* ----------------------------------------------------------------------c */
/* ************************************************************************** */
/* SPARSKIT2 library routine, copyright 1990, 1994 by Yousef Saad.            */
/* Used by permission.  This program is not to be copied without the          */
/* permission of Yousef Saad.  This program comes with no warranty whatsover. */
/* Yousef Saad and the contributors to SPARSKIT2 are not liable for any       */
/* loss, damage, or inconvenience caused in the use of this program or        */
/* any modification of it.                                                    */
/* ************************************************************************** */
/* Subroutine */ int submat_(n, job, i1, i2, j1, j2, a, ja, ia, nr, nc, ao, 
	jao, iao)

integer *n;
integer *job, *i1, *i2, *j1, *j2;
doublereal *a;
integer *ja, *ia, *nr, *nc;
doublereal *ao;
integer *jao, *iao;
{
    /* System generated locals */
    integer i_1, i_2;

    /* Local variables */
    static integer klen, i, j, k, k1, k2, ii;

/* -----------------------------------------------------------------------
 */
/* extracts the submatrix A(i1:i2,j1:j2) and puts the result in */
/* matrix ao,iao,jao */
/* ---- In place: ao,jao,iao may be the same as a,ja,ia. */
/* -------------- */
/* on input */
/* --------- */
/* n	= row dimension of the matrix */
/* i1,i2 = two integers with i2 .ge. i1 indicating the range of rows to be
 */
/*          extracted. */
/* j1,j2 = two integers with j2 .ge. j1 indicating the range of columns */

/*         to be extracted. */
/*         * There is no checking whether the input values for i1, i2, j1,
 */
/*           j2 are between 1 and n. */
/* a, */
/* ja, */
/* ia    = matrix in compressed sparse row format. */

/* job	= job indicator: if job .ne. 1 then the real values in a are NOT */

/*         extracted, only the column indices (i.e. data structure) are. 
*/
/*         otherwise values as well as column indices are extracted... */

/* on output */
/* -------------- */
/* nr	= number of rows of submatrix */
/* nc	= number of columns of submatrix */
/* 	  * if either of nr or nc is nonpositive the code will quit. */

/* ao, */
/* jao,iao = extracted matrix in general sparse format with jao containing
 */
/* 	the column indices,and iao being the pointer to the beginning */
/* 	of the row,in arrays a,ja. */
/* ----------------------------------------------------------------------c
 */
/*           Y. Saad, Sep. 21 1989                                      c 
*/
/* ----------------------------------------------------------------------c
 */
    /* Parameter adjustments */
    --iao;
    --jao;
    --ao;
    --ia;
    --ja;
    --a;

    /* Function Body */
    *nr = *i2 - *i1 + 1;
    *nc = *j2 - *j1 + 1;

    if (*nr <= 0 || *nc <= 0) {
	return 0;
    }

    klen = 0;

/*     simple procedure. proceeds row-wise... */

    i_1 = *nr;
    for (i = 1; i <= i_1; ++i) {
	ii = *i1 + i - 1;
	k1 = ia[ii];
	k2 = ia[ii + 1] - 1;
	iao[i] = klen + 1;
/* ------------------------------------------------------------------
----- */
	i_2 = k2;
	for (k = k1; k <= i_2; ++k) {
	    j = ja[k];
	    if (j >= *j1 && j <= *j2) {
		++klen;
		if (*job == 1) {
		    ao[klen] = a[k];
		}
		jao[klen] = j - *j1 + 1;
	    }
/* L60: */
	}
/* L100: */
    }
    iao[*nr + 1] = klen + 1;
    return 0;
/* ------------end-of submat----------------------------------------------
 */
/* -----------------------------------------------------------------------
 */
} /* submat_ */

/* ************************************************************************** */
/* SPARSKIT2 library routine, copyright 1990, 1994 by Yousef Saad.            */
/* Used by permission.  This program is not to be copied without the          */
/* permission of Yousef Saad.  This program comes with no warranty whatsover. */
/* Yousef Saad and the contributors to SPARSKIT2 are not liable for any       */
/* loss, damage, or inconvenience caused in the use of this program or        */
/* any modification of it.                                                    */
/* ************************************************************************** */
/* ----------------------------------------------------------------------- */
/* Subroutine */ int filter_(n, job, drptol, a, ja, ia, b, jb, ib, len, ierr)
integer *n, *job;
doublereal *drptol, *a;
integer *ja, *ia;
doublereal *b;
integer *jb, *ib, *len, *ierr;
{
    /* System generated locals */
    integer i_1, i_2;
    doublereal d_1;

    /* Builtin functions */
    double sqrt();

    /* Local variables */
    static doublereal norm;
    static integer k, index, k1, k2;
    static doublereal loctol;
    static integer row;

/* -----------------------------------------------------------------------
 */
/*     This module removes any elements whose absolute value */
/*     is small from an input matrix A and puts the resulting */
/*     matrix in B.  The input parameter job selects a definition */
/*     of small. */
/* -----------------------------------------------------------------------
 */
/* on entry: */
/* --------- */
/*  n	 = integer. row dimension of matrix */
/*  job   = integer. used to determine strategy chosen by caller to */
/*         drop elements from matrix A. */
/*          job = 1 */
/*              Elements whose absolute value is less than the */
/*              drop tolerance are removed. */
/*          job = 2 */
/*              Elements whose absolute value is less than the */
/*              product of the drop tolerance and the Euclidean */
/*              norm of the row are removed. */
/*          job = 3 */
/*              Elements whose absolute value is less that the */
/*              product of the drop tolerance and the largest */
/*              element in the row are removed. */

/* drptol = real. drop tolerance used for dropping strategy. */
/* a */
/* ja */
/* ia     = input matrix in compressed sparse format */
/* len	 = integer. the amount of space available in arrays b and jb. */

/* on return: */
/* ---------- */
/* b */
/* jb */
/* ib    = resulting matrix in compressed sparse format. */

/* ierr	= integer. containing error message. */
/*         ierr .eq. 0 indicates normal return */
/*         ierr .gt. 0 indicates that there is'nt enough */
/*         space is a and ja to store the resulting matrix. */
/*         ierr then contains the row number where filter stopped. */
/* note: */
/* ------ This module is in place. (b,jb,ib can ne the same as */
/*       a, ja, ia in which case the result will be overwritten). */
/* ----------------------------------------------------------------------c
 */
/*           contributed by David Day,  Sep 19, 1989.                   c 
*/
/* ----------------------------------------------------------------------c
 */
/* local variables */

    /* Parameter adjustments */
    --ib;
    --jb;
    --b;
    --ia;
    --ja;
    --a;

    /* Function Body */
    index = 1;
    i_1 = *n;
    for (row = 1; row <= i_1; ++row) {
	k1 = ia[row];
	k2 = ia[row + 1] - 1;
	ib[row] = index;
	switch ((int)*job) {
	    case 1:  goto L100;
	    case 2:  goto L200;
	    case 3:  goto L300;
	}
L100:
	norm = 1.;
	goto L400;
L200:
	norm = 0.;
	i_2 = k2;
	for (k = k1; k <= i_2; ++k) {
	    norm += a[k] * a[k];
/* L22: */
	}
	norm = sqrt(norm);
	goto L400;
L300:
	norm = 0.;
	i_2 = k2;
	for (k = k1; k <= i_2; ++k) {
	    if ((d_1 = a[k], abs(d_1)) > norm) {
		norm = (d_1 = a[k], abs(d_1));
	    }
/* L23: */
	}
L400:
	loctol = *drptol * norm;
	i_2 = k2;
	for (k = k1; k <= i_2; ++k) {
	    if ((d_1 = a[k], abs(d_1)) > loctol) {
		if (index > *len) {
		    *ierr = row;
		    return 0;
		}
		b[index] = a[k];
		jb[index] = ja[k];
		++index;
	    }
/* L30: */
	}
/* L10: */
    }
    ib[*n + 1] = index;
    return 0;
/* --------------------end-of-filter -------------------------------------
 */
/* -----------------------------------------------------------------------
 */
} /* filter_ */


/* ************************************************************************** */
/* SPARSKIT2 library routine, copyright 1990, 1994 by Yousef Saad.            */
/* Used by permission.  This program is not to be copied without the          */
/* permission of Yousef Saad.  This program comes with no warranty whatsover. */
/* Yousef Saad and the contributors to SPARSKIT2 are not liable for any       */
/* loss, damage, or inconvenience caused in the use of this program or        */
/* any modification of it.                                                    */
/* ************************************************************************** */
/* ----------------------------------------------------------------------- */
/* Subroutine */ int copmat_(nrow, a, ja, ia, ao, jao, iao, ipos, job)
integer *nrow;
doublereal *a;
integer *ja, *ia;
doublereal *ao;
integer *jao, *iao, *ipos, *job;
{
    /* System generated locals */
    integer i_1;

    /* Local variables */
    static integer i, k, kst;

/* ---------------------------------------------------------------------- 
*/
/* copies the matrix a, ja, ia, into the matrix ao, jao, iao. */
/* ---------------------------------------------------------------------- 
*/
/* on entry: */
/* --------- */
/* nrow	= row dimension of the matrix */
/* a, */
/* ja, */
/* ia    = input matrix in compressed sparse row format. */
/* ipos  = integer. indicates the position in the array ao, jao */
/*         where the first element should be copied. Thus */
/*         iao(1) = ipos on return. */
/* job   = job indicator. if (job .ne. 1) the values are not copies */
/*         (i.e., pattern only is copied in the form of arrays ja, ia). */


/* on return: */
/* ---------- */
/* ao, */
/* jao, */
/* iao   = output matrix containing the same data as a, ja, ia. */
/* -----------------------------------------------------------------------
 */
/*           Y. Saad, March 1990. */
/* -----------------------------------------------------------------------
 */
/* local variables */

    /* Parameter adjustments */
    --iao;
    --jao;
    --ao;
    --ia;
    --ja;
    --a;

    /* Function Body */
    kst = *ipos - ia[1];
    i_1 = *nrow + 1;
    for (i = 1; i <= i_1; ++i) {
	iao[i] = ia[i] + kst;
/* L100: */
    }

    i_1 = ia[*nrow + 1] - 1;
    for (k = ia[1]; k <= i_1; ++k) {
	jao[kst + k] = ja[k];
/* L200: */
    }

    if (*job != 1) {
	return 0;
    }
    i_1 = ia[*nrow + 1] - 1;
    for (k = ia[1]; k <= i_1; ++k) {
	ao[kst + k] = a[k];
/* L201: */
    }

    return 0;
/* --------end-of-copmat -------------------------------------------------
 */
/* -----------------------------------------------------------------------
 */
} /* copmat_ */

/* ************************************************************************** */
/* SPARSKIT2 library routine, copyright 1990, 1994 by Yousef Saad.            */
/* Used by permission.  This program is not to be copied without the          */
/* permission of Yousef Saad.  This program comes with no warranty whatsover. */
/* Yousef Saad and the contributors to SPARSKIT2 are not liable for any       */
/* loss, damage, or inconvenience caused in the use of this program or        */
/* any modification of it.                                                    */
/* ************************************************************************** */
/* ----------------------------------------------------------------------- */
/* Subroutine */ int getdia_(nrow, ncol, job, a, ja, ia, len, diag, idiag, 
	ioff)
integer *nrow, *ncol, *job;
doublereal *a;
integer *ja, *ia, *len;
doublereal *diag;
integer *idiag, *ioff;
{
    /* System generated locals */
    integer i_1, i_2;

    /* Local variables */
    static integer iend, kold, i, k, kdiag, ko, istart;

/* -----------------------------------------------------------------------
 */
/* this subroutine extracts a given diagonal from a matrix stored in csr 
*/
/* format. the output matrix may be transformed with the diagonal removed 
*/
/* from it if desired (as indicated by job.) */
/* -----------------------------------------------------------------------
 */
/* our definition of a diagonal of matrix is a vector of length nrow */
/* (always) which contains the elements in rows 1 to nrow of */
/* the matrix that are contained in the diagonal offset by ioff */
/* with respect to the main diagonal. if the diagonal element */
/* falls outside the matrix then it is defined as a zero entry. */
/* thus the proper definition of diag(*) with offset ioff is */

/*     diag(i) = a(i,ioff+i) i=1,2,...,nrow */
/*     with elements falling outside the matrix being defined as zero. */

/* -----------------------------------------------------------------------
 */

/* on entry: */
/* ---------- */

/* nrow	= integer. the row dimension of the matrix a. */
/* ncol	= integer. the column dimension of the matrix a. */
/* job   = integer. job indicator.  if job = 0 then */
/*         the matrix a, ja, ia, is not altered on return. */
/*         if job.ne.0  then getdia will remove the entries */
/*         collected in diag from the original matrix. */
/*         this is done in place. */

/* a,ja, */
/*    ia = matrix stored in compressed sparse row a,ja,ia,format */
/* ioff  = integer,containing the offset of the wanted diagonal */
/* 	  the diagonal extracted is the one corresponding to the */
/* 	  entries a(i,j) with j-i = ioff. */
/* 	  thus ioff = 0 means the main diagonal */

/* on return: */
/* ----------- */
/* len   = number of nonzero elements found in diag. */
/*         (len .le. min(nrow,ncol-ioff)-max(1,1-ioff) + 1 ) */

/* diag  = real*8 array of length nrow containing the wanted diagonal. */
/* 	  diag contains the diagonal (a(i,j),j-i = ioff ) as defined */
/*         above. */

/* idiag = integer array of  length len, containing the poisitions */
/*         in the original arrays a and ja of the diagonal elements */
/*         collected in diag. a zero entry in idiag(i) means that */
/*         there was no entry found in row i belonging to the diagonal. */


/* a, ja, */
/*    ia = if job .ne. 0 the matrix is unchanged. otherwise the nonzero */

/*         diagonal entries collected in diag are removed from the */
/*         matrix and therefore the arrays a, ja, ia will change. */
/* 	  (the matrix a, ja, ia will contain len fewer elements) */

/* ----------------------------------------------------------------------c
 */
/*     Y. Saad, sep. 21 1989 - modified and retested Feb 17, 1996.      c 
*/
/* ----------------------------------------------------------------------c
 */
/*     local variables */

    /* Parameter adjustments */
    --idiag;
    --diag;
    --ia;
    --ja;
    --a;

    /* Function Body */
/* Computing MAX */
    i_1 = 0, i_2 = -(*ioff);
    istart = max(i_1,i_2);
/* Computing MIN */
    i_1 = *nrow, i_2 = *ncol - *ioff;
    iend = min(i_1,i_2);
    *len = 0;
    i_1 = *nrow;
    for (i = 1; i <= i_1; ++i) {
	idiag[i] = 0;
	diag[i] = 0.;
/* L1: */
    }

/*     extract  diagonal elements */

    i_1 = iend;
    for (i = istart + 1; i <= i_1; ++i) {
	i_2 = ia[i + 1] - 1;
	for (k = ia[i]; k <= i_2; ++k) {
	    if (ja[k] - i == *ioff) {
		diag[i] = a[k];
		idiag[i] = k;
		++(*len);
		goto L6;
	    }
/* L51: */
	}
L6:
	;
    }
    if (*job == 0 || *len == 0) {
	return 0;
    }

/*     remove diagonal elements and rewind structure */

    ko = 0;
    i_1 = *nrow;
    for (i = 1; i <= i_1; ++i) {
	kold = ko;
	kdiag = idiag[i];
	i_2 = ia[i + 1] - 1;
	for (k = ia[i]; k <= i_2; ++k) {
	    if (k != kdiag) {
		++ko;
		a[ko] = a[k];
		ja[ko] = ja[k];
	    }
/* L71: */
	}
	ia[i] = kold + 1;
/* L7: */
    }

/*     redefine ia(nrow+1) */

    ia[*nrow + 1] = ko + 1;
    return 0;
/* ------------end-of-getdia----------------------------------------------
 */
/* -----------------------------------------------------------------------
 */
} /* getdia_ */

/* ************************************************************************** */
/* SPARSKIT2 library routine, copyright 1990, 1994 by Yousef Saad.            */
/* Used by permission.  This program is not to be copied without the          */
/* permission of Yousef Saad.  This program comes with no warranty whatsover. */
/* Yousef Saad and the contributors to SPARSKIT2 are not liable for any       */
/* loss, damage, or inconvenience caused in the use of this program or        */
/* any modification of it.                                                    */
/* ************************************************************************** */
/* ----------------------------------------------------------------------- */
/* Subroutine */ int transp_(nrow, ncol, a, ja, ia, iwk, ierr)
integer *nrow, *ncol;
doublereal *a;
integer *ja, *ia, *iwk, *ierr;
{
    /* System generated locals */
    integer i_1, i_2, i_3;

    /* Local variables */
    static integer jcol, init, i, j, k, l;
    static doublereal t;
    static integer inext;
    static doublereal t1;
    static integer nnz;

/*-----------------------------------------------------------------------
-*/
/* In-place transposition routine. */
/*-----------------------------------------------------------------------
-*/
/* this subroutine transposes a matrix stored in compressed sparse row */
/* format. the transposition is done in place in that the arrays a,ja,ia 
*/
/* of the transpose are overwritten onto the original arrays. */
/*-----------------------------------------------------------------------
-*/
/* on entry: */
/* --------- */
/* nrow	= integer. The row dimension of A. */
/* ncol	= integer. The column dimension of A. */
/* a	= real array of size nnz (number of nonzero elements in A). */
/*         containing the nonzero elements */
/* ja	= integer array of length nnz containing the column positions */
/* 	  of the corresponding elements in a. */
/* ia	= integer of size n+1, where n = max(nrow,ncol). On entry */
/*         ia(k) contains the position in a,ja of  the beginning of */
/*         the k-th row. */

/* iwk	= integer work array of same length as ja. */

/* on return: */
/* ---------- */

/* ncol	= actual row dimension of the transpose of the input matrix. */
/*         Note that this may be .le. the input value for ncol, in */
/*         case some of the last columns of the input matrix are zero */
/*         columns. In the case where the actual number of rows found */
/*         in transp(A) exceeds the input value of ncol, transp will */
/*         return without completing the transposition. see ierr. */
/* a, */
/* ja, */
/* ia	= contains the transposed matrix in compressed sparse */
/*         row format. The row dimension of a, ja, ia is now ncol. */

/* ierr	= integer. error message. If the number of rows for the */
/*         transposed matrix exceeds the input value of ncol, */
/*         then ierr is  set to that number and transp quits. */
/*         Otherwise ierr is set to 0 (normal return). */

/* Note: */
/* ----- 1) If you do not need the transposition to be done in place */
/*         it is preferrable to use the conversion routine csrcsc */
/*         (see conversion routines in formats). */
/*      2) the entries of the output matrix are not sorted (the column */
/*         indices in each are not in increasing order) use csrcsc */
/*         if you want them sorted. */
/* ----------------------------------------------------------------------c
 */
/*           Y. Saad, Sep. 21 1989                                      c 
*/
/*  modified Oct. 11, 1989.                                             c 
*/
/* ----------------------------------------------------------------------c
 */
/* local variables */
    /* Parameter adjustments */
    --iwk;
    --ia;
    --ja;
    --a;

    /* Function Body */
    *ierr = 0;
    nnz = ia[*nrow + 1] - 1;

/*     determine column dimension */

    jcol = 0;
    i_1 = nnz;
    for (k = 1; k <= i_1; ++k) {
/* Computing MAX */
	i_2 = jcol, i_3 = ja[k];
	jcol = max(i_2,i_3);
/* L1: */
    }
    if (jcol > *ncol) {
	*ierr = jcol;
	return 0;
    }

/*     convert to coordinate format. use iwk for row indices. */

    *ncol = jcol;

    i_1 = *nrow;
    for (i = 1; i <= i_1; ++i) {
	i_2 = ia[i + 1] - 1;
	for (k = ia[i]; k <= i_2; ++k) {
	    iwk[k] = i;
/* L2: */
	}
/* L3: */
    }
/*     find pointer array for transpose. */
    i_1 = *ncol + 1;
    for (i = 1; i <= i_1; ++i) {
	ia[i] = 0;
/* L35: */
    }
    i_1 = nnz;
    for (k = 1; k <= i_1; ++k) {
	i = ja[k];
	++ia[i + 1];
/* L4: */
    }
    ia[1] = 1;
/*-----------------------------------------------------------------------
-*/
    i_1 = *ncol;
    for (i = 1; i <= i_1; ++i) {
	ia[i + 1] = ia[i] + ia[i + 1];
/* L44: */
    }

/*     loop for a cycle in chasing process. */

    init = 1;
    k = 0;
L5:
    t = a[init];
    i = ja[init];
    j = iwk[init];
    iwk[init] = -1;
/*-----------------------------------------------------------------------
-*/
L6:
    ++k;
/*     current row number is i.  determine  where to go. */
    l = ia[i];
/*     save the chased element. */
    t1 = a[l];
    inext = ja[l];
/*     then occupy its location. */
    a[l] = t;
    ja[l] = j;
/*     update pointer information for next element to be put in row i. */
    ia[i] = l + 1;
/*     determine  next element to be chased */
    if (iwk[l] < 0) {
	goto L65;
    }
    t = t1;
    i = inext;
    j = iwk[l];
    iwk[l] = -1;
    if (k < nnz) {
	goto L6;
    }
    goto L70;
L65:
    ++init;
    if (init > nnz) {
	goto L70;
    }
    if (iwk[init] < 0) {
	goto L65;
    }
/*     restart chasing -- */
    goto L5;
L70:
    for (i = *ncol; i >= 1; --i) {
	ia[i + 1] = ia[i];
/* L80: */
    }
    ia[1] = 1;

    return 0;
/*------------------end-of-transp ---------------------------------------
-*/
/*-----------------------------------------------------------------------
-*/
} /* transp_ */

/* ************************************************************************** */
/* SPARSKIT2 library routine, copyright 1990, 1994 by Yousef Saad.            */
/* Used by permission.  This program is not to be copied without the          */
/* permission of Yousef Saad.  This program comes with no warranty whatsover. */
/* Yousef Saad and the contributors to SPARSKIT2 are not liable for any       */
/* loss, damage, or inconvenience caused in the use of this program or        */
/* any modification of it.                                                    */
/* ************************************************************************** */
/* ----------------------------------------------------------------------- */
/* Subroutine */ int getu_(n, a, ja, ia, ao, jao, iao)
integer *n;
doublereal *a;
integer *ja, *ia;
doublereal *ao;
integer *jao, *iao;
{
    /* System generated locals */
    integer i_1, i_2;

    /* Local variables */
    static integer i, k, kdiag;
    static doublereal t;
    static integer ko, kfirst;

/*-----------------------------------------------------------------------
-*/
/* this subroutine extracts the upper triangular part of a matrix */
/* and writes the result ao, jao, iao. The routine is in place in */
/* that ao, jao, iao can be the same as a, ja, ia if desired. */
/* ----------- */
/* on input: */

/* n     = dimension of the matrix a. */
/* a, ja, */
/*    ia = matrix stored in a, ja, ia, format */
/* On return: */
/* ao, jao, */
/*    iao = upper triangular matrix (upper part of a) */
/* 	stored in compressed sparse row format */
/* note: the diagonal element is the last element in each row. */
/* i.e. in  a(ia(i+1)-1 ) */
/* ao, jao, iao may be the same as a, ja, ia on entry -- in which case */
/* getu will overwrite the result on a, ja, ia. */

/*-----------------------------------------------------------------------
-*/
/* local variables */
    /* Parameter adjustments */
    --iao;
    --jao;
    --ao;
    --ia;
    --ja;
    --a;

    /* Function Body */
    ko = 0;
    i_1 = *n;
    for (i = 1; i <= i_1; ++i) {
	kfirst = ko + 1;
	kdiag = 0;
	i_2 = ia[i + 1] - 1;
	for (k = ia[i]; k <= i_2; ++k) {
	    if (ja[k] < i) {
		goto L71;
	    }
	    ++ko;
	    ao[ko] = a[k];
	    jao[ko] = ja[k];
	    if (ja[k] == i) {
		kdiag = ko;
	    }
L71:
	    ;
	}
	if (kdiag == 0 || kdiag == kfirst) {
	    goto L72;
	}
/*     exchange */
	t = ao[kdiag];
	ao[kdiag] = ao[kfirst];
	ao[kfirst] = t;

	k = jao[kdiag];
	jao[kdiag] = jao[kfirst];
	jao[kfirst] = k;
L72:
	iao[i] = kfirst;
/* L7: */
    }
/*     redefine iao(n+1) */
    iao[*n + 1] = ko + 1;
    return 0;
/* ----------end-of-getu -------------------------------------------------
 */
/* -----------------------------------------------------------------------
 */
} /* getu_ */

/* ************************************************************************** */
/* SPARSKIT2 library routine, copyright 1990, 1994 by Yousef Saad.            */
/* Used by permission.  This program is not to be copied without the          */
/* permission of Yousef Saad.  This program comes with no warranty whatsover. */
/* Yousef Saad and the contributors to SPARSKIT2 are not liable for any       */
/* loss, damage, or inconvenience caused in the use of this program or        */
/* any modification of it.                                                    */
/* ************************************************************************** */
/* ----------------------------------------------------------------------- */
/* Subroutine */ int rperm_(nrow, a, ja, ia, ao, jao, iao, perm, job)
integer *nrow;
doublereal *a;
integer *ja, *ia;
doublereal *ao;
integer *jao, *iao, *perm, *job;
{
    /* System generated locals */
    integer i_1, i_2;

    /* Local variables */
    static integer i, j, k, ii, ko;
    static logical values;

/* -----------------------------------------------------------------------
 */
/* this subroutine permutes the rows of a matrix in CSR format. */
/* rperm  computes B = P A  where P is a permutation matrix. */
/* the permutation P is defined through the array perm: for each j, */
/* perm(j) represents the destination row number of row number j. */
/* Youcef Saad -- recoded Jan 28, 1991. */
/* -----------------------------------------------------------------------
 */
/* on entry: */
/* ---------- */
/* n 	= dimension of the matrix */
/* a, ja, ia = input matrix in csr format */
/* perm 	= integer array of length nrow containing the permutation arrays 
*/
/* 	  for the rows: perm(i) is the destination of row i in the */
/*         permuted matrix. */
/*         ---> a(i,j) in the original matrix becomes a(perm(i),j) */
/*         in the output  matrix. */

/* job	= integer indicating the work to be done: */
/* 		job = 1	permute a, ja, ia into ao, jao, iao */
/*                       (including the copying of real values ao and */
/*                       the array iao). */
/* 		job .ne. 1 :  ignore real values. */
/*                     (in which case arrays a and ao are not needed nor 
*/
/*                      used). */

/* ------------ */
/* on return: */
/* ------------ */
/* ao, jao, iao = input matrix in a, ja, ia format */
/* note : */
/*        if (job.ne.1)  then the arrays a and ao are not used. */
/* ----------------------------------------------------------------------c
 */
/*           Y. Saad, May  2, 1990                                      c 
*/
/* ----------------------------------------------------------------------c
 */
    /* Parameter adjustments */
    --perm;
    --iao;
    --jao;
    --ao;
    --ia;
    --ja;
    --a;

    /* Function Body */
    values = *job == 1;

/*     determine pointers for output matix. */

    i_1 = *nrow;
    for (j = 1; j <= i_1; ++j) {
	i = perm[j];
	iao[i + 1] = ia[j + 1] - ia[j];
/* L50: */
    }

/* get pointers from lengths */

    iao[1] = 1;
    i_1 = *nrow;
    for (j = 1; j <= i_1; ++j) {
	iao[j + 1] += iao[j];
/* L51: */
    }

/* copying */

    i_1 = *nrow;
    for (ii = 1; ii <= i_1; ++ii) {

/* old row = ii  -- new row = iperm(ii) -- ko = new pointer */

	ko = iao[perm[ii]];
	i_2 = ia[ii + 1] - 1;
	for (k = ia[ii]; k <= i_2; ++k) {
	    jao[ko] = ja[k];
	    if (values) {
		ao[ko] = a[k];
	    }
	    ++ko;
/* L60: */
	}
/* L100: */
    }

    return 0;
/* ---------end-of-rperm -------------------------------------------------
 */
/* -----------------------------------------------------------------------
 */
} /* rperm_ */

/* ************************************************************************** */
/* SPARSKIT2 library routine, copyright 1990, 1994 by Yousef Saad.            */
/* Used by permission.  This program is not to be copied without the          */
/* permission of Yousef Saad.  This program comes with no warranty whatsover. */
/* Yousef Saad and the contributors to SPARSKIT2 are not liable for any       */
/* loss, damage, or inconvenience caused in the use of this program or        */
/* any modification of it.                                                    */
/* ************************************************************************** */
/* ----------------------------------------------------------------------- */
/* Subroutine */ int cperm_(nrow, a, ja, ia, ao, jao, iao, perm, job)
integer *nrow;
doublereal *a;
integer *ja, *ia;
doublereal *ao;
integer *jao, *iao, *perm, *job;
{
    /* System generated locals */
    integer i_1;

    /* Local variables */
    static integer i, k, nnz;

/* -----------------------------------------------------------------------
 */
/* this subroutine permutes the columns of a matrix a, ja, ia. */
/* the result is written in the output matrix  ao, jao, iao. */
/* cperm computes B = A P, where  P is a permutation matrix */
/* that maps column j into column perm(j), i.e., on return */
/*      a(i,j) becomes a(i,perm(j)) in new matrix */
/* Y. Saad, May 2, 1990 / modified Jan. 28, 1991. */
/* -----------------------------------------------------------------------
 */
/* on entry: */
/* ---------- */
/* nrow 	= row dimension of the matrix */

/* a, ja, ia = input matrix in csr format. */

/* perm	= integer array of length ncol (number of columns of A */
/*         containing the permutation array  the columns: */
/*         a(i,j) in the original matrix becomes a(i,perm(j)) */
/*         in the output matrix. */

/* job	= integer indicating the work to be done: */
/* 		job = 1	permute a, ja, ia into ao, jao, iao */
/*                       (including the copying of real values ao and */
/*                       the array iao). */
/* 		job .ne. 1 :  ignore real values ao and ignore iao. */

/* ------------ */
/* on return: */
/* ------------ */
/* ao, jao, iao = input matrix in a, ja, ia format (array ao not needed) 
*/

/* Notes: */
/* ------- */
/* 1. if job=1 then ao, iao are not used. */
/* 2. This routine is in place: ja, jao can be the same. */
/* 3. If the matrix is initially sorted (by increasing column number) */
/*    then ao,jao,iao  may not be on return. */

/* ----------------------------------------------------------------------c
 */
/* local parameters: */

    /* Parameter adjustments */
    --perm;
    --iao;
    --jao;
    --ao;
    --ia;
    --ja;
    --a;

    /* Function Body */
    nnz = ia[*nrow + 1] - 1;
    i_1 = nnz;
    for (k = 1; k <= i_1; ++k) {
	jao[k] = perm[ja[k]];
/* L100: */
    }

/*     done with ja array. return if no need to touch values. */

    if (*job != 1) {
	return 0;
    }

/* else get new pointers -- and copy values too. */

    i_1 = *nrow + 1;
    for (i = 1; i <= i_1; ++i) {
	iao[i] = ia[i];
/* L1: */
    }

    i_1 = nnz;
    for (k = 1; k <= i_1; ++k) {
	ao[k] = a[k];
/* L2: */
    }

    return 0;
/* ---------end-of-cperm--------------------------------------------------
 */
/* -----------------------------------------------------------------------
 */
} /* cperm_ */

/* ************************************************************************** */
/* SPARSKIT2 library routine, copyright 1990, 1994 by Yousef Saad.            */
/* Used by permission.  This program is not to be copied without the          */
/* permission of Yousef Saad.  This program comes with no warranty whatsover. */
/* Yousef Saad and the contributors to SPARSKIT2 are not liable for any       */
/* loss, damage, or inconvenience caused in the use of this program or        */
/* any modification of it.                                                    */
/* ************************************************************************** */
/* ----------------------------------------------------------------------- */
/* Subroutine */ int rnrms_(nrow, nrm, a, ja, ia, diag)
integer *nrow, *nrm;
doublereal *a;
integer *ja, *ia;
doublereal *diag;
{
    /* System generated locals */
    integer i_1, i_2;
    doublereal d_1, d_2, d_3;

    /* Builtin functions */
    double sqrt();

    /* Local variables */
    static doublereal scal;
    static integer k, k1, k2, ii;

/* -----------------------------------------------------------------------
 */
/* gets the norms of each row of A. (choice of three norms) */
/* -----------------------------------------------------------------------
 */
/* on entry: */
/* --------- */
/* nrow	= integer. The row dimension of A */

/* nrm   = integer. norm indicator. nrm = 1, means 1-norm, nrm =2 */
/*                  means the 2-nrm, nrm = 0 means max norm */

/* a, */
/* ja, */
/* ia   = Matrix A in compressed sparse row format. */

/* on return: */
/* ---------- */

/* diag = real vector of length nrow containing the norms */

/* ----------------------------------------------------------------- */
    /* Parameter adjustments */
    --diag;
    --ia;
    --ja;
    --a;

    /* Function Body */
    i_1 = *nrow;
    for (ii = 1; ii <= i_1; ++ii) {

/*     compute the norm if each element. */

	scal = 0.;
	k1 = ia[ii];
	k2 = ia[ii + 1] - 1;
	if (*nrm == 0) {
	    i_2 = k2;
	    for (k = k1; k <= i_2; ++k) {
/* Computing MAX */
		d_2 = scal, d_3 = (d_1 = a[k], abs(d_1));
		scal = max(d_2,d_3);
/* L2: */
	    }
	} else if (*nrm == 1) {
	    i_2 = k2;
	    for (k = k1; k <= i_2; ++k) {
		scal += (d_1 = a[k], abs(d_1));
/* L3: */
	    }
	} else {
	    i_2 = k2;
	    for (k = k1; k <= i_2; ++k) {
/* Computing 2nd power */
		d_1 = a[k];
		scal += d_1 * d_1;
/* L4: */
	    }
	}
	if (*nrm == 2) {
	    scal = sqrt(scal);
	}
	diag[ii] = scal;
/* L1: */
    }
    return 0;
/* -----------------------------------------------------------------------
 */
/* -------------end-of-rnrms----------------------------------------------
 */
} /* rnrms_ */

/* ************************************************************************** */
/* SPARSKIT2 library routine, copyright 1990, 1994 by Yousef Saad.            */
/* Used by permission.  This program is not to be copied without the          */
/* permission of Yousef Saad.  This program comes with no warranty whatsover. */
/* Yousef Saad and the contributors to SPARSKIT2 are not liable for any       */
/* loss, damage, or inconvenience caused in the use of this program or        */
/* any modification of it.                                                    */
/* ************************************************************************** */
/* ----------------------------------------------------------------------- */
/* Subroutine */ int cnrms_(nrow, nrm, a, ja, ia, diag)
integer *nrow, *nrm;
doublereal *a;
integer *ja, *ia;
doublereal *diag;
{
    /* System generated locals */
    integer i_1, i_2;
    doublereal d_1, d_2, d_3;

    /* Builtin functions */
    double sqrt();

    /* Local variables */
    static integer j, k, k1, k2, ii;

/* -----------------------------------------------------------------------
 */
/* gets the norms of each column of A. (choice of three norms) */
/* -----------------------------------------------------------------------
 */
/* on entry: */
/* --------- */
/* nrow	= integer. The row dimension of A */

/* nrm   = integer. norm indicator. nrm = 1, means 1-norm, nrm =2 */
/*                  means the 2-nrm, nrm = 0 means max norm */

/* a, */
/* ja, */
/* ia   = Matrix A in compressed sparse row format. */

/* on return: */
/* ---------- */

/* diag = real vector of length nrow containing the norms */

/* ----------------------------------------------------------------- */
    /* Parameter adjustments */
    --diag;
    --ia;
    --ja;
    --a;

    /* Function Body */
    i_1 = *nrow;
    for (k = 1; k <= i_1; ++k) {
	diag[k] = 0.;
/* L10: */
    }
    i_1 = *nrow;
    for (ii = 1; ii <= i_1; ++ii) {
	k1 = ia[ii];
	k2 = ia[ii + 1] - 1;
	i_2 = k2;
	for (k = k1; k <= i_2; ++k) {
	    j = ja[k];
/*     update the norm of each column */
	    if (*nrm == 0) {
/* Computing MAX */
		d_2 = diag[j], d_3 = (d_1 = a[k], abs(d_1));
		diag[j] = max(d_2,d_3);
	    } else if (*nrm == 1) {
		diag[j] += (d_1 = a[k], abs(d_1));
	    } else {
/* Computing 2nd power */
		d_1 = a[k];
		diag[j] += d_1 * d_1;
	    }
/* L2: */
	}
/* L1: */
    }
    if (*nrm != 2) {
	return 0;
    }
    i_1 = *nrow;
    for (k = 1; k <= i_1; ++k) {
	diag[k] = sqrt(diag[k]);
/* L3: */
    }
    return 0;
/* -----------------------------------------------------------------------
 */
/* ------------end-of-cnrms-----------------------------------------------
 */
} /* cnrms_ */

/* ----------------------------------------------------------------------c */
/*                          S P A R S K I T                             c */
/* ----------------------------------------------------------------------c */
/*          BASIC MATRIX-VECTOR OPERATIONS - MATVEC MODULE              c */
/*         Matrix-vector Mulitiplications and Triang. Solves            c */
/* ----------------------------------------------------------------------c */
/* contents: (as of Nov 18, 1991)                                       c */
/* ----------                                                            c */
/* 1) Matrix-vector products:                                           c */
/* ---------------------------                                           c */
/* amux  : A times a vector. Compressed Sparse Row (CSR) format.        c */
/*                                                                      c */
/* 2) Triangular system solutions:                                      c */
/* -------------------------------                                       c */
/* usol  : Unit Upper Triang. solve. Compressed Sparse Row (CSR) format.c */
/*                                                                      c */
/* ----------------------------------------------------------------------c */
/* 1)     M A T R I X    B Y    V E C T O R     P R O D U C T S         c */
/* ----------------------------------------------------------------------c */
/* ************************************************************************** */
/* SPARSKIT2 library routine, copyright 1990, 1994 by Yousef Saad.            */
/* Used by permission.  This program is not to be copied without the          */
/* permission of Yousef Saad.  This program comes with no warranty whatsover. */
/* Yousef Saad and the contributors to SPARSKIT2 are not liable for any       */
/* loss, damage, or inconvenience caused in the use of this program or        */
/* any modification of it.                                                    */
/* ************************************************************************** */
/* Subroutine */ int amux_(n, x, y, a, ja, ia)
integer *n;
doublereal *x, *y, *a;
integer *ja, *ia;
{
    /* System generated locals */
    integer i_1, i_2;

    /* Local variables */
    static integer i, k;
    static doublereal t;

/* -----------------------------------------------------------------------
 */
/*         A times a vector */
/* -----------------------------------------------------------------------
 */
/* multiplies a matrix by a vector using the dot product form */
/* Matrix A is stored in compressed sparse row storage. */

/* on entry: */
/* ---------- */
/* n     = row dimension of A */
/* x     = real array of length equal to the column dimension of */
/*         the A matrix. */
/* a, ja, */
/*    ia = input matrix in compressed sparse row format. */

/* on return: */
/* ----------- */
/* y     = real array of length n, containing the product y=Ax */

/* -----------------------------------------------------------------------
 */
/* local variables */

/* -----------------------------------------------------------------------
 */
    /* Parameter adjustments */
    --ia;
    --ja;
    --a;
    --y;
    --x;

    /* Function Body */
    i_1 = *n;
    for (i = 1; i <= i_1; ++i) {

/*     compute the inner product of row i with vector x */

	t = 0.;
	i_2 = ia[i + 1] - 1;
	for (k = ia[i]; k <= i_2; ++k) {
	    t += a[k] * x[ja[k]];
/* L99: */
	}

/*     store result in y(i) */

	y[i] = t;
/* L100: */
    }

    return 0;
/* ---------end-of-amux---------------------------------------------------
 */
/* -----------------------------------------------------------------------
 */
} /* amux_ */


/* ----------------------------------------------------------------------c */
/* 2)     T R I A N G U L A R    S Y S T E M    S O L U T I O N S       c */
/* ----------------------------------------------------------------------c */
/* ----------------------------------------------------------------------- */
/* ************************************************************************** */
/* SPARSKIT2 library routine, copyright 1990, 1994 by Yousef Saad.            */
/* Used by permission.  This program is not to be copied without the          */
/* permission of Yousef Saad.  This program comes with no warranty whatsover. */
/* Yousef Saad and the contributors to SPARSKIT2 are not liable for any       */
/* loss, damage, or inconvenience caused in the use of this program or        */
/* any modification of it.                                                    */
/* ************************************************************************** */
/* Subroutine */ int usol_(n, x, y, au, jau, iau)
integer *n;
doublereal *x, *y, *au;
integer *jau, *iau;
{
    /* System generated locals */
    integer i_1;

    /* Local variables */
    static integer j, k;
    static doublereal t;

/* -----------------------------------------------------------------------
 */
/*             Solves   U x = y    U = unit upper triangular. */
/* -----------------------------------------------------------------------
 */
/* solves a unit upper triangular system by standard (sequential ) */
/* backward elimination - matrix stored in CSR format. */
/* -----------------------------------------------------------------------
 */

/* On entry: */
/* ---------- */
/* n      = integer. dimension of problem. */
/* y      = real array containg the right side. */

/* au, */
/* jau, */
/* iau,    = Lower triangular matrix stored in compressed sparse row */
/*          format. */

/* On return: */
/* ----------- */
/* 	x = The solution of  U x = y . */
/* -------------------------------------------------------------------- */

/* local variables */

/* -----------------------------------------------------------------------
 */
    /* Parameter adjustments */
    --iau;
    --jau;
    --au;
    --y;
    --x;

    /* Function Body */
    x[*n] = y[*n];
    for (k = *n - 1; k >= 1; --k) {
	t = y[k];
	i_1 = iau[k + 1] - 1;
	for (j = iau[k]; j <= i_1; ++j) {
	    t -= au[j] * x[jau[j]];
/* L100: */
	}
	x[k] = t;
/* L150: */
    }

    return 0;
/* ----------end-of-usol--------------------------------------------------
 */
/* -----------------------------------------------------------------------
 */
} /* usol_ */

/* blassm.f -- translated by f2c (version of 27 June 1990  8:41:01).
   You must link the resulting object file with the libraries:
	-lF77 -lI77 -lm -lc   (in that order)
*/

#include "f2c.h"

/* ----------------------------------------------------------------------c */
/*                          S P A R S K I T                             c */
/* ----------------------------------------------------------------------c */
/*        BASIC LINEAR ALGEBRA FOR SPARSE MATRICES. BLASSM MODULE       c */
/* ----------------------------------------------------------------------c */
/* amub   :   computes     C = A*B                                      c */
/* aplb   :   computes     C = A+B                                      c */
/* diamua :   Computes     C = Diag * A                                 c */
/* ----------------------------------------------------------------------c */
/* Note: this module still incomplete.                                  c */
/* ----------------------------------------------------------------------c */
/* ************************************************************************** */
/* SPARSKIT2 library routine, copyright 1990, 1994 by Yousef Saad.            */
/* Used by permission.  This program is not to be copied without the          */
/* permission of Yousef Saad.  This program comes with no warranty whatsover. */
/* Yousef Saad and the contributors to SPARSKIT2 are not liable for any       */
/* loss, damage, or inconvenience caused in the use of this program or        */
/* any modification of it.                                                    */
/* ************************************************************************** */
/* Subroutine */ int amub_(nrow, ncol, job, a, ja, ia, b, jb, ib, c, jc, ic, 
	nzmax, iw, ierr)
integer *nrow, *ncol, *job;
doublereal *a;
integer *ja, *ia;
doublereal *b;
integer *jb, *ib;
doublereal *c;
integer *jc, *ic, *nzmax, *iw, *ierr;
{
    /* System generated locals */
    integer i_1, i_2, i_3;

    /* Local variables */
    static doublereal scal;
    static integer jcol, jpos, j, k, ka, kb, ii, jj;
    static logical values;
    static integer len;

/* -----------------------------------------------------------------------
 */
/* performs the matrix by matrix product C = A B */
/* -----------------------------------------------------------------------
 */
/* on entry: */
/* --------- */
/* nrow  = integer. The row dimension of A = row dimension of C */
/* ncol  = integer. The column dimension of B = column dimension of C */
/* job   = integer. Job indicator. When job = 0, only the structure */
/*                  (i.e. the arrays jc, ic) is computed and the */
/*                  real values are ignored. */

/* a, */
/* ja, */
/* ia   = Matrix A in compressed sparse row format. */

/* b, */
/* jb, */
/* ib    =  Matrix B in compressed sparse row format. */

/* nzmax = integer. The  length of the arrays c and jc. */
/*         amub will stop if the result matrix C  has a number */
/*         of elements that exceeds exceeds nzmax. See ierr. */

/* on return: */
/* ---------- */
/* c, */
/* jc, */
/* ic    = resulting matrix C in compressed sparse row sparse format. */

/* ierr  = integer. serving as error message. */
/*         ierr = 0 means normal return, */
/*         ierr .gt. 0 means that amub stopped while computing the */
/*         i-th row  of C with i=ierr, because the number */
/*         of elements in C exceeds nzmax. */

/* work arrays: */
/* ------------ */
/* iw    = integer work array of length equal to the number of */
/*         columns in A. */
/* Note: */
/* ------- */
/*   The row dimension of B is not needed. However there is no checking */

/*   on the condition that ncol(A) = nrow(B). */

/* -----------------------------------------------------------------------
 */
    /* Parameter adjustments */
    --iw;
    --ic;
    --jc;
    --c;
    --ib;
    --jb;
    --b;
    --ia;
    --ja;
    --a;

    /* Function Body */
    values = *job != 0;
    len = 0;
    ic[1] = 1;
    *ierr = 0;
/*     initialize array iw. */
    i_1 = *ncol;
    for (j = 1; j <= i_1; ++j) {
	iw[j] = 0;
/* L1: */
    }

    i_1 = *nrow;
    for (ii = 1; ii <= i_1; ++ii) {
/*     row i */
	i_2 = ia[ii + 1] - 1;
	for (ka = ia[ii]; ka <= i_2; ++ka) {
	    if (values) {
		scal = a[ka];
	    }
	    jj = ja[ka];
	    i_3 = ib[jj + 1] - 1;
	    for (kb = ib[jj]; kb <= i_3; ++kb) {
		jcol = jb[kb];
		jpos = iw[jcol];
		if (jpos == 0) {
		    ++len;
		    if (len > *nzmax) {
			*ierr = ii;
			return 0;
		    }
		    jc[len] = jcol;
		    iw[jcol] = len;
		    if (values) {
			c[len] = scal * b[kb];
		    }
		} else {
		    if (values) {
			c[jpos] += scal * b[kb];
		    }
		}
/* L100: */
	    }
/* L200: */
	}
	i_2 = len;
	for (k = ic[ii]; k <= i_2; ++k) {
	    iw[jc[k]] = 0;
/* L201: */
	}
	ic[ii + 1] = len + 1;
/* L500: */
    }
    return 0;
/* -------------end-of-amub-----------------------------------------------
 */
/* -----------------------------------------------------------------------
 */
} /* amub_ */

/* ************************************************************************** */
/* SPARSKIT2 library routine, copyright 1990, 1994 by Yousef Saad.            */
/* Used by permission.  This program is not to be copied without the          */
/* permission of Yousef Saad.  This program comes with no warranty whatsover. */
/* Yousef Saad and the contributors to SPARSKIT2 are not liable for any       */
/* loss, damage, or inconvenience caused in the use of this program or        */
/* any modification of it.                                                    */
/* ************************************************************************** */
/* ----------------------------------------------------------------------- */
/* Subroutine */ int aplb_(nrow, ncol, job, a, ja, ia, b, jb, ib, c, jc, ic, 
	nzmax, iw, ierr)
integer *nrow, *ncol, *job;
doublereal *a;
integer *ja, *ia;
doublereal *b;
integer *jb, *ib;
doublereal *c;
integer *jc, *ic, *nzmax, *iw, *ierr;
{
    /* System generated locals */
    integer i_1, i_2;

    /* Local variables */
    static integer jcol, jpos, j, k, ka, kb, ii;
    static logical values;
    static integer len;

/* -----------------------------------------------------------------------
 */
/* performs the matrix sum  C = A+B. */
/* -----------------------------------------------------------------------
 */
/* on entry: */
/* --------- */
/* nrow	= integer. The row dimension of A and B */
/* ncol  = integer. The column dimension of A and B. */
/* job   = integer. Job indicator. When job = 0, only the structure */
/*                  (i.e. the arrays jc, ic) is computed and the */
/*                  real values are ignored. */

/* a, */
/* ja, */
/* ia   = Matrix A in compressed sparse row format. */

/* b, */
/* jb, */
/* ib	=  Matrix B in compressed sparse row format. */

/* nzmax	= integer. The  length of the arrays c and jc. */
/*         amub will stop if the result matrix C  has a number */
/*         of elements that exceeds exceeds nzmax. See ierr. */

/* on return: */
/* ---------- */
/* c, */
/* jc, */
/* ic	= resulting matrix C in compressed sparse row sparse format. */

/* ierr	= integer. serving as error message. */
/*         ierr = 0 means normal return, */
/*         ierr .gt. 0 means that amub stopped while computing the */
/*         i-th row  of C with i=ierr, because the number */
/*         of elements in C exceeds nzmax. */

/* work arrays: */
/* ------------ */
/* iw	= integer work array of length equal to the number of */
/*         columns in A. */

/* -----------------------------------------------------------------------
 */
    /* Parameter adjustments */
    --iw;
    --ic;
    --jc;
    --c;
    --ib;
    --jb;
    --b;
    --ia;
    --ja;
    --a;

    /* Function Body */
    values = *job != 0;
    *ierr = 0;
    len = 0;
    ic[1] = 1;
    i_1 = *ncol;
    for (j = 1; j <= i_1; ++j) {
	iw[j] = 0;
/* L1: */
    }

    i_1 = *nrow;
    for (ii = 1; ii <= i_1; ++ii) {
/*     row i */
	i_2 = ia[ii + 1] - 1;
	for (ka = ia[ii]; ka <= i_2; ++ka) {
	    ++len;
	    jcol = ja[ka];
	    if (len > *nzmax) {
		goto L999;
	    }
	    jc[len] = jcol;
	    if (values) {
		c[len] = a[ka];
	    }
	    iw[jcol] = len;
/* L200: */
	}

	i_2 = ib[ii + 1] - 1;
	for (kb = ib[ii]; kb <= i_2; ++kb) {
	    jcol = jb[kb];
	    jpos = iw[jcol];
	    if (jpos == 0) {
		++len;
		if (len > *nzmax) {
		    goto L999;
		}
		jc[len] = jcol;
		if (values) {
		    c[len] = b[kb];
		}
		iw[jcol] = len;
	    } else {
		if (values) {
		    c[jpos] += b[kb];
		}
	    }
/* L300: */
	}
	i_2 = len;
	for (k = ic[ii]; k <= i_2; ++k) {
	    iw[jc[k]] = 0;
/* L301: */
	}
	ic[ii + 1] = len + 1;
/* L500: */
    }
    return 0;
L999:
    *ierr = ii;
    return 0;
/* ------------end of aplb -----------------------------------------------
 */
/* -----------------------------------------------------------------------
 */
} /* aplb_ */

/* ************************************************************************** */
/* SPARSKIT2 library routine, copyright 1990, 1994 by Yousef Saad.            */
/* Used by permission.  This program is not to be copied without the          */
/* permission of Yousef Saad.  This program comes with no warranty whatsover. */
/* Yousef Saad and the contributors to SPARSKIT2 are not liable for any       */
/* loss, damage, or inconvenience caused in the use of this program or        */
/* any modification of it.                                                    */
/* ************************************************************************** */
/* ----------------------------------------------------------------------- */
/* Subroutine */ int diamua_(nrow, job, a, ja, ia, diag, b, jb, ib)
integer *nrow, *job;
doublereal *a;
integer *ja, *ia;
doublereal *diag, *b;
integer *jb, *ib;
{
    /* System generated locals */
    integer i_1, i_2;

    /* Local variables */
    static doublereal scal;
    static integer k, k1, k2, ii;

/* -----------------------------------------------------------------------
 */
/* performs the matrix by matrix product B = Diag * A  (in place) */
/* -----------------------------------------------------------------------
 */
/* on entry: */
/* --------- */
/* nrow	= integer. The row dimension of A */

/* job   = integer. job indicator. Job=0 means get array b only */
/*         job = 1 means get b, and the integer arrays ib, jb. */

/* a, */
/* ja, */
/* ia   = Matrix A in compressed sparse row format. */

/* diag = diagonal matrix stored as a vector dig(1:n) */

/* on return: */
/* ---------- */

/* b, */
/* jb, */
/* ib	= resulting matrix B in compressed sparse row sparse format. */

/* Notes: */
/* ------- */
/* 1)        The column dimension of A is not needed. */
/* 2)        algorithm in place (B can take the place of A). */
/*           in this case use job=0. */
/* ----------------------------------------------------------------- */
    /* Parameter adjustments */
    --ib;
    --jb;
    --b;
    --diag;
    --ia;
    --ja;
    --a;

    /* Function Body */
    i_1 = *nrow;
    for (ii = 1; ii <= i_1; ++ii) {

/*     normalize each row */

	k1 = ia[ii];
	k2 = ia[ii + 1] - 1;
	scal = diag[ii];
	i_2 = k2;
	for (k = k1; k <= i_2; ++k) {
	    b[k] = a[k] * scal;
/* L2: */
	}
/* L1: */
    }

    if (*job == 0) {
	return 0;
    }

    i_1 = *nrow + 1;
    for (ii = 1; ii <= i_1; ++ii) {
	ib[ii] = ia[ii];
/* L3: */
    }
    i_1 = ia[*nrow + 1] - 1;
    for (k = ia[1]; k <= i_1; ++k) {
	jb[k] = ja[k];
/* L31: */
    }
    return 0;
/* ----------end-of-diamua------------------------------------------------
 */
/* -----------------------------------------------------------------------
 */
} /* diamua_ */

/* ************************************************************************ */
/* end subset of SPARSKIT2 library routines used in sparseAim.c             */
/* ************************************************************************ */
