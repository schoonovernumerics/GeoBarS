! NodalStorage_Class.f90
! 
! Copyright 2018 Joseph Schoonover <joeschoonover@fluidnumerics.com>, Fluid Numerics, LLC
!
! //////////////////////////////////////////////////////////////////////////////////////////////// !

!> \file NodalStorage_Class.f90
!! Contains the \ref NodalStorage_Class module, and <BR>
!! defines the \ref NodalStorage data-structure.


!> \defgroup NodalStorage_Class NodalStorage_Class 
!! This module defines the NodalStorage data-structure and its associated routines.

MODULE NodalStorage_Class

! src/common/
 USE ModelPrecision
 USE ConstantsDictionary
 USE CommonRoutines
! src/interp/
 USE Quadrature
 USE Lagrange_Class

IMPLICIT NONE

!> \addtogroup NodalStorage_Class 
!! @{

!> \struct NodalStorage
!!  The NodalStorage class contains attributes needed for implementing spectral element methods
!!  in 3-D.
!!  
!!  An interpolant is formed that handles mapping between a computational "quadrature" mesh and a
!!  uniform plotting mesh. Quadrature (integration) weights are stored for use with Galerkin type
!!  methods. Galerkin derivative matrices (collocation derivative matrices weighted by appropriate
!!  ratios of the quadrature weights) are stored to facilitate the computation of weak derivatives.
!!  Finally, an interpolation matrix and accompanying subroutine is provided to interpolate 3-D data, 
!!  defined on the quadrature mesh, to the element boundaries.
!!
!! <H2> NodalStorage </H2>
!! <H3> Attributes </H3>
!!    <table>
!!       <tr> <th> N <td> INTEGER  <td> Polynomial degree of the spectral element method
!!       <tr> <th> nPlot <td> INTEGER <td> Number uniform plotting points
!!       <tr> <th> interp <td> Lagrange <td> Lagrange interpolant
!!       <tr> <th> qWeight(0:N) <td> REAL(prec) <td> Quadrature integration weights
!!       <tr> <th> dMatS(0:N,0:N) <td> REAL(prec) <td> Either the DG or CG derivative matrix
!!       <tr> <th> dMatP(0:N,0:N) <td> REAL(prec) <td> Either the DG or CG derivative matrix transpose
!!       <tr> <th> bMat(0:1,0:N) <td> REAL(prec) <td> Matrix for interpolating data to element boundaries
!!    </table>
!!
!! <H3> Procedures </H3>
!!    See \ref NodalStorage_Class for more information. The first column lists the "call-name" and 
!!    the second column lists the name of routine that is aliased onto the call-name.
!!    <table>
!!       <tr> <th> Build <td> Build_NodalStorage
!!       <tr> <th> Trash <td> Trash_NodalStorage
!!       <tr> <th> CalculateAtBoundaries_1D <td> CalculateAtBoundaries_1D_NodalStorage
!!       <tr> <th> CalculateAtBoundaries_2D <td> CalculateAtBoundaries_2D_NodalStorage
!!       <tr> <th> CalculateAtBoundaries_3D <td> CalculateAtBoundaries_3D_NodalStorage
!!    </table>
!!

!>@}
   TYPE NodalStorage
      INTEGER                 :: N, nPlot
      TYPE(Lagrange)          :: interp      ! Lagrange interpolant
      REAL(prec), ALLOCATABLE :: qWeight(:)  ! Quadrature weights for integration
      REAL(prec), ALLOCATABLE :: dMatS(:,:)  ! Derivative matrix
      REAL(prec), ALLOCATABLE :: dMatP(:,:)  ! Derivative matrix
      REAL(prec), ALLOCATABLE :: bMat(:,:)   ! Matrix for interpolating functions to boundaries of 
                                             ! an element
      CONTAINS

      ! Manual Constructors/Destructors
      PROCEDURE :: Build => Build_NodalStorage
      PROCEDURE :: Trash => Trash_NodalStorage

      ! Type-Specific
      PROCEDURE :: CalculateAtBoundaries_1D => CalculateAtBoundaries_1D_NodalStorage
      PROCEDURE :: CalculateAtBoundaries_2D => CalculateAtBoundaries_2D_NodalStorage
      PROCEDURE :: CalculateAtBoundaries_3D => CalculateAtBoundaries_3D_NodalStorage
      
    END TYPE NodalStorage
    
 CONTAINS
!
!
!==================================================================================================!
!------------------------------- Manual Constructors/Destructors ----------------------------------!
!==================================================================================================!
!
!
!> \addtogroup NodalStorage_Class 
!! @{ 
! ================================================================================================ !
! S/R Build 
! 
!> \fn Build_NodalStorage 
!!  Allocates space fills values for the NodalStorage attributes using to the specified 
!!  quadrature and approximation form.
!! 
!! 
!! <H2> Usage : </H2> 
!! <B>TYPE</B>(NodalStorage) :: this <BR>
!! <B>INTEGER</B>               :: N, nPlot
!!         .... <BR>
!!     ! To build a  structure for Continuous Galerkin with Gauss-Lobatto quadrature <BR>
!!     <B>CALL</B> this % Build( N, nPlot, GAUSS_LOBATTO, CG ) <BR>
!!
!!     ! To build a  structure for Discontinuous Galerkin with Gauss quadrature <BR>
!!     <B>CALL</B> this % Build( N, nPlot, GAUSS, DG ) <BR>
!! 
!!  <H2> Parameters : </H2>
!!  <table> 
!!   <tr> <td> out <th> myNodal <td> NodalStorage <td> On output, the attributes of the
!!                                                        NodalStorage data structure are filled
!!                                                        in.
!!   <tr> <td> in <th> N <td> INTEGER <td> Polynomial degree of the method.
!!   <tr> <td> in <th> nPlot <td> INTEGER <td> The number of uniform plotting points in each 
!!                                             computational direction.
!!   <tr> <td> in <th> quadrature <td> INTEGER <td> A flag for specifying the desired type of 
!!                                                  quadrature. Can be set to either GAUSS or
!!                                                  GAUSS_LOBATTO. See \ref ModelFlags.f90 for
!!                                                  flag definitions.
!!   <tr> <td> in <th> approxForm <td> INTEGER <td> A flag for specifying the type of method that 
!!                                                  you are using. Can be set to either CG or DG.
!!                                                  See \ref ModelFlags.f90 for flag definitions.
!! 
!!  </table>  
!!   
! ================================================================================================ ! 
!>@}
 SUBROUTINE Build_NodalStorage( myNodal, N, nPlot, quadrature, approxForm  )

   IMPLICIT NONE
   CLASS(NodalStorage), INTENT(out) :: myNodal
   INTEGER, INTENT(in)                 :: N
   INTEGER, INTENT(in)                 :: nPlot
   INTEGER, INTENT(in)                 :: quadrature
   INTEGER, INTENT(in)                 :: approxForm
   !LOCAL
   INTEGER                 :: i, j
   REAL(prec), ALLOCATABLE :: tempS(:), tempQ(:), tempUni(:)

      myNodal % N     = N
      myNodal % nPlot = nPlot
      
      ! Allocate space
      ALLOCATE( myNodal % dMatS(0:N,0:N), &
                myNodal % dMatP(0:N,0:N), &
                myNodal % bMat(0:1,0:N), &
                myNodal % qWeight(0:N) )
                
      myNodal % dMatS   = ZERO
      myNodal % dMatP   = ZERO
      myNodal % bMat    = ZERO
      myNodal % qWeight = ZERO

      ALLOCATE( tempS(0:N), tempQ(0:N), tempUni(0:nPlot) )
      
      ! Generate the quadrature
      CALL LegendreQuadrature( N, tempS, tempQ, quadrature )
      myNodal % qWeight = tempQ      

      ! Build and store the interpolant
      tempUni = UniformPoints( -ONE, ONE, nPlot )
      CALL myNodal % interp % Build( N, nPlot, tempS, tempUni )
   
      ! Calculate and store the interpolants evaluated at the endpoints
      myNodal % bMat(0,0:N) = myNodal % interp % CalculateLagrangePolynomials( -ONE )
      myNodal % bMat(1,0:N) = myNodal % interp % CalculateLagrangePolynomials( ONE )
      
      IF( approxForm == CG )then ! Continuous Galerkin, store the derivative matrices as is

         myNodal % dMatS = myNodal % interp % D
         myNodal % dMatP = myNodal % interp % DTr

      ELSEIF( approxForm == DG )then
      
         ! For Discontinuous Galerkin, the matrix is transposed and multiplied by a ratio of quadrature
         ! weights.
        DO j = 0, N ! loop over the matrix rows
            DO i = 0, N ! loop over the matrix columns

               myNodal % dMatS(i,j) = -myNodal % interp % D(j,i)*&
                                         myNodal % qWeight(j)/&
                                         myNodal % qWeight(i)

            ENDDO
         ENDDO
         
         DO j = 0, N ! loop over the matrix rows
            DO i = 0, N ! loop over the matrix columns

               ! Here, we are purposefully using the transpose of the p-derivative matrix
               ! to conform with a new version of "MappedTimeDerivative"
               myNodal % dMatP(j,i) = myNodal % dMatS(i,j)

            ENDDO
         ENDDO
        
         
      ELSE

         PRINT*,'Module NodalStorage_Class.f90 : S/R BuildNodalStorage : Invalid SEM form. Stopping'
         STOP

      ENDIF

      DEALLOCATE( tempS, tempQ, tempUni )

 END SUBROUTINE Build_NodalStorage
!
!> \addtogroup NodalStorage_Class 
!! @{ 
! ================================================================================================ !
! S/R Trash
! 
!> \fn Trash_NodalStorage  
!! Frees memory held by the attributes of the NodalStorage class. 
!! 
!! <H2> Usage : </H2> 
!! <B>TYPE</B>(NodalStorage) :: this <BR>
!!         .... <BR>
!!     <B>CALL</B> this % Trash( ) <BR>
!! 
!!  <H2> Parameters : </H2>
!!  <table> 
!!   <tr> <td> in/out <th> myNodal <td> NodalStorage <td>
!!                         On <B>input</B>, a NodalStorage class that has previously been 
!!                         constructed. <BR>
!!                         On <B>output</B>, the memory held by the attributes of this 
!!                         data-structure have been freed.
!!                                                           
!!  </table>  
!!   
! ================================================================================================ ! 
!>@}
 SUBROUTINE Trash_NodalStorage( myNodal)

   IMPLICIT NONE
   CLASS(NodalStorage), INTENT(inout) :: myNodal

   CALL myNodal % interp % TRASH( )
   DEALLOCATE( myNodal % qWeight, myNodal % dMatS, myNodal % dMatP, myNodal % bMat )


 END SUBROUTINE Trash_NodalStorage
!
!
!==================================================================================================!
!--------------------------- Type Specific Routines -----------------------------------------------!
!==================================================================================================!
!
!
!
!
!> \addtogroup NodalStorage_Class 
!! @{ 
! ================================================================================================ !
! Function CalculateAtBoundaries 
! 
!> \fn CalculateAtBoundaries_NodalStorage
!!  Interpolates a 1-D array of nodal function values, defined on the quadrature mesh,
!!  to the boundaries of the computational element.
!!
!!  Recall that Lagrange-interpolation of data onto a point can be expressed as a matrix-vector 
!!  multiplication (in 1-D).  In 1-D, to interpolate to the boundaries of the computational domain
!!  ( \f$ \xi = -1,1 \f$ ), a \f$ 2 \times N \f$ matrix can be constructed whose columns are the 
!!  Lagrange interpolating polynomials evaluated at \f$ \xi = -1,1 \f$. An array of nodal function
!!  values at the interpolation nodes (identical to the quadrature nodes in a spectral element 
!!  method) can be interpolated to the boundaries through matrix vector multiplication.
!! 
!!  A single matrix-matrix multiplications effectively result in interpolation onto the boundaries.
!! 
!! 
!! <H2> Usage : </H2> 
!! <B>TYPE</B>(NodalStorage) :: this <BR>
!! <B>REAL</B>(prec)         :: f(0:this%N) <BR>
!! <B>REAL</B>(prec)         :: fbound(1:2) <BR>
!!         .... <BR>
!!     fbound = this % CalculateAtBoundaries_1D( f ) <BR>
!! 
!!  <H2> Parameters : </H2>
!!  <table> 
!!   <tr> <td> in <th> myNodal <td> NodalStorage <td> Previously constructed NodalStorage data
!!                                                       structure. 
!!   <tr> <td> in <th> f(0:myNodal%N) <td> REAL(prec) <td> 
!!                     1-D array of nodal function values defined on the quadrature mesh.
!!   <tr> <td> out <th> fBound(1:2) <td> REAL(prec) <td> 
!!                     1-D array of nodal function values derived from interpolation onto the element
!!                     boundaries. The third index cycles over the sides of a 1-D element.
!!                     LEFT=1, RIGHT=2. See \ref ConstantsDictionary.f90 for more details on
!!                     boundary-integer flags.
!!  </table>  
!!   
! ================================================================================================ ! 
!>@}
 FUNCTION CalculateAtBoundaries_1D_NodalStorage( myNodal, f ) RESULT( fBound )

   IMPLICIT NONE
   CLASS(NodalStorage), INTENT(in) :: myNodal
   REAL(prec), INTENT(in)          :: f(0:myNodal % N)
   REAL(prec)                      :: fBound(1:2)
   ! Local
   INTEGER :: N
   REAL(prec) :: bmat(0:1,myNodal % N), fB(0:1)
   
      N = myNodal % N 
      bmat = myNodal % bmat
      
      fB = MATMUL( bMat, f )
      fBound = fB
      
 END FUNCTION CalculateAtBoundaries_1D_NodalStorage
!
!> \addtogroup NodalStorage_Class 
!! @{ 
! ================================================================================================ !
! Function CalculateAtBoundaries 
! 
!> \fn CalculateAtBoundaries_NodalStorage
!!  Interpolates a 2-D array of nodal function values, defined on the quadrature mesh,
!!  to the boundaries of the computational element.
!!
!!  Recall that Lagrange-interpolation of data onto a point can be expressed as a matrix-vector 
!!  multiplication (in 1-D).  In 1-D, to interpolate to the boundaries of the computational domain
!!  ( \f$ \xi = -1,1 \f$ ), a \f$ 2 \times N \f$ matrix can be constructed whose columns are the 
!!  Lagrange interpolating polynomials evaluated at \f$ \xi = -1,1 \f$. An array of nodal function
!!  values at the interpolation nodes (identical to the quadrature nodes in a spectral element 
!!  method) can be interpolated to the boundaries through matrix vector multiplication.
!! 
!!  In 2-D we need to interpolate \f$ 2(N+1) \f$ 1-D arrays to the boundaries. This routine views
!!  the nodal function data as an \f$ N+1 \times (N+1) \f$ matrix. Matrix-matrix multiplcation
!!  between the boundary interpolation matrix and the data-matrix results in boundary data in the
!!  first computational direction. Matrix-matrix multiplcation between the boundary interpolation 
!!  matrix and the data-matrix transpose results in boundary data in the second computational
!!  direction.
!!  Two matrix-matrix multiplications effectively result in interpolation onto the boundaries.
!! 
!! 
!! <H2> Usage : </H2> 
!! <B>TYPE</B>(NodalStorage) :: this <BR>
!! <B>REAL</B>(prec)         :: f(0:this%N, 0:this%N) <BR>
!! <B>REAL</B>(prec)         :: fbound(0:this%N, 1:4) <BR>
!!         .... <BR>
!!     fbound = this % CalculateAtBoundaries_2D( f ) <BR>
!! 
!!  <H2> Parameters : </H2>
!!  <table> 
!!   <tr> <td> in <th> myNodal <td> NodalStorage <td> Previously constructed NodalStorage data
!!                                                       structure. 
!!   <tr> <td> in <th> f(0:myNodal%N, 0:myNodal%N) <td> REAL(prec) <td> 
!!                     2-D array of nodal function values defined on the quadrature mesh.
!!   <tr> <td> out <th> fBound(0:myNodal%N, 1:4) <td> REAL(prec) <td> 
!!                     2-D array of nodal function values derived from interpolation onto the element
!!                     boundaries. The third index cycles over the sides of a 2-D element.
!!                     SOUTH=1, EAST=2, NORTH=3, WEST=4. See \ref ConstantsDictionary.f90
!!                     for more details on boundary-integer flags.
!!  </table>  
!!   
! ================================================================================================ ! 
!>@}
 FUNCTION CalculateAtBoundaries_2D_NodalStorage( myNodal, f ) RESULT( fBound )

   IMPLICIT NONE
   CLASS(NodalStorage) :: myNodal
   REAL(prec)          :: f(0:myNodal % N, 0:myNodal % N)
   REAL(prec)          :: fBound(0:myNodal % N, 1:4)
   ! Local
   INTEGER :: N
   REAL(prec) :: bmat(0:1,0:myNodal % N)
   REAL(prec) :: fWE(0:1,0:myNodal % N), fSN(0:1,0:myNodal % N)
   REAL(prec) :: fT(0:myNodal % N, 0:myNodal % N)
   
      N    = myNodal % N
      bmat = myNodal % bmat
      fT   = TRANSPOSE( f )
      
      fWE = MATMUL( bMat, f )
      fSN = MATMUL( bMat, fT )
      
      fBound(0:N,WEST)  = fWE(0,0:N)
      fBound(0:N,EAST)  = fWE(1,0:N)
      fBound(0:N,SOUTH) = fSN(0,0:N)
      fBound(0:N,NORTH) = fSN(1,0:N)
      
      
 END FUNCTION CalculateAtBoundaries_2D_NodalStorage
!
!> \addtogroup NodalStorage_Class 
!! @{ 
! ================================================================================================ !
! Function CalculateAtBoundaries_3D 
! 
!> \fn CalculateAtBoundaries_NodalStorage
!!  Interpolates a 3-D array of nodal function values, defined on the quadrature mesh,
!!  to the boundaries of the computational element.
!!
!!  Recall that Lagrange-interpolation of data onto a point can be expressed as a matrix-vector 
!!  multiplication (in 1-D).  In 1-D, to interpolate to the boundaries of the computational domain
!!  ( \f$ \xi = -1,1 \f$ ), a \f$ 2 \times N \f$ matrix can be constructed whose columns are the 
!!  Lagrange interpolating polynomials evaluated at \f$ \xi = -1,1 \f$. An array of nodal function
!!  values at the interpolation nodes (identical to the quadrature nodes in a spectral element 
!!  method) can be interpolated to the boundaries through matrix vector multiplication.
!! 
!!  In 3-D we need to interpolate \f$ 3(N+1)^2 \f$ 1-D arrays to the boundaries. This routine forms
!!  3 matrices that are \f$ N+1 \times (N+1)^2 \f$ by collapsing pairs of array indices. The columns
!!  of each matrix correspond to the 1-D nodal function values in a given computational direction.
!!  Three matrix-matrix multiplications effectively result in interpolation onto the boundaries.
!! 
!! 
!! <H2> Usage : </H2> 
!! <B>TYPE</B>(NodalStorage) :: this <BR>
!! <B>REAL</B>(prec)         :: f(0:this%N, 0:this%N, 0:this%N) <BR>
!! <B>REAL</B>(prec)         :: fbound(0:this%N, 0:this%N, 1:6) <BR>
!!         .... <BR>
!!     fbound = this % CalculateAtBoundaries_3D( f ) <BR>
!! 
!!  <H2> Parameters : </H2>
!!  <table> 
!!   <tr> <td> in <th> myNodal <td> NodalStorage <td> Previously constructed NodalStorage data
!!                                                       structure. 
!!   <tr> <td> in <th> f(0:myNodal%N, 0:myNodal%N, 0:myNodal%N) <td> REAL(prec) <td> 
!!                     3-D array of nodal function values defined on the quadrature mesh.
!!   <tr> <td> out <th> fBound(0:myNodal%N, 0:myNodal%N, 1:6) <td> REAL(prec) <td> 
!!                     3-D array of nodal function values derived from interpolation onto the element
!!                     boundaries. The third index cycles over the sides of a 3-D element.
!!                     SOUTH=1, EAST=2, NORTH=3, WEST=4, BOTTOM=5, TOP=6. See \ref ConstantsDictionary.f90
!!                     for more details on boundary-integer flags.
!!  </table>  
!!   
! ================================================================================================ ! 
!>@}
 FUNCTION CalculateAtBoundaries_3D_NodalStorage( myNodal, f ) RESULT( fBound )

   IMPLICIT NONE
   CLASS(NodalStorage) :: myNodal
   REAL(prec)          :: f(0:myNodal % N, 0:myNodal % N, 0:myNodal % N)
   REAL(prec)          :: fBound(0:myNodal % N, 0:myNodal % N, 1:6)
   ! Local
   INTEGER :: N, j, k, col
   REAL(prec) :: bmat(0:1,0:myNodal % N)
   REAL(prec) :: floc1(0:myNodal % N,0:myNodal % interp % Nc)
   REAL(prec) :: floc2(0:myNodal % N,0:myNodal % interp % Nc)
   REAL(prec) :: floc3(0:myNodal % N,0:myNodal % interp % Nc)
   REAL(prec) :: fWE(0:1,0:myNodal % interp % Nc)
   REAL(prec) :: fSN(0:1,0:myNodal % interp % Nc)
   REAL(prec) :: fBT(0:1,0:myNodal % interp % Nc)
   
      N    = myNodal % N
      bmat = myNodal % bmat
      
      ! Condense the 3-D array to 2-D arrays to compute derivatives in each computational direction
      DO k = 0, N
         DO j = 0, N
            col = j + (N+1)*k
            floc1(0:N,col) = f(0:N,j,k)
            floc2(0:N,col) = f(j,0:N,k)
            floc3(0:N,col) = f(j,k,0:N)
         ENDDO
      ENDDO
      
      fWE = MATMUL( bMat, floc1 )
      fSN = MATMUL( bMat, floc2 )
      fBT = MATMUL( bMat, floc3 )
      
      ! Remap derivatives to the 3-D arrays
      DO k = 0, N
         DO j = 0, N
            col = j + (N+1)*k
            fBound(j,k,WEST)   = fWE(0,col) 
            fBound(j,k,EAST)   = fWE(1,col) 
            fBound(j,k,SOUTH)  = fSN(0,col) 
            fBound(j,k,NORTH)  = fSN(1,col) 
            fBound(j,k,BOTTOM) = fBT(0,col)
            fBound(j,k,TOP)    = fBT(1,col)  
         ENDDO
      ENDDO
      
 END FUNCTION CalculateAtBoundaries_3D_NodalStorage

END MODULE NodalStorage_Class
