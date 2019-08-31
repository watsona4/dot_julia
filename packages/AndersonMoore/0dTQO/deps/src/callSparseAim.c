/* ---------------------------------------------------------------------------- 
 * callSparseAim.c                                                              
 * wrapper to sparseAim()												        
 * Allocates memory																
 * for sparseAim and calls sparseAim 
 * takes as input a full H matrix, and returns a full cofb matrix
 * also, Q (asymptotic constraints) and S (structural coef) matrices
 *
 *
 * At the bottom is an R wrapper (the function is "callSparseAimFromR")
 * R wrapper is necessary because when calling C from R, all arguments
 * must be passed by reference.
 * ---------------------------------------------------------------------------- */
#include "sparseAim.h"

#define cpuTime() (( (double)clock() ) / CLOCKS_PER_SEC)	      


void extern obtainSparseReducedForm();

void extern submat_();
int USEARPACK=1;
int TESTBLANCHARDKAHN=1;
double ZERO_TOLERANCE = 0.00000000001;
double ZERO_TOL1 = 0.0001;



void callSparseAim(double *hmatFull,int hrows,int hcols,
				   int neq,int leads,int lags,int nstate,
				   int qmax, 
				   double *returnCodePointer,
				   double *cofb, double *qmatrix)
{

	/* declare coefficient matrices, etc */
	double *hmat, *newHmat, *qmat, *bmat, *sbmat;
	int *hmatj, *newHmatj, *qmatj, *bmatj, *sbmatj;
	int *hmati, *newHmati, *qmati, *bmati, *sbmati;
	double *rootr, *rooti;

	/* declarations for sparseAim call */ 
	int qrows, qcols, brows, bcols, sbrows, sbcols;
	int maxSize, discreteTime ;
	int auxCond, rowsInQ, essential;
	void *aPointerToVoid ;

	/* rwt work variables  */
	int i, nnz, ierr;
	int returnCode;
	int one = 1;
   	qrows = neq * leads;
   	qcols = neq * (lags + leads);

   	bcols = neq * lags;
	maxSize = qmax ;
	rowsInQ = auxCond = 0 ;


	/* alloc space for H matrix */
	hmat = (double *)calloc(maxSize,sizeof(double)) ;
	hmatj = (int *)calloc(maxSize,sizeof(int)) ;
	hmati = (int *)calloc((neq+1),sizeof(int)) ;
    /* convert incoming full H matrix (hmatFull) to CSR sparse */
	int hrowsCopy = hrows;

	dnsToCsr (&hrows, &hcols, &maxSize, hmatFull, &hrowsCopy, hmat, hmatj, hmati, &ierr) ;

	/* allocate space for arrays needed in call to sparseAim*/
	newHmat = (double *)calloc(maxSize,sizeof(double)) ;
	newHmatj = (int *)calloc(maxSize,sizeof(int)) ;
	newHmati = (int *)calloc((neq+1),sizeof(int)) ;

	qmat = (double *)calloc(maxSize,sizeof(double)) ;
	qmatj = (int *)calloc(maxSize,sizeof(int)) ;
	qmati = (int *)calloc((qrows+1),sizeof(int)) ;

	rootr = (double *)calloc(qcols,sizeof(double)) ;
	rooti = (double *)calloc(qcols,sizeof(double)) ;


	
			      
	/* zero roots to start */
	for (i=0; i<qcols; i++) 
		rootr[i] = rooti[i] = 0.0 ;

	/* initialize other arguments */
	discreteTime = 1 ;
	auxCond = 0 ;
	rowsInQ = 0 ;
	qmati[0] = 1 ;	/*this makes for a sparse matrix with no nonzero elements */
	essential = 0 ;
	returnCode = 0 ;
	aPointerToVoid = (void *)NULL ;


	/* and call sparseAim */
	sparseAim (
		&maxSize, discreteTime, hrows, hcols, leads,
		hmat, hmatj, hmati, newHmat, newHmatj, newHmati,
		&auxCond, &rowsInQ, qmat, qmatj, qmati,
		&essential, rootr, rooti, &returnCode, aPointerToVoid
	) ;


	*returnCodePointer = returnCode;
	if (returnCode == 0) {

		/* compute B matrix */
		bmat = (double *)calloc(maxSize,sizeof(double)) ;
		bmatj = (int *)calloc(maxSize,sizeof(int)) ;
		bmati = (int *)calloc((qrows+1),sizeof(int)) ;

		obtainSparseReducedForm (&maxSize, hrows*leads, hcols-hrows,
			qmat, qmatj, qmati, bmat, bmatj, bmati
		) ;
	fflush(stdout);

		csrToDns (&qrows, &qcols, qmat, qmatj, qmati, qmatrix, &qrows, &ierr);
	

		free (hmat) ; free (hmatj) ; free (hmati);
		free (newHmat);	free (newHmatj) ; free (newHmati);
		free (qmat); free (qmatj); free (qmati);


		// take submat of bmat to include only the first HROWS rows.
		sbmat = (double *)calloc(maxSize,sizeof(double)) ;
		sbmatj = (int *)calloc(maxSize,sizeof(int)) ;
		sbmati = (int *)calloc((hrows+1),sizeof(int)) ;
		sbrows = hrows;
		sbcols = bcols;

		submat_(&qrows,&one,&one,&hrows,&one,&bcols,bmat,bmatj,bmati,&sbrows,&sbcols,sbmat,sbmatj,sbmati);
		free(bmat); free(bmatj); free(bmati);



		csrToDns (&sbrows, &sbcols, sbmat, sbmatj, sbmati, cofb, &sbrows, &ierr) ;
		nnz = sbmati[sbrows]-sbmati[0];


		
	}   /* if returnCode == 0 */


}	/* end main fn */




/* BEGIN R WRAPPER */

void callSparseAimFromR(double *hmatFull, int *Rhrows, int * Rhcols,
		int * Rneq, int * Rleads, int * Rlags, int * Rnstate,
		int * Rqmax, double * returnCodePointer,
		double *cofb, double *qmatrix){

	int hrows = *Rhrows;
	int hcols = *Rhcols;
	int neq = *Rneq;
	int leads = *Rleads;
	int lags = *Rlags;
	int nstate = *Rnstate;
	int qmax = *Rqmax;
	callSparseAim(hmatFull, hrows, hcols, neq, leads, lags,
			nstate, qmax, returnCodePointer, cofb, qmatrix);

}
