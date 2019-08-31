C######DATE 20 May 1993 COPYRIGHT Rutherford Appleton Laboratory
C 24 September 1993 Some IVDEP comments added for speed on the Cray,
C     some minor bugs fixed, default changed to BLAS 3 with block size
C     32.
C 6 December 1993. Minor bug fixed re threshold test for pivots.
      SUBROUTINE MA50AD(M,N,NE,LA,A,IRN,JCN,IQ,CNTL,ICNTL,IP,NP,JFIRST,
     +                  LENR,LASTR,NEXTR,IW,IFIRST,LENC,LASTC,NEXTC,
     +                  INFO,RINFO)

C MA50A/AD chooses a pivot sequence using a Markowitz criterion with
C     threshold pivoting.

C If  the user requires a more convenient data interface then the MA48
C     package should be used. The MA48 subroutines call the MA50
C     subroutines after checking the user's input data and optionally
C     permute the matrix to block triangular form.

      INTEGER M,N,NE,LA
      DOUBLE PRECISION A(LA)
      INTEGER IRN(LA),JCN(LA),IQ(N)
      DOUBLE PRECISION CNTL(4)
      INTEGER ICNTL(7),IP(M),NP,JFIRST(M),LENR(M),LASTR(M),NEXTR(M),
     +        IW(M),IFIRST(N),LENC(N),LASTC(N),NEXTC(N),INFO(7)
      DOUBLE PRECISION RINFO

C M is an integer variable that must be set to the number of rows.
C      It is not altered by the subroutine.
C N is an integer variable that must be set to the number of columns.
C      It is not altered by the subroutine.
C NE is an integer variable that must be set to the number of entries
C      in the input matrix. It is not altered by the subroutine.
C LA is an integer variable that must be set to the size of A, IRN, and
C      JCN. It is not altered by the subroutine.
C A is an array that holds the input matrix on entry and is used as
C      workspace.
C IRN  is an integer array.  Entries 1 to NE must be set to the
C      row indices of the corresponding entries in A.  IRN is used
C      as workspace and holds the row indices of the reduced matrix.
C JCN  is an integer array that need not be set by the user. It is
C      used to hold the column indices of entries in the reduced
C      matrix.
C IQ is an integer array of length N. On entry, it holds pointers
C      to column starts. During execution, IQ(j) holds the position of
C      the start of column j of the reduced matrix or -IQ(j) holds the
C      column index in the permuted matrix of column j. On exit, IQ(j)
C      holds the index of the column that is in position j of the
C      permuted matrix.
C CNTL must be set by the user as follows and is not altered.
C     CNTL(1)  Full matrix processing will be used if the density of
C       the reduced matrix is MIN(CNTL(1),1.0) or more.
C     CNTL(2) determines the balance between pivoting for sparsity and
C       for stability, values near zero emphasizing sparsity and values
C       near one emphasizing stability. Each pivot must have absolute
C       value at least CNTL(2) times the greatest absolute value in the
C       same column of the reduced matrix.
C     CNTL(3) If this is set to a positive value, any entry of the
C       reduced matrix whose modulus is less than CNTL(3) will be
C       dropped.
C     CNTL(4)  Any entry of the reduced matrix whose modulus is less
C       than or equal to CNTL(4) will be regarded as zero from the
C        point of view of rank.
C ICNTL must be set by the user as follows and is not altered.
C     ICNTL(1)  must be set to the stream number for error messages.
C       A value less than 1 suppresses output.
C     ICNTL(2) must be set to the stream number for diagnostic output.
C       A value less than 1 suppresses output.
C     ICNTL(3) must be set to control the amount of output:
C       0 None.
C       1 Error messages only.
C       2 Error and warning messages.
C       3 As 2, plus scalar parameters and a few entries of array
C         parameters on entry and exit.
C       4 As 3, plus all parameters on entry and exit.
C     ICNTL(4) If set to a positive value, the pivot search is limited
C       to ICNTL(4) columns (Zlatev strategy). This may result in
C       different fill-in and execution time. If ICNTL(4) is positive,
C       the workspace arrays LASTR and NEXTR are not referenced.
C     ICNTL(5) The block size to be used for full-matrix processing.
C     ICNTL(6) The last ICNTL(6) columns of A must be the last
C       ICNTL(6) columns of the permuted matrix. A value outside the
C       range 1 to N-1 is treated as zero.
C     ICNTL(7) If given the value 1, pivots are limited to
C       the main diagonal, which may lead to a premature switch to full
C       processing if no suitable diagonal entries are available.
C       If given the value 2, IFIRST must be set so that IFIRST(i) is
C       the column in position i of the permuted matrix and IP must
C       be set so that IP(i) < IP(j) if row i is recommended to
C       precede row j in the pivot sequence.
C IP is an integer array of length M that need not be set on entry
C      unless ICNTL(7)=2 (see ICNTL(7) for details of this case).
C      During execution, IP(i) holds the position of the start of row i
C      of the reduced matrix or -IP(i) holds the row index in the
C      permuted matrix of row i. Before exit, IP(i) is made positive.
C NP is an integer variable. It need not be set on entry. On exit,
C     it will be set to the number of columns to be processed in
C     packed storage.
C JFIRST is an integer workarray of length M. JFIRST(i) is the
C      first column of the reduced matrix to have i entries or is
C      zero if no column has i entries.
C LENR is an integer workarray of length M that is used to hold the
C      numbers of entries in the rows of the reduced matrix.
C LASTR is an integer workarray of length M, used only if ICNTL(4) = 0.
C      For rows in the reduced matrix, LASTR(i) indicates the previous
C      row to i with the same number of entries. LASTR(i) is zero if
C      no such row exists.
C NEXTR is an integer workarray of length M, used only if ICNTL(4) = 0
C      or ICNTL(7)=2. If ICNTL(4)=0, for rows in the reduced matrix,
C      NEXTR(i) indicates the next row to i with the same number of
C      entries; and if row i is the last in the chain, NEXTR is
C      equal to zero. If ICNTL(7)=2, NEXTR is a copy of the value of
C      IP on entry.
C IW is an integer array of length M used as workspace and is used to
C     assist the detection of duplicate entries and the sparse SAXPY
C     operations. It is reset to zero each time round the main loop.
C IFIRST is an integer array of length N, used only if ICNTL(4) = 0
C      or ICNTL(7)=2. If ICNTL(4) = 0, it is a workarray; IFIRST(i)
C      points to the first row of the reduced matrix to have i entries
C      or is zero if no row has i entries. If ICNTL(7)=2, IFIRST
C      must be set on entry (see ICNTL(7) for details of this case).
C LENC is an integer workarray of length N that is used to hold
C      the numbers of entries in the columns of the reduced matrix.
C LASTC is an integer workarray of length N.  For columns in the reduced
C      matrix, LASTC(j) indicates the previous column to j with the same
C      number of entries.  If column j is the first in the chain,
C      LASTC(j) is equal to zero.
C NEXTC is an integer workarray of length N.  For columns in the reduced
C      matrix, NEXTC(j) indicates the next column to j with the same
C      number of entries.  If column j is the last column in the chain,
C      NEXTC(j) is zero.
C INFO need not be set on entry. On exit, it holds the following:
C    INFO(1):
C       0  Successful entry.
C      -1  M < 1 or N < 1.
C      -2  NE < 1.
C      -3  Insufficient space.
C      -4  Duplicated entries.
C      -5  Faulty column permutation in IFIRST when ICNTL(7)=2.
C      -6  ICNTL(4) not equal to 1 when ICNTL(7)=2.
C      +1  Rank deficient.
C      +2  Premature switch to full processing because of failure to
C          find a stable diagonal pivot (ICNTL(7)>=1 case only).
C      +3  Both of these warnings.
C    INFO(2) Number of compresses of the arrays.
C    INFO(3) Minimum LA recommended to analyse matrix.
C    INFO(4) Minimum LFACT required to factorize matrix.
C    INFO(5) Upper bound on the rank of the matrix.
C    INFO(6) Number of entries dropped from the data structure.
C    INFO(7) Number of rows processed in full storage.
C RINFO need not be set on entry. On exit, it holds the number of
C    floating-point operations needed for the factorization.

      INTEGER IDAMAX
      EXTERNAL IDAMAX
      EXTERNAL MA50DD
      INTRINSIC ABS,MAX,MIN

      DOUBLE PRECISION ZERO,ONE
      PARAMETER (ZERO=0D0,ONE=1.0D0)

      DOUBLE PRECISION ALEN,AMULT,ANEW,ASW,AU,COST,CPIV
      INTEGER DISPC,DISPR,EYE,I,IDROP,IDUMMY,IEND,IFILL,IFIR,II,IJ,
     +        IJPOS,IOP,IPIV,IPOS,ISRCH,I1,I2,J,JBEG,JEND,JJ,JLAST,
     +        JMORE,JNEW,JPIV,JPOS,J1,J2,L,LC,LEN,LENPIV,LP,LR
      DOUBLE PRECISION MAXENT
      INTEGER MINC,MORD,MP,MSRCH,NC,NDROP,NEFACT,NEPR,NERED,NE1,NORD,
     +        NORD1,NR,NULLC,NULLI,NULLJ,NULLR,PIVBEG,PIVCOL,PIVEND,
     +        PIVOT
      DOUBLE PRECISION PIVR,PIVRAT,U

C ALEN Real(LEN-1).
C AMULT Temporary variable used to store current multiplier.
C ANEW Temporary variable used to store value of fill-in.
C ASW Temporary variable used when swopping two real quantities.
C AU Temporary variable used in threshold test.
C COST Markowitz cost of current potential pivot.
C CPIV Markowitz cost of best pivot so far found.
C DISPC is the first free location in the column file.
C DISPR is the first free location in the row file.
C EYE Running relative position when processing pivot row.
C I Temporary variable holding row number. Also used as index in DO
C     loops used in initialization of arrays.
C IDROP Temporary variable used to accumulate number of entries dropped.
C IDUMMY DO index not referenced in the loop.
C IEND Position of end of pivot row.
C IFILL is the fill-in to the non-pivot column.
C IFIR Temporary variable holding first entry in chain.
C II Running position for current column.
C IJ Temporary variable holding row/column index.
C IJPOS Position of current pivot in A/IRN.
C IOP holds a running count of the number of rows with entries in both
C     the pivot and the non-pivot column.
C IPIV Row of the pivot.
C IPOS Temporary variable holding position in column file.
C ISRCH Temporary variable holding number of columns searched for pivot.
C I1 Position of the start of the current column.
C I2 Position of the end of the current column.
C J Temporary variable holding column number.
C JBEG Position of beginning of non-pivot column.
C JEND Position of end of non-pivot column.
C JJ Running position for current row.
C JLAST Last column acceptable as pivot.
C JMORE Temporary variable holding number of locations still needed
C     for fill-in in non-pivot column.
C JNEW Position of end of changed non-pivot column.
C JPIV Column of the pivot.
C JPOS Temporary variable holding position in row file.
C J1 Position of the start of the current row.
C J2 Position of the end of the current row.
C L Loop index.
C LC Temporary variable holding previous column in sequence.
C LEN Length of column or row.
C LENPIV Length of pivot column.
C LP Unit for error messages.
C LR Temporary variable holding previous row in sequence.
C MAXENT Temporary variable used to hold value of largest entry in
C    column.
C MINC Minimum number of entries of any row or column of the reduced
C     matrix, or in any column if ICNTL(4) > 0.
C MORD Number of rows ordered, excluding null rows.
C MP Unit for diagnostic messages.
C MSRCH Number of columns to be searched.
C NC Temporary variable holding next column in sequence.
C NDROP Number of entries dropped because of being in a column all of
C   whose entries are smaller than the pivot threshold.
C NEFACT Number of entries in factors.
C NEPR Number of entries in pivot row, excluding the pivot.
C NERED Number of entries in reduced matrix.
C NE1 Temporary variable used to hold number of entries in row/column
C     and to hold temporarily value of MINC.
C NORD Number of columns ordered, excluding null columns beyond JLAST.
C NORD1 Value of NORD at start of step.
C NR Temporary variable holding next row in sequence.
C NULLC Number of structurally zero columns found before any entries
C     dropped for being smaller than CNTL(3).
C NULLR Number of structurally zero rows found before any entries
C     dropped for being smaller than CNTL(3).
C NULLI Number of zero rows found.
C NULLJ Number of zero columns found beyond column JLAST.
C PIVBEG Position of beginning of pivot column.
C PIVCOL Temporary variable holding position in pivot column.
C PIVEND Position of end of pivot column.
C PIVOT Current step in Gaussian elimination.
C PIVR ratio of current pivot candidate to largest in its column.
C PIVRAT ratio of best pivot candidate to largest in its column.
C U Used to hold local copy of CNTL(2), changed if necessary so that it
C    is in range.

      LP = ICNTL(1)
      IF (ICNTL(3).LE.0) LP = 0
      MP = ICNTL(2)
      IF (ICNTL(3).LE.1) MP = 0
      INFO(1) = 0
      INFO(2) = 0
      INFO(3) = NE
      INFO(4) = NE
      INFO(5) = 0
      INFO(6) = 0
      INFO(7) = 0
      RINFO = ZERO

C Make some simple checks
      IF (M.LT.1 .OR. N.LT.1) GO TO 690
      IF (NE.LT.1) GO TO 700
      IF (LA.LT.NE) THEN
         INFO(3) = NE
         GO TO 710
      END IF

C Initial printing
      IF (MP.GT.0 .AND. ICNTL(3).GT.2) THEN
         WRITE (MP,'(/2(A,I6),A,I8,A,I8/A,1P,4E10.2/A,7I4)')
     +     ' Entering MA50AD with M =',M,' N =',N,' NE =',NE,' LA =',LA,
     +     ' CNTL =',CNTL,' ICNTL =',ICNTL
         IF (N.EQ.1 .OR. ICNTL(3).GT.3) THEN
            DO 10 J = 1,N - 1
               IF (IQ(J).LT.IQ(J+1)) WRITE (MP,
     +             '(A,I5,(T13,3(1P,E12.4,I5)))') ' Column',J,
     +             (A(II),IRN(II),II=IQ(J),IQ(J+1)-1)
   10       CONTINUE
            IF (IQ(N).LE.NE) WRITE (MP,'(A,I5,(T13,3(1P,E12.4,I5)))')
     +          ' Column',N, (A(II),IRN(II),II=IQ(N),NE)
         ELSE
            IF (IQ(1).LT.IQ(2)) WRITE (MP,
     +          '(A,I5,(T13,3(1P,E12.4,I5)))') ' Column',1,
     +          (A(II),IRN(II),II=IQ(1),IQ(2)-1)
         END IF
         IF (ICNTL(7).EQ.2) THEN
            WRITE (MP,'(A,(T10,10(I7)))') ' IP = ',IP
            WRITE (MP,'(A,(T10,10(I7)))') ' IFIRST = ',IFIRST
         END IF
      END IF

C Initialization of counts etc.
      MINC = 1
      NERED = NE
      U = MIN(CNTL(2),ONE)
      U = MAX(U,ZERO)
      MSRCH = ICNTL(4)
      IF (MSRCH.EQ.0) MSRCH = N
      JLAST = N - ICNTL(6)
      IF (JLAST.LT.1 .OR. JLAST.GT.N) JLAST = N
      NULLI = 0
      NULLJ = 0
      MORD = 0
      NORD = 0
      NDROP = 0
      NEFACT = 0
      DO 20 I = 1,N - 1
         LENC(I) = IQ(I+1) - IQ(I)
   20 CONTINUE
      LENC(N) = NE + 1 - IQ(N)

      IF (CNTL(3).GT.ZERO) THEN
C Drop small entries
         NERED = 0
         DO 40 J = 1,N
            I = IQ(J)
            IQ(J) = NERED + 1
            DO 30 II = I,I + LENC(J) - 1
               IF (ABS(A(II)).GE.CNTL(3)) THEN
                  NERED = NERED + 1
                  A(NERED) = A(II)
                  IRN(NERED) = IRN(II)
               ELSE
                  INFO(6) = INFO(6) + 1
               END IF
   30       CONTINUE
            LENC(J) = NERED + 1 - IQ(J)
   40    CONTINUE
      END IF

      IF (ICNTL(7).EQ.2) THEN
C Column order specified - copy the row ordering array
         DO 50 I = 1,M
            NEXTR(I) = IP(I)
   50    CONTINUE
C Check ICNTL(4)
         IF (ICNTL(4).NE.1) GO TO 740
      END IF

      DISPR = NERED + 1
      DISPC = NERED + 1
C
C Set up row oriented storage.
      DO 60 I = 1,M
         IW(I) = 0
         LENR(I) = 0
         JFIRST(I) = 0
   60 CONTINUE
C Calculate row counts.
      DO 70 II = 1,NERED
         I = IRN(II)
         LENR(I) = LENR(I) + 1
   70 CONTINUE
C Set up row pointers so that IP(i) points to position after end
C     of row i in row file.
      IP(1) = LENR(1) + 1
      DO 80 I = 2,M
         IP(I) = IP(I-1) + LENR(I)
   80 CONTINUE
C Generate row file.
      DO 100 J = 1,N
         I = IQ(J)
         DO 90 II = I,I + LENC(J) - 1
            I = IRN(II)
C Check for duplicate entry.
            IF (IW(I).EQ.J) GO TO 720
            IW(I) = J
            IPOS = IP(I) - 1
            JCN(IPOS) = J
            IP(I) = IPOS
   90    CONTINUE
  100 CONTINUE
      DO 110 I = 1,M
         IW(I) = 0
  110 CONTINUE

C Check for zero rows and (unless ICNTL(4) > 0), compute chains of rows
C    with equal numbers of entries.
      IF (ICNTL(4).LE.0) THEN
         DO 120 I = 1,N
            IFIRST(I) = 0
  120    CONTINUE
         DO 130 I = M,1,-1
            NE1 = LENR(I)
            IF (NE1.GT.0) THEN
               IFIR = IFIRST(NE1)
               IFIRST(NE1) = I
               LASTR(I) = 0
               NEXTR(I) = IFIR
               IF (IFIR.GT.0) LASTR(IFIR) = I
            ELSE
               IP(I) = -M + NULLI
               NULLI = NULLI + 1
            END IF
  130    CONTINUE
      ELSE
         DO 140 I = M,1,-1
            NE1 = LENR(I)
            IF (NE1.EQ.0) THEN
               IP(I) = -M + NULLI
               NULLI = NULLI + 1
            END IF
  140    CONTINUE
      END IF
C Check for zero columns and compute chains of columns with equal
C   numbers of entries.
      DO 150 J = N,1,-1
         NE1 = LENC(J)
         IF (NE1.EQ.0) THEN
            IF (ICNTL(7).NE.2) THEN
               IF (J.LE.JLAST) THEN
                  NORD = NORD + 1
                  IQ(J) = -NORD
                  IF (NORD.EQ.JLAST) THEN
C We have ordered the first N - ICNTL(6) columns.
                     NORD = NORD + NULLJ
                     JLAST = N
                     NULLJ = 0
                  END IF
               ELSE
                  NULLJ = NULLJ + 1
                  IQ(J) = - (JLAST+NULLJ)
               END IF
               LASTC(J) = 0
               NEXTC(J) = 0
            END IF
         ELSE
            IFIR = JFIRST(NE1)
            JFIRST(NE1) = J
            NEXTC(J) = IFIR
            LASTC(J) = 0
            IF (IFIR.GT.0) LASTC(IFIR) = J
         END IF
  150 CONTINUE
      IF (INFO(6).EQ.0) THEN
         NULLC = NORD + NULLJ
         NULLR = NULLI
      END IF

C
C **********************************************
C ****    Start of main elimination loop    ****
C **********************************************
      DO 630 PIVOT = 1,N
C Check to see if reduced matrix should be considered as full.
         IF (NERED.GE. (MIN(CNTL(1),ONE)*(N-NORD))*
     +       (M-MORD)) GO TO 640

         IF (ICNTL(7).EQ.2) THEN
C Column order specified - choose the pivot within the column
            IPIV = 0
            J = IFIRST(PIVOT)
            IF (J.LT.1 .OR. J.GT.N) GO TO 730
            IF (IQ(J).LT.0) GO TO 730
            LEN = LENC(J)
            IF (LEN.LE.0) GO TO 320
            ALEN = LEN - 1
            I1 = IQ(J)
            I2 = I1 + LEN - 1
C Find largest entry in column
            II = IDAMAX(LEN,A(I1),1)
            MAXENT = ABS(A(I1+II-1))
C Is every entry in the column below the pivot threshold?
            IF (MAXENT.LE.CNTL(4)) GO TO 320
            AU = MAX(MAXENT*U,CNTL(4))
C Scan column for pivot
            DO 160 II = I1,I2
               IF (ABS(A(II)).LT.AU) GO TO 160
C Candidate satisfies threshold criterion.
               I = IRN(II)
               IF (IPIV.NE.0) THEN
                  IF (NEXTR(I).GE.NEXTR(IPIV)) GO TO 160
               END IF
               CPIV = ALEN*(LENR(I)-1)
               IJPOS = II
               IPIV = I
               JPIV = J
  160       CONTINUE
            GO TO 330
         END IF

C Find the least number of entries in a row or column (column only if
C   the Zlatev strategy is in use)
         LEN = MINC
         DO 170 MINC = LEN,M - MORD
            IF (JFIRST(MINC).NE.0) GO TO 180
            IF (ICNTL(4).LE.0) THEN
               IF (IFIRST(MINC).NE.0) GO TO 180
            END IF
  170    CONTINUE

C Find the next pivot or a column whose entries are all very small.
C CPIV is the Markowitz cost of the best pivot so far and PIVRAT is the
C      ratio of its absolute value to that of the largest entry in its
C      column.
  180    CPIV = M
         CPIV = CPIV*N
         PIVRAT = ZERO
C Examine columns/rows in order of ascending count.
         ISRCH = 0
         DO 300 LEN = MINC,M - MORD
            ALEN = LEN - 1
C Jump if Markowitz count cannot be bettered.
            IF (CPIV.LE.ALEN**2 .AND. ICNTL(4).LE.0) GO TO 310
            IJ = JFIRST(LEN)
C Scan columns with LEN entries.
            DO 220 IDUMMY = 1,N
C If no more columns with LEN entries, exit loop.
               IF (IJ.LE.0) GO TO 230
               J = IJ
               IJ = NEXTC(J)
               IF (J.GT.JLAST) GO TO 220
C Column J is now examined.
C First calculate multiplier threshold level.
               MAXENT = ZERO
               I1 = IQ(J)
               I2 = I1 + LEN - 1
               II = IDAMAX(LEN,A(I1),1)
               MAXENT = ABS(A(I1+II-1))
C Exit loop if every entry in the column is below the pivot threshold.
               IF (MAXENT.LE.CNTL(4)) GO TO 320
               AU = MAX(MAXENT*U,CNTL(4))
C If diagonal pivoting requested, look for diagonal entry.
               IF (ICNTL(7).EQ.1) THEN
                  DO 190 II = I1,I2
                     IF (IRN(II).EQ.J) GO TO 200
  190             CONTINUE
                  GO TO 220
  200             I1 = II
                  I2 = II
               END IF
C Scan column for possible pivots
               DO 210 II = I1,I2
                  IF (ABS(A(II)).LT.AU) GO TO 210
C Candidate satisfies threshold criterion.
                  I = IRN(II)
                  COST = ALEN*(LENR(I)-1)
                  IF (COST.GT.CPIV) GO TO 210
                  PIVR = ABS(A(II))/MAXENT
                  IF (COST.EQ.CPIV) THEN
                     IF (PIVR.LE.PIVRAT) GO TO 210
                  END IF
C Best pivot so far is found.
                  CPIV = COST
                  IJPOS = II
                  IPIV = I
                  JPIV = J
                  IF (CPIV.LE.ALEN**2 .AND. ICNTL(4).LE.0) GO TO 330
                  PIVRAT = PIVR
  210          CONTINUE
C Increment number of columns searched.
               ISRCH = ISRCH + 1
C Jump if we have searched the number of columns stipulated and found a
C   pivot.
               IF (ISRCH.GE.MSRCH) THEN
                  IF (PIVRAT.GT.ZERO) GO TO 330
               END IF
  220       CONTINUE
C
C Rows with LEN entries now examined.
  230       IF (ICNTL(4).GT.0) GO TO 300
            IF (CPIV.LE.ALEN*(ALEN+1)) GO TO 310
            IF (LEN.GT.N-NORD) GO TO 300
            IJ = IFIRST(LEN)
            DO 290 IDUMMY = 1,M
               IF (IJ.EQ.0) GO TO 300
               I = IJ
               IJ = NEXTR(IJ)
               J1 = IP(I)
               J2 = J1 + LEN - 1
C If diagonal pivoting requested, look for diagonal entry.
               IF (ICNTL(7).EQ.1) THEN
                  DO 240 JJ = J1,J2
                     IF (JCN(JJ).EQ.I) GO TO 250
  240             CONTINUE
                  GO TO 290
  250             J1 = JJ
                  J2 = JJ
               END IF
C Scan row I.
               DO 280 JJ = J1,J2
                  J = JCN(JJ)
                  IF (J.GT.JLAST) GO TO 280
                  COST = ALEN*(LENC(J)-1)
                  IF (COST.GE.CPIV) GO TO 280
C Pivot has best Markowitz count so far. Now check its suitability
C     on numerical grounds by examining other entries in its column.
                  I1 = IQ(J)
                  I2 = I1 + LENC(J) - 1
                  II = IDAMAX(LENC(J),A(I1),1)
                  MAXENT = ABS(A(I1+II-1))
                  DO 260 II = I1,I2 - 1
                     IF (IRN(II).EQ.I) GO TO 270
  260             CONTINUE
  270             JPOS = II
C Exit loop if every entry in the column is below the pivot threshold.
                  IF (MAXENT.LE.CNTL(4)) GO TO 320
                  IF (ABS(A(JPOS)).LT.MAXENT*U) GO TO 280
C Candidate satisfies threshold criterion.
                  CPIV = COST
                  IPIV = I
                  JPIV = J
                  IJPOS = JPOS
                  PIVRAT = ABS(A(JPOS))/MAXENT
                  IF (CPIV.LE.ALEN*(ALEN+1)) GO TO 330
  280          CONTINUE

  290       CONTINUE
C
  300    CONTINUE
  310    IF (PIVRAT.GT.ZERO) GO TO 330
C No pivot found. Switch to full matrix processing.
         INFO(1) = INFO(1) + 2
         IF (MP.GT.0) WRITE (MP,'(A/A)')
     +       ' Warning message from MA50AD: no suitable diagonal pivot',
     +       ' found, so switched to full matrix processing.'
         GO TO 640

C Every entry in the column is below the pivot threshold.
  320    IPIV = 0
         JPIV = J

C The pivot has now been found in position (IPIV,JPIV) in location
C     IJPOS in column file or all entries of column JPIV are very small
C     (IPIV=0).
C Update row and column ordering arrays to correspond with removal
C     of the active part of the matrix. Also update NEFACT.
  330    NEFACT = NEFACT + LENC(JPIV)
         PIVBEG = IQ(JPIV)
         PIVEND = PIVBEG + LENC(JPIV) - 1
         NORD = NORD + 1
         NORD1 = NORD
         IF (NORD.EQ.JLAST) THEN
C We have ordered the first N - ICNTL(6) columns.
            NORD = NORD + NULLJ
            JLAST = N
            NULLJ = 0
         END IF
         IF (ICNTL(4).LE.0) THEN
C Remove active rows from their row ordering chains.
            DO 340 II = PIVBEG,PIVEND
               I = IRN(II)
               LR = LASTR(I)
               NR = NEXTR(I)
               IF (NR.NE.0) LASTR(NR) = LR
               IF (LR.EQ.0) THEN
                  NE1 = LENR(I)
                  IFIRST(NE1) = NR
               ELSE
                  NEXTR(LR) = NR
               END IF
  340       CONTINUE
         END IF
         IF (IPIV.GT.0) THEN
C NEPR is number of entries in strictly U part of pivot row.
            NEPR = LENR(IPIV) - 1
            NEFACT = NEFACT + NEPR
            RINFO = RINFO + CPIV*2 + LENR(IPIV)
            J1 = IP(IPIV)
C Remove active columns from their column ordering chains.
            DO 350 JJ = J1,J1 + NEPR
               J = JCN(JJ)
               LC = LASTC(J)
               NC = NEXTC(J)
               IF (NC.NE.0) LASTC(NC) = LC
               IF (LC.EQ.0) THEN
                  NE1 = LENC(J)
                  JFIRST(NE1) = NC
               ELSE
                  NEXTC(LC) = NC
               END IF
  350       CONTINUE
C Move pivot to beginning of pivot column.
            IF (PIVBEG.NE.IJPOS) THEN
               ASW = A(PIVBEG)
               A(PIVBEG) = A(IJPOS)
               A(IJPOS) = ASW
               IRN(IJPOS) = IRN(PIVBEG)
               IRN(PIVBEG) = IPIV
            END IF
         ELSE
            NEPR = 0
            NE1 = LENC(JPIV)
            IF (CNTL(3).GT.ZERO) NDROP = NDROP + NE1
            IF (NE1.GT.0) THEN
C Remove column of small entries from its column ordering chain.
               LC = LASTC(JPIV)
               NC = NEXTC(JPIV)
               IF (NC.NE.0) LASTC(NC) = LC
               IF (LC.EQ.0) THEN
                  JFIRST(NE1) = NC
               ELSE
                  NEXTC(LC) = NC
               END IF
            END IF
         END IF
C
C Set up IW array so that IW(i) holds the relative position of row i
C    entry from beginning of pivot column.
         DO 360 II = PIVBEG + 1,PIVEND
            I = IRN(II)
            IW(I) = II - PIVBEG
  360    CONTINUE
C LENPIV is length of strictly L part of pivot column.
         LENPIV = PIVEND - PIVBEG
C
C Remove pivot column (including pivot) from row oriented file.
         DO 390 II = PIVBEG,PIVEND
            I = IRN(II)
            LENR(I) = LENR(I) - 1
            J1 = IP(I)
C J2 is last position in old row.
            J2 = J1 + LENR(I)
            DO 370 JJ = J1,J2 - 1
               IF (JCN(JJ).EQ.JPIV) GO TO 380
  370       CONTINUE
  380       JCN(JJ) = JCN(J2)
            JCN(J2) = 0
  390    CONTINUE

C For each active column, add the appropriate multiple of the pivot
C     column to it.
C We loop on the number of entries in the pivot row since the position
C     of this row may change because of compresses.
         DO 600 EYE = 1,NEPR
            J = JCN(IP(IPIV)+EYE-1)
C Search column J for entry to be eliminated, calculate multiplier,
C     and remove it from column file.
C  IDROP is the number of nonzero entries dropped from column J
C        because these fall beneath tolerance level.
            IDROP = 0
            JBEG = IQ(J)
            JEND = JBEG + LENC(J) - 1
            DO 400 II = JBEG,JEND - 1
               IF (IRN(II).EQ.IPIV) GO TO 410
  400       CONTINUE
  410       AMULT = -A(II)/A(IQ(JPIV))
            A(II) = A(JEND)
            IRN(II) = IRN(JEND)
            LENC(J) = LENC(J) - 1
            IRN(JEND) = 0
            JEND = JEND - 1
C Jump if pivot column is a singleton.
            IF (LENPIV.EQ.0) GO TO 600
C Now perform necessary operations on rest of non-pivot column J.
            IOP = 0
C Innermost loop.
CDIR$ IVDEP
            DO 420 II = JBEG,JEND
               I = IRN(II)
               IF (IW(I).GT.0) THEN
C Row i is involved in the pivot column.
                  IOP = IOP + 1
                  PIVCOL = IQ(JPIV) + IW(I)
C Flag IW(I) to show that the operation has been done.
                  IW(I) = -IW(I)
                  A(II) = A(II) + AMULT*A(PIVCOL)
               END IF
  420       CONTINUE

            IF (CNTL(3).GT.ZERO) THEN
C  Run through non-pivot column compressing column so that entries less
C      than CNTL(3) are not stored. All entries less than CNTL(3) are
C      also removed from the row structure.
               JNEW = JBEG
               DO 450 II = JBEG,JEND
                  IF (ABS(A(II)).GE.CNTL(3)) THEN
                     A(JNEW) = A(II)
                     IRN(JNEW) = IRN(II)
                     JNEW = JNEW + 1
                  ELSE
C  Remove non-zero entry from row structure.
                     I = IRN(II)
                     J1 = IP(I)
                     J2 = J1 + LENR(I) - 1
                     DO 430 JJ = J1,J2 - 1
                        IF (JCN(JJ).EQ.J) GO TO 440
  430                CONTINUE
  440                JCN(JJ) = JCN(J2)
                     JCN(J2) = 0
                     LENR(I) = LENR(I) - 1
                  END IF
  450          CONTINUE
               DO 460 II = JNEW,JEND
                  IRN(II) = 0
  460          CONTINUE
               IDROP = JEND + 1 - JNEW
               JEND = JNEW - 1
               LENC(J) = LENC(J) - IDROP
               NERED = NERED - IDROP
               INFO(6) = INFO(6) + IDROP
            END IF

C IFILL is fill-in left to do to non-pivot column J.
            IFILL = LENPIV - IOP
            NERED = NERED + IFILL
            INFO(3) = MAX(INFO(3),NERED+LENC(J))

C Treat no-fill case
            IF (IFILL.EQ.0) THEN
CDIR$ IVDEP
               DO 470 II = PIVBEG + 1,PIVEND
                  I = IRN(II)
                  IW(I) = -IW(I)
  470          CONTINUE
               GO TO 600
            END IF

C See if there is room for fill-in at end of the column.
            DO 480 IPOS = JEND + 1,MIN(JEND+IFILL,DISPC-1)
               IF (IRN(IPOS).NE.0) GO TO 490
  480       CONTINUE
            IF (IPOS.EQ.JEND+IFILL+1) GO TO 540
            IF (JEND+IFILL+1.LE.LA+1) THEN
               DISPC = JEND + IFILL + 1
               GO TO 540
            END IF
            IPOS = LA
            DISPC = LA + 1
C JMORE more spaces for fill-in are required.
  490       JMORE = JEND + IFILL - IPOS + 1
C We now look in front of the column to see if there is space for
C     the rest of the fill-in.
            DO 500 IPOS = JBEG - 1,MAX(JBEG-JMORE,1),-1
               IF (IRN(IPOS).NE.0) GO TO 510
  500       CONTINUE
            IPOS = IPOS + 1
            IF (IPOS.EQ.JBEG-JMORE) GO TO 520
C Column must be moved to the beginning of available storage.
  510       IF (DISPC+LENC(J)+IFILL.GT.LA+1) THEN
               INFO(2) = INFO(2) + 1
               CALL MA50DD(LA,A,IRN,IQ,N,DISPC,.TRUE.)
               JBEG = IQ(J)
               JEND = JBEG + LENC(J) - 1
               PIVBEG = IQ(JPIV)
               PIVEND = PIVBEG + LENC(JPIV) - 1
               IF (DISPC+LENC(J)+IFILL.GT.LA+1) GO TO 710
            END IF
            IPOS = DISPC
            DISPC = DISPC + LENC(J) + IFILL
C Move non-pivot column J.
  520       IQ(J) = IPOS
            DO 530 II = JBEG,JEND
               A(IPOS) = A(II)
               IRN(IPOS) = IRN(II)
               IPOS = IPOS + 1
               IRN(II) = 0
  530       CONTINUE
            JBEG = IQ(J)
            JEND = IPOS - 1
C Innermost fill-in loop which also resets IW.
C We know at this stage that there are IFILL positions free after JEND.
  540       IDROP = 0
            DO 580 II = PIVBEG + 1,PIVEND
               I = IRN(II)
               INFO(3) = MAX(INFO(3),NERED+LENR(I)+1)
               IF (IW(I).LT.0) THEN
                  IW(I) = -IW(I)
                  GO TO 580
               END IF
               ANEW = AMULT*A(II)
               IF (ABS(ANEW).LT.CNTL(3)) THEN
                  IDROP = IDROP + 1
               ELSE
                  JEND = JEND + 1
                  A(JEND) = ANEW
                  IRN(JEND) = I

C Put new entry in row file.
                  IEND = IP(I) + LENR(I)
                  IF (IEND.LT.DISPR) THEN
                     IF (JCN(IEND).EQ.0) GO TO 560
                  ELSE
                     IF (DISPR.LE.LA) THEN
                        DISPR = DISPR + 1
                        GO TO 560
                     END IF
                  END IF
                  IF (IP(I).GT.1) THEN
                     IF (JCN(IP(I)-1).EQ.0) THEN
C Put new entry at front.
                        IP(I) = IP(I) - 1
                        JCN(IP(I)) = J
                        GO TO 570
                     END IF
                  END IF
                  IF (DISPR+LENR(I).GT.LA) THEN
C Compress.
                     INFO(2) = INFO(2) + 1
                     CALL MA50DD(LA,A,JCN,IP,M,DISPR,.FALSE.)
                     IF (DISPR+LENR(I).GT.LA) GO TO 710
                  END IF
C Copy row to first free position.
                  J1 = IP(I)
                  J2 = IP(I) + LENR(I) - 1
                  IP(I) = DISPR
                  DO 550 JJ = J1,J2
                     JCN(DISPR) = JCN(JJ)
                     JCN(JJ) = 0
                     DISPR = DISPR + 1
  550             CONTINUE
                  IEND = DISPR
                  DISPR = IEND + 1
  560             JCN(IEND) = J
  570             LENR(I) = LENR(I) + 1
C End of adjustment to row file.
               END IF
  580       CONTINUE
            INFO(6) = INFO(6) + IDROP
            NERED = NERED - IDROP
            DO 590 II = 1,IDROP
               IRN(JEND+II) = 0
  590       CONTINUE
            LENC(J) = LENC(J) + IFILL - IDROP
C End of scan of pivot row.
  600    CONTINUE


C Remove pivot row from row oriented storage and update column
C     ordering arrays.  Remember that pivot row no longer includes
C     pivot.
         DO 610 EYE = 1,NEPR
            JJ = IP(IPIV) + EYE - 1
            J = JCN(JJ)
            JCN(JJ) = 0
            NE1 = LENC(J)
            LASTC(J) = 0
            IF (NE1.GT.0) THEN
               IFIR = JFIRST(NE1)
               JFIRST(NE1) = J
               NEXTC(J) = IFIR
               IF (IFIR.NE.0) LASTC(IFIR) = J
               MINC = MIN(MINC,NE1)
            ELSE IF (ICNTL(7).NE.2) THEN
               IF (INFO(6).EQ.0) NULLC = NULLC + 1
               IF (J.LE.JLAST) THEN
                  NORD = NORD + 1
                  IQ(J) = -NORD
                  IF (NORD.EQ.JLAST) THEN
C We have ordered the first N - ICNTL(6) columns.
                     NORD = NORD + NULLJ
                     JLAST = N
                     NULLJ = 0
                  END IF
               ELSE
                  NULLJ = NULLJ + 1
                  IQ(J) = - (JLAST+NULLJ)
               END IF
            END IF
  610    CONTINUE
         NERED = NERED - NEPR

C Restore IW and remove pivot column from column file.
C    Record the row permutation in IP(IPIV) and the column
C    permutation in IQ(JPIV), flagging them negative so that they
C    are not confused with real pointers in compress routine.
         IF (IPIV.NE.0) THEN
            LENR(IPIV) = 0
            IW(IPIV) = 0
            IRN(PIVBEG) = 0
            MORD = MORD + 1
            PIVBEG = PIVBEG + 1
            IP(IPIV) = -MORD
         END IF
         NERED = NERED - LENPIV - 1
         DO 620 II = PIVBEG,PIVEND
            I = IRN(II)
            IW(I) = 0
            IRN(II) = 0
            NE1 = LENR(I)
            IF (NE1.EQ.0) THEN
               IF (INFO(6).EQ.0) NULLR = NULLR + 1
               IP(I) = -M + NULLI
               NULLI = NULLI + 1
            ELSE IF (ICNTL(4).LE.0) THEN
C Adjust row ordering arrays.
               IFIR = IFIRST(NE1)
               LASTR(I) = 0
               NEXTR(I) = IFIR
               IFIRST(NE1) = I
               IF (IFIR.NE.0) LASTR(IFIR) = I
               MINC = MIN(MINC,NE1)
            END IF
  620    CONTINUE
         IQ(JPIV) = -NORD1
  630 CONTINUE
C We may drop through this loop with NULLI nonzero.

C ********************************************
C ****    End of main elimination loop    ****
C ********************************************

C Complete the permutation vectors
  640 INFO(5) = MORD + MIN(M-MORD-NULLI,N-NORD-NULLJ)
      DO 650 L = 1,MIN(M-MORD,N-NORD)
         RINFO = RINFO + M - MORD - L + 1 + REAL(M-MORD-L)*(N-NORD-L)*2
  650 CONTINUE
      NP = NORD
      INFO(4) = 2 + NEFACT + M*2 + MAX(N-NORD+M-MORD,
     +          (N-NORD)*(M-MORD))
      INFO(6) = INFO(6) + NDROP
      INFO(7) = M - MORD
      DO 660 L = 1,M
         IF (IP(L).LT.0) THEN
            IP(L) = -IP(L)
         ELSE
            MORD = MORD + 1
            IP(L) = MORD
         END IF
  660 CONTINUE
      DO 670 L = 1,N
         IF (IQ(L).LT.0) THEN
            LASTC(L) = -IQ(L)
         ELSE
            IF (NORD.EQ.JLAST) NORD = NORD + NULLJ
            NORD = NORD + 1
            LASTC(L) = NORD
         END IF
  670 CONTINUE
C Store the inverse permutation
      DO 680 L = 1,N
         IQ(LASTC(L)) = L
  680 CONTINUE

C Test for rank deficiency
      IF (INFO(5).LT.MIN(M,N)) INFO(1) = INFO(1) + 1

      IF (MP.GT.0 .AND. ICNTL(3).GT.2) THEN
         WRITE (MP,'(A,I6,A,F12.1/A,7I8)') ' Leaving MA50AD with NP =',
     +     NP,' RINFO =',RINFO,' INFO =',INFO
         IF (ICNTL(3).GT.3) THEN
            WRITE (MP,'(A,(T6,10(I7)))') ' IP = ',IP
            WRITE (MP,'(A,(T6,10(I7)))') ' IQ = ',IQ
         END IF
      END IF

      GO TO 750

C Error conditions.
  690 INFO(1) = -1
      IF (LP.GT.0) WRITE (LP,'(/A/(2(A,I8)))')
     +    ' **** Error return from MA50AD ****',' M =',M,' N =',N
      GO TO 750
  700 INFO(1) = -2
      IF (LP.GT.0) WRITE (LP,'(/A/(A,I10))')
     +    ' **** Error return from MA50AD ****',' NE =',NE
      GO TO 750
  710 INFO(1) = -3
      IF (LP.GT.0) WRITE (LP,'(/A/A,I9,A,I9)')
     +    ' **** Error return from MA50AD ****',
     +    ' LA  must be increased from',LA,' to at least',INFO(3)
      GO TO 750
  720 INFO(1) = -4
      IF (LP.GT.0) WRITE (LP,'(/A/(3(A,I9)))')
     +    ' **** Error return from MA50AD ****',' Entry in row',I,
     +    ' and column',J,' duplicated'
      GO TO 750
  730 INFO(1) = -5
      IF (LP.GT.0) WRITE (LP,'(/A/(3(A,I9)))')
     +    ' **** Error return from MA50AD ****',' Fault in component ',
     +    PIVOT,' of column permutation given in IFIRST'
      GO TO 750
  740 INFO(1) = -6
      IF (LP.GT.0) WRITE (LP,'(/A/(3(A,I9)))')
     +    ' **** Error return from MA50AD ****',' ICNTL(4) = ',ICNTL(4),
     +    ' when ICNTL(6) = 2'
  750 END


      SUBROUTINE MA50BD(M,N,NE,JOB,AA,IRNA,IPTRA,CNTL,ICNTL,IP,IQ,NP,
     +                  LFACT,FACT,IRNF,IPTRL,IPTRU,W,IW,INFO,RINFO)
C MA50B/BD factorizes the matrix in AA/IRNA/IPTRA as P L U Q where
C     P and Q are permutations, L is lower triangular, and U is unit
C     upper triangular. The prior information that it uses depends on
C     the value of the parameter JOB.
C
      INTEGER M,N,NE,JOB
      DOUBLE PRECISION AA(NE)
      INTEGER IRNA(NE),IPTRA(N)
      DOUBLE PRECISION CNTL(4)
      INTEGER ICNTL(7),IP(M),IQ(N),NP,LFACT
      DOUBLE PRECISION FACT(LFACT)
      INTEGER IRNF(LFACT),IPTRL(N),IPTRU(N)
      DOUBLE PRECISION W(M)
      INTEGER IW(M+2*N),INFO(7)
      DOUBLE PRECISION RINFO
C
C M is an integer variable that must be set to the number of rows.
C      It is not altered by the subroutine.
C N is an integer variable that must be set to the number of columns.
C      It is not altered by the subroutine.
C NE is an integer variable that must be set to the number of entries
C      in the input matrix.  It is not altered by the subroutine.
C JOB is an integer variable that must be set to the value 1, 2, or 3.
C     If JOB is equal to 1 and any of the first NP recommended pivots
C      fails to satisfy the threshold pivot tolerance, the row is
C      interchanged with the earliest row in the recommended sequence
C      that does satisfy the tolerance. Normal row interchanges are
C      performed in the last N-NP columns.
C     If JOB is equal to 2, then M, N, NE, IRNA, IPTRA, IP, IQ,
C      LFACT, NP, IRNF, IPTRL, and IPTRU must be unchanged since a
C      JOB=1 entry for the same matrix pattern and no interchanges are
C      performed among the first NP pivots; if ICNTL(6) > 0, the first
C      N-ICNTL(6) columns of AA must also be unchanged.
C     If JOB is equal to 3, ICNTL(6) must be in the range 1 to N-1.
C      The effect is as for JOB=2 except that interchanges are
C      performed.
C     JOB is not altered by the subroutine.
C AA is an array that holds the entries of the matrix and
C      is not altered.
C IRNA is an integer array of length NE that must be set to hold the
C      row indices of the corresponding entries in AA. It is not
C      altered.
C IPTRA is an integer array that holds the positions of the starts of
C      the columns of AA. It is not altered by the subroutine.
C CNTL  must be set by the user as follows and is not altered.
C     CNTL(2) determines the balance between pivoting for sparsity and
C       for stability, values near zero emphasizing sparsity and values
C       near one emphasizing stability.
C     CNTL(3) If this is set to a positive value, any entry whose
C       modulus is less than CNTL(3) will be dropped from the factors.
C       The factorization will then require less storage but will be
C       inaccurate.
C     CNTL(4)  Any entry of the reduced matrix whose modulus is less
C       than or equal to CNTL(4) will be regarded as zero from the
C        point of view of rank.
C ICNTL must be set by the user as follows and is not altered.
C     ICNTL(1)  must be set to the stream number for error messages.
C       A value less than 1 suppresses output.
C     ICNTL(2) must be set to the stream number for diagnostic output.
C       A value less than 1 suppresses output.
C     ICNTL(3) must be set to control the amount of output:
C       0 None.
C       1 Error messages only.
C       2 Error and warning messages.
C       3 As 2, plus scalar parameters and a few entries of array
C         parameters on entry and exit.
C       4 As 2, plus all parameters on entry and exit.
C     ICNTL(5) The block size to be used for full-matrix processing.
C       If <=0, the BLAS1 version is used.
C       If =1, the BLAS2 version is used.
C     ICNTL(6) If N > ICNTL(6) > 0, only the columns of A that
C       correspond to the last ICNTL(6) columns of the permuted matrix
C       may change prior to an entry with JOB > 1.
C IP is an integer array. If JOB=1, it must be set so that IP(I) < IP(J)
C      if row I is recommended to precede row J in the pivot sequence.
C      If JOB>1, it need not be set. If JOB=1 or JOB=3, IP(I) is set
C      to -K when row I is chosen for pivot K and IP is eventually
C      reset to recommend the chosen pivot sequence to a subsequent
C      JOB=1 entry. If JOB=2, IP is not be referenced.
C IQ is an integer array that must be set so that either IQ(J) is the
C      column in position J in the pivot sequence, J=1,2,...,N,
C      or IQ(1)=0 and the columns are taken in natural order.
C      It is not altered by the subroutine.
C NP is an integer variable that holds the number of columns to be
C      processed in packed storage. It is not altered by the subroutine.
C LFACT is an integer variable set to the size of FACT and IRNF.
C      It is not altered by the subroutine.
C FACT is an array that need not be set on a JOB=1 entry and must be
C      unchanged since the previous entry if JOB>1. On return, FACT(1)
C      holds the value of CNTL(3) used, FACT(2) will holds the value
C      of CNTL(4) used, FACT(3:IPTRL(N)) holds the packed part of L/U
C      by columns, and the full part of L/U is held by columns
C      immediately afterwards. U has unit diagonal entries, which are
C      not stored. In each column of the packed part, the entries of
C      U precede the entries of L; also the diagonal entries of L
C      head each column of L and are reciprocated.
C IRNF is an integer array of length LFACT that need not be set on
C      a JOB=1 entry and must be unchanged since the previous entry
C      if JOB>1. On exit, IRNF(1) holds the number of dropped entries,
C      IRNF(2) holds the number of rows MF in full storage,
C      IRNF(3:IPTRL(N)) holds the row numbers of the packed part
C      of L/U, IRNF(IPTRL(N)+1:IPTRL(N)+MF) holds the row indices
C      of the full part of L/U, and IRNF(IPTRL(N)+MF+I), I=1,2,..,N-NP
C      holds the vector IPIV output by MA50GD.
C      If JOB=2, IRNF will be unaltered.
C IPTRL is an integer array that need not be set on a JOB=1 entry and
C     must be unchanged since the previous entry if JOB>1.
C     For J = 1,..., NP, IPTRL(J) holds the position in
C     FACT and IRNF of the end of column J of L.
C     For J = NP+1,..., N, IPTRL(J) is equal to IPTRU(J).
C IPTRU is an integer array that need not be set on a JOB=1 entry and
C     must be unchanged since the previous entry if JOB>1.
C     For J = 1,..., N, IPTRU(J) holds the position in
C     FACT and IRNF of the end of the packed part of column J of U.
C W is an array of length M used as workspace for holding
C      the expanded form of a sparse vector.
C IW is an integer array of length M+2*N used as workspace.
C INFO need not be set on entry. On exit, it holds the following:
C    INFO(1) A negative value will indicate an error return and a
C       positive value a warning. Possible nonzero values are:
C      -1  M < 1 or N < 1.
C      -2  NE < 0.
C      -3  Insufficient space.
C      -4  There are duplicated entries.
C      -5  JOB < 1, 3 when ICNTL(6)=0, or > 3.
C      -6  JOB = 2, but entries were dropped in the corresponding JOB=1
C          entry.
C      -7  NP < 0 or NP > N.
C     -(7+K) Pivot too small in column K when JOB=2.
C      +1  Rank deficient.
C    INFO(4) Minimum storage required to factorize matrix (or
C            recommended value for LFACT if INFO(1) = -3.
C    INFO(5) Computed rank of the matrix.
C    INFO(6) Number of entries dropped from the data structure.
C    INFO(7) Number of rows processed in full storage.
C RINFO need not be set on entry. On exit, it holds the number of
C    floating-point operations performed.

      DOUBLE PRECISION ZERO,ONE
      PARAMETER (ZERO=0D0,ONE=1.0D0)
      DOUBLE PRECISION AMULT,ASW
      INTEGER BEGCOL
      LOGICAL DROP
      INTEGER ENDCOL,EYE,EYE1,I,IA1,IA2,IF1,IF2,II,IL1,IL2,IPIV,IQPIV,
     +        IU1,IU2,ISW,J,JDUMMY,JJ,JLAST,K,LP
      DOUBLE PRECISION MAXENT
      INTEGER MF,MORD,MP,NEU,NF,NULLC
      DOUBLE PRECISION PIVLIM
      INTEGER RANK
      DOUBLE PRECISION U
C AMULT Temporary variable used to store current multiplier.
C ASW Temporary variable used when swopping two real quantities.
C BEGCOL is pointer to beginning of section of column when pruning.
C DROP True if any entries dropped from current column.
C ENDCOL is pointer to end of section of column when pruning.
C EYE Running position for current column.
C EYE1 Position of the start of second current column.
C I Temporary variable holding row number. Also used as index in DO
C     loops used in initialization of arrays.
C IA1 Position of the start of the current column in AA.
C IA2 Position of the end of the current column in AA.
C IF1 Position of the start of the full submatrix.
C IF2 Position of the end of the full submatrix.
C II Running position for current column.
C IL1 Position of the first entry of the current column of L.
C IL2 Position of the last entry of the current column of L.
C IPIV Position of the pivot in FACT and IRNF.
C IQPIV Recommended position of the pivot row in the pivot sequence.
C IU1 Position of the start of current column of U.
C IU2 Position of the end of the current column of U.
C ISW Temporary variable used when swopping two integer quantities.
C J Temporary variable holding column number.
C JDUMMY DO index not referenced in the loop.
C JJ Running position for current column.
C JLAST The lesser of NP and the last column of A for which no new
C     factorization operations are needed.
C K Temporary variable holding the current pivot step in the elimination
C LP Unit for error messages.
C MAXENT Temporary variable used to hold value of largest entry in
C    column.
C MF Number of rows in full block.
C MORD Number of rows ordered.
C MP Unit for diagnostic messages.
C NEU Number of entries omitted from U and the full block in order to
C    calculate INFO(4) (0 unless INFO(1)=-3).
C NF Number of columns in full block.
C NULLC Number of columns found null before dropping any elements.
C PIVLIM Limit on pivot size.
C RANK Value returned by MA50E/ED or MA50F/FD
C U Used to hold local copy of CNTL(2), changed if necessary so that it
C    is in range.
C
      EXTERNAL MA50ED,MA50FD,MA50GD
      INTRINSIC ABS,MAX,MIN
C LAPACK subroutine for triangular factorization.

      INFO(1) = 0
      INFO(4) = 0
      INFO(5) = 0
      INFO(6) = 0
      INFO(7) = 0
      RINFO = ZERO
      LP = ICNTL(1)
      MP = ICNTL(2)
      IF (ICNTL(3).LE.0) LP = 0
      IF (ICNTL(3).LE.1) MP = 0

C Check input values
      IF (M.LT.1 .OR. N.LT.1) THEN
         INFO(1) = -1
         IF (LP.GT.0) WRITE (LP,'(/A/A,I8,A,I8)')
     +       ' **** Error return from MA50BD ****',' M =',M,' N =',N
         GO TO 550
      END IF
      IF (NE.LE.0) THEN
         INFO(1) = -2
         IF (LP.GT.0) WRITE (LP,'(/A/A,I6)')
     +       ' **** Error return from MA50BD ****',' NE =',NE
         GO TO 550
      END IF
      IF (NP.LT.0 .OR. NP.GT.N) THEN
         INFO(1) = -7
         IF (LP.GT.0) WRITE (LP,'(/A/A,I8,A,I8)')
     +       ' **** Error return from MA50BD ****',' NP =',NP,' N =',N
         GO TO 550
      END IF
      IF (LFACT.LT.MAX(M,NE+2)) THEN
         INFO(4) = MAX(M,NE+2)
         GO TO 520
      END IF
      IF (JOB.EQ.1) THEN
      ELSE IF (JOB.EQ.2 .OR. JOB.EQ.3) THEN
         IF (IRNF(1).NE.0) THEN
            INFO(1) = -6
            IF (LP.GT.0) WRITE (LP,'(/A/A,I1,A)')
     +          ' **** Error return from MA50BD ***',' Call with JOB=',
     +          JOB,' follows JOB=1 call in which entries were dropped'
            GO TO 550
         END IF
      ELSE
         INFO(1) = -5
         IF (LP.GT.0) WRITE (LP,'(/A/A,I2)')
     +       ' **** Error return from MA50BD ****',' JOB =',JOB
         GO TO 550
      END IF

C Print input data
      IF (MP.GT.0) THEN
         IF (ICNTL(3).GT.2) WRITE (MP,
     +       '(/2(A,I6),A,I8,A,I3/A,I8,A,I7/A,1P,4E10.2/A,7I8)')
     +       ' Entering MA50BD with M =',M,' N =',N,' NE =',NE,' JOB =',
     +       JOB,' LFACT =',LFACT,' NP =',NP,' CNTL =',CNTL,' ICNTL =',
     +       ICNTL
         IF (ICNTL(3).GT.3) THEN
            WRITE (MP,'(A,(T6,10(I7)))') ' IP = ',IP
            IF (IQ(1).GT.0) THEN
               WRITE (MP,'(A,(T6,10(I7)))') ' IQ = ',IQ
            ELSE
               WRITE (MP,'(A,(T6,I7))') ' IQ = ',IQ(1)
            END IF
            DO 10 J = 1,N - 1
               IF (IPTRA(J).LT.IPTRA(J+1)) WRITE (MP,
     +             '(A,I5,(T13,3(1P,E12.4,I5)))') ' Column',J,
     +             (AA(II),IRNA(II),II=IPTRA(J),IPTRA(J+1)-1)
   10       CONTINUE
            IF (IPTRA(N).LE.NE) WRITE (MP,
     +          '(A,I5,(T13,3(1P,E12.4,I5)))') ' Column',N,
     +          (AA(II),IRNA(II),II=IPTRA(N),NE)
         END IF
      END IF

C Initializations.
      JLAST = 0
      NULLC = 0
      IF (JOB.GT.1 .AND. ICNTL(6).GT.0 .AND.
     +    ICNTL(6).LT.N) JLAST = MIN(NP,N-ICNTL(6))

      U = MIN(CNTL(2),ONE)
      U = MAX(U,ZERO)
      DO 20 I = 1,M
         IW(I+N) = 0
         W(I) = ZERO
   20 CONTINUE
      MORD = 0
      IF1 = LFACT + 1
      IF2 = 0
      NF = N - NP
      MF = 0
      IL2 = 2
      IF (JLAST.GT.0) IL2 = IPTRL(JLAST)
      NEU = 0

C Jump if JOB is equal to 2.
      IF (JOB.EQ.2) GO TO 370

      IF (JOB.EQ.3) THEN
C Reconstruct IP and set MORD
         DO 30 J = 1,NP
            IA1 = IPTRU(J) + 1
            IF (IA1.GT.IPTRL(J)) GO TO 30
            IF (J.LE.JLAST) THEN
               MORD = MORD + 1
               IP(IRNF(IA1)) = -J
            ELSE
               IP(IRNF(IA1)) = J
            END IF
   30    CONTINUE
         MF = IRNF(2)
         IA1 = IPTRL(N)
         DO 40 J = 1,MF
            IP(IRNF(IA1+J)) = NP + J
   40    CONTINUE
      END IF

C Store copies of column ends ready for pruning
      DO 50 K = 1,JLAST
         IW(M+N+K) = IPTRL(K)
   50 CONTINUE

C Each pass through this main loop processes column K.
      DO 310 K = JLAST + 1,N
         DROP = .FALSE.
         IF (K.EQ.NP+1) THEN
C Set up data structure for full part.
            MF = M - MORD
            IF1 = LFACT + 1 - MF
            II = 0
            DO 60 I = 1,M
               IF (IP(I).GT.0) THEN
                  IW(I+N) = N
                  IRNF(IF1+II) = I
                  II = II + 1
                  IP(I) = NP + II
               END IF
   60       CONTINUE
            IF1 = LFACT + 1 - MAX(MF*NF,MF+NF)
            IF2 = IF1 - 1 + MF*MAX(0,JLAST-NP)
         END IF
         J = K
         IF (IQ(1).GT.0) J = IQ(K)
         IA1 = IPTRA(J)
         IA2 = NE
         IF (J.NE.N) IA2 = IPTRA(J+1) - 1
         IU1 = IL2 + 1
         IU2 = IU1 - 1
         IL1 = IF1 - 1 + IA1 - IA2
         IL2 = IL1 - 1
         INFO(4) = MAX(INFO(4),NEU+LFACT-IL1+IU2+M+1)
         IF (IL1-IU2.LE.M) THEN
            IF (INFO(1).NE.-3) THEN
C Get rid of U info.
               INFO(1) = -3
               NEU = IL2 + LFACT + 1 - MF - IF1
               IF1 = LFACT + 1 - MF
               IF2 = IF1 - 1
               IL2 = 0
               EYE = 0
               DO 80 J = 1,MIN(K-1,NP)
                  IU2 = IPTRU(J)
                  IPTRU(J) = EYE
                  IL2 = IPTRL(J)
                  NEU = NEU + IU2 - IL2
                  DO 70 II = IU2 + 1,IL2
                     EYE = EYE + 1
                     IRNF(EYE) = IRNF(II)
                     FACT(EYE) = FACT(II)
   70             CONTINUE
                  IPTRL(J) = EYE
                  IW(M+N+J) = EYE
   80          CONTINUE
               IU1 = EYE + 1
               IU2 = EYE
               IL1 = IF1 - 1 + IA1 - IA2
               IL2 = IL1 - 1
            END IF
C Quit if LFACT is much too small
            IF (IL1-IU2.LE.M) GO TO 480
         END IF
C Load column K of AA into full vector W and into the back of IRNF.
C Check for duplicates.
         EYE = IL1
         DO 90 II = IA1,IA2
            I = IRNA(II)
            IF (IW(I+N).EQ.-1) GO TO 540
            IW(I+N) = -1
            W(I) = AA(II)
            IRNF(EYE) = I
            EYE = EYE + 1
   90    CONTINUE
C Depth first search to find topological order for triangular solve
C     and structure of column K of L/U
C IW(J) is used to hold a pointer to next entry in column J
C     during the depth-first search at stage K, J = 1,..., N.
C IW(I+N) is set to K when row I has been processed, and to N for rows
C     of the full part once column NP has been passed. It is also
C     used for backtracking, a negative value being used to point to the
C     previous row in the chain.
C IW(M+N+I) is set to the position in FACT and IRNF of the end of the
C     active part of the column after pruning.  It is initially set to
C     IPTRL(I) and is flagged negative when column has been pruned.
C Set IPTRL temporarily for column K so that special code is
C     not required to process this column.
         IPTRL(K) = EYE - 1
         IW(M+N+K) = EYE - 1
C IW(K) is set to beginning of original column K.
         IW(K) = IL1
         J = K
C The outer loop of the depth-first search is executed once for column
C      K and twice for each entry in the upper-triangular part of column
C      K (once to initiate a search in the corresponding column and
C      once when the search in the column is finished).
         DO 120 JDUMMY = 1,2*K
C Look through column J of L (or column K of A). All the entries
C     are entries of the filled-in column K. Store new entries of the
C     lower triangle and continue until reaching an entry of the upper
C     triangle.
            DO 100 II = IW(J),ABS(IW(M+N+J))
               I = IRNF(II)
C Jump if index I already encountered in column K or is in full part.
               IF (IW(I+N).GE.K) GO TO 100
               IF (IP(I).LE.0) GO TO 110
C Entry is in lower triangle. Flag it and store it in L.
               IW(I+N) = K
               IL1 = IL1 - 1
               IRNF(IL1) = I
  100       CONTINUE
            IF (J.EQ.K) GO TO 130
C Flag J, put its row index into U, and backtrack
            IU2 = IU2 + 1
            I = IRNF(IPTRU(J)+1)
            IRNF(IU2) = I
            J = -IW(I+N)
            IW(I+N) = K
            GO TO 120
C Entry in upper triangle.  Move search to corresponding column.
  110       IW(I+N) = -J
            IW(J) = II + 1
            J = -IP(I)
            IW(J) = IPTRU(J) + 2
  120    CONTINUE
C Run through column K of U in the lexicographical order that was just
C     constructed, performing elimination operations.
  130    DO 150 II = IU2,IU1,-1
            I = IRNF(II)
            J = -IP(I)
C Add multiple of column J of L to column K
            EYE1 = IPTRU(J) + 1
            IF (ABS(W(I)).LT.CNTL(3)) GO TO 150
            AMULT = -W(I)*FACT(EYE1)
C Note we are storing negative multipliers
            W(I) = AMULT
            DO 140 EYE = EYE1 + 1,IPTRL(J)
               I = IRNF(EYE)
               W(I) = W(I) + AMULT*FACT(EYE)
  140       CONTINUE
            RINFO = RINFO + ONE + 2*(IPTRL(J)-EYE1)
  150    CONTINUE

C Unload reals of column of U and set pointer
         IF (CNTL(3).GT.ZERO) THEN
            EYE = IU1
            DO 160 II = IU1,IU2
               I = IRNF(II)
               IF (ABS(W(I)).LT.CNTL(3)) THEN
                  INFO(6) = INFO(6) + 1
               ELSE
                  IRNF(EYE) = -IP(I)
                  FACT(EYE) = W(I)
                  EYE = EYE + 1
               END IF
               W(I) = ZERO
  160       CONTINUE
            IU2 = EYE - 1
         ELSE
            DO 170 II = IU1,IU2
               I = IRNF(II)
               IRNF(II) = -IP(I)
               FACT(II) = W(I)
               W(I) = ZERO
  170       CONTINUE
         END IF
         IF (INFO(1).EQ.-3) THEN
            NEU = NEU + IU2 - IU1 + 1
            IU2 = IU1 - 1
         END IF
         IPTRU(K) = IU2
         IF (K.LE.NP) THEN
C Find the largest entry in the column and drop any small entries
            MAXENT = ZERO
            IF (CNTL(3).GT.ZERO) THEN
               EYE = IL1
               DO 180 II = IL1,IL2
                  I = IRNF(II)
                  IF (ABS(W(I)).LT.CNTL(3)) THEN
                     INFO(6) = INFO(6) + 1
                     W(I) = ZERO
                     DROP = .TRUE.
                  ELSE
                     IRNF(EYE) = I
                     EYE = EYE + 1
                     MAXENT = MAX(ABS(W(I)),MAXENT)
                  END IF
  180          CONTINUE
               IL2 = EYE - 1
            ELSE
               DO 190 II = IL1,IL2
                  MAXENT = MAX(ABS(W(IRNF(II))),MAXENT)
  190          CONTINUE
            END IF
C Unload column of L, performing pivoting and moving indexing
C      information.
            PIVLIM = U*MAXENT
            EYE = IU2
            IQPIV = M + N
            IF (IL1.GT.IL2) NULLC = NULLC + 1
            DO 200 II = IL1,IL2
               I = IRNF(II)
               EYE = EYE + 1
               IRNF(EYE) = I
               FACT(EYE) = W(I)
               W(I) = ZERO
C Find position of pivot
               IF (ABS(FACT(EYE)).GE.PIVLIM) THEN
                  IF (ABS(FACT(EYE)).GT.CNTL(4)) THEN
                     IF (IP(I).LT.IQPIV) THEN
                        IQPIV = IP(I)
                        IPIV = EYE
                     END IF
                  END IF
               END IF
  200       CONTINUE
            IL1 = IU2 + 1
            IL2 = EYE
            IF (IL1.LE.IL2) THEN
C Column is not null
               IF (IQPIV.EQ.M+N) THEN
C All entries in the column are too small to be pivotal. Drop them all.
                  IF (CNTL(3).GT.ZERO) INFO(6) = INFO(6) + EYE - IU2
                  IL2 = IU2
               ELSE
                  IF (IL1.NE.IPIV) THEN
C Move pivot to front of L
                     ASW = FACT(IPIV)
                     FACT(IPIV) = FACT(IL1)
                     FACT(IL1) = ASW
                     ISW = IRNF(IL1)
                     IRNF(IL1) = IRNF(IPIV)
                     IRNF(IPIV) = ISW
                  END IF
C Reciprocate pivot
                  INFO(5) = INFO(5) + 1
                  FACT(IL1) = ONE/FACT(IL1)
                  RINFO = RINFO + ONE
C Record pivot row
                  MORD = MORD + 1
                  IP(IRNF(IL1)) = -K
               END IF
            END IF
         ELSE
C Treat column as full
            IL2 = IPTRU(K)
CDIR$ IVDEP
            DO 210 II = LFACT - MF + 1,LFACT
               I = IRNF(II)
               IF2 = IF2 + 1
               FACT(IF2) = W(I)
               W(I) = ZERO
  210       CONTINUE
            IF (INFO(1).EQ.-3) IF2 = IF2 - MF
         END IF
         IW(M+N+K) = IL2
         IPTRL(K) = IL2
         IF (DROP) GO TO 310
C Scan columns involved in update of column K and remove trailing block.
         DO 300 II = IU1,IU2
            I = IRNF(II)
C Jump if column already pruned.
            IF (IW(M+N+I).LT.0) GO TO 300
            BEGCOL = IPTRU(I) + 2
            ENDCOL = IPTRL(I)
C Scan column to see if there is an entry in the current pivot row.
            IF (K.LE.NP) THEN
               DO 220 JJ = BEGCOL,ENDCOL
                  IF (IP(IRNF(JJ)).EQ.-K) GO TO 230
  220          CONTINUE
               GO TO 300
            END IF
C Sort the entries so that those in rows already pivoted (negative IP
C    values) precede the rest.
  230       DO 280 JDUMMY = BEGCOL,ENDCOL
               JJ = BEGCOL
               DO 240 BEGCOL = JJ,ENDCOL
                  IF (IP(IRNF(BEGCOL)).GT.0) GO TO 250
  240          CONTINUE
               GO TO 290
  250          JJ = ENDCOL
               DO 260 ENDCOL = JJ,BEGCOL,-1
                  IF (IP(IRNF(ENDCOL)).LT.0) GO TO 270
  260          CONTINUE
               GO TO 290
  270          ASW = FACT(BEGCOL)
               FACT(BEGCOL) = FACT(ENDCOL)
               FACT(ENDCOL) = ASW
               J = IRNF(BEGCOL)
               IRNF(BEGCOL) = IRNF(ENDCOL)
               IRNF(ENDCOL) = J
               BEGCOL = BEGCOL + 1
               ENDCOL = ENDCOL - 1
  280       CONTINUE
  290       IW(M+N+I) = -ENDCOL
  300    CONTINUE
  310 CONTINUE
      IF (N.EQ.NP) THEN
C Set up data structure for the (null) full part.
         MF = M - MORD
         IF1 = LFACT + 1 - MF
         II = 0
         DO 320 I = 1,M
            IF (IP(I).GT.0) THEN
               IW(I+N) = N
               IRNF(IF1+II) = I
               II = II + 1
               IP(I) = NP + II
            END IF
  320    CONTINUE
         IF1 = LFACT + 1 - MAX(MF*NF,MF+NF)
         IF2 = IF1 - 1 + MF*MAX(0,JLAST-NP)
      END IF
      IF (INFO(5).EQ.MIN(M,N)) THEN
C Restore sign of IP
         DO 330 I = 1,M
            IP(I) = ABS(IP(I))
  330    CONTINUE
      ELSE
C Complete IP
         MORD = NP
         DO 340 I = 1,M
            IF (IP(I).LT.0) THEN
               IP(I) = -IP(I)
            ELSE
               MORD = MORD + 1
               IP(I) = MORD
            END IF
  340    CONTINUE
      END IF
      IRNF(1) = INFO(6)
      IRNF(2) = MF
      INFO(7) = MF
      FACT(1) = CNTL(3)
      FACT(2) = CNTL(4)
      IF (INFO(1).EQ.-3) GO TO 520
C Move full part forward
      IF2 = IF2 - MF*NF
      DO 350 II = 1,MF*NF
         FACT(IL2+II) = FACT(IF1-1+II)
  350 CONTINUE
      DO 360 II = 1,MF
         IRNF(IL2+II) = IRNF(LFACT-MF+II)
  360 CONTINUE
      IF1 = IL2 + 1
      GO TO 440
C
C Fast factor (JOB = 2)
C Each pass through this main loop processes column K.
  370 MF = IRNF(2)
      IF1 = IPTRL(N) + 1
      IF2 = IF1 - 1
      DO 430 K = JLAST + 1,N
         J = K
         IF (IQ(1).GT.0) J = IQ(K)
         IA1 = IPTRA(J)
         IA2 = NE
         IF (J.NE.N) IA2 = IPTRA(J+1) - 1
         IU1 = IL2 + 1
         IU2 = IPTRU(K)
         IL1 = IU2 + 1
         IL2 = IPTRL(K)
C Load column K of A into full vector W
         DO 380 II = IA1,IA2
            W(IRNA(II)) = AA(II)
  380    CONTINUE
C Run through column K of U in lexicographical order, performing
C      elimination operations.
         DO 400 II = IU2,IU1,-1
            J = IRNF(II)
            I = IRNF(IPTRU(J)+1)
C Add multiple of column J of L to column K
            EYE1 = IPTRU(J) + 1
            AMULT = -W(I)*FACT(EYE1)
C Note we are storing negative multipliers
            FACT(II) = AMULT
            W(I) = ZERO
            DO 390 EYE = EYE1 + 1,IPTRL(J)
               I = IRNF(EYE)
               W(I) = W(I) + AMULT*FACT(EYE)
  390       CONTINUE
            RINFO = RINFO + ONE + 2*(IPTRL(J)-EYE1)
  400    CONTINUE
         IF (K.LE.NP) THEN
            IF (IL1.LE.IL2) THEN
C Load column of L.
CDIR$ IVDEP
               DO 410 II = IL1,IL2
                  I = IRNF(II)
                  FACT(II) = W(I)
                  W(I) = ZERO
  410          CONTINUE
C Test pivot. Note that this is the only numerical test when JOB = 2.
               IF (ABS(FACT(IL1)).LE.CNTL(4)) THEN
                  GO TO 530
               ELSE
C Reciprocate pivot
                  INFO(5) = INFO(5) + 1
                  FACT(IL1) = ONE/FACT(IL1)
                  RINFO = RINFO + ONE
               END IF
            END IF
         ELSE
C Treat column as full
            DO 420 II = IF1,IF1 + MF - 1
               I = IRNF(II)
               IF2 = IF2 + 1
               FACT(IF2) = W(I)
               W(I) = ZERO
  420       CONTINUE
         END IF
  430 CONTINUE
      INFO(4) = MAX(IF1+MF+NF-1,IF2)

  440 IF (MF.GT.0 .AND. NF.GT.0) THEN
C Factorize full block
         IF (ICNTL(5).GT.1) CALL MA50GD(MF,NF,FACT(IF1),MF,ICNTL(5),
     +                                  CNTL(4),IRNF(IF1+MF),RANK)
         IF (ICNTL(5).EQ.1) CALL MA50FD(MF,NF,FACT(IF1),MF,CNTL(4),
     +                                  IRNF(IF1+MF),RANK)
         IF (ICNTL(5).LE.0) CALL MA50ED(MF,NF,FACT(IF1),MF,CNTL(4),
     +                                  IRNF(IF1+MF),RANK)
         INFO(5) = INFO(5) + RANK
         DO 450 I = 1,MIN(MF,NF)
            RINFO = RINFO + MF - I + 1 + REAL(MF-I)*(NF-I)*2
  450    CONTINUE
      END IF
      IF (INFO(5).LT.MIN(M,N)) INFO(1) = 1
      IF (MP.GT.0 .AND. ICNTL(3).GT.2) THEN
         WRITE (MP,'(A,I6,A,F12.1/A,I3,A,4I8)')
     +     ' Leaving MA50BD with IRNF(2) =',IRNF(2),' RINFO =',RINFO,
     +     ' INFO(1) =',INFO(1),' INFO(4:7) =', (INFO(J),J=4,7)
         IF (ICNTL(3).GT.3) THEN
            IF (JOB.NE.2) WRITE (MP,'(A,(T6,10(I7)))') ' IP = ',IP
            DO 460 J = 1,N
               IF (J.GT.1) THEN
                  IF (IPTRL(J-1).LT.IPTRU(J)) WRITE (MP,
     +                '(A,I5,A,(T18,3(1P,E12.4,I5)))') ' Column',J,
     +                ' of U', (FACT(II),IRNF(II),II=IPTRL(J-1)+1,
     +                IPTRU(J))
               END IF
               IF (IPTRU(J).LT.IPTRL(J)) WRITE (MP,
     +             '(A,I5,A,(T18,3(1P,E12.4,I5)))') ' Column',J,' of L',
     +              (FACT(II),IRNF(II),II=IPTRU(J)+1,IPTRL(J))
  460       CONTINUE
            WRITE (MP,'(A)') ' Full part'
            WRITE (MP,'((6I12))') (IRNF(IF1+MF+J),J=0,NF-1)
            DO 470 I = 0,MF - 1
               WRITE (MP,'(I4,1P,6E12.4:/(4X,1P,6E12.4))') IRNF(IF1+I),
     +            (FACT(IF1+I+J*MF),J=0,NF-1)
  470       CONTINUE
         END IF
      END IF
      GO TO 550

C Error conditions
C LFACT is much too small. Patch up IP and quit.
  480 DO 490 I = 1,M
         IW(I) = 0
  490 CONTINUE
      DO 500 I = 1,M
         IF (IP(I).GT.0) THEN
            IW(IP(I)) = I
         ELSE
            IP(I) = -IP(I)
         END IF
  500 CONTINUE
      DO 510 I = 1,M
         IF (IW(I).GT.0) THEN
            IP(IW(I)) = K
            K = K + 1
         END IF
  510 CONTINUE
  520 INFO(1) = -3
      IF (LP.GT.0) THEN
         WRITE (LP,'(/A/A,I7,A,I7)')
     +     ' **** Error return from MA50BD **** ',
     +     ' LFACT must be increased from',LFACT,' to at least',INFO(4)
      END IF
      GO TO 550
  530 INFO(1) = - (7+K)
      IF (LP.GT.0) WRITE (LP,'(/A/A,I6,A)')
     +    ' **** Error return from MA50BD **** ',
     +    ' Small pivot found in column',K,' of the permuted matrix.'
      GO TO 550
  540 INFO(1) = -4
      IF (LP.GT.0) WRITE (LP,'(/A/(3(A,I9)))')
     +    ' **** Error return from MA50BD ****',' Entry in row',I,
     +    ' and column',J,' duplicated'
  550 END

      SUBROUTINE MA50CD(M,N,ICNTL,IQ,NP,TRANS,LFACT,FACT,IRNF,IPTRL,
     +                  IPTRU,B,X,W,INFO)
C MA50C/CD uses the factorization produced by
C     MA50B/BD to solve A x = b or (A trans) x = b.
C
      INTEGER M,N,ICNTL(7),IQ(N),NP
      LOGICAL TRANS
      INTEGER LFACT
      DOUBLE PRECISION FACT(LFACT)
      INTEGER IRNF(LFACT),IPTRL(N),IPTRU(N)
      DOUBLE PRECISION B(*),X(*),W(*)
      INTEGER INFO(7)
C
C M  is an integer variable set to the number of rows.
C     It is not altered by the subroutine.
C N  is an integer variable set to the number of columns.
C     It is not altered by the subroutine.
C ICNTL must be set by the user as follows and is not altered.
C     ICNTL(1)  must be set to the stream number for error messages.
C       A value less than 1 suppresses output.
C     ICNTL(2) must be set to the stream number for diagnostic output.
C       A value less than 1 suppresses output.
C     ICNTL(3) must be set to control the amount of output:
C       0 None.
C       1 Error messages only.
C       2 Error and warning messages.
C       3 As 2, plus scalar parameters and a few entries of array
C         parameters on entry and exit.
C       4 As 2, plus all parameters on entry and exit.
C     ICNTL(5) must be set to control the level of BLAS used:
C       0 Level 1 BLAS.
C      >0 Level 2 BLAS.
C IQ is an integer array holding the permutation Q.
C     It is not altered by the subroutine.
C NP is an integer variable that must be unchanged since calling
C     MA50B/BD. It holds the number of rows and columns in packed
C     storage. It is not altered by the subroutine.
C TRANS a logical variable thatmust be set to .TRUE. if (A trans)x = b
C     is to be solved and to .FALSE. if A x = b is to be solved.
C     TRANS is not altered by the subroutine.
C LFACT is an integer variable set to the size of FACT and IRNF.
C     It is not altered by the subroutine.
C FACT is an array that must be unchanged since calling MA50B/BD. It
C     holds the packed part of L/U by columns, and the full part of L/U
C     by columns. U has unit diagonal entries, which are not stored, and
C     the signs of the off-diagonal entries are inverted.  In the packed
C     part, the entries of U precede the entries of L; also the diagonal
C     entries of L head each column of L and are reciprocated.
C     FACT is not altered by the subroutine.
C IRNF is an integer array that must be unchanged since calling
C     MA50B/BD. It holds the row numbers of the packed part of L/U, and
C     the row numbers of the full part of L/U.
C     It is not altered by the subroutine.
C IPTRL is an integer array that must be unchanged since calling
C     MA50B/BD. For J = 1,..., NP, IPTRL(J) holds the position in
C     FACT and IRNF of the end of column J of L.
C     For J = NP+1,..., N, IPTRL(J) is equal to IPTRU(J).
C     It is not altered by the subroutine.
C IPTRU is an integer array that must be unchanged since calling
C     MA50B/BD. For J = 1,..., N, IPTRU(J) holds the position in
C     FACT and IRNF of the end of the packed part of column J of U.
C     It is not altered by the subroutine.
C B is an array that must be set to the vector b.
C     It is not altered.
C X is an array that need not be set on entry. On return, it holds the
C    solution x.
C W is a work array of length max(M,N).
C INFO need not be set on entry. On exit, it holds the following:
C    INFO(1) A nonzero value will indicate an error return. Possible
C      nonzero values are:
C      -1  M < 1 or N < 1

      DOUBLE PRECISION ZERO
      PARAMETER (ZERO=0D0)
      INTEGER I,II,IA1,IF1,J,LP,MF,MP,NF
      DOUBLE PRECISION PROD
C I Temporary variable holding row number.
C II Position of the current entry in IRNF.
C IA1 Position of the start of the current row or column.
C IF1 Position of the start of the full part of U.
C J Temporary variable holding column number.
C LP Unit for error messages.
C MF Number of rows held in full format.
C MP Unit for diagnostic messages.
C NF Number of columns held in full format.
C PROD Temporary variable used to accumulate inner products.

      EXTERNAL MA50HD

      LP = ICNTL(1)
      MP = ICNTL(2)
      IF (ICNTL(3).LE.0) LP = 0
      IF (ICNTL(3).LE.1) MP = 0

C Make some simple checks
      IF (M.LT.1 .OR. N.LT.1) GO TO 250

      IF (MP.GT.0 .AND. ICNTL(3).GT.2) WRITE (MP,
     +    '(/2(A,I6),A,I4,A,L2)') ' Entering MA50CD with M=',M,' N =',N,
     +    ' NP =',NP,' TRANS =',TRANS
      IF1 = IPTRL(N) + 1
      MF = IRNF(2)
      NF = N - NP
      IF (MP.GT.0 .AND. ICNTL(3).GT.2) WRITE (MP,
     +    '(A,I5,A,I5)') ' Size of full submatrix',MF,' by',NF
      IF (MP.GT.0 .AND. ICNTL(3).GT.3) THEN
         DO 10 J = 1,N
            IF (J.GT.1) THEN
               IF (IPTRL(J-1).LT.IPTRU(J)) WRITE (MP,
     +             '(A,I5,A,(T18,3(1P,E12.4,I5)))') ' Column',J,' of U',
     +              (FACT(II),IRNF(II),II=IPTRL(J-1)+1,IPTRU(J))
            END IF
            IF (IPTRU(J).LT.IPTRL(J)) WRITE (MP,
     +          '(A,I5,A,(T18,3(1P,E12.4,I5)))') ' Column',J,' of L',
     +          (FACT(II),IRNF(II),II=IPTRU(J)+1,IPTRL(J))
   10    CONTINUE
         WRITE (MP,'(A)') ' Full part'
         WRITE (MP,'((6I12))') (IRNF(IF1+MF+J),J=0,NF-1)
         DO 20 I = 0,MF - 1
            WRITE (MP,'(I4,1P,6E12.4:/(4X,1P,6E12.4))') IRNF(IF1+I),
     +        (FACT(IF1+I+J*MF),J=0,NF-1)
   20    CONTINUE
      END IF

      IF (TRANS) THEN
         IF (MP.GT.0 .AND. ICNTL(3).GT.3) WRITE (MP,
     +       '(A4,5F10.4:/(4X,5F10.4))') ' B =', (B(I),I=1,N)
         IF (IQ(1).GT.0) THEN
            DO 30 I = 1,N
               W(I) = B(IQ(I))
   30       CONTINUE
         ELSE
            DO 40 I = 1,N
               W(I) = B(I)
   40       CONTINUE
         END IF
         DO 50 I = 1,M
            X(I) = ZERO
   50    CONTINUE
C Forward substitution through packed part of (U trans).
         DO 70 I = 2,N
            PROD = ZERO
            DO 60 II = IPTRL(I-1) + 1,IPTRU(I)
               PROD = PROD + FACT(II)*W(IRNF(II))
   60       CONTINUE
            W(I) = W(I) + PROD
   70    CONTINUE
C Backsubstitute through the full part of (PL) trans.
         DO 80 I = 1,NF
            X(I) = W(NP+I)
   80    CONTINUE
         IF (MF.GT.0 .AND. NF.GT.0) THEN
            CALL MA50HD(TRANS,MF,NF,FACT(IF1),MF,IRNF(IF1+MF),X,
     +                  ICNTL(5))
         ELSE
            DO 90 I = 1,MF
               X(I) = ZERO
   90       CONTINUE
         END IF
         DO 100 I = MF,1,-1
            J = IRNF(IF1+I-1)
            IF (J.NE.I) X(J) = X(I)
  100    CONTINUE
C Backsubstitute through the packed part of (PL) trans.
         DO 120 I = NP,1,-1
            IA1 = IPTRU(I) + 1
            IF (IA1.GT.IPTRL(I)) GO TO 120
            PROD = ZERO
            DO 110 II = IA1 + 1,IPTRL(I)
               PROD = PROD + FACT(II)*X(IRNF(II))
  110       CONTINUE
            X(IRNF(IA1)) = (W(I)-PROD)*FACT(IA1)
  120    CONTINUE
         IF (MP.GT.0 .AND. ICNTL(3).GT.3) WRITE (MP,
     +       '(A/(4X,5F10.4))') ' Leaving MA50CD with X =', (X(I),I=1,M)
C
      ELSE
         IF (MP.GT.0 .AND. ICNTL(3).GT.3) WRITE (MP,
     +       '(A4,5F10.4:/(4X,5F10.4))') ' B =', (B(I),I=1,M)
C Forward substitution through the packed part of PL
         DO 130 I = 1,M
            W(I) = B(I)
  130    CONTINUE
         DO 150 I = 1,NP
            IA1 = IPTRU(I) + 1
            IF (IA1.LE.IPTRL(I)) THEN
               X(I) = W(IRNF(IA1))*FACT(IA1)
               IF (X(I).NE.ZERO) THEN
CDIR$ IVDEP
                  DO 140 II = IA1 + 1,IPTRL(I)
                     W(IRNF(II)) = W(IRNF(II)) - FACT(II)*X(I)
  140             CONTINUE
               END IF
            END IF
  150    CONTINUE
C Forward substitution through the full part of PL
         IF (MF.GT.0 .AND. NF.GT.0) THEN
            DO 160 I = 1,MF
               W(I) = W(IRNF(IF1+I-1))
  160       CONTINUE
            CALL MA50HD(TRANS,MF,NF,FACT(IF1),MF,IRNF(IF1+MF),W,
     +                  ICNTL(5))
            DO 170 I = 1,NF
               X(NP+I) = W(I)
  170       CONTINUE
         ELSE
            DO 180 I = 1,NF
               X(NP+I) = ZERO
  180       CONTINUE
         END IF
C Back substitution through the packed part of U
         DO 200 J = N,MAX(2,NP+1),-1
            PROD = X(J)
CDIR$ IVDEP
            DO 190 II = IPTRL(J-1) + 1,IPTRU(J)
               X(IRNF(II)) = X(IRNF(II)) + FACT(II)*PROD
  190       CONTINUE
  200    CONTINUE
         DO 220 J = NP,2,-1
            IA1 = IPTRU(J)
            IF (IA1.GE.IPTRL(J)) THEN
               X(J) = ZERO
            ELSE
               PROD = X(J)
CDIR$ IVDEP
               DO 210 II = IPTRL(J-1) + 1,IA1
                  X(IRNF(II)) = X(IRNF(II)) + FACT(II)*PROD
  210          CONTINUE
            END IF
  220    CONTINUE
         IF (NP.GE.1 .AND. IPTRU(1).GE.IPTRL(1)) X(1) = ZERO
         IF (IQ(1).GT.0) THEN
C         Permute X
            DO 230 I = 1,N
               W(I) = X(I)
  230       CONTINUE
            DO 240 I = 1,N
               X(IQ(I)) = W(I)
  240       CONTINUE
         END IF
         IF (MP.GT.0 .AND. ICNTL(3).GT.3) WRITE (MP,
     +       '(A/(4X,5F10.4))') ' Leaving MA50CD with X =', (X(I),I=1,N)
      END IF
      RETURN
C Error condition.
  250 INFO(1) = -1
      IF (LP.GT.0) WRITE (LP,'(/A/2(A,I8))')
     +    ' **** Error return from MA50CD ****',' M =',M,' N =',N
      END

      SUBROUTINE MA50DD(LA,A,IND,IPTR,N,DISP,REALS)
C This subroutine performs garbage collection on the arrays A and IND.
C DISP is the position in arrays A/IND immediately after the data
C     to be compressed.
C     On exit, DISP equals the position of the first entry
C     after the compressed part of A/IND.
C
      INTEGER LA,N,DISP
      DOUBLE PRECISION A(LA)
      INTEGER IPTR(N)
      LOGICAL REALS
      INTEGER IND(LA)
C Local variables.
      INTEGER J,K,KN
C Set the first entry in each row(column) to the negative of the
C     row(column) and hold the column(row) index in the row(column)
C     pointer.  This enables the start of each row(column) to be
C     recognized in a subsequent scan.
      DO 10 J = 1,N
         K = IPTR(J)
         IF (K.GT.0) THEN
            IPTR(J) = IND(K)
            IND(K) = -J
         END IF
   10 CONTINUE
      KN = 0
C Go through arrays compressing to the front so that there are no
C     zeros held in positions 1 to DISP-1 of IND.
C     Reset first entry of each row(column) and the pointer array IPTR.
      DO 20 K = 1,DISP - 1
         IF (IND(K).EQ.0) GO TO 20
         KN = KN + 1
         IF (REALS) A(KN) = A(K)
         IF (IND(K).LE.0) THEN
C First entry of row(column) has been located.
            J = -IND(K)
            IND(K) = IPTR(J)
            IPTR(J) = KN
         END IF
         IND(KN) = IND(K)
   20 CONTINUE
      DISP = KN + 1
      END


      SUBROUTINE MA50ED(M,N,A,LDA,PIVTOL,IPIV,RANK)
**
      INTEGER LDA,M,N,RANK
      DOUBLE PRECISION PIVTOL

      INTEGER IPIV(N)
      DOUBLE PRECISION A(LDA,N)

*
*  Purpose
*  =======
*
*  MA50ED computes an LU factorization of a general m-by-n matrix A.

*  The factorization has the form
*     A = P * L * U * Q
*  where P is a permutation matrix of order m, L is lower triangular
*  of order m with unit diagonal elements, U is upper trapezoidal of
*  order m * n, and Q is a permutation matrix of order n.
*
*  Row interchanges are used to ensure that the entries of L do not
*  exceed 1 in absolute value. Column interchanges are used to
*  ensure that the first r diagonal entries of U exceed PIVTOL in
*  absolute value. If r < m, the last (m-r) rows of U are zero.

*  This is the Level 1 BLAS version.
*
*  Arguments
*  =========
*
*  M       (input) INTEGER
*          The number of rows of the matrix A.  M >= 1.
*
*  N       (input) INTEGER
*          The number of columns of the matrix A.  N >= 1.
*
*  A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)
*          On entry, the m by n matrix to be factored.
*          On exit, the factors L and U from the factorization
*          A = P*L*U*Q; the unit diagonal elements of L are not stored.
*
*  LDA     (input) INTEGER
*          The leading dimension of the array A.  LDA >= max(1,M).
*
*  PIVTOL  (input) DOUBLE PRECISION
*          The pivot tolerance. Any entry with absolute value less
*          than or equal to PIVTOL is regarded as unsuitable to be a
*          pivot.
**
*  IPIV    (output) INTEGER array, dimension (N)
*          The permutations; for 1 <= i <= RANK, row i of the
*          matrix was interchanged with row IPIV(i); for
*          RANK + 1 <= j <= N, column j of the
*          matrix was interchanged with column -IPIV(j).
*
*  RANK    (output) INTEGER
*          The computed rank of the matrix.
*
*  =====================================================================
*
      DOUBLE PRECISION ONE,ZERO
      PARAMETER (ONE=1.0D+0,ZERO=0.0D+0)

      INTEGER I,J,JP,K
      LOGICAL PIVOT
* I   Row index.
* J   Current column.
* JP  Pivot position.
* K   Main loop index.
* PIVOT True if there is a pivot in current column.

      INTEGER IDAMAX
      EXTERNAL IDAMAX

      EXTERNAL DAXPY,DSCAL,DSWAP
      INTRINSIC ABS

*
      J = 1
      DO 30 K = 1,N

*        Update elements in column J.
         DO 10 I = 1,J - 1
            IF (M.GT.I) CALL DAXPY(M-I,-A(I,J),A(I+1,I),1,A(I+1,J),1)
   10    CONTINUE

*        Find pivot.
         IF (J.LE.M) THEN
            JP = J - 1 + IDAMAX(M-J+1,A(J,J),1)
            IPIV(J) = JP
            PIVOT = ABS(A(JP,J)) .GT. PIVTOL
         ELSE
            PIVOT = .FALSE.
         END IF
         IF (PIVOT) THEN

*           Apply row interchange to columns 1:N+J-K.
            IF (JP.NE.J) CALL DSWAP(N+J-K,A(J,1),LDA,A(JP,1),LDA)
*
*           Compute elements J+1:M of J-th column.
            IF (J.LT.M) CALL DSCAL(M-J,ONE/A(J,J),A(J+1,J),1)

*           Update J
            J = J + 1
*
         ELSE
*
            DO 20 I = J,M
               A(I,J) = ZERO
   20       CONTINUE
*           Apply column interchange and record it.
            IF (K.LT.N) CALL DSWAP(M,A(1,J),1,A(1,N-K+J),1)
            IPIV(N-K+J) = -J
*
         END IF
*
   30 CONTINUE

      RANK = J - 1
*
*     End of MA50ED
*
      END


      SUBROUTINE MA50FD(M,N,A,LDA,PIVTOL,IPIV,RANK)
*
*  -- This is a variant of the LAPACK routine DGETF2 --
*
      INTEGER LDA,M,N,RANK
      DOUBLE PRECISION PIVTOL

      INTEGER IPIV(N)
      DOUBLE PRECISION A(LDA,N)

*
*  Purpose
*  =======
*
*  MA50FD computes an LU factorization of a general m-by-n matrix A.

*  The factorization has the form
*     A = P * L * U * Q
*  where P is a permutation matrix of order m, L is lower triangular
*  of order m with unit diagonal elements, U is upper trapezoidal of
*  order m * n, and Q is a permutation matrix of order n.
*
*  Row interchanges are used to ensure that the entries of L do not
*  exceed 1 in absolute value. Column interchanges are used to
*  ensure that the first r diagonal entries of U exceed PIVTOL in
*  absolute value. If r < m, the last (m-r) rows of U are zero.

*  This is the Level 2 BLAS version.
*
*  Arguments
*  =========
*
*  M       (input) INTEGER
*          The number of rows of the matrix A.  M >= 1.
*
*  N       (input) INTEGER
*          The number of columns of the matrix A.  N >= 1.
*
*  A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)
*          On entry, the m by n matrix to be factored.
*          On exit, the factors L and U from the factorization
*          A = P*L*U*Q; the unit diagonal elements of L are not stored.
*
*  LDA     (input) INTEGER
*          The leading dimension of the array A.  LDA >= max(1,M).
*
*  PIVTOL  (input) DOUBLE PRECISION
*          The pivot tolerance. Any entry with absolute value less
*          than or equal to PIVTOL is regarded as unsuitable to be a
*          pivot.
**
*  IPIV    (output) INTEGER array, dimension (N)
*          The permutations; for 1 <= i <= RANK, row i of the
*          matrix was interchanged with row IPIV(i); for
*          RANK + 1 <= j <= N, column j of the
*          matrix was interchanged with column -IPIV(j).
*
*  RANK    (output) INTEGER
*          The computed rank of the matrix.
*
*  =====================================================================
*
      DOUBLE PRECISION ONE,ZERO
      PARAMETER (ONE=1.0D+0,ZERO=0.0D+0)

      INTEGER I,J,JP,K
      LOGICAL PIVOT
* I   Row index.
* J   Current column.
* JP  Pivot position.
* K   Main loop index.
* PIVOT True if there is a pivot in current column.

      INTEGER IDAMAX
      EXTERNAL IDAMAX

      EXTERNAL DGEMV,DSCAL,DSWAP

      INTRINSIC ABS

*
      J = 1
      DO 20 K = 1,N

         IF (J.LE.M) THEN
*           Update diagonal and subdiagonal elements in column J.
            CALL DGEMV('No transpose',M-J+1,J-1,-ONE,A(J,1),LDA,A(1,J),
     +                 1,ONE,A(J,J),1)
*          Find pivot.
            JP = J - 1 + IDAMAX(M-J+1,A(J,J),1)
            IPIV(J) = JP
            PIVOT = ABS(A(JP,J)) .GT. PIVTOL
         ELSE
            PIVOT = .FALSE.
         END IF

         IF (PIVOT) THEN

*           Apply row interchange to columns 1:N+J-K.
            IF (JP.NE.J) CALL DSWAP(N+J-K,A(J,1),LDA,A(JP,1),LDA)
*
*           Compute elements J+1:M of J-th column.
            IF (J.LT.M) CALL DSCAL(M-J,ONE/A(J,J),A(J+1,J),1)

            IF (J.LT.N) THEN
*             Compute block row of U.
               CALL DGEMV('Transpose',J-1,N-J,-ONE,A(1,J+1),LDA,A(J,1),
     +                    LDA,ONE,A(J,J+1),LDA)
            END IF

*           Update J
            J = J + 1
*
         ELSE
*
            DO 10 I = J,M
               A(I,J) = ZERO
   10       CONTINUE
*           Apply column interchange and record it.
            IF (K.LT.N) CALL DSWAP(M,A(1,J),1,A(1,N-K+J),1)
            IPIV(N-K+J) = -J
*
         END IF
*
   20 CONTINUE

      RANK = J - 1
*
*     End of MA50FD
*
      END


      SUBROUTINE MA50GD(M,N,A,LDA,NB,PIVTOL,IPIV,RANK)
*
*  -- This is a variant of the LAPACK routine DGETRF --
*
      INTEGER LDA,M,N,NB,RANK
      DOUBLE PRECISION PIVTOL

      INTEGER IPIV(N)
      DOUBLE PRECISION A(LDA,N)

*
*  Purpose
*  =======
*
*  MA50GD computes an LU factorization of a general m-by-n matrix A.
*
*  The factorization has the form
*     A = P * L * U * Q
*  where P is a permutation matrix of order m, L is lower triangular
*  of order m with unit diagonal elements, U is upper trapezoidal of
*  order m * n, and Q is a permutation matrix of order n.
*
*  Row interchanges are used to ensure that the entries of L do not
*  exceed 1 in absolute value. Column interchanges are used to
*  ensure that the first r diagonal entries of U exceed PIVTOL in
*  absolute value. If r < m, the last (m-r) rows of U are zero.
*
*  This is the Level 3 BLAS version.
*
*  Arguments
*  =========
*
*  M       (input) INTEGER
*          The number of rows of the matrix A.  M >= 1.
*
*  N       (input) INTEGER
*          The number of columns of the matrix A.  N >= 1.
*
*  A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)
*          On entry, the m by n matrix to be factored.
*          On exit, the factors L and U from the factorization
*          A = P*L*U*Q; the unit diagonal elements of L are not stored.
*
*  LDA     (input) INTEGER
*          The leading dimension of the array A.  LDA >= max(1,M).
*
*  NB      (input) INTEGER
*          The block size for BLAS3 processing.
*
*  PIVTOL  (input) DOUBLE PRECISION
*          The pivot tolerance. Any entry with absolute value less
*          than or equal to PIVTOL is regarded as unsuitable to be a
*          pivot.
**
*  IPIV    (output) INTEGER array, dimension (N)
*          The permutations; for 1 <= i <= RANK, row i of the
*          matrix was interchanged with row IPIV(i); for
*          RANK + 1 <= j <= N, column j of the
*          matrix was interchanged with column -IPIV(j).
*
*  RANK    (output) INTEGER
*          The computed rank of the matrix.
*
*  =====================================================================
*
      DOUBLE PRECISION ONE,ZERO
      PARAMETER (ONE=1.0D+0,ZERO=0.0D+0)

      INTEGER I,J,JJ,JP,J1,J2,K
      LOGICAL PIVOT
      DOUBLE PRECISION TEMP

* I   DO index for applying permutations.
* J   Current column.
* JJ  Column in which swaps occur.
* JP  Pivot position.
* J1  Column at start of current block.
* J2  Column at end of current block.
* K   Main loop index.
* PIVOT True if there is a pivot in current column.
* TEMP Temporary variable for swaps.

      EXTERNAL DGEMM,DGEMV,DSWAP,DSCAL,DTRSM,DTRSV

      INTEGER IDAMAX
      EXTERNAL IDAMAX

      INTRINSIC ABS,MIN

*
      J = 1
      J1 = 1
      J2 = MIN(N,NB)
      DO 70 K = 1,N

         IF (J.LE.M) THEN

*          Update diagonal and subdiagonal elements in column J.
            CALL DGEMV('No transpose',M-J+1,J-J1,-ONE,A(J,J1),LDA,
     +                 A(J1,J),1,ONE,A(J,J),1)

*          Find pivot.
            JP = J - 1 + IDAMAX(M-J+1,A(J,J),1)
            IPIV(J) = JP
            PIVOT = ABS(A(JP,J)) .GT. PIVTOL
         ELSE
            PIVOT = .FALSE.
         END IF

         IF (PIVOT) THEN

*           Apply row interchange to columns J1:J2
            IF (JP.NE.J) CALL DSWAP(J2-J1+1,A(J,J1),LDA,A(JP,J1),LDA)
*
*           Compute elements J+1:M of J-th column.
            IF (J.LT.M) CALL DSCAL(M-J,ONE/A(J,J),A(J+1,J),1)

            IF (J+1.LE.J2) THEN
*             Compute row of U within current block
               CALL DGEMV('Transpose',J-J1,J2-J,-ONE,A(J1,J+1),LDA,
     +                    A(J,J1),LDA,ONE,A(J,J+1),LDA)
            END IF

*           Update J
            J = J + 1
*
         ELSE

            DO 10 I = J,M
               A(I,J) = ZERO
   10       CONTINUE
*
*           Record column interchange and revise J2 if necessary
            IPIV(N-K+J) = -J
*           Apply column interchange.
            IF (K.NE.N) CALL DSWAP(M,A(1,J),1,A(1,N-K+J),1)
            IF (N-K+J.GT.J2) THEN
*              Apply operations to new column.
               DO 20 I = J1,J - 1
                  JP = IPIV(I)
                  TEMP = A(I,J)
                  A(I,J) = A(JP,J)
                  A(JP,J) = TEMP
   20          CONTINUE
            IF (J.GT.J1) 
     +          CALL DTRSV('Lower','No transpose','Unit',J-J1,A(J1,J1),
     +                    LDA,A(J1,J),1)
            ELSE
               J2 = J2 - 1
            END IF
*
         END IF

         IF (J.GT.J2) THEN
*           Apply permutations to columns outside the block
            DO 40 JJ = 1,J1 - 1
               DO 30 I = J1,J2
                  JP = IPIV(I)
                  TEMP = A(I,JJ)
                  A(I,JJ) = A(JP,JJ)
                  A(JP,JJ) = TEMP
   30          CONTINUE
   40       CONTINUE
            DO 60 JJ = J2 + 1,N - K + J - 1
               DO 50 I = J1,J2
                  JP = IPIV(I)
                  TEMP = A(I,JJ)
                  A(I,JJ) = A(JP,JJ)
                  A(JP,JJ) = TEMP
   50          CONTINUE
   60       CONTINUE

            IF (K.NE.N) THEN
*              Update the Schur complement
               CALL DTRSM('Left','Lower','No transpose','Unit',J2-J1+1,
     +                    N-K,ONE,A(J1,J1),LDA,A(J1,J2+1),LDA)
               IF (M.GT.J2) CALL DGEMM('No transpose','No transpose',
     +                                 M-J2,N-K,J2-J1+1,-ONE,A(J2+1,J1),
     +                                 LDA,A(J1,J2+1),LDA,ONE,
     +                                 A(J2+1,J2+1),LDA)
            END IF

            J1 = J2 + 1
            J2 = MIN(J2+NB,N-K+J-1)

         END IF

*
   70 CONTINUE
      RANK = J - 1
*
*     End of MA50GD
*
      END

      SUBROUTINE MA50HD(TRANS,M,N,A,LDA,IPIV,B,ICNTL5)
*
*  -- This is a variant of the LAPACK routine DGETRS --
*     It handles the singular or rectangular case.
*
      LOGICAL TRANS
      INTEGER LDA,M,N,ICNTL5
      INTEGER IPIV(N)
      DOUBLE PRECISION A(LDA,N),B(*)

*
*  Purpose
*  =======
*
*  Solve a system of linear equations
*     A * X = B  or  A' * X = B
*  with a general m by n matrix A using the LU factorization computed
*  by MA50DE, MA50FD, or MA50GD.
*
*  Arguments
*  =========
*
*  TRANS   (input) LOGICAL
*          Specifies the form of the system of equations.
*          = .FALSE. :  A * X = B  (No transpose)
*          = .TRUE.  :  A'* X = B  (Transpose)
*
*  M       (input) INTEGER
*          The number of rows of the matrix A.  M >= 1.
*
*  N       (input) INTEGER
*          The number of columns of the matrix A.  N >= 1.
*
*  A       (input) DOUBLE PRECISION array, dimension (LDA,N)
*          The factors L and U from the factorization A = P*L*U
*          as computed by MA50GD.
*
*  LDA     (input) INTEGER
*          The leading dimension of the array A.  LDA >= max(1,N).
*
*  IPIV    (input) INTEGER array, dimension (N)
*          The permutations; for 1 <= i <= RANK, row i of the
*          matrix was interchanged with row IPIV(i); for
*          RANK + 1 <= j <= N, column j of the
*          matrix was interchanged with column -IPIV(j).

*  B       (input/output) DOUBLE PRECISION array, size max(M,N)
*          On entry, the right hand side vectors B for the system of
*          linear equations.
*          On exit, the solution vectors, X.
*
*  ICNTL5  (input) INTEGER
*          0 for BLAS1 or >0 for BLAS2
*
*  =====================================================================
*
      INTEGER I,K,RANK
C I    Temporary variable.
C K    Temporary variable.
C RANK Rank of matrix.

      DOUBLE PRECISION ZERO
      PARAMETER (ZERO=0D0)
      DOUBLE PRECISION TEMP
      INTRINSIC MIN
      EXTERNAL DAXPY,DDOT,DTRSV
      DOUBLE PRECISION DDOT

*   Find the rank
      RANK = 0
      DO 10 RANK = MIN(M,N),1,-1
         IF (IPIV(RANK).GT.0) GO TO 20
   10 CONTINUE

   20 IF (.NOT.TRANS) THEN
*
*        Solve A * X = B.
*
*        Apply row interchanges to the right hand side.
         DO 30 I = 1,RANK
            K = IPIV(I)
            TEMP = B(I)
            B(I) = B(K)
            B(K) = TEMP
   30    CONTINUE
*
*        Solve L*X = B, overwriting B with X.
         IF (ICNTL5.GT.0) THEN
            IF (RANK.GT.0) CALL DTRSV('L','NoTrans','Unit',RANK,A,LDA,B,
     +                                1)
         ELSE
            DO 40 K = 1,RANK - 1
               IF (B(K).NE.ZERO) CALL DAXPY(RANK-K,-B(K),A(K+1,K),1,
     +                                B(K+1),1)
   40       CONTINUE
         END IF

*        Solve U*X = B, overwriting B with X.
         IF (ICNTL5.GT.0) THEN
            IF (RANK.GT.0) CALL DTRSV('U','NoTrans','NonUnit',RANK,A,
     +                                LDA,B,1)
         ELSE
            DO 50 K = RANK,2,-1
               IF (B(K).NE.ZERO) THEN
                  B(K) = B(K)/A(K,K)
                  CALL DAXPY(K-1,-B(K),A(1,K),1,B(1),1)
               END IF
   50       CONTINUE
            IF (RANK.GT.0) B(1) = B(1)/A(1,1)
         END IF

*        Set singular part to zero
         DO 60 K = RANK + 1,N
            B(K) = ZERO
   60    CONTINUE
*
*        Apply column interchanges to the right hand side.
         DO 70 I = RANK + 1,N
            K = -IPIV(I)
            TEMP = B(I)
            B(I) = B(K)
            B(K) = TEMP
   70    CONTINUE

      ELSE
*
*        Solve A' * X = B.

*        Apply column interchanges to the right hand side.
         DO 80 I = N,RANK + 1,-1
            K = -IPIV(I)
            TEMP = B(I)
            B(I) = B(K)
            B(K) = TEMP
   80    CONTINUE
*
*        Solve U'*X = B, overwriting B with X.
*
         IF (ICNTL5.GT.0) THEN
            IF (RANK.GT.0) CALL DTRSV('U','Trans','NonUnit',RANK,A,LDA,
     +                                B,1)
         ELSE
            IF (RANK.GT.0) B(1) = B(1)/A(1,1)
            DO 90 I = 2,RANK
               TEMP = B(I) - DDOT(I-1,A(1,I),1,B(1),1)
               B(I) = TEMP/A(I,I)
   90       CONTINUE
         END IF

*        Solve L'*X = B, overwriting B with X.
         IF (ICNTL5.GT.0) THEN
            IF (RANK.GT.0) CALL DTRSV('L','Trans','Unit',RANK,A,LDA,B,1)
         ELSE
            DO 100 I = RANK - 1,1,-1
               B(I) = B(I) - DDOT(RANK-I,A(I+1,I),1,B(I+1),1)
  100       CONTINUE
         END IF

*        Set singular part to zero
         DO 110 I = RANK + 1,M
            B(I) = ZERO
  110    CONTINUE
*
*        Apply row interchanges to the solution vectors.
         DO 120 I = RANK,1,-1
            K = IPIV(I)
            TEMP = B(I)
            B(I) = B(K)
            B(K) = TEMP
  120    CONTINUE
      END IF

      END

      SUBROUTINE MA50ID(CNTL,ICNTL)
C Set default values for the control arrays.

      DOUBLE PRECISION CNTL(4)
      INTEGER ICNTL(7)

      CNTL(1) = 0.5D0
      CNTL(2) = 0.1D0
      CNTL(3) = 0.0D0
      CNTL(4) = 0.0D0
      ICNTL(1) = 6
      ICNTL(2) = 6
      ICNTL(3) = 1
      ICNTL(4) = 3
      ICNTL(5) = 32
      ICNTL(6) = 0
      ICNTL(7) = 0

      END
