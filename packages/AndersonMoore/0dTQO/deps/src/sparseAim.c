/* 	-------------------------------------------------------------------------------- */
/* 	sparseAim.c                                                                      */
/*                                                                                   */
/*  implements Anderson-Moore algorithm to solve linear saddle-point problems        */
/*  original version by Gary Anderson.                                               */
/*                                                                                   */
/*                                                                                   */
/*  main functions, in order:                                                        */
/*                                                                                   */
/* 		sparseAim                                                            */
/* 			-- autoRegression                                           */
/* 				-- shiftRightAndRecord                               */
/* 				-- annihilateRows                                                    */
/* 					-- constructQRDecomposition                                      */
/* 			-- augmentQmatWithInvariantSpaceVectors                                  */
/* 				-- identifyEssential                                                 */
/* 				-- constructA                                                        */
/* 				-- useArpack                                                         */
/*                                                                                   */
/* 		obtainSparseReducedForm                                                      */
/* 		applySparseReducedForm                                                       */
/* 		satisfiesLinearSystem                                                        */
/*                                                                                   */
/*                                                                                   */
/*  known problems                                                                   */
/*  --------------                                                                   */
/* 	amat dense but allocated with HMATSIZE.  Should discover the                     */
/* 	appropriate scaling factor for allocation and implement                          */
/*                                                                                   */
/* 	js too big.  The js array has dimension as large as the transition               */
/* 	matrix array even though it only needs as much space to hold column dimensions   */
/*                                                                                   */
/*  calls to dnaupd and dneupd (also dgeesx, etc are platform specific               */
/*  check treatment of char array args when calling Fortran programs from C          */
/*                                                                                   */
/*  satisfiesLinearSystem crashes hard if space parameter is too small.              */
/*  (it also seems to need a lot of space.)  deal with space mgmt generally.         */
/*                                                                                   */
/*                                                                                   */
/*  change log                                                                       */
/*  ----------                                                                       */
/*  12/15/99	gsa original program                                                 */
/*  04/01/02    gsa add pointer to void to arg list of fns using mxCalloc              */
/*  Jan 2003 	rwt reformat source file from nuweb to straight C                    */
/* 	                add profiling statements throughout                              */
/* 	     			replace DBL_EPSILON with ZERO_TOLERANCE, defined below.          */
/*                  add fPrintMatrix, fPrintSparse                                   */
/*  Mar 2003 	rwt add comments, delete unused routines, etc                        */
/*  3/17/03		rwt replace rightMostAllZeroQ with rowEndsInZeroBlock                */
/*                  (called from shiftRightAndRecord)                                */
/*  3/19/03     rwt drop signal/longjmp in sparseAimAssert, use simple return        */
/*                  use error codes instead of line numbers in message calls         */
/*                                                                                   */
/*  3/21/03		rwt rework test to call arpack vs dgees                              */
/*  3/26/03     rwt add ZERO_TOL1 for counting large roots                           */
/*  4/1/03	    rwt add Blanchard-Kahn test, windows compile options                 */
/*  Dec 2004	lg	del fPrintMatrix and fPrintSparse so as to hook up to Matlab                                                                                 */
/*  6/30/2010	ar 	change various "ifdef win32" statements to account for gfortran compiler                                                                                 */
/* 	-------------------------------------------------------------------------------- */


double ZERO_TOLERANCE, ZERO_TOL1 ;
int USEARPACK, TESTBLANCHARDKAHN ;
#include <stdio.h>

#ifdef WIN32
#include <time.h>
#else
#include <sys/time.h>
#include <time.h>
#endif
#define cputime() (( (double)clock() ) / CLOCKS_PER_SEC)
double totcpusec, tmpcpusec, oldcpusec, alloc_sec, assert_sec, qr_sec ;
int alloc_count, assert_count, qr_count ;

double time_rightMostAllZeroQ, time_rmazq_alloc ;
int count_rightMostAllZeroQ, count_constructA, count_useArpack, count_dgees ;
double time_constructQRDecomposition, time_sparseMult, time_arpack, time_sparseMatTimesVec ;
double time_extract, time_backsolve ;
double time_autoregression, time_augmentQ;

int rowEndsInZeroBlock() ;

/*not static because mathLink code uses these*/
int discreteSelect(double * realPart,double * imagPart) {
	return((*realPart* *realPart)+(*imagPart* *imagPart)>1+ (ZERO_TOL1));
}
int continuousSelect(double * realPart,double * imagPart) {
	return(*realPart>ZERO_TOLERANCE);
}

#include "sparseAim.h"
//#include "mex.h"

/* --------------------------------------------------------------- */
/* !sparseAim                                                      */
/* rwt add profiling                                               */
/* --------------------------------------------------------------- */

/* ---------------------------------------------------------------------------------

	Given the structural coefficients matrix, this routine computes
	the statespace transition matrix, and its eigenvalues and constructs the asymptotic 
	constraints matrix.  Returns an int, the number of rows in the asymptotic constraint
	matrix.


Arguments
---------

	All args should be allocated and initialized by the caller as shown below.
	In these comments, 
			qmax == maxNumberOfHElements
	Arrays are assumed to be initialized to zero unless otherwise specified.

	maxNumberOfHElements (input,output) 

		A pointer to a strictly positive int:  the number of elements to allocate 
		for sparse matrix storage. On output, the minimum value required to carry 
		out the computations for this function invocation.  

		Recommended initial guess is hrows*hcols. 
				
	discreteTime (input) 
	
		when non-zero, computes discrete time solutions 
		when 0 computes continuous time solutions.
		The former case requires ruling out eigenvalues bigger than one in magnitude.
		The latter case requires ruling out eigenvalues with positive real part. 
		The sparseAim.h include file provides definitions for these int constants.

	hrows (input) 
	
		a strictly positive int characterizing the number of rows in hmat
		also equal to the number of equations in the model, referred to here as neq

	hcols (input) 
	
		a strictly positive int characterizing the number of columns in hmat

	leads (input) 
	
		a strictly positive int characterizing the number of leads

	hmat, hmatj, hmati (input)

		structural coefficients matrix in `compressed sparse row' (CSR) format. 
		The CSR data structure consists of three arrays:

			A real array A containing the real values a_{i,j} stored row by row,
			from row 1 to N. The length of A is NNZ.

			An integer array JA containing the column indices of the elements a_{i,j} 
			as stored in the array $A$.  The length of JA is NNZ.

			An integer array IA containing the pointers to the beginning of each row 
			in the arrays A and JA. The content of IA(i) is the position in arrays A and JA 
			where the i-th row starts.  The length of IA is N+1 with IA(N+1) containing the
			number IA(1)+NNZ, i.e., the address in A and JA of the beginning of a fictitious 
			row N+1.

		allocate as:

			double *hmat[qmax]
			int *hmatj[qmax]
			int *hmati[hrows+1]

	newHmat, newHmatj, newHmati (output)

		transformed structural coefficients matrix in CSR format. Leading block non-singular.
		allocate as:

			double *newHmat[qmax]
			int *newHmatj[qmax]
			int *newHmati[hrows+1]

	auxiliaryInitialConditions (input,output) 
	
		a non-negative int indicating the number of auxiliary initial conditions
		set to zero on input unless user is pre-initializing Q with aux conditions.

	rowsInQ (input,output)  
		
		a non-negative int indicating the number of rows in qmat.
		set to zero on input (unless aux conditions set on input?)

	qmat, qmatj, qmati (input,output) 
	
		asymptotic constraint matrix in CSR format.
		allocate as:
			double *qmat[qmax]
			int *qmatj[qmax]
			int *qmati[hrows*(nleads+nlags+1)+1]
		where nleads == max number of leads, nlags = max number of lags

	essential (output)  
		
		a non-negative int indicating the number of elements in rootr and rooti.

	rootr (output) 
	
		real part of transition matrix eigenvalues
		allocate as:
			double *rootr[qcols]
		where qcols == neq*(nlags+nleads)

	rooti (output) 
	
		imaginary part of transition matrix eigenvalues
		allocate as:
			double *rooti[qcols]
		where qcols == neq*(nlags+nleads)

	returnCode (output)

		ASYMPTOTIC_LINEAR_CONSTRAINTS_AVAILABLE 0
		STACKED_SYSTEM_NOT_FULL_RANK 2000
		sparseAim_PRECONDITIONS_VIOLATED 2001
		autoRegression_POSTCONDITIONS_VIOLATED 2002
		augmentQmatWithInvariantSpaceVectors_PRECONDITIONS_VIOLATED 2003
		augmentQmatWithInvariantSpaceVectors_POSTCONDITIONS_VIOLATED 2004
		shiftRightAndRecord_PRECONDITIONS_VIOLATED 2005
		annihilateRows_POSTCONDITIONS_VIOLATED 2006
		HELEMS_TOO_SMALL 2007
		AMAT_TOO_LARGE 2008

	aPointerToVoid (input,output) 
	
		not used in the default implementation.


	'global' variables

		double ZERO_TOLERANCE
		double ZERO_TOL1
		int USEARPACK
		int TESTBLANCHARDKAHN

	must all be declared and set in the calling program.  



---------------------------------------------------------------------------------- */

void sparseAim (

	int *maxNumberOfHElements,
    int discreteTime,
    int hrows,int hcols,
    int leads,
    double * hmat,int * hmatj,int * hmati,
    double * newHmat,int * newHmatj,int * newHmati,
    int *  auxiliaryInitialConditions, 
    int *  rowsInQ,
    double * qmat,int * qmatj,int * qmati,
    int * essential,
    double * rootr,double * rooti,
    int *returnCode, void * aPointerToVoid
             
)
{
	static int maxHElementsEncountered=0;
	int originalMaxHElements;
	double * annihilator;int * annihilatorj;int * annihilatori;
	double * rmat;int * rmatj;int * rmati;
	int * prow;int * pcol;
	int constraintsNeeded;
	int i;
	double time0 ;

	/* Check Inputs*/
	//cPrintSparse(hrows,hmat,hmatj,hmati);

	/* save maxspace parameter -- original will be overwritten by actual */
	originalMaxHElements=*maxNumberOfHElements;

	/* rwt                                                     */
	/*totcpusec = oldcpusec = 0 is initialized in main program */
	tmpcpusec = alloc_sec = assert_sec = qr_sec = 0.0 ; /* rwt */
	alloc_count = assert_count = qr_count = 0 ;	 /* rwt */
	time_rightMostAllZeroQ = 0 ; /* rwt */
	count_rightMostAllZeroQ = 0 ; /* rwt */
	time_autoregression = time_augmentQ = 0 ;

	sparseAimAssert(*maxNumberOfHElements > 0, sparseAimPreMaxNumberOfHElementsLEZero);
    sparseAimAssert(hrows > 0, sparseAimPreHrows);
    sparseAimAssert((hcols > 0)&&(hcols>=hrows)&&((hcols%hrows) == 0), sparseAimPreHcolsHrows);
    sparseAimAssert(leads > 0, sparseAimPreLeads);
 	sparseAimAssert(validCSRMatrix(hrows,hmat,hmatj,hmati), sparseAimPreHmat);
	sparseAimAssert(hmati[hrows]-hmati[0]<=*maxNumberOfHElements, sparseAimPreHmatTotElems);
    sparseAimAssert(*auxiliaryInitialConditions >= 0, sparseAimPreAuxRows);
    sparseAimAssert(*rowsInQ>=*auxiliaryInitialConditions,sparseAimPreRowsInQ);
	sparseAimAssert(*rowsInQ==0||validCSRMatrix(*rowsInQ,qmat,qmatj,qmati),sparseAimPreQmat);
	if (*returnCode) return ;

	annihilator=(double *) calloc((unsigned)RBLOCKSIZE,sizeof(double));
	annihilatorj=(int *) calloc((unsigned)RBLOCKSIZE,sizeof(int));
	annihilatori=(int *) calloc((unsigned)hrows+1,sizeof(int));
	rmat=(double *)calloc((unsigned)RBLOCKSIZE,sizeof(double));
	rmatj=(int *)calloc((unsigned)RBLOCKSIZE,sizeof(int));
	rmati=(int *)calloc((unsigned)hrows+1,sizeof(int));
	prow=(int *) calloc((unsigned)hrows,sizeof(int));
	pcol=(int *) calloc((unsigned)hrows,sizeof(int));
	/* originalMaxHElements=*maxNumberOfHElements; just did this above */
	
	for(i=0;i<=hrows;i++) {
		rmati[i]=annihilatori[i]=1;
	}

	qmati[0]=1;
	time0 = cputime() ; /* rwt */

	
	/* ----------------------------------- */
	/* 1. autoRegression                   */
	/* ----------------------------------- */

	/* -----------------------------------------------------------------------------------
	In addition to the number of auxiliary initial conditions, the call to 
	autoRegression() returns several sparse matrices:

		newHmat, newHmatj, newHmati
			The transformed structural coefficients matrix. 
			The algorithm constructs a matrix with a non-singular right-hand block.

		annihilator, annihilatorj, annihilatori 
			The Q matrix in the final rank determining QR-Decomposition.

		rmat, rmatj, rmati 
				The R matrix in the final rank determining QR-Decomposition.

	The routine also returns the row and column permutations used in the QR-Decomposition
	(prow and pcol).  Subsequent routines use the QR-Decomposition matrix to avoid
	computing the inverse of the right-hand block of the transformed structural
	coefficients matrix.
	------------------------------------------------------------------------------------- */

	*returnCode=0;
	*auxiliaryInitialConditions=autoRegression(
                  
		maxNumberOfHElements,returnCode,
        hrows,hcols,
        hmat,hmatj,hmati,
        qmat,qmatj,qmati,
        newHmat,newHmatj,newHmati,
        annihilator,annihilatorj,annihilatori,
        rmat,rmatj,rmati,
        prow,pcol,aPointerToVoid

	);
	if (*returnCode) return ;

	/* record max space actually used and reset limit to original value */
	bumpSparseAim(*maxNumberOfHElements);
	*maxNumberOfHElements=originalMaxHElements;

	time_autoregression = cputime() - time0 ; /* rwt */



	/* --------------------------------------- */
	/* 2. augmentQmatWithInvariantSpaceVectors */
	/* --------------------------------------- */

	/* -----------------------------------------------------------------------------------
	In addition to returning the number of rows in the asymptotic constraint matrix, 
	the call to augmentQmatWithInvariantSpaceVectors returns several matrices:

		qmat, qmatj, qmati 	matrix of asymptotic constraints in CSR format
		amat				transition matrix in dense format
		rootr				real part of the eignvalues
		rooti				imaginary part of the eignvalues
		js					a vector indicating which columns of the original structural
							coefficients matrix correspond to the columns of the transition matrix.
		essential			dimension of the transition matrix
   -------------------------------------------------------------------------------------- */

	constraintsNeeded=leads*hrows;
	time0 = cputime() ; /* rwt */
	*rowsInQ=augmentQmatWithInvariantSpaceVectors(
      
		maxNumberOfHElements,returnCode,discreteTime,
      	hrows,hcols,
      	hmat,hmatj,hmati,
      	annihilator,annihilatorj,annihilatori,
      	rmat,rmatj,rmati,
      	prow,pcol,
      	*auxiliaryInitialConditions,
      	constraintsNeeded,
      	qmat,qmatj,qmati,
      	essential,
      	rootr,rooti,aPointerToVoid
      
	);
	if (*returnCode) return ;

	/* record max space actually used and reset limit to original value */
	bumpSparseAim(*maxNumberOfHElements);
	*maxNumberOfHElements=originalMaxHElements;

	time_augmentQ = cputime() - time0 ; /* rwt */


	/* save max space used where user can find it */
 	*maxNumberOfHElements = maxHElementsEncountered;

	free(annihilator);
	free(annihilatorj);
	free(annihilatori);
	free(rmat);
	free(rmatj);
	free(rmati);
	free(prow);
	free(pcol);

		
}	/* sparseAim */ 


/* --------------------------------------------------------------- */
/* !autoRegression                                                 */
/* rwt allocate space for rightMostAllZeroQ                        */
/* rwt add profiling                                               */
/* --------------------------------------------------------------- */

/* -------------------------------------------------------------------------

	First stage of computation of unconstrained autoregression X(t) = A X(t-1).
	Transforms matrix of structural coefficients (H) so that right-most block
	(H-theta) is non-singular.  This is done by shifting zero rows of H-theta
	right and storing them in Q as auxiliary initial conditions.  A QR decomposition
	is performed on H-theta, which is premultiplied by the q matrix to generate
	additional zero rows, which are then shifted as well.  This process continues 
	until H-theta becomes non-singular.
		
	Arguments

		*maxNumberOfHElements 			on input, number of elements to allocate for hmat storage
		returnCode 						on output, number of elements to allocate for qmat storage
		
		hrows, hcols					rows and columns in H matrix
		hmat, hmatj, hmati 				structural coefficients matrix in CSR format
		qmat, qmatj, qmati 				asymptotic constraint matrix in CSR format.
		
		newHmat, newHmatj, newHmati 	transformed structural coefficients matrix in CSR format
		annihilator, annihilatorj, 		q matrix from final QR decomposition of H-theta
			annihilatori		
		rmat, rmatj,  rmati				r matrix from final QR decomposition of H-theta
		prow (output) 					permution of rows in H-theta (?)
		pcol (output) 					column pivots from final QR decomposition of H-theta
		aPointToVoid					not used		

------------------------------------------------------------------------- */

static int autoRegression(
	int *maxNumberOfHElements,
    int *returnCode,
    int hrows,int hcols,
    double * hmat,int * hmatj,int * hmati,
    double * qmat,int * qmatj,int * qmati,
    double * newHmat,int * newHmatj,int * newHmati,
    double * annihilator,int * annihilatorj,int * annihilatori,
    double * rmat,int * rmatj,int * rmati,
    int * prow,int * pcol,
    void * aPointerToVoid
)
{
	double time0, time_annihilateRows, time_shiftRightAndRecord ; /* rwt */
	int count_ARloop ; /* rwt */
	int originalMaxHElements;
	int aOne;int swapped;int i;static int maxHElementsEncountered=0;
	int len;int ierr;double ztol;int job;
	int rowsInQ,rnk;
	int * tmpHmati;int * tmpHmatj;
	double * tmpHmat;
  	int * chkJs;
	int valid;

	/* save original maxspace parameter */	
	originalMaxHElements=*maxNumberOfHElements;

	time_shiftRightAndRecord = 0 ;  /* rwt */
	time_annihilateRows = 0 ;  		/* rwt */
	count_ARloop = 0 ; 				/* rwt */

	/* init ... */
	aOne=1;swapped=0;rowsInQ=0;rnk=0;

	/* initialize permuatation vectors */
	for (i=0;i<hrows;i++)
		prow[i]=i;
	for (i=0;i<hrows;i++)
	    pcol[i]=i;

	/* rwt init profile vars */
	time_rightMostAllZeroQ = 0 ;		/* accumulated in rightMostAllZeroQ */
	count_rightMostAllZeroQ = 0 ;		/* accumulated in rightMostAllZeroQ */
	time_rmazq_alloc = 0 ;	   			/* accumulated in rightMostAllZeroQ */
	time_constructQRDecomposition = 0;	/* accumulated in annihilateRows */
	time_sparseMult = 0 ;				/* accumulated in annihilateRows */




	/* while rightmost block of H is singular ... */
	while (rnk != hrows) {


		count_ARloop ++ ;  /* rwt */

		/* clean up near-zeros */
		ztol=ZERO_TOLERANCE;ztol=1.0e-8;job=3;len=HMATSIZE;ierr=0; 
		dropSmallElements(&hrows,&job,&ztol,&len,hmat,hmatj,hmati,hmat,hmatj,hmati,&ierr);


		/* shift zero rows of rightmost block of H to the right and copy into Q as auxiliary initial conditions */
		time0 = cputime() ; /* rwt */
		rowsInQ=shiftRightAndRecord(maxNumberOfHElements,returnCode,hrows,rowsInQ,
			qmat,qmatj,qmati,hrows,hcols,hmat,hmatj,hmati,aPointerToVoid
		);

		if (*returnCode) return (-1) ;
		time_shiftRightAndRecord += cputime() - time0 ; /* rwt */

		/* record space used and reset */
		bumpSparseAim(*maxNumberOfHElements);
		*maxNumberOfHElements=originalMaxHElements;
		
		/* Perform QR decomposition on rightmost block of H, and premultiply H by left singular vectors.
		(This creates additional zero rows if H-theta is singular.  Recompute rank of H-theta */
		time0 = cputime() ; /* rwt */

		rnk=annihilateRows(maxNumberOfHElements,returnCode,hrows,hcols,
			hmat, hmatj, hmati,
			newHmat, newHmatj, newHmati,
			annihilator, annihilatorj, annihilatori,
			rmat, rmatj, rmati,
			prow, pcol, aPointerToVoid
		);

		if (*returnCode) return (-1) ;
		time_annihilateRows += cputime()-time0 ; /* rwt */

		/* record space used and reset */
		bumpSparseAim(*maxNumberOfHElements);
		*maxNumberOfHElements=originalMaxHElements;


		/* if still not full rank, set up to go again */
		if (rnk != hrows) {
			tmpHmat=hmat; tmpHmati=hmati; tmpHmatj=hmatj;
			hmat=newHmat; hmati=newHmati; hmatj=newHmatj;
			newHmat=tmpHmat; newHmati=tmpHmati; newHmatj=tmpHmatj;
			if (swapped) {swapped=0;} else {swapped=1;}
		}

	}


	if(swapped) {
		copyMatrix(&hrows,&aOne,hmat,hmatj,hmati,&aOne,newHmat,newHmatj,newHmati);
		bumpSparseAim((newHmati[hrows]-newHmati[0]));
	}

	sparseAimAssert(validCSRMatrix(rowsInQ,qmat,qmatj,qmati), autoRegressionPostValidQ);
	sparseAimAssert(validCSRMatrix(hrows,newHmat,newHmatj,newHmati), autoRegressionPostValidH);
	sparseAimAssert(validCSRMatrix(hrows,annihilator,annihilatorj,annihilatori), autoRegressionPostValidAnnihilator);
	sparseAimAssert(validCSRMatrix(hrows,rmat,rmatj,rmati), autoRegressionPostValidR);
	if (*returnCode) return (-1) ;

	/* 	The Js vector makes the correspondence between the columns of the */
	/* 	reduced dimension matrix and the original input matrix.           */
	/* 	The Js vector should contain 0's for excluded columns and         */
	/*  each integer from 1 to *essential for retained columns.           */

	chkJs=(int *)calloc((unsigned)hrows,sizeof(int));
	for(i=0;i<hrows;i++) chkJs[i]=0;
	for(i=0;i<hrows;i++) if(prow[i]>=0&&prow[i]<hrows) chkJs[prow[i]]+=1;
	for(i=0;i<hrows;i++) chkJs[i]=0;
	for(i=0;i<hrows;i++) if(pcol[i]>=0&&pcol[i]<hrows) chkJs[pcol[i]]+=1;
	valid=TRUE;
	for(i=0;i<hrows;i++) if(chkJs[i]!=1) valid=FALSE;
	free(chkJs);
	sparseAimAssert(valid, autoRegressionPostValidJs);
	if (*returnCode) return (-1) ;




	/* all done ... */
	*maxNumberOfHElements=maxHElementsEncountered;
	return(rowsInQ);

}	/* autoRegression */


/* --------------------------------------------------------------- */
/* !shiftRighttAndRecord                                           */
/* --------------------------------------------------------------- */

/* -----------------------------------------------------------------------------

	shift rows of H right one block at a time until no row ends in a zero block.
	for each shift, add row to Q to form auxiliary initial conditions.
	return total number of rows in Q.
	
	arguments
		
		maxNumberOfHElements 		space allocated for Q matrix
		returnCode 					used by sparseAimAssert
		dim  						number of columns in block to check for zero
		rowsInQ 					number of rows in Q matrix
		qmat, qmatj, qmati			Q matrix in CSR format
		hrows, hcols				number of rows, columns in H matrix
		hmat, hmatj, hmati			H matrix in CSR format
		aPointerToVoid				not used

----------------------------------------------------------------------------- */

static int shiftRightAndRecord (
	int *maxNumberOfHElements,
    int *returnCode,
    int dim,
    int rowsInQ,
    double * qmat,int * qmatj,int * qmati,
    int hrows,int hcols,
    double * hmat,int * hmatj,int * hmati,
    void * aPointerToVoid
)
{
	int i, j, qextent, zeroRow ;
	static int maxHElementsEncountered=0;		/* bumpSparseAim */

	/* check for zero rows in H matrix -- can't shift right if all zeros */
	/* (if row has no nonzero values, adjacent row pointers will be equal) */
	zeroRow=FALSE;
	i = 1 ;
	while (i <= hrows && !zeroRow) {
		zeroRow = (hmati[i-1]==hmati[i]) ;
		i++ ;
	}
    sparseAimAssert (zeroRow==FALSE, shiftRightAndRecordPreZeroRow);
	if (*returnCode) return (-1) ;

	/* keep track of space used in Q */
 	qextent=qmati[rowsInQ]-qmati[0];
	bumpSparseAim((qextent));

	/* loop through rows of H */
	for(i=1; i<=hrows; i++) {				

		/* while row ends in zero block, add row to Q and shift right in H */
		while (rowEndsInZeroBlock(i, dim, hmat, hmatj, hmati, hcols)) {

			/* add a row to Q */
			rowsInQ ++ ;
			qmati[rowsInQ-1]=qextent+1;

			/* loop through nonzeros in this row of H */
			for(j=hmati[i-1]; j<hmati[i]; j++){
				
				/* copy H value into Q */
				qmat[qextent]=hmat[j-1];
				qmatj[qextent]=hmatj[j-1];
				qextent++;

				/* make sure we've got enough space (tighten up vis-a-vis original) */
			   	/* sparseAimAssert((qextent <= *maxNumberOfHElements+1), qextentTooBig); */
			   	sparseAimAssert((qextent < *maxNumberOfHElements), qextentTooBig);
				if (*returnCode) return (-1) ;

				/* shift H value right one block.  (Zeros are just ignored.) */
				hmatj[j-1] += dim;

			}
		}
	}
 
	/* keep track of space used in Q */
	qmati[rowsInQ]=qextent+1;
	bumpSparseAim((qextent));
	*maxNumberOfHElements=maxHElementsEncountered;


	/* that's it */
	return(rowsInQ);

}	/* shiftRightAndRecord */


/* --------------------------------------------------------------- */
/* !annihilateRows                                                 */
/* rwt add profiling, ztol                                         */
/* --------------------------------------------------------------- */

/* ----------------------------------------------------------------------------------------
    compute QR decomposition of rightmost block of H matrix (H-theta), then premultiply H 
    by resulting q and reorder matrix by rows so that the bottom rows of the right block are 
    zeroed out.  return result in newHmat, along with QR decomposition and pivot vectors.

	arguments

		maxNumberOfHElements						max space used
	    returnCode									used in sparseAimAssert
	    hrows, hcols								rows and cols in H
	    hmat, hmatj, hmati,							H matrix in CSR format
	    newHmat, newHmatj, newHmati,				transformed H matrix in CSR format
	    annihilator, annihilatorj, annihilatori,	q matrix from QR decomposition of H-theta
	    rmat, rmatj, rmati,							r matrix from QR decomposition of H-theta
	    prow										reordering of H matrix by rows (?)
	    pcol										column pivots from QR decomposition
	    aPointerToVoid								not used
----------------------------------------------------------------------------------------- */

static int annihilateRows(
	int *maxNumberOfHElements,
    int *returnCode,
    int hrows,int hcols,
    double * hmat,int * hmatj,int * hmati,
    double * newHmat,int * newHmatj,int * newHmati,
    double * annihilator,int * annihilatorj,int * annihilatori,
    double * rmat,int * rmatj,int * rmati,
    int * prow,int * pcol,
    void * aPointerToVoid
)
{
	int i,j;static int maxHElementsEncountered=0;
	double ztol;int rnk;int len;int * perm;
	double * rightBlock;int * rightBlockj;int * rightBlocki;
	double * tempHmat;int * tempHmatj;int * tempHmati;
	int job,i1,i2,j1,j2,resRows,resColumns,ierr,nzmax;
	int * iw;
	double time0 ;

	/* allocate space */
	perm		= (int *) calloc((unsigned)hrows,sizeof(int));
	rightBlock	= (double *) calloc(RBLOCKSIZE,sizeof(double));
	rightBlockj	= (int *) calloc(RBLOCKSIZE,sizeof(int));
	rightBlocki = (int *) calloc((unsigned)hrows+1,sizeof(int));
	tempHmat	= (double *) calloc(HMATSIZE,sizeof(double));
	tempHmatj	= (int *) calloc(HMATSIZE,sizeof(int));
	tempHmati	= (int *) calloc((unsigned)hrows+1,sizeof(int));
	iw			= (int *) calloc((unsigned)HMATSIZE,sizeof(int));


	/* copy rightmost block of H to rightBlock */
	job=1; i1=1; i2=hrows;
	ztol=ZERO_TOLERANCE ;
	j1=hcols-hrows+1; j2=hcols;

	extractSubmatrix (
		&hrows, &job, &i1, &i2, &j1, &j2, hmat, hmatj, hmati,
		&resRows, &resColumns, rightBlock, rightBlockj, rightBlocki
	);

	/* QR decomposition of rightmost block of H.  results returned in annihilator (q), 
	rmat (r), and prow and pcol  */
	time0 = cputime() ; /* rwt */

	rnk=constructQRDecomposition(
		(int)RBLOCKSIZE, hrows, hrows, rightBlock, rightBlockj, rightBlocki,
		annihilator, annihilatorj, annihilatori,
		rmat, rmatj, rmati,
		prow, pcol, aPointerToVoid
	);
	time_constructQRDecomposition += cputime() - time0 ; /* rwt */

	/* zero means zero ... */
	ztol=ZERO_TOLERANCE; job=1; len=HMATSIZE; ierr=0;

	dropSmallElements (
		&hrows, &job, &ztol, &len,
		annihilator, annihilatorj, annihilatori,
		annihilator, annihilatorj, annihilatori, &ierr
	);


	/* calculate ordering of new H by rows depending on rank (?).  nb first row number zero not one */
	for(i=0;i<hrows;i++) {
		if(i>=rnk) {
			perm[prow[i]]=i-rnk+1;
		} else {
			perm[prow[i]]=i+hrows-rnk+1;
		}
	}

	/* premultiply H by q from QR decomposition to create zero rows, results in newHmat */
	time0 = cputime() ; /* rwt */
	nzmax=HMATSIZE;

	sparseMult (
		&hrows, &hcols, &nzmax, iw, &job,
		annihilator, annihilatorj, annihilatori,
		hmat, hmatj, hmati,
		newHmat, newHmatj, newHmati, &ierr
	);
	time_sparseMult += cputime()-time0 ; /* rwt */
	sparseAimAssert(ierr==0, nzmaxTooSmallAnnihilateRows);
	if (*returnCode) return (-1) ;
	bumpSparseAim((newHmati[hrows]-newHmati[0]));

	/* reorder rows of new Hmat using permutation calculated above, store in tempHmat */

	permuteRows(&hrows,newHmat,newHmatj,newHmati,tempHmat,tempHmatj,tempHmati,perm,&job);
	bumpSparseAim((tempHmati[hrows]-tempHmati[0]));

     
	/* zero out numerically small elements in right block of tempHmat */
	for(i=0;i<hrows-rnk;i++) {
		for(j=tempHmati[i];j<tempHmati[i+1];j++) {
			if(((tempHmatj[j-1]>hcols-hrows)))
				tempHmat[j-1]=0.0;
		}
	}

	/* and save new H matrix for next time */
	len=HMATSIZE;
	dropSmallElements(&hrows,&job,&ztol,&len,tempHmat,tempHmatj,tempHmati,newHmat,newHmatj,newHmati,&ierr);

	free(perm);
	free(iw);
	free(tempHmat);
	free(tempHmatj);
	free(tempHmati);
	free(rightBlock);
	free(rightBlockj);
	free(rightBlocki);

	sparseAimAssert(validCSRMatrix(hrows,hmat,hmatj,hmati), annihilateRowsPostValidH);
	if (*returnCode) return (-1) ;

	*maxNumberOfHElements=maxHElementsEncountered;

	return(rnk);

}	/* annihilateRows */


/* --------------------------------------------------------------- */
/* !constructQRDecomposition                                       */
/* rwt add profiling                                               */
/* --------------------------------------------------------------- */

/* -------------------------------------------------------------------------
	QR decomposition of matrix A.  return results as q and r, plus 
	permutation vectors prow and pcol.  calls LAPACK routines dgeqpf
	and dorqpr, which operate on dense matrices.

	arguments

		matSize 		max number of elements in A
		a, ja, ia		source matrix A in CSR format
		q, jq, iq		target matrix q in CSR format
		r, jr, ir		target matrix r in CSR format
		prow, pcol		row and column pivots (only column pivots used here)
		aPointerToVoid	not used		

--------------------------------------------------------------------------- */

static int constructQRDecomposition (
	int matSize, int nr, int nc,
	double * a, int * ja, int * ia,
    double * q, int * jq, int * iq,
    double * r, int * jr, int * ir,
    int * prow, int * pcol, 
    void * aPointerToVoid
)
{
	int info;
	int lwork;
	int nzmax;
	int i;
	int * jpvt;
	double * denseA;
	double * tau; 
	double * work;
	int rank;
	int norm;
	double * diag;
	double time0 ;

	denseA = (double *) calloc((unsigned)nr*nc,sizeof(double));
	tau= (double *) calloc((unsigned)nr,sizeof(double));
	jpvt= (int *) calloc((unsigned)nr,sizeof(int));
	diag= (double *) calloc((unsigned)nr,sizeof(double));
	lwork = 3*nr;
	work = (double *) calloc((unsigned)lwork,sizeof(double));
	rank=0;
	
	nzmax=matSize;



	/* convert source matrix to dense for LAPACK routines, init pivot vectors */
	csrToDns(&nr,&nr,a,ja,ia,denseA,&nr,&info);
	for(i=0;i<nr;i++) {pcol[i]=0;}
	for(i=0;i<nr;i++) {prow[i]=i;}


	/* dgeqpf computes QR factorization with column pivoting of denseA */
	/* rwt profile QR decomposition */
	time0 = cputime() ; /* rwt */
	dgeqpf_(&nr,&nc,denseA,&nr,pcol,tau,work,&info);

	qr_sec += cputime()-time0 ; /* rwt */

	/* upper triangle of denseA has r of qr decomposition, convert to CSR */
	dnsToCsr(&nr,&nr,&nzmax,denseA,&nr,r,jr,ir,&info);


	getUpperTriangular(&nr,r,jr,ir,r,jr,ir);

	/* lower triangle and tau have info for constructing q */
	time0 = cputime() ; /* rwt */

	dorgqr_(&nr,&nc,&nr,denseA,&nr,tau,work,&lwork,&info);
	/*	printf("dorgqr returned %d \n",info);*/

	qr_sec += cputime()-time0 ; /* rwt */
	qr_count ++ ;  /* rwt */

	/* convert q to CSR and transpose (use denseA for workspace) */
	dnsToCsr(&nr,&nr,&nzmax,denseA,&nr,q,jq,iq,&info);


	inPlaceTranspose(&nr,&nr,q,jq,iq,denseA,&info);


	for(i=0;i<nr;i++) {pcol[i]--;}

	/* find rank of r matrix */ 
	norm=0;
	normsByRow(&nr, &norm, r, jr, ir, diag);
	rank=0;
	for(i=0;i<nr;i++) {
		if(diag[i]/diag[0] > ZERO_TOLERANCE) 
			rank++;
	}

	/* and we're done */
	free(denseA);
	free(tau);
	free(jpvt);
	free(diag);
	free(work);
	

	return(rank);

}	/* constructQRDecomposition */


/* --------------------------------------------------------------- */
/* !augmentQmatWithInvariantSpaceVectors                           */
/* rwt add profiling                                               */
/* --------------------------------------------------------------- */

/* -----------------------------------------------------------------------------------
	this documentation is based on the old faim program ...

    premultiplies h by the negative inverse of htheta.  The left
    part of h (all but htheta, the rightmost block) will be referred to
    now as gamma.  A vector js is made to contain zeros for each zero
    column of gamma.  Nonzero entries in js (corresponding to nonzero
    columns in gamma) are numbered (1,2,...,nroot) -- nroot is the number of
    nonzero columns in gamma.  gcols is the total number of columns in
    gamma.

    if there are any nonzero columns in gamma, constructs a matrix
    A, which is a squeezed down version of a state transition matrix Q.
    (A is the rows and columns of Q corresponding to nonzero entries in js.)

    computes vectors spanning the left invariant subspace of A and stores them
    in w.  The eigenvalues are stored in roots.

    writes any of these vectors associated with roots outside
    the unit circle into q. 

	arguments

		maxNumberOfHElements						max size for alloc matrices
		returnCode									return code
		discreteTime								discrete (0) or continuous (1)
		hrows, hcols								rows and columns of H matrix
		hmat, hmatj, hmati							H matrix in CSR format
		annihilator, annihilatorj, annihilatori		final q matrix from QR decomposition 
		rmat, rmatj, rmati							final r matrix from QR decomposition
		prow, pcol									permutations of rows and columns
		auxiliaryInitialConditions					number of aux init conditions
		constraintsNeeded							number of constraints
		qmat, qmatj,qmati							Q matrix in CSR format
		essential									dimension of transition matrix
		rootr, rooti								vectors of roots, real and imaginary
		aPointerToVoid								not used

------------------------------------------------------------------------------------ */

static int augmentQmatWithInvariantSpaceVectors (

	int *maxNumberOfHElements,
	int *returnCode,
	int discreteTime,
	int hrows,int hcols,
	double * hmat,int * hmatj,int * hmati,
	double * annihilator,int * annihilatorj,int * annihilatori,
	double * rmat,int * rmatj,int * rmati,
	int * prow,int * pcol,
	int auxiliaryInitialConditions,
	int constraintsNeeded,
	double * qmat,int * qmatj,int * qmati,
	int * essential,
	double * rootr,double * rooti,void * aPointerToVoid
)
{
	static int maxHElementsEncountered=0;
	int originalMaxHElements;
	int nzmax;
	double rconde;double rcondv;
	char jobvs,sort,sense;
	int sdim,*bwork;
	int liwork;int * anotheriwork;
	double * damat;
	int * js;
	int qextent;int delQextent;int j;
	double * beyondQmat;
	double * a;int * ia;int * ja;
	double * ta;int * tia;int * tja;
	int * wcols;
	int len;int ierr;double ztol;int job;
	int rowsInQ;
	int i;
	int nroot, maxroots;
	double * work;
	int lwork;int info;int spacedim;int rc;
	unsigned int ONE=1 ;

	double time0, time_useArpack, time_dgees, time_constructA ;

	int nxt,valid;
	originalMaxHElements=*maxNumberOfHElements;
	time_useArpack = 0 ;
	time_dgees = 0 ;
	time_constructA = 0 ;
	*returnCode = 0 ;

	sparseAimAssert(constraintsNeeded>0, augmentQmatWithInvariantSpaceVectorsPreConstraints);
    sparseAimAssert(auxiliaryInitialConditions>=0, augmentQmatWithInvariantSpaceVectorsPreAuxiliary);
	if (*returnCode) return (-1) ;

    wcols = (int *) calloc((unsigned)hcols-hrows,sizeof(int));
	rowsInQ=auxiliaryInitialConditions;
	qextent=qmati[auxiliaryInitialConditions]-qmati[0];
	bumpSparseAim((qextent));
	js=(int *)calloc((unsigned)(hcols-hrows),sizeof(int));
	
	originalMaxHElements=*maxNumberOfHElements;


	/* obtain dimension of transition matrix */
	*essential=identifyEssential(hrows, hcols, hmat, hmatj, hmati, js, aPointerToVoid) ;
	bumpSparseAim((*essential));
	*maxNumberOfHElements=originalMaxHElements;
	damat=(double *)calloc((unsigned)*essential * *essential,sizeof(double));
	nxt=1;
	valid=TRUE;
	for(i=0;(valid &&i<(hcols-hrows));i++) {
		if(js[i] !=0) { 
	    	if(js[i] != nxt)valid=FALSE;nxt=nxt+1;
		}
	}
	sparseAimAssert(valid==TRUE, augmentQmatWithInvariantSpaceVectorsPostValidJs);
	if (*returnCode) return (-1) ;


	/* construct state space transition matrix A -- output is dense matrix damat */
	time0 = cputime() ; 
	constructA(maxNumberOfHElements,returnCode,hrows,hcols,*essential,js,
		hmat,hmatj,hmati,
		annihilator,annihilatorj,annihilatori,
		rmat,rmatj,rmati,
		prow,pcol,
		damat, 
		aPointerToVoid
	);
	if (*returnCode) return (-1) ;
	time_constructA += cputime() - time0 ; 
	bumpSparseAim(*maxNumberOfHElements);
	sparseAimAssert(validVector(*essential* *essential,damat), augmentQmatWithInvariantSpaceVectorsPostADim);
	if (*returnCode) return (-1) ;


	/* obtain eigenvectors and roots ... */
	if (*essential>0) {

		bumpSparseAim(*maxNumberOfHElements);
		*maxNumberOfHElements=originalMaxHElements;


		/* !!! nroot is the dimension of the eigenproblem (not spacedim)  	  */
		/* !!! spacedim is the number of eigenvalues to calculate (not nroot) */

   		info=0;
		nroot=*essential;											/* dimension of eigenproblem */
		spacedim=constraintsNeeded-auxiliaryInitialConditions;		/* number of eigenvalues to be calculated */
		/* GSA:  debug, too big by far only need for schur computation test */
		lwork = 1+nroot*(1+2*nroot);

		/* GSA:  fix it, need to call with itdim nev and ncv so that really going to use arpack */

		beyondQmat = (double *) calloc((unsigned)nroot*nroot,sizeof(double));
		bwork = (int*)calloc((unsigned)nroot,sizeof(int));
		work = (double *) calloc((unsigned)(lwork ), sizeof(double));
		a = (double *) calloc((unsigned)*maxNumberOfHElements,sizeof(double));
		ja = (int *) calloc((unsigned)*maxNumberOfHElements,sizeof(int));
		ia = (int *) calloc((unsigned)nroot+1,sizeof(int));
		ta = (double *) calloc((unsigned)*maxNumberOfHElements,sizeof(double));
		tja = (int *) calloc((unsigned)*maxNumberOfHElements,sizeof(int));
		tia = (int *) calloc((unsigned)nroot+1,sizeof(int));
		liwork = nroot*nroot;
		anotheriwork = (int *) calloc((unsigned) (liwork),sizeof(int));

		rowsInQ=auxiliaryInitialConditions;
		qextent=qmati[rowsInQ]-qmati[0];
		bumpSparseAim((qextent+1));
		nzmax= *maxNumberOfHElements-qextent;
		sdim=spacedim;

		/* calculate eigenvectors and eigenvalues.  if dimension of eigenproblem exceeds the number 
		of eigenvalues to be calculated (nroot>spacedim), we can use arpack, else use dgees */

		
		/* dimension must exceed number of roots by 2 to use arpack */
		/* allow one room for one more root to check B-K conditions in useArpack */ 
		/* Note:  nroot == dimension of eigenproblem, spacedim == number of large roots! */
		/* TESTBLANCHARDKAHN and USEARPACK must be set in the calling program */
		if (USEARPACK) {
			if (TESTBLANCHARDKAHN)
				maxroots = spacedim+2+1 ;
			else
				maxroots = spacedim+2 ;
		   	if (nroot<=maxroots) {
			  //				printf ("unable to use ARPACK, switching to DGEESX\n") ;
				USEARPACK=0 ;
			}
		}

		/* compute eigenvectors, eigenvalues using Arpack (sparse, computes selected eigenvectors */
		if (USEARPACK) {

		  //			printf("using ARPACK\n");

			/* convert damat to sparse for useArpack */
			dnsToCsr(&nroot,&nroot,maxNumberOfHElements,damat,&nroot,a,ja,ia,&ierr);

			/* call useArpack to compute eigenvectors and values -- store in beyondQmat, rootr, rooti */
			time0 = cputime() ; 
			rc = useArpack (
				maxNumberOfHElements, spacedim, nroot, a, ja, ia, beyondQmat, rootr, rooti, &sdim
			);
			sparseAimAssert (rc==0, errorReturnFromUseArpack) ;
			if (*returnCode) return (-1) ;
			time_useArpack += cputime() - time0 ;

			/* convert eigenvectors to CSR sparse, store in space for 'a' matrix */
			dnsToCsr(&nroot,&spacedim,&nzmax,beyondQmat,&nroot,a,ja,ia,&ierr);
			bumpSparseAim(qextent+(*essential * spacedim));

			/* zero small elements in eigenvectors in 'a' */
			job=1;ztol=ZERO_TOLERANCE;len=*maxNumberOfHElements;
			dropSmallElements(&nroot,&job,&ztol,&len,a,ja,ia,a,ja,ia,&ierr);

			/* transpose eigenvectors (not in place).  matrix won't be square, because we are only 
			computing a subset of eigenvectors, so use csrToCscRectangular */
			csrToCscRectangular(&nroot,&nroot,&job,&job,a,ja,ia,ta,tja,tia);

		/* compute eigenvectors, eigenvalues using dgeesx (nonsparse, computes all eigenvectors) */
		} else {

			/* compute eigenvectors and values, output stored in beyondQmat, rootr, rooti */
		  //			printf("using dgees\n");
			time0 = cputime() ; 
			jobvs='V';sort='S';sense='B';
			if (discreteTime!=0){
/* Fortran calls from C in Win32 require extra args for string length */
/* nb strings are single chars, so take address when calling */
/*#ifdef WIN32
			   	dgeesx_(
			        &jobvs,ONE,&sort,ONE,discreteSelect,&sense,ONE,&nroot,damat,&nroot,
			        &sdim,rootr,rooti,
			        beyondQmat,&nroot,&rconde,&rcondv,
			        work,&lwork,anotheriwork,&liwork,bwork,
			        &info
				);
#else */
			   	dgeesx_(
			        &jobvs,&sort,discreteSelect,&sense,&nroot,damat,&nroot,
			        &sdim,rootr,rooti,
			        beyondQmat,&nroot,&rconde,&rcondv,
			        work,&lwork,anotheriwork,&liwork,bwork,
			        &info
				);
// #endif
			} else {
/* Fortran calls from C in Win32 require extra args for string length */
/* nb strings are single chars, so take address when calling */
/*#ifdef WIN32
		   		dgeesx_(
			        &jobvs,ONE,&sort,ONE,continuousSelect,&sense,ONE,&nroot,damat,&nroot,
			        &sdim,rootr,rooti,
			        beyondQmat,&nroot,&rconde,&rcondv,
			        work,&lwork,anotheriwork,&liwork,bwork,
			        &info);
#else */
		   		dgeesx_(
			        &jobvs,&sort,continuousSelect,&sense,&nroot,damat,&nroot,
			        &sdim,rootr,rooti,
			        beyondQmat,&nroot,&rconde,&rcondv,
			        work,&lwork,anotheriwork,&liwork,bwork,
			        &info);
// #endif
			}
			//			printf("done dgees: info = %d, sdim= %d, nroot = %d\n",info,sdim,nroot);
			//			printf("done dgees: rconde = %e, rcondv= %e\n",rconde,rcondv);
			time_dgees = cputime() - time0 ;

			/* convert eigenvectors to CSR format, store in space for 'a' */
			dnsToCsr(&nroot,&nroot,&nzmax,beyondQmat,&nroot,a,ja,ia,&ierr);
			bumpSparseAim(qextent+(*essential* *essential));

			/* drop small elements from eigenvectors */
			job=1;ztol=ZERO_TOLERANCE;len=*maxNumberOfHElements;
			dropSmallElements(&nroot,&job,&ztol,&len,a,ja,ia,a,ja,ia,&ierr);

			/* transpose matrix of eigenvectors -- square, so use csrToCsc; store in 'ta' */
			csrToCsc(&nroot,&job,&job,a,ja,ia,ta,tja,tia);

		} /* USEARPACK */


		/* append matrix of eigenvectors to bottom of Q */
		qextent=qextent+1;
		copyMatrix(&sdim,&job,ta,tja,tia,&qextent,qmat,qmatj,qmati+rowsInQ); 


		/* reorder columns of block of eigenvectors we just added to Q */
		/* (to match earlier reordering of cols of H ???) */
		delQextent=qmati[rowsInQ+sdim]-qmati[rowsInQ];	/* number of nonzeros added to Q */					
		j=0;
		for(i=0;i<hcols-hrows;i++) {				  /* loop through extra cols in H */
			if (js[i]) {							  /* if i+1'th col of H is nonzero */
				wcols[j]=i+1;						  /* add col number to vector wcols */
				j++;				
			}
		}		
		for(j=0;j<delQextent;j++){					  /* loop through values added to Q */
			qmatj[qextent+j-1]=wcols[qmatj[qextent+j-1]-1];	 /* and reset column index */
		}
		bumpSparseAim(qextent);
	    sparseAimAssert(qextent  <= *maxNumberOfHElements, qextentTooBig);
		if (*returnCode) return (-1) ;

		/* reset rowsInQ; drop small elements one more time */
		rowsInQ=rowsInQ+sdim;
		job=1;ztol=ZERO_TOLERANCE;len=HMATSIZE;
		dropSmallElements(&rowsInQ,&job,&ztol,&len,qmat,qmatj,qmati,qmat,qmatj,qmati,&ierr);

		free(beyondQmat);free(anotheriwork);
		free(bwork);
		free(work);
		free(a);free(ia);free(ja);
		free(ta);free(tia);free(tja);

	} /* *essential > 0 */


	/* that's it ... */
	free(damat);
	free(js);
	free(wcols);

	/* check Blanchard-Kahn conditions. spacedim is desired number of large roots, sdim the actual */
	if (TESTBLANCHARDKAHN) {
		/* note double negative -- sparseAimAssert will negate expression we want to be true */
		sparseAimAssert (!(sdim<spacedim), tooFewLargeRoots) ;
		sparseAimAssert (!(sdim>spacedim), tooManyLargeRoots) ;
	}

	sparseAimAssert(validCSRMatrix(rowsInQ,qmat,qmatj,qmati), augmentQmatWithInvariantSpaceVectorsPostValidQ);
	sparseAimAssert(validVector(*essential,rootr), augmentQmatWithInvariantSpaceVectorsPostValidRealRoot);
	sparseAimAssert(validVector(*essential,rooti), augmentQmatWithInvariantSpaceVectorsPostValidImagRoot);
	sparseAimAssert(*essential>=0, augmentQmatWithInvariantSpaceVectorsPostADim);
	/* if error here, just set in *returnCode -- return rowsInQ as usual */
	/* if (*returnCode) return (-1) ; */



	*maxNumberOfHElements=maxHElementsEncountered;
	return(rowsInQ);

}	/* augmentQmatWithInvariantSpaceVectors */


/* --------------------------------------------------------------- */
/* !identifyEssential                                              */
/* --------------------------------------------------------------- */
/* ------------------------------------------------------------------
	compute dimension of transition matrix.  Loosely speaking, that's
	the number of nonzero columns in H ...
	
	arguments
	
		neq						number of rows in H matrix
		hcols					number of cols in H
		hmat, hmatj, hmati		H matrix in CSR format
		js						vector masking nonzero columns in H
		aPointerToVoid			not used  
	
------------------------------------------------------------------ */
static int identifyEssential(
	int neq,
	int hcols,
    double *hmat, int *hmatj, int *hmati,
    int * js,
	void *aPointerToVoid                         
)
{
   	int i, j, ia, norm;
   	double * diag, epsi;

	/* write column norms of H (max abs values) into 'diag'  */
	diag=(double *)calloc((unsigned)hcols,sizeof(double));
	norm=0;
   	cnrms_(&neq, &norm, hmat, hmatj, hmati, diag) ;

	/* set js to indicate nonzero columns */
	epsi=ZERO_TOLERANCE;
   	for (i = 0; i < hcols-neq; ++i)
      	if (diag[i]>epsi)
         	for (j=i; j<hcols-neq; j=j+neq)
            	js[j] = 1;

	/* dimension is the number of nonzeros in js */
   	ia = 0;
   	for (i=0; i<hcols-neq; ++i)
      	if (js[i]>0)
         	js[i] = ++ia;

	free(diag);
   	return(ia);

} 	/* identifyEssential */



/* --------------------------------------------------------------- */
/* !constructA                                                     */
/* rwt add profiling                                               */
/* --------------------------------------------------------------- */

/* ------------------------------------------------------------------
	construct A == [ 0   I ]
	               [ gamma ]										   

    where gamma == [ H-theta inverse * H ]		   

	use QR decomposition from autoRegression above to avoid inverting 
	H-theta.

	arguments

		maxNumberOfHElements	   		max size parameter
		returnCode				   		ptr to global return code
		hrows, hcols			   		rows, columns in H matrix
		ia						   		?
		js						   		pointers to nonzero cols in gamma
		hmat, hmatj, hmati		   		H matrix in CSR format
		qmat, qmatj, qmati		   		Q matrix in CSR format
		rmat, rmatj, rmati		   		r matrix from QR decomposition of H-theta
		prow, pcol				   		row and column permutations of H-theta (?)
		damat					   		dense version of A ??? used in call to dgeesx
		aPointerToVoid			   		not used
------------------------------------------------------------------- */
static void constructA (

	int *maxNumberOfHElements,
	int *returnCode,
	int hrows,int hcols,int ia,int * js,
	double * hmat,int * hmatj,int * hmati,
	double * qmat,int * qmatj,int * qmati,
	double * rmat,int * rmatj,int * rmati,
	int * prow,int * pcol,
	double * damat,
	void * aPointerToVoid

)
{
	double ztol;static int maxHElementsEncountered=0;
	double val;
	int nzmax;
	int ierr;int * iw;
	int i;int job;int j;
	int * perm;int rowNow;
	int len;int ioff;int nr;int nc;int aOne;int ndns;int i1,i2,j1,j2;
	int * idiag;double * diag;
	double * xo;int * ixo;int * jxo;double * x;double * y;
	double * gmat;int * gmatj;int * gmati;
	double * tempHmat;int * tempHmatj;int * tempHmati;
	double * tempRmat;int * tempRmatj;int * tempRmati;
	double time0 ;
	int originalMaxHElements;

	originalMaxHElements=*maxNumberOfHElements;

	/* allocate space */
	perm=(int *)calloc((unsigned)hrows,sizeof(int));
	iw =(int *)calloc((unsigned)hcols,sizeof(int));
	xo=(double *)calloc((unsigned)hrows,sizeof(double));
	ixo=(int *)calloc((unsigned)hrows+1,sizeof(int));
	jxo=(int *)calloc((unsigned)hrows,sizeof(int));
	x=(double *)calloc((unsigned)hrows * ia,sizeof(double));
	y=(double *)calloc((unsigned)hrows * ia,sizeof(double));
	tempHmat=(double *)calloc(HMATSIZE,sizeof(double));
	tempHmatj=(int *)calloc(HMATSIZE,sizeof(int));
	tempHmati=(int *)calloc((unsigned)hrows+1,sizeof(int));
	tempRmat=(double *)calloc(RBLOCKSIZE,sizeof(double));
	tempRmatj=(int *)calloc(RBLOCKSIZE,sizeof(int));
	tempRmati=(int *)calloc((unsigned)hrows+1,sizeof(int));
	gmat=(double *)calloc(HMATSIZE,sizeof(double));
	gmatj=(int *)calloc(HMATSIZE,sizeof(int));
	gmati=(int *)calloc((unsigned)hrows+1,sizeof(int));
	diag=(double *)calloc((unsigned)hrows,sizeof(double));
	idiag=(int *)calloc((unsigned)hrows,sizeof(int));

	*returnCode=0;


	/* construct sparse representation of squeezed a matrix */
	/* first for rows above gamma */

	/* multiply Q by H, store in tempHmat.  (is this gamma?) */
	job=1;
	nzmax=HMATSIZE;
	time0 = cputime() ; 
	time_sparseMult = 0 ;
	sparseMult (&hrows, &hcols, &nzmax, iw, &job, qmat, qmatj, qmati,
		hmat, hmatj, hmati, tempHmat, tempHmatj, tempHmati, &ierr
	);
	time_sparseMult += cputime()-time0 ;
	sparseAimAssert(ierr == 0, nzmaxTooSmallConstructA);
	if (*returnCode) return ;
	bumpSparseAim((tempHmati[hrows]-tempHmati[0]));
	ztol=ZERO_TOLERANCE;len=HMATSIZE;
	dropSmallElements(&hrows,&job,&ztol,&len,tempHmat,tempHmatj,tempHmati,tempHmat,tempHmatj,tempHmati,&ierr);


	/* permute rows of r (from QR decomposition of H) and H to form gmat=gamma? */
	/* first row number zero not one*/
	for(i=0;i<hrows;i++)
		perm[prow[i]]=i+1;
	permuteRows(&hrows,rmat,rmatj,rmati,tempRmat,tempRmatj,tempRmati,perm,&job);
	permuteRows(&hrows,tempHmat,tempHmatj,tempHmati,gmat,gmatj,gmati,perm,&job);
	for(i=0;i<hrows;i++)
		perm[pcol[i]]=i+1;
	/* this line commented out on purpose ... */
	/*permuteCols(&hrows,tempRmat,tempRmatj,tempRmati,tempRmat,tempRmatj,tempRmati,perm,&job);*/


	/* diagonal elements of permuted r matrix */
	job=0;
	ioff=0;
	getDiagonalElements (&hrows, &hcols, &job, tempRmat, tempRmatj, tempRmati, &len, diag, idiag, &ioff) ;


	/* invert diagonal elements and multiply by R and gmat to make the unit upper triangular for usol_ */
	for(i=0;i<hrows;i++)diag[i]=1/diag[i];
	job=0;
	diagMatTimesSparseMat (&hrows, &job, diag, tempRmat, tempRmatj, tempRmati, tempRmat, tempRmatj, tempRmati);
	diagMatTimesSparseMat (&hrows, &job, diag, gmat, gmatj, gmati, gmat, gmatj, gmati);


	/* extract nonzero columns of gmat for backsolving to get components of gamma */
	job=1;
	i1=1; i2=hrows; aOne=1; ndns=hrows; rowNow=0;
	time_extract = 0 ; 		/* rwt */
	time_backsolve = 0 ; 	/* rwt */
	count_constructA = 0 ; 	/* rwt */
	for(i=0; i<hcols-hrows; i++) {
		if(js[i]) {
  			j1=j2=i+1;
			count_constructA ++ ; /* rwt */
			time0 = cputime() ; /* rwt */
			extractSubmatrix(&hrows,&job,&i1,&i2,&j1,&j2,gmat,gmatj,gmati,&nr,&nc,xo,jxo,ixo);
			time_extract += cputime()-time0 ; /* rwt */
			csrToDns(&hrows,&aOne,xo,jxo,ixo,y+(rowNow*hrows),&ndns,&ierr);
			sparseAimAssert(ierr == 0, ndnsTooSmall);
			if (*returnCode) return ;

			time0 = cputime() ; 
			backSolveUnitUpperTriangular (&hrows, tempRmat, tempRmatj, tempRmati,
				x+(rowNow*hrows), y+(rowNow*hrows)
			);
			time_backsolve += cputime() - time0 ; 
			rowNow++;
		}
	}


	/* finally, build A matrix.  Build in dense form, needed by dgeesx */
	for(i=0;i<ia*ia;i++) 
		*(damat+i)=0.0;

	for(i=0;i<hcols-2*hrows;i++) {
	  	if(js[i]) {
	    	*(damat+((js[i+hrows]-1))+(js[i]-1)*ia)=1;
		}
	}

	for(i=hcols-2*hrows;i<hcols-hrows;i++) {
	  	if(js[i]) {
			for(j=0;j<hcols-hrows;j++) {
				if(js[j] ) {
					val= -1* *(x+(js[j]-1)*hrows+perm[i-(hcols-2*hrows)]-1);
					if (fabs(val) > ZERO_TOLERANCE) {
		    			*(damat+((js[i]-1)*ia)+js[j]-1)=val;
					}
				}
			}
	    }
	}

	/* all done */
	free(x);
	free(y);
	free(xo);
	free(ixo);
	free(jxo);
	free(diag);
	free(idiag);
	free(iw);
	free(perm);
	free(tempHmat);
	free(tempHmatj);
	free(tempHmati);
	free(tempRmat);
	free(tempRmatj);
	free(tempRmati);
	free(gmat);
	free(gmatj);
	free(gmati);

	*maxNumberOfHElements=maxHElementsEncountered;

}	/* constructA */


/* --------------------------------------------------------------- */
/* !useArpack                                                      */
/* rwt add profiling                                               */
/* --------------------------------------------------------------- */

/* ------------------------------------------------------------------
	wrapper function to call arpack routines to compute eigenvectors
	and eigen values for matrix A.  returns arpack error code.
	computes number of large roots if global TESTBLANCHARDKAHN=true

	arguments

		maxNumberOfHElements				max size parameter
		maxnev								number of eigenvalues to calculate
		nroot								dimension of eigenproblem
		amat, amatj, amati					A matrix in CSR format
		spanVecs							array of eigenvectors
		rootr, rooti						vectors of real and imaginary roots
		&nlarge								ptr to number of large roots
------------------------------------------------------------------------- */
static int useArpack(
	int *maxNumberOfHElements, int maxnev, int nroot,
	double * amat,int * amatj,int * amati,
	double * spanVecs,double * rootr,double * rooti,
	int *nlarge
)
{
	int ishfts=1;
	int maxitr=300;
	int model=1;
	int ido;int lworkl;int info;
	int rvec=1;
	double tol=0;
	char  bmat[1]={'I'};
	char  huhmat[1]={'A'};
	char  which[2]={'L','M'};
	int * iparam;int * ipntr;int * select;
	double * workd;double sigmar;double sigmai;
	double * ax;double * d;double * v; double * workev;double * workl;
	double * resid;int maxn;int ldv;int maxncv;
	double time0 ;
	int i, lowpos;
	double thisroot, lowroot, realpart, imagpart ;
	unsigned int ONE=1, TWO=2 ;
	int original_maxnev ;

	time_arpack = 0.0 ;				/* declared in sparseAim() */
	time_sparseMatTimesVec = 0.0 ;	/* declared in sparseAim() */

	ldv=maxn=nroot;
	ido=0;info=0;

	/* bump maxnev so we get one extra root to check B-K conditions */
	original_maxnev = maxnev ;
	if (TESTBLANCHARDKAHN) {
		maxnev += 1 ;
	}

	/* number of columns in spanvecs, or something */
	if(2* maxnev+1<maxn) {
		maxncv=2*maxnev+1;
	} else {
		maxncv=maxn-1;
	}

	/* allocate space for dnaupd */
	lworkl = 3*maxncv*maxncv+6*maxncv;
	iparam=(int *)calloc((unsigned)11,sizeof(int));
	ipntr=(int *)calloc((unsigned)14,sizeof(int));
	select=(int *)calloc((unsigned)maxncv,sizeof(int));
	ax=(double *)calloc((unsigned)maxn,sizeof(double));
	d=(double *)calloc((unsigned)maxncv*3,sizeof(double));
	resid=(double *)calloc((unsigned)maxn,sizeof(double));
	v=(double *)calloc((unsigned)ldv*maxncv,sizeof(double));
	workev=(double *)calloc((unsigned)3*maxncv,sizeof(double));
	workl=(double *)calloc((unsigned)lworkl,sizeof(double));
	workd=(double *)calloc((unsigned)3*maxn,sizeof(double));

	ishfts=1;
	maxitr=3000;
	model=1;
	iparam[0]=ishfts;iparam[2]=maxitr;iparam[6]=model;

	/* initialize dnaupd */
	tol=ZERO_TOLERANCE;
		tol=1.0e-17;
	fflush (stdout);

	time0 = cputime() ;
/* Fortran calls in Win32 require hidden args for string length */
/* strings are char arrays, so don't take addresses when calling */
/* #ifdef WIN32
	dnaupd_( &ido, bmat, ONE, &maxn, which, TWO, &maxnev, &tol, resid, &maxncv, spanVecs, &ldv,
		iparam, ipntr, workd, workl, &lworkl, &info 
	);
*/
//#else
	dnaupd_( &ido, bmat, &maxn, which, &maxnev, &tol, resid, &maxncv, spanVecs, &ldv,
		iparam, ipntr, workd, workl, &lworkl, &info 
	);

	fflush (stdout);
//#endif
	time_arpack += (cputime() - time0) ;
	if (info != 0) {
		printf ("error return from dnaupd, ierr=%d\n", info) ;
		return(-1) ;
	}
		
	/* iterate on candidate eigenvectors until convergence */
   	count_useArpack = 0 ; 
	while(ido==1||ido==(-1)){

		time0 = cputime() ; 
	    sparseMatTimesVec(&maxn,&maxn,amat,amatj,amati, workd+ipntr[0]-1, workd+ipntr[1]-1);
		time_sparseMatTimesVec += (cputime() - time0) ; 

		time0 = cputime() ;
/* Fortran calls in Win32 require hidden args for string length */
/* strings are char arrays, so don't take addresses when calling */
/* #ifdef WIN32
	    dnaupd_( &ido, bmat, ONE, &maxn, which, TWO, &maxnev, &tol, resid, &maxncv, spanVecs, &ldv,
	    	iparam, ipntr, workd, workl, &lworkl, &info 
	    );
*/
// #else
	    dnaupd_( &ido, bmat, &maxn, which, &maxnev, &tol, resid, &maxncv, spanVecs, &ldv,
	    	iparam, ipntr, workd, workl, &lworkl, &info 
	    );
// #endif
		time_arpack += (cputime() - time0) ;
		if (info != 0) {
			printf ("error return from dnaupd, ierr=%d\n", info) ;
			return(-1) ;
		}

		count_useArpack ++ ;
	}

	/* call dneupd to retrive eigenvectors and values */
	time0 = cputime() ;
/* Fortran calls in Win32 require hidden args for string length */
/* strings are char arrays, so don't take addresses when calling */
/*#ifdef WIN32
	dneupd_( &rvec, huhmat, ONE, select, rootr, rooti, spanVecs, &ldv,
	         &sigmar, &sigmai, workev, bmat, ONE, &maxn, which, TWO, &maxnev, &tol,
	         resid, &maxncv, spanVecs, &ldv, iparam, ipntr, workd, workl,
	         &lworkl, &info 
	);
#else
*/

/*		printf ("calling dneupd, tol=%e\n", tol) ;*/

	dneupd_( &rvec, huhmat, select, rootr, rooti, spanVecs, &ldv,
	         &sigmar, &sigmai, workev, bmat, &maxn, which, &maxnev, &tol,
	         resid, &maxncv, spanVecs, &ldv, iparam, ipntr, workd, workl,
	         &lworkl, &info 
	);
// #endif
	time_arpack += (cputime() - time0) ; 
	if (info != 0) {
		printf ("error return from dneupd, ierr=%d\n", info) ;
		return(-1) ;
	}

	/* compute number of large roots; find row num of smallest root (may have been added for B-K test) */  
	*nlarge = 0 ;
	lowroot = 0.0 ;

	/* loop through roots */
   	for (i=0; i<maxnev; i++) {

		/* magnitude of this root */
		realpart = rootr[i];
		imagpart = rooti[i];
       	thisroot = sqrt(realpart*realpart + imagpart*imagpart);

		/* count large roots */
		if (thisroot > 1+ZERO_TOL1) 
			*nlarge = *nlarge + 1 ;

		/* keep track of smallest root */
       	if (i == 0 || thisroot < lowroot) {
	  		lowroot = thisroot;
	  		lowpos = i;
        }

	} /* end for */

	/* if testing Blanchard-Kahn conditions, and if smallest root is not large,
	   delete row we added for test.  If smallest root is large, B-K conditions
	   fail and we want to report extra large root to user.  If smallest root is
	   not large, B-K conditions may be satisfied, and we don't want the extra 
	   row in the matrix.
	*/
#define BKFIXUP 0
	if (BKFIXUP && TESTBLANCHARDKAHN && lowroot <= 1+ZERO_TOL1) {

		printf ("useArpack:  deleting row %d\n", lowpos+1) ;
		deleteRow (lowpos+1, rootr, maxnev, 1) ;
		deleteRow (lowpos+1, rooti, maxnev, 1) ;
		deleteRow (lowpos+1, spanVecs, maxnev, nroot) ;

		/* the extra root might have been a conjugate pair, in which case dneupd would 
		have increased maxnev by one and added one more row.  Delete that one, too */
		if (maxnev-original_maxnev >= 2) {
			printf ("useArpack:  deleting conjugate row %d\n", lowpos+1) ;
			deleteRow (lowpos+1, rootr, maxnev, 1) ;
			deleteRow (lowpos+1, rooti, maxnev, 1) ;
			deleteRow (lowpos+1, spanVecs, maxnev, nroot) ;
		}


	}	/* TESTBLANCHARDKAHN */




	free(iparam);
	free(ipntr);
	free(select);
	free(ax);
	free(d);
	free(resid);
	free(v);
	free(workev);
	free(workl);
	free(workd);

	return (0) ;

} /* use Arpack */



/* --------------------------------------------------------------- */
/* !obtainSparseReducedForm                                        */
/* rwt add profiling                                               */
/* --------------------------------------------------------------- */
void obtainSparseReducedForm(

  int * maxNumberOfHElements, 
  int qrows, int qcols, double * qmat, int * qmatj, int * qmati,
  double * bmat, int * bmatj, int * bmati

)
{
	int maxHElementsEncountered=0;
	double * nsSumC;int ierr;double * x;
	int nzmaxLeft;double aSmallDouble;
	int cmatsExtent;int i;int cColumns;
	double *b;int *jb,*ib;
	double *tb;int *jtb,*itb;
	int  trans;
    double * qrmat; int * qrmatj; int * qrmati;
	int *iw;double * w;
	int  aOne; int  firstColumn;int  lastColumn;
	int  nr;int  nc;int nonZeroNow;int nzmax;
	int * jcn;
	double * cntl;
	int * icntl;
	int * ip ;
	int * np;
	int * jfirst;
	int * lenr;
	int * lastr;
	int * nextr;
	int * ifirst;
	int * lenc;
	int * lastc;
	int * nextc;
	int * info;
	double * rinfo;
	int *lfact;
	double * fact;
	int *irnf;
	int * iptrl;
	int * iptru;
	int originalMaxHElements;
	double time0 ;

	originalMaxHElements=*maxNumberOfHElements;
	time0 = cputime() ; /* rwt */

	/* allocate space for args to ma50bd, etc */
	jcn = (int *)calloc(*maxNumberOfHElements,sizeof(int));
	cntl= (double *)calloc(5,sizeof(double));
	icntl= (int *)calloc(9,sizeof(int));
	ip = (int *)calloc(qrows,sizeof(int));
	np = (int *)calloc(1,sizeof(int));
	jfirst = (int *)calloc(qrows,sizeof(int));
	lenr = (int *)calloc(qrows,sizeof(int));
	lastr = (int *)calloc(qrows,sizeof(int));
	nextr = (int *)calloc(qrows,sizeof(int));
	w = (double *)calloc(qrows,sizeof(double));
	iw = (int *)calloc(3*qrows,sizeof(int));
	ifirst = (int *)calloc(qrows,sizeof(int));
	lenc = (int *)calloc(qrows,sizeof(int));
	lastc = (int *)calloc(qrows,sizeof(int));
	nextc = (int *)calloc(qrows,sizeof(int));
	info = (int *)calloc(7,sizeof(int));
	rinfo = (double *)calloc(1,sizeof(double));


	qrmat = (double *) calloc(*maxNumberOfHElements,sizeof(double));
	qrmatj = (int *) calloc(*maxNumberOfHElements,sizeof(double));
	qrmati = (int *) calloc(qrows+1,sizeof(double));
	tb = (double *) calloc(*maxNumberOfHElements,sizeof(double));
	jtb = (int *) calloc(*maxNumberOfHElements,sizeof(double));
	itb = (int *) calloc(qcols+1,sizeof(double));
	b = (double *) calloc(*maxNumberOfHElements,sizeof(double));
	jb = (int *) calloc(*maxNumberOfHElements,sizeof(int));
	ib = (int *) calloc(qrows+1,sizeof(int));

	lfact =(int *)calloc(1,sizeof(int));
	*lfact = (  *maxNumberOfHElements);/*pessimistic setting for filling*/
	fact = (double *)calloc(*lfact,sizeof(double));
	irnf = (int *)calloc(*lfact,sizeof(int));
	iptrl = (int *)calloc(qrows,sizeof(int));
	iptru = (int *)calloc(qrows,sizeof(int));
	x = (double *)calloc(  qcols,sizeof(double));
	nsSumC = (double *)calloc(qrows ,sizeof(double));



	/*solve relation Qr xr = Ql xl and change sign later note xl are just
	elements of identity matrix so that  solving Qr xr = Ql will give us
	Bmatrix but with wrong sign*/

	/*still using CSR consequently doing everything to the transpose */
	/*note ma50ad modifies its A argument*/

	firstColumn=(qcols-qrows+1);
	lastColumn=qcols;
	aOne=1;
	extractSubmatrix (&qrows,&aOne,&aOne,&qrows,&firstColumn,&lastColumn,
		qmat,qmatj,qmati,&nr,&nc, qrmat,qrmatj,qrmati
	);

	nonZeroNow=qrmati[qrows]-qrmati[0];


	ma50id_(cntl,icntl);
	nzmax=*maxNumberOfHElements;

	ma50ad_(&qrows,&qrows,&nonZeroNow,
		&nzmax,qrmat,qrmatj,jcn,qrmati,cntl,icntl,
		ip,np,jfirst,lenr,lastr,nextr,iw,ifirst,lenc,lastc,nextc,info,rinfo
	);
	bumpSparseAim(info[3]);


	/* restore odd since ad is destructive*/
	extractSubmatrix(&qrows,&aOne,&aOne,&qrows,
		&firstColumn,&lastColumn,
		qmat,qmatj,qmati,&nr,&nc,
		qrmat,qrmatj,jcn
	);

	ma50bd_(&qrows,&qrows,&nonZeroNow,&aOne,
		qrmat,qrmatj,jcn,
		cntl,icntl,ip,qrmati,np,lfact,fact,irnf,iptrl,iptru,
		w,iw,info,rinfo
	);
	/* wordybumpSparseAim(info[3]); */
	bumpSparseAim(info[3]);


	/*expand sum of c's. use transpose since c column major order */
	trans = 1;
	itb[0]=1;cmatsExtent=0;
	cColumns=qcols-qrows;
	for(i=0;i<cColumns;i++){
	
		lastColumn = firstColumn=(1+i);

		extractSubmatrix(&qrows,&aOne,&aOne,&qrows,&firstColumn,&lastColumn,
			qmat,qmatj,qmati,&nr,&nc,b,jb,ib
		);


		csrToDns(&qrows,&aOne,b,jb,ib,nsSumC,&qrows,&ierr);
		bumpSparseAim(qrows);
		if(ierr!=0){printf("*************ran out of space****************\n");return;}

		ma50cd_(&qrows,&qrows,icntl,qrmati,np,&trans,
			lfact,fact,irnf,iptrl,iptru,
			nsSumC,x,w,info
		);
		bumpSparseAim(qrows);
		nzmaxLeft= nzmax-cmatsExtent-1;

		dnsToCsr(&aOne,&qrows,&nzmaxLeft,x,&aOne,tb+(itb[i]-1),jtb+(itb[i]-1),itb+i,&ierr);
		/*wordybumpSparseAim(info[3]);&*/
		if(ierr!=0){printf("*************ran out of space****************\n");return;}
		itb[i+1]=itb[i+1]+cmatsExtent;
		itb[i]=itb[i]+cmatsExtent;
		cmatsExtent=itb[i+1]-1;
	}

	
	bumpSparseAim(cmatsExtent);
	aSmallDouble=ZERO_TOLERANCE; 

	dropSmallElements(&cColumns,&aOne,&aSmallDouble,&nzmax,tb,jtb,itb,tb,jtb,itb,&ierr);
	bumpSparseAim(itb[cColumns]-itb[0]);
	if(ierr!=0){printf("*************ran out of space****************\n");return;}
	csrToCscRectangular(&cColumns,&qrows,&aOne,&aOne,tb,jtb,itb,bmat,bmatj,bmati);
	/*change sign*/
	for(i=0;i<bmati[qrows]-bmati[0];i++)bmat[i]=(-1)*bmat[i];
	 

	free(w);
	free(iw);
	free(b);
	free(jb);
	free(ib);
	free(tb);
	free(jtb);
	free(itb);
	free(jcn );
	free(cntl);
	free(icntl);
	free(ip );
	free(np );
	free(jfirst );
	free(lenr );
	free(lastr );
	free(nextr );
	free(ifirst );
	free(lenc );
	free(lastc );
	free(nextc );
	free(info );
	free(rinfo );
	free(/* ma50bd*/qrmat );
	free(qrmatj );
	free(qrmati );
	free(lfact );
	free(fact );
	free(irnf );
	free(iptrl );
	free(iptru );
	free(x );
	free(nsSumC );


	/* rwt print profile results */

	return;

}	/* obtainSparseReducedForm */


/* --------------------------------------------------------------- */
/* !applySparseReducedForm                                        */
/* --------------------------------------------------------------- */
void applySparseReducedForm(

	int rowDim,int colDim,double * initialX, 
	double * fp,double * intercept,
	double * bmat,int * bmatj,int * bmati,double * resultX

)
{
	double * deviations;
	int i;

	deviations = (double *) calloc(colDim,sizeof(double));

	for(i=0;i<colDim;i++){
		deviations[i]=initialX[i]-fp[(rowDim+i)%rowDim];
	}

	sparseMatTimesVec(&rowDim,&colDim,bmat,bmatj,bmati,deviations,resultX);

	for(i=0;i<rowDim;i++){
		resultX[i]=resultX[i]+fp[(rowDim+i)%rowDim]+intercept[i];
	}

	free(deviations);

}	/* applySparseReducedForm */


 

/* --------------------------------------------------------------- */
/* !satisfiesLinearSystemQ                                         */
/* rwt allocate space for rightMostAllZeroQ                        */
/* rwt add profiling                                               */
/* --------------------------------------------------------------- */
int satisfiesLinearSystemQ (

	int *maxNumberOfHElements,
	int hrows,int lags,	int leads,
	double * hmat,int * hmatj,int * hmati,
	int *  auxiliaryInitialConditions,
	int *  rowsInQ,
	double * bmat, int * bmatj, int * bmati,
	int * essential,
	double * rootr,double * rooti,double * normVec,
	void * aPointerToVoid
)
{
	int ierr;
	int hcols;
	int neqTimesTau;
	int neqTimesTheta;
	double * wkspc;
	double * partB;int * partBj;int * partBi;
	double * forHMult;int * forHMultj;int *forHMulti;
	double * bTrans;int * bTransj;int *bTransi;
	double * forBMult;int * forBMultj;int *forBMulti;
	double * resBMult;int * resBMultj;int *resBMulti;
	double * ltpt;int * ltptj;int * ltpti;
	int resRows;int resCols;
	int aOne=1;int aTwo=2;
	int lastRow;int firstRow;int offset;
	int ii;
	int originalMaxHElements;

	int maxHElementsEncountered=0;
	originalMaxHElements=*maxNumberOfHElements;

	wkspc=(double *)calloc(*maxNumberOfHElements,sizeof(double));
	forHMult=(double *)calloc(*maxNumberOfHElements,sizeof(double));
	forHMultj=(int *)calloc(*maxNumberOfHElements,sizeof(int));
	forHMulti=(int *)calloc(*maxNumberOfHElements,sizeof(int));
	bTrans=(double *)calloc(*maxNumberOfHElements,sizeof(double));
	bTransj=(int *)calloc(*maxNumberOfHElements,sizeof(int));
	bTransi=(int *)calloc(*maxNumberOfHElements,sizeof(int));
	forBMult=(double *)calloc(*maxNumberOfHElements,sizeof(double));
	forBMultj=(int *)calloc(*maxNumberOfHElements,sizeof(int));
	forBMulti=(int *)calloc(*maxNumberOfHElements,sizeof(int));
	resBMult=(double *)calloc(*maxNumberOfHElements,sizeof(double));
	resBMultj=(int *)calloc(*maxNumberOfHElements,sizeof(int));
	resBMulti=(int *)calloc(*maxNumberOfHElements,sizeof(int));
	partB=(double *)calloc(*maxNumberOfHElements,sizeof(double));
	partBj=(int *)calloc(*maxNumberOfHElements,sizeof(int));
	partBi=(int *)calloc(*maxNumberOfHElements,sizeof(int));
	ltpt=(double *)calloc(*maxNumberOfHElements,sizeof(double));
	ltptj=(int *)calloc(*maxNumberOfHElements,sizeof(int));
	ltpti=(int *)calloc(*maxNumberOfHElements,sizeof(int));

	neqTimesTau=hrows*lags;
	neqTimesTheta=hrows*leads;
	/*identity matrix at the top*/
	for(ii=0;ii<neqTimesTau;ii++)
		{ltpt[ii]=1;ltptj[ii]=ii+1;ltpti[ii]=ii+1;}
	offset=ltpti[neqTimesTau]=neqTimesTau+1;
	copyMatrix(&neqTimesTheta,&aOne,bmat,bmatj,bmati,&offset,ltpt,ltptj,ltpti+neqTimesTau);

	lastRow=neqTimesTau+neqTimesTheta;
	firstRow=lastRow-neqTimesTau+1;
	extractSubmatrix(&neqTimesTheta,&aOne,&firstRow,&lastRow,&aOne,&neqTimesTau,
		ltpt,ltptj,ltpti,&resRows,&resCols,forBMult,forBMultj,forBMulti
	);
	firstRow=1;lastRow=hrows;
	extractSubmatrix(&neqTimesTheta,&aOne,&firstRow,&lastRow,&aOne,&neqTimesTau,
		bmat,bmatj,bmati,&resRows,&resCols,partB,partBj,partBi
	);

	if(lags>0) {
		for(ii=0;ii<(lags-1)*hrows;ii++) {
			bTrans[ii]=1;bTransj[ii]=hrows+ii+1;bTransi[ii]=ii+1;
		}
		offset=(int)(bTrans[(lags-1)*hrows]=(lags-1)*hrows+1);
		copyMatrix(&hrows,&aOne,bmat,bmatj,bmati,&offset,bTrans,bTransj,bTransi+(lags-1)*hrows);
	} else {
		offset=1;
		copyMatrix(&hrows,&aOne,bmat,bmatj,bmati,&offset,bTrans,bTransj,bTransi+neqTimesTau);
	}
	bumpSparseAim(bTransi[neqTimesTau]-bTransi[0]);

	sparseMult(&neqTimesTau,&neqTimesTau,maxNumberOfHElements,wkspc,&aOne,
		partB,partBj,partBi,
		forBMult,forBMultj,forBMulti,
		/*bTrans,bTransj,bTransi,*/
		resBMult,resBMultj,resBMulti,
		&ierr
	);
	if(ierr!=0){printf("*************ran out of space****************\n");return(1);}
	bumpSparseAim(resBMulti[neqTimesTau]-resBMulti[0]);
	firstRow=1;lastRow=hrows;
	extractSubmatrix(&neqTimesTheta,&aOne,&firstRow,&lastRow,&aOne,&neqTimesTau,
		resBMult,resBMultj,resBMulti,&resRows,&resCols,partB,partBj,partBi
	);
	offset=ltpti[neqTimesTau+neqTimesTheta];

	bumpSparseAim (partBi[hrows]-partBi[0]+ltpti[hrows]-ltpti[0]+offset) ;
	if (*maxNumberOfHElements<=partBi[hrows]-partBi[0]+ltpti[hrows]-ltpti[0]+offset) 
		{printf("*************ran out of space****************\n");return(1);}
	copyMatrix(&hrows,&aOne,partB,partBj,partBi,&offset,ltpt,ltptj,ltpti+neqTimesTau+neqTimesTheta);
	/*copyMatrix(&hrows,&aOne,resBMult,resBMultj,resBMulti,&offset,ltpt,ltptj,ltpti+neqTimesTau+neqTimesTheta);*/

	hcols=hrows*(lags+leads+1);
	sparseMult(&hrows,&hcols,maxNumberOfHElements,wkspc,&aOne,
		hmat,hmatj,hmati,
		ltpt,ltptj,ltpti,
		forHMult,forHMultj,forHMulti,
		&ierr
	);
	bumpSparseAim(ltpti[neqTimesTau+neqTimesTheta+1]-ltpti[0]);
	bumpSparseAim(forHMulti[hrows]-forHMulti[0]);
	if(ierr!=0){printf("*************ran out of space****************\n");return(1);}

	normsByRow(&hrows,&aTwo,forHMult,forHMultj,forHMulti,normVec);

	free(wkspc);
	free(forHMult);
	free(forHMultj);
	free(forHMulti);
	free(bTrans);
	free(bTransj);
	free(bTransi);
	free(forBMult);
	free(forBMultj);
	free(forBMulti);
	free(resBMult);
	free(resBMultj);
	free(resBMulti);
	free(partB);
	free(partBj);
	free(partBi);
	free(ltpt);
	free(ltptj);
	free(ltpti);

	*maxNumberOfHElements=maxHElementsEncountered;
	return(0);

}	/* satsifiesLinearSystemQ */



/* ----------------------------------------------------------------- */
/* misc utility routines follow ...                                  */
/*                                                                   */
/*                                                                   */
/*  lineNumberToViolation                                            */
/*  lineNumberToString                                               */
/*  validVector                                                      */
/*  validCSRMatrix                                                   */
/*  cPrintMatrix                                                     */
/*  cPrintMatrixNonZero                                              */
/*  cPrintSparse                                                     */
/*  rowEndsInZeroBlock                                               */
/*                                                                   */
/* ----------------------------------------------------------------- */

static int lineNumberToViolation(int lineNo)
{
int result;
switch(lineNo)
{
case  sparseAimPreMaxNumberOfHElementsLEZero: result=
  sparseAim_PRECONDITIONS_VIOLATED; break;
case  sparseAimPreHrows: result=
  sparseAim_PRECONDITIONS_VIOLATED; break;
case  sparseAimPreHcolsHrows: result=
  sparseAim_PRECONDITIONS_VIOLATED; break;
case  sparseAimPreLeads: result=
  sparseAim_PRECONDITIONS_VIOLATED; break;
case  sparseAimPreHmat: result=
  sparseAim_PRECONDITIONS_VIOLATED; break;
case  sparseAimPreAuxRows: result=
  sparseAim_PRECONDITIONS_VIOLATED; break;
case  sparseAimPreRowsInQ: result=
  sparseAim_PRECONDITIONS_VIOLATED; break;
case  sparseAimPreQmat: result=
  sparseAim_PRECONDITIONS_VIOLATED; break;
case  autoRegressionPostValidQ: result=
  autoRegression_POSTCONDITIONS_VIOLATED; break;
case  autoRegressionPostValidH: result=
  autoRegression_POSTCONDITIONS_VIOLATED; break;
case  autoRegressionPostValidAnnihilator: result=
  autoRegression_POSTCONDITIONS_VIOLATED; break;
case  autoRegressionPostValidR: result=
  autoRegression_POSTCONDITIONS_VIOLATED; break;
case  autoRegressionPostValidJs: result=
  autoRegression_POSTCONDITIONS_VIOLATED; break;
case  augmentQmatWithInvariantSpaceVectorsPreConstraints: result=
  augmentQmatWithInvariantSpaceVectors_PRECONDITIONS_VIOLATED; break;
case  augmentQmatWithInvariantSpaceVectorsPreAuxiliary: result=
  augmentQmatWithInvariantSpaceVectors_PRECONDITIONS_VIOLATED; break;
case  augmentQmatWithInvariantSpaceVectorsPostValidQ: result=
  augmentQmatWithInvariantSpaceVectors_POSTCONDITIONS_VIOLATED; break;
case  augmentQmatWithInvariantSpaceVectorsPostValidRealRoot: result=
  augmentQmatWithInvariantSpaceVectors_POSTCONDITIONS_VIOLATED; break;
case  augmentQmatWithInvariantSpaceVectorsPostValidImagRoot: result=
  augmentQmatWithInvariantSpaceVectors_POSTCONDITIONS_VIOLATED; break;
case  augmentQmatWithInvariantSpaceVectorsPostValidA: result=
  augmentQmatWithInvariantSpaceVectors_POSTCONDITIONS_VIOLATED; break;
case  augmentQmatWithInvariantSpaceVectorsPostADim: result=
  augmentQmatWithInvariantSpaceVectors_POSTCONDITIONS_VIOLATED; break;
case  augmentQmatWithInvariantSpaceVectorsPostValidJs: result=
  augmentQmatWithInvariantSpaceVectors_POSTCONDITIONS_VIOLATED; break;
case  shiftRightAndRecordPreZeroRow: result=
  STACKED_SYSTEM_NOT_FULL_RANK; break;
case  annihilateRowsPostValidH: result=
  annihilateRows_POSTCONDITIONS_VIOLATED; break;
case nzmaxTooSmallConstructA: result=
  HELEMS_TOO_SMALL; break;
case nzmaxTooSmallAugmentQ: result=
  HELEMS_TOO_SMALL; break;
case nzmaxTooSmallAnnihilateRows: result=
  HELEMS_TOO_SMALL; break;
case ndnsTooSmall: result=
  AMAT_TOO_LARGE; break;
case qextentTooBig: result=
  HELEMS_TOO_SMALL; break;
case errorReturnFromUseArpack: result=
  augmentQmatWithInvariantSpaceVectors_POSTCONDITIONS_VIOLATED; break;
case tooManyLargeRoots: result=
  TOO_MANY_LARGE_ROOTS; break;
case tooFewLargeRoots: result=
  TOO_FEW_LARGE_ROOTS; break;
default: result=
  -1;break;
}
return(result);
}


static char * lineNumberToString(int lineNo)
{
char * result;
switch(lineNo)
{
case  sparseAimPreMaxNumberOfHElementsLEZero: result=
  "sparseAim_PRECONDITIONS_VIOLATED"; break;
case  sparseAimPreHrows: result=
  "sparseAim_PRECONDITIONS_VIOLATED"; break;
case  sparseAimPreHcolsHrows: result=
  "sparseAim_PRECONDITIONS_VIOLATED"; break;
case  sparseAimPreLeads: result=
  "sparseAim_PRECONDITIONS_VIOLATED"; break;
case  sparseAimPreHmat: result=
  "sparseAim_PRECONDITIONS_VIOLATED"; break;
case  sparseAimPreAuxRows: result=
  "sparseAim_PRECONDITIONS_VIOLATED"; break;
case  sparseAimPreRowsInQ: result=
  "sparseAim_PRECONDITIONS_VIOLATED"; break;
case  sparseAimPreQmat: result=
  "sparseAim_PRECONDITIONS_VIOLATED"; break;
case  autoRegressionPostValidQ: result=
  "autoRegression_POSTCONDITIONS_VIOLATED"; break;
case  autoRegressionPostValidH: result=
  "autoRegression_POSTCONDITIONS_VIOLATED"; break;
case  autoRegressionPostValidAnnihilator: result=
  "autoRegression_POSTCONDITIONS_VIOLATED"; break;
case  autoRegressionPostValidR: result=
  "autoRegression_POSTCONDITIONS_VIOLATED"; break;
case  autoRegressionPostValidJs: result=
  "autoRegression_POSTCONDITIONS_VIOLATED"; break;
case  augmentQmatWithInvariantSpaceVectorsPreConstraints: result=
  "augmentQmatWithInvariantSpaceVectors_PRECONDITIONS_VIOLATED"; break;
case  augmentQmatWithInvariantSpaceVectorsPreAuxiliary: result=
  "augmentQmatWithInvariantSpaceVectors_PRECONDITIONS_VIOLATED"; break;
case  augmentQmatWithInvariantSpaceVectorsPostValidQ: result=
  "augmentQmatWithInvariantSpaceVectors_POSTCONDITIONS_VIOLATED"; break;
case  augmentQmatWithInvariantSpaceVectorsPostValidRealRoot: result=
  "augmentQmatWithInvariantSpaceVectors_POSTCONDITIONS_VIOLATED"; break;
case  augmentQmatWithInvariantSpaceVectorsPostValidImagRoot: result=
  "augmentQmatWithInvariantSpaceVectors_POSTCONDITIONS_VIOLATED"; break;
case  augmentQmatWithInvariantSpaceVectorsPostValidA: result=
  "augmentQmatWithInvariantSpaceVectors_POSTCONDITIONS_VIOLATED"; break;
case  augmentQmatWithInvariantSpaceVectorsPostADim: result=
  "augmentQmatWithInvariantSpaceVectors_POSTCONDITIONS_VIOLATED"; break;
case  augmentQmatWithInvariantSpaceVectorsPostValidJs: result=
  "augmentQmatWithInvariantSpaceVectors_POSTCONDITIONS_VIOLATED"; break;
case  shiftRightAndRecordPreZeroRow: result=
  "STACKED_SYSTEM_NOT_FULL_RANK"; break;
case  annihilateRowsPostValidH: result=
  "annihilateRows_POSTCONDITIONS_VIOLATED"; break;
case nzmaxTooSmallConstructA: result=
  "maxNumberOfHElementsTooSmall"; break;
case nzmaxTooSmallAnnihilateRows: result=
  "maxNumberOfHElementsTooSmall"; break;
case nzmaxTooSmallAugmentQ: result=
  "nzmaxTooSmallAugmentQ"; break;
case ndnsTooSmall: result=
  "transitionMatrixTooSmall"; break;
case qextentTooBig: result=
  "maxNumberOfHElementsTooSmall"; break;
case errorReturnFromUseArpack: result=
  "unable to compute eigenvalues using ARPACK"; break;
case tooManyLargeRoots: result=
  "Blanchard-Kahn fails:  too many large roots" ; break;
case tooFewLargeRoots: result=
  "Blanchard-Kahn fails:  too few large roots" ; break;
default: result=
  "unknown assertion violation";break;
}
return(result);
}


static int validVector(int numRows,double * vec)
{
	int i,allFiniteNumbers;
      allFiniteNumbers=TRUE;
      for(i=0;i<numRows;i++){
        allFiniteNumbers=(finite(vec[i])&&allFiniteNumbers);}

      return(allFiniteNumbers);
}


static int validCSRMatrix(int numRows,double * mata,int * matj,int *mati)
{
int result,allPositive,elements,i,allFiniteNumbers;
elements=mati[numRows]-mati[0];
result=
  (mati[numRows]>0) && (mati[0]>0) && (
          (elements) >=0);
      allPositive=TRUE;
      for(i=0;i<numRows;i++){allPositive=(mati[i]>0&&allPositive);}
      result=
        (result && allPositive);
      allPositive=TRUE;
      for(i=0;i<elements;i++){
        allPositive=(matj[i]>0&&allPositive);}
      allFiniteNumbers=TRUE;
      for(i=0;i<elements;i++){
        allFiniteNumbers=(finite(mata[i])&&allFiniteNumbers);}

      result=
        (result && allPositive && allFiniteNumbers);
      return(result);
}


void cPrintMatrix(int nrows,int ncols,double * matrix)
{
int i,j;
for(i=0;i<nrows;i++)
for(j=0;j<ncols;j++)printf("[%d] [%d] %f\n",i,j,matrix[i+(j*nrows)]);
}


void cPrintMatrixNonZero(nrows,ncols,matrix,zerotol)
int  nrows;
int  ncols;
double * matrix;
double zerotol;
{
int i,j;
double fabs(double x);
for(i=0;i<nrows;i++)
for(j=0;j<ncols;j++)
    if(fabs(matrix[i+(j*nrows)]) > zerotol)
    printf("[%d] [%d] %f\n",i,j,matrix[i+(j*nrows)]);
}


void cPrintSparse(int rows,double * a,int * aj,int * ai)
{
int i,j,numEls;
numEls=ai[rows]-ai[0];
printf("matrix has %d non zero element/s\n",numEls);
for(i=0;i<rows;i++)
{
for(j=ai[i];j<ai[i+1];j++)
{
printf("row=%d,col=%d,val=%f\n",i+1,aj[j-1],a[j-1]);
}}
}



/* ----------------------------------------------------------------------
 rowEndsInZeroBlock (targetRow, blockLength, mat, matj, mati, ncols)

 returns true if targetRow in CSR matrix mat ends in zero block,
 else returns false

	targetRow   		row number to check
	blockLength   		length of block to check
	mat, matj, mati  	target matrix in CSR format
	ncols    			number of columns in 'mat'

 notes
 no range checking -- targetRow and blockLength are assumed to be in bounds
---------------------------------------------------------------------- */
int rowEndsInZeroBlock (
 	int targetRow, 
 	int blockLength, 
 	double *mat, 
 	int *matj, 
 	int *mati, 
 	int ncols
) {

 	int i ;

 	/* loop through nonzeros for this row */
 	for (i=mati[targetRow-1]; i<mati[targetRow]; i++) {

	  	/* if column index for this value is inside block, 
	       we have a nonzero value, so return false */
	  	if (matj[i-1]>(ncols-blockLength) && matj[i-1]<=ncols)
	   		return (0) ;

	}
 
 	/* no nonzeros found, return true */
 	return (1) ;

}


/* ----------------------------------------------------------------------
 deleteRow (targetRow, mat, nrows, ncols)

 	deletes row targetRow from dense matrix mat, which is nrows by ncols
	deletes in place, last row of existing matrix is left unchanged
 	returns 0 if successful
	targetRow is indexed from 1 to nrows


---------------------------------------------------------------------- */
int deleteRow (int targetRow, double *mat, int nrows, int ncols) {

	int i, istart, istop ;

	/* if targetRow is out of bounds, print msg and return */
	if (targetRow < 1 || targetRow > nrows) {
		printf ("deleteRow:  target row %d is out of bounds\n", targetRow) ;
		return (-1) ;
	}

	/* start with first value of row to be deleted */
	istart = (targetRow-1)*ncols ;

	/* stop and beginning of last row */
	istop = (nrows-1)*ncols ;

	/* copy data from one row ahead */
	for (i=istart; i<istop; i++)
		mat[i] = mat[i+ncols] ;

	/* all done */
	return (0) ;

}	/* deleteRow */



/* ******************************************************************************************* */
/* ******************************************************************************************* */
/*                               end sparseAim.c                                               */
/* ******************************************************************************************* */
/* ******************************************************************************************* */
