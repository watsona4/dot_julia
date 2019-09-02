
subroutine a_mul_b_rr( nthreads, nvec, n, m, alpha, beta, A, jA, iA, x, y )
!DIR$ ATTRIBUTES DLLEXPORT :: a_mul_b_rr
!DIR$ ATTRIBUTES ALIAS: 'a_mul_b_rr_':: a_mul_b_rr

! y = beta*y  +  alpha * A*x

use omp_lib
implicit none

integer(kind=8),intent(in):: nthreads
integer(kind=8),intent(in):: nvec
integer(kind=8),intent(in):: n  ! # of columns in A
integer(kind=8),intent(in):: m  ! # of rows in A

real(kind=8),intent(in):: alpha, beta
real(kind=8),intent(in):: A(*)
integer(kind=8),intent(in):: jA(*), iA(n+1)
real(kind=8),intent(in):: x(n,nvec)
real(kind=8),intent(inout):: y(m,nvec)

integer ivec, i, j1,j2, j, jaj, mythread, mm, jm
real(kind=8) xi
real(kind=8),allocatable:: yt(:)

include "A_mul_B.fi"

return
end subroutine a_mul_b_rr

!--------------------------------------------------------------------

subroutine a_mul_b_rc( nthreads, nvec, n, m, alpha, beta, A, jA, iA, x, y )
!DIR$ ATTRIBUTES DLLEXPORT :: a_mul_b_rc
!DIR$ ATTRIBUTES ALIAS: 'a_mul_b_rc_':: a_mul_b_rc

! y = beta*y  +  alpha * A*x

use omp_lib
implicit none

integer(kind=8),intent(in):: nthreads
integer(kind=8),intent(in):: nvec
integer(kind=8),intent(in):: n  ! # of columns in A
integer(kind=8),intent(in):: m  ! # of rows in A

complex(kind=8),intent(in):: alpha, beta
real(kind=8),intent(in):: A(*)
integer(kind=8),intent(in):: jA(*), iA(n+1)
complex(kind=8),intent(in):: x(n,nvec)
complex(kind=8),intent(inout):: y(m,nvec)

integer ivec, i, j1,j2, j, jaj, mythread, mm, jm
complex(kind=8) xi
complex(kind=8),allocatable:: yt(:)

include "A_mul_B.fi"

return
end subroutine a_mul_b_rc

!--------------------------------------------------------------------

subroutine a_mul_b_cc( nthreads, nvec, n, m, alpha, beta, A, jA, iA, x, y )
!DIR$ ATTRIBUTES DLLEXPORT :: a_mul_b_cc
!DIR$ ATTRIBUTES ALIAS: 'a_mul_b_cc_':: a_mul_b_cc

! y = beta*y  +  alpha * A*x

use omp_lib
implicit none

integer(kind=8),intent(in):: nthreads
integer(kind=8),intent(in):: nvec
integer(kind=8),intent(in):: n  ! # of columns in A
integer(kind=8),intent(in):: m  ! # of rows in A

complex(kind=8),intent(in):: alpha, beta
complex(kind=8),intent(in):: A(*)
integer(kind=8),intent(in):: jA(*), iA(n+1)
complex(kind=8),intent(in):: x(n,nvec)
complex(kind=8),intent(inout):: y(m,nvec)

integer ivec, i, j1,j2, j, jaj, mythread, mm, jm
complex(kind=8) xi
complex(kind=8),allocatable:: yt(:)

include "A_mul_B.fi"

return
end subroutine a_mul_b_cc

