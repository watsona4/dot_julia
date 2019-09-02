
   

subroutine ac_mul_b_rr( nthreads, nvec, n, m, alpha, beta, A, jA, iA, x, y )
!DIR$ ATTRIBUTES DLLEXPORT :: ac_mul_b_rr
!DIR$ ATTRIBUTES ALIAS: 'ac_mul_b_rr_':: ac_mul_b_rr

! y = beta*y  + alpha * A'*x

#undef CMPLXA
implicit none

integer(kind=8),intent(in):: nthreads
integer(kind=8),intent(in):: nvec ! # of vectors
integer(kind=8),intent(in):: n  ! # of columns in A
integer(kind=8),intent(in):: m  ! # of rows in A

real(kind=8),intent(in):: alpha, beta
real(kind=8),intent(in):: A(*)
integer(kind=8),intent(in):: jA(*), iA(n+1)
real(kind=8),intent(in):: x(m,nvec)
real(kind=8),intent(inout):: y(n,nvec)

integer(kind=8) ivec, i, j1,j2, j
real(kind=8) t

#include "Ac_mul_B.fi"

return
end subroutine ac_mul_b_rr

!------------------------------------------------------------------------

subroutine ac_mul_b_rc( nthreads, nvec, n, m, alpha, beta, A, jA, iA, x, y )
!DIR$ ATTRIBUTES DLLEXPORT :: ac_mul_b_rc
!DIR$ ATTRIBUTES ALIAS: 'ac_mul_b_rc_':: ac_mul_b_rc

! y = beta*y  + alpha * A'*x

#undef CMPLXA
implicit none

integer(kind=8),intent(in):: nthreads
integer(kind=8),intent(in):: nvec ! # of vectors
integer(kind=8),intent(in):: n  ! # of columns in A
integer(kind=8),intent(in):: m  ! # of rows in A

complex(kind=8),intent(in):: alpha, beta
real(kind=8),intent(in):: A(*)
integer(kind=8),intent(in):: jA(*), iA(n+1)
complex(kind=8),intent(in):: x(m,nvec)
complex(kind=8),intent(inout):: y(n,nvec)

integer(kind=8) ivec, i, j1,j2, j
complex(kind=8) t

#include "Ac_mul_B.fi"

return
end subroutine ac_mul_b_rc

!------------------------------------------------------------------------

subroutine ac_mul_b_cc( nthreads, nvec, n, m, alpha, beta, A, jA, iA, x, y )
!DIR$ ATTRIBUTES DLLEXPORT :: ac_mul_b_cc
!DIR$ ATTRIBUTES ALIAS: 'ac_mul_b_cc_':: ac_mul_b_cc

! y = beta*y  + alpha * A'*x

#define CMPLXA
implicit none

integer(kind=8),intent(in):: nthreads
integer(kind=8),intent(in):: nvec ! # of vectors
integer(kind=8),intent(in):: n  ! # of columns in A
integer(kind=8),intent(in):: m  ! # of rows in A

complex(kind=8),intent(in):: alpha, beta
complex(kind=8),intent(in):: A(*)
integer(kind=8),intent(in):: jA(*), iA(n+1)
complex(kind=8),intent(in):: x(m,nvec)
complex(kind=8),intent(inout):: y(n,nvec)



integer(kind=8) ivec, i, j1,j2, j
complex(kind=8) t

#include "Ac_mul_B.fi"

return
end subroutine ac_mul_b_cc






subroutine ac_mul_b_cc_short( nthreads, nvec, n, m, alpha, beta, A, jA, iA, x, y )
!DIR$ ATTRIBUTES DLLEXPORT :: ac_mul_b_cc_short
!DIR$ ATTRIBUTES ALIAS: 'ac_mul_b_cc_short_':: ac_mul_b_cc_short

! y = beta*y  + alpha * A'*x

#define CMPLXA
implicit none

integer(kind=8),intent(in):: nthreads
integer(kind=8),intent(in):: nvec ! # of vectors
integer(kind=8),intent(in):: n  ! # of columns in A
integer(kind=8),intent(in):: m  ! # of rows in A

complex(kind=4),intent(in):: alpha, beta
complex(kind=4),intent(in):: A(*)
integer(kind=8),intent(in):: jA(*), iA(n+1)
complex(kind=4),intent(in):: x(m,nvec)
complex(kind=4),intent(inout):: y(n,nvec)



integer(kind=8) ivec, i, j1,j2, j
complex(kind=8) t

#include "Ac_mul_B.fi"

return
end subroutine ac_mul_b_cc_short

subroutine ac_mul_b_rc_short( nthreads, nvec, n, m, alpha, beta, A, jA, iA, x, y )
!DIR$ ATTRIBUTES DLLEXPORT :: ac_mul_b_rc_short
!DIR$ ATTRIBUTES ALIAS: 'ac_mul_b_rc_short_':: ac_mul_b_rc_short

! y = beta*y  + alpha * A'*x

#undef CMPLXA
implicit none

integer(kind=8),intent(in):: nthreads
integer(kind=8),intent(in):: nvec ! # of vectors
integer(kind=8),intent(in):: n  ! # of columns in A
integer(kind=8),intent(in):: m  ! # of rows in A

complex(kind=4),intent(in):: alpha, beta
real(kind=4),intent(in):: A(*)
integer(kind=8),intent(in):: jA(*), iA(n+1)
complex(kind=4),intent(in):: x(m,nvec)
complex(kind=4),intent(inout):: y(n,nvec)



integer(kind=8) ivec, i, j1,j2, j
complex(kind=8) t

#include "Ac_mul_B.fi"

return
end subroutine ac_mul_b_rc_short



subroutine ac_mul_b_cc_mixed( nthreads, nvec, n, m, alpha, beta, A, jA, iA, x, y )
!DIR$ ATTRIBUTES DLLEXPORT :: ac_mul_b_cc_mixed
!DIR$ ATTRIBUTES ALIAS: 'ac_mul_b_cc_mixed_':: ac_mul_b_cc_mixed

! y = beta*y  + alpha * A'*x

#define CMPLXA
implicit none

integer(kind=8),intent(in):: nthreads
integer(kind=8),intent(in):: nvec ! # of vectors
integer(kind=8),intent(in):: n  ! # of columns in A
integer(kind=8),intent(in):: m  ! # of rows in A

complex(kind=8),intent(in):: alpha
complex(kind=8),intent(in):: beta
complex(kind=4),intent(in):: A(*)
integer(kind=8),intent(in):: jA(*), iA(n+1)
complex(kind=8),intent(in):: x(m,nvec)
complex(kind=8),intent(inout):: y(n,nvec)



integer(kind=8) ivec, i, j1,j2, j
complex(kind=8) t

#include "Ac_mul_B.fi"

return
end subroutine ac_mul_b_cc_mixed
