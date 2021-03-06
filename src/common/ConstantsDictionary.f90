! ConstantsDictionary.f90
! 
! Copyright 2018 Joseph Schoonover <joeschoonover@fluidnumerics.com>, Fluid Numerics, LLC
!
! //////////////////////////////////////////////////////////////////////////////////////////////// !

!> \file ConstantsDictionary.f90
!! Contains the \ref ConstantsDictionary module

!> \defgroup ConstantsDictionary ConstantsDictionary
!! This module defines a set of mathematical constants, time integrator parameters, and boundary 
!! condition flags.

 MODULE ConstantsDictionary

   USE ModelPrecision

  !*************************************************************!
  ! ------------------ MATHEMATICAL CONSTANTS ------------------!
  ! ************************************************************!
  !                                                             !
  ! ------------------------------------------------------------!
    REAL(prec), PARAMETER :: pi   = 4.0_prec*atan(1.0_prec)
    REAL(prec), PARAMETER :: ZERO = 0.0_prec
    REAL(prec), PARAMETER :: ONE  = 1.0_prec
    REAL(prec), PARAMETER :: TWO  = 2.0_prec
    REAL(prec), PARAMETER :: HALF = 0.5_prec
    REAL(prec), PARAMETER :: TOL  = epsilon(1.0_prec)


    REAL(prec), PARAMETER :: fillValue = -9999.99_prec
    INTEGER, PARAMETER    :: fillValueInt = -99999
  !*************************************************************!
  ! ----------------- ROOT FINDER CONSTANTS --------------------!
  ! ************************************************************!
  !                                                             !
  ! ------------------------------------------------------------!
    REAL(prec), PARAMETER :: newtonTolerance = 10.0**(-10)
    INTEGER, PARAMETER    :: newtonMax       = 100
  
  !*************************************************************!
  ! ----------------- TIME STEPPING CONSTANTS ------------------!
  ! ************************************************************!
  !                                                             !
  ! ------------------------------------------------------------!
  ! Runge-Kutta 3rd Order, low storage constants
    REAL(prec), PARAMETER :: rk3_a(1:3) = (/ 0.0_prec, -5.0_prec/9.0_prec, -153.0_prec/128.0_prec /)
    REAL(prec), PARAMETER :: rk3_b(1:3) = (/ 0.0_prec, 1.0_prec/3.0_prec, 3.0_prec/4.0_prec /)
    REAL(prec), PARAMETER :: rk3_g(1:3) = (/ 1.0_prec/3.0_prec, 15.0_prec/16.0_prec, 8.0_prec/15.0_prec /)

  !*************************************************************!
  ! ------------------- PHYSICAL CONSTANTS ---------------------!
  ! ************************************************************!
  !                                                             !
  ! ------------------------------------------------------------!
  ! Time conversion factors
    REAL(prec), PARAMETER   :: secondsToMinutes = 1.0_prec/60.0_prec                   ! conversion for seconds to minutes
    REAL(prec), PARAMETER   :: minutesToHours   = 1.0_prec/60.0_prec                   ! conversion for minutes to hours
    REAL(prec), PARAMETER   :: hoursToDays      = 1.0_prec/24.0_prec                   ! conversion for hours to days
    REAL(prec), PARAMETER   :: daysToMonths     = 12.0_prec/365.25_prec                ! conversion for days to months
    REAL(prec), PARAMETER   :: monthsToYears    = 1.0_prec/12.0_prec                   ! conversion for months to years
    REAL(prec), PARAMETER   :: daysToSeconds    = 86400.0_prec

!*************************************************************!
  ! ------------------- Edge/Face Numbering --------------------!
  ! ************************************************************!
  ! This block of flags pertains to the integer associates with !
  ! assigning boundary edge and face ordering of an element     !
  !                                                             !
  ! ------------------------------------------------------------!
    INTEGER, PARAMETER :: left   = 1
    INTEGER, PARAMETER :: right  = 2
    INTEGER, PARAMETER :: south  = 1
    INTEGER, PARAMETER :: east   = 2
    INTEGER, PARAMETER :: north  = 3
    INTEGER, PARAMETER :: west   = 4
    INTEGER, PARAMETER :: bottom = 5
    INTEGER, PARAMETER :: top    = 6
    
    INTEGER, PARAMETER :: nHexFaces  = 6
    INTEGER, PARAMETER :: nHexNodes  = 8
    INTEGER, PARAMETER :: nQuadEdges = 4
    INTEGER, PARAMETER :: nQuadNodes = 4

  !*************************************************************!
  ! ----------------- BOUNDARY CONDITION FLAGS -----------------!
  ! ************************************************************!
  ! This block of flags pertain to boundary condition flags     !
  ! that make it easy to reference which boundary condition     !
  ! to USE. These flags improve code readability and are        !
  ! easy to USE.                                                !
  !                                                             !
  ! For any boundary condition, it is imperative that the flag  !
  ! be negative.                                                !
  !                                                             !
  ! "Cornernodes" are an exception to this rule                 !
  !                                                             !
  ! The convention for any software within the                  !
  ! SCHOONER package is that the elements of a mesh and have    !
  ! a positive element ID. In the "edge" information for a mesh !
  ! the secondary element ID can be an actual element ID or set !
  ! to a boundary condition flag. A boundary condition check is !
  ! usually done by  passing through a conditional              !
  !                                                             !
  !           " if( secondaryElement < 0 )"                     !
  !                                                             !
  ! ------------------------------------------------------------!
  !==============================================!
  ! ------------- Node Specifiers -------------- !
  !==============================================!
   INTEGER, PARAMETER :: INTERIOR = 1
   INTEGER, PARAMETER :: BOUNDARY = 0
  !
  !==============================================!
  ! --------- Discontinuous Galerkin ----------- !
  !==============================================!
   INTEGER, PARAMETER :: NO_NORMAL_FLOW = -100
   INTEGER, PARAMETER :: RADIATION      = -101
   INTEGER, PARAMETER :: PRESCRIBED     = -102
   INTEGER, PARAMETER :: InflowOne      = -103
   INTEGER, PARAMETER :: InflowTwo      = -104
   INTEGER, PARAMETER :: SEA_FLOOR      = -105
   INTEGER, PARAMETER :: SHARED         = -106
  !
  !==============================================!
  ! ---------- Continuous Galerkin ------------- !
  !==============================================!
   INTEGER, PARAMETER :: DIRICHLET = -200
   INTEGER, PARAMETER :: HOMOGENEOUS_NEUMANN = -201
   INTEGER, PARAMETER :: ROBIN = -202
   INTEGER, PARAMETER :: ROBIN_FORCED = -204
   INTEGER, PARAMETER :: INHOMOGENEOUS_NEUMANN = -203
   INTEGER, PARAMETER :: NEUMANN = -100 ! = NO_NORMAL_FLOW
   INTEGER, PARAMETER :: NEUMANN_WALL = -206
   INTEGER, PARAMETER :: DIRICHLET_INFLOW = -207
   INTEGER, PARAMETER :: DIRICHLET_OUTFLOW = -208
  !
  !==============================================!
  !
  !*************************************************************!
  ! ----------------- MODEL FORMULATION FLAGS ------------------!
  ! ************************************************************!
  ! This block of flags pertains to those which are USEd to     !
  ! change the formulation of a particular model, such as the   !
  ! "ShallowWater" class which offers up three different flavors!
  ! of the model. Additionally, multipurpose flags which are    !
  ! USEd for specifying the TYPE of quadrature are given here.  !
  !                                                             !
  ! ------------------------------------------------------------!
  !==============================================!
  ! --------------- Quadrature------------------ !
  !==============================================!
   INTEGER, PARAMETER :: GAUSS = 1
   INTEGER, PARAMETER :: GAUSS_LOBATTO = -1
   INTEGER, PARAMETER :: DG = 2000
   INTEGER, PARAMETER :: CG = 2001
   INTEGER, PARAMETER :: LEGENDRE_BASIS = 2100
   INTEGER, PARAMETER :: CHEBYSHEV_BASIS = 2101
  !
  !==============================================!
  ! ---------------- Geometry ------------------ !
  !==============================================!
   INTEGER, PARAMETER      :: maxNodalValence = 16
  !
  !==============================================!
  ! --------------- Model forms ---------------- !
  !==============================================!
   INTEGER, PARAMETER :: LINEAR = 99               ! Solves the Linearized form of the shallow water equations
   INTEGER, PARAMETER :: NONLINEAR = 100
   INTEGER, PARAMETER :: SKEW_SYMMETRIC = 101      ! Solves the Skew-symmetric form of the shallow water equations
   INTEGER, PARAMETER :: CONSERVATIVE = 102        ! Solves the Conservative form of the shallow water equations
  !==============================================!
  !==============================================!
  ! --------- Special plotting flags ----------- !
  !==============================================!
   INTEGER, PARAMETER :: surf2din3d = 500
   INTEGER, PARAMETER :: keepItFlat = 501


! Misc. INTEGER and CHARACTER flag definitions
  INTEGER, PARAMETER      :: NONE = 0
  CHARACTER(1), PARAMETER :: nada = ' '

!$acc declare copyin( ZERO )
!$acc declare pcopyin( rk3_a )
!$acc declare pcopyin( rk3_b )
!$acc declare pcopyin( rk3_g )
 END MODULE ConstantsDictionary
