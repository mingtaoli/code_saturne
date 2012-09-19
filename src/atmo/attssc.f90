!-------------------------------------------------------------------------------

! This file is part of Code_Saturne, a general-purpose CFD tool.
!
! Copyright (C) 1998-2012 EDF S.A.
!
! This program is free software; you can redistribute it and/or modify it under
! the terms of the GNU General Public License as published by the Free Software
! Foundation; either version 2 of the License, or (at your option) any later
! version.
!
! This program is distributed in the hope that it will be useful, but WITHOUT
! ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
! FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
! details.
!
! You should have received a copy of the GNU General Public License along with
! this program; if not, write to the Free Software Foundation, Inc., 51 Franklin
! Street, Fifth Floor, Boston, MA 02110-1301, USA.

!-------------------------------------------------------------------------------

subroutine attssc &
     !================

     ( nvar   , nscal  , ncepdp , ncesmp ,                            &
     iscal  ,                                                       &
     itypfb ,                                                       &
     icepdc , icetsm , itypsm ,                                     &
     izfppp ,                                                       &
     dt     , rtpa   , rtp    , propce , propfa , propfb ,          &
     coefa  , coefb  , ckupdc , smacel ,                            &
     crvexp , crvimp )

!===============================================================================
! Purpose :
! ----------

!   Atmospheric physics subroutine.

!   Additional right-hand side source terms for scalar equations

!   if 1D atmospheric radiative module is used (iatra1 = 1) additional source terms
!   for the thermal scalar equation to take into account the radiative forcing.


!-------------------------------------------------------------------------------
!ARGU                             ARGUMENTS
!__________________.____._____.________________________________________________.
! name             !type!mode ! role                                           !
!__________________!____!_____!________________________________________________!
! nvar             ! i  ! <-- ! total number of variables                      !
! nscal            ! i  ! <-- ! total number of scalars                        !
! ncepdp           ! i  ! <-- ! number of cells with head loss                 !
! ncesmp           ! i  ! <-- ! number of cells with mass source term          !
! iscal            ! i  ! <-- ! scalar number                                  !
! itypfb(nfabor    ! te ! --> ! type des faces de bord                         !
! icepdc(ncelet    ! te ! <-- ! numero des ncepdp cellules avec pdc            !
! icetsm(ncesmp    ! te ! <-- ! numero des cellules a source de masse          !
! itypsm           ! te ! <-- ! type de source de masse pour les               !
! (ncesmp,nvar)    !    !     !  variables (cf. ustsma)                        !
! izfppp           ! te ! --> ! numero de zone de la face de bord              !
! (nfabor)         !    !     !  pour le module phys. part.                    !
! dt(ncelet)       ! ra ! <-- ! time step (per cell)                           !
! rtp, rtpa        ! ra ! <-- ! calculated variables at cell centers           !
!  (ncelet, *)     !    !     !  (at current and previous time steps)          !
! propce(ncelet, *)! ra ! <-- ! physical properties at cell centers            !
! propfa(nfac, *)  ! ra ! <-- ! physical properties at interior face centers   !
! propfb(nfabor, *)! ra ! <-- ! physical properties at boundary face centers   !
! coefa, coefb     ! ra ! <-- ! boundary conditions                            !
!  (nfabor, *)     !    !     !                                                !
! ckupdc           ! tr ! <-- ! tableau de travail pour pdc                    !
!  (ncepdp,6)      !    !     !                                                !
! smacel           ! tr ! <-- ! valeur des variables associee a la             !
! (ncesmp,*   )    !    !     !  source de masse                               !
!                  !    !     !  pour ivar=ipr, smacel=flux de masse           !
! crvexp(ncelet)   ! tr ! --> ! second membre explicite                        !
! crvimp(ncelet    ! tr ! --> ! partie diagonale implicite                     !
!__________________!____!_____!________________________________________________!

!     Type: i (integer), r (real), s (string), a (array), l (logical),
!           and composite types (ex: ra real array)
!     mode: <-- input, --> output, <-> modifies data, --- work array
!===============================================================================

!===============================================================================
! Module files
!===============================================================================

use paramx
use numvar
use entsor
use optcal
use cstphy
use parall
use period
use mesh
use atincl

!===============================================================================

implicit none

! Arguments

integer          nvar   , nscal
integer          ncepdp , ncesmp
integer          nideve , nrdeve , nituse , nrtuse
integer          iscal

integer          itypfb(nfabor)
integer          icepdc(ncepdp)
integer          icetsm(ncesmp), itypsm(ncesmp,nvar)
integer          izfppp(nfabor)

double precision dt(ncelet), rtp(ncelet,*), rtpa(ncelet,*)
double precision propce(ncelet,*)
double precision propfa(nfac,*), propfb(nfabor,*)
double precision coefa(nfabor,*), coefb(nfabor,*)
double precision ckupdc(ncepdp,6), smacel(ncesmp,nvar)
double precision crvexp(ncelet), crvimp(ncelet)

! Local variables

character*80     chaine
integer          ivar, ipcrom, iel

integer ntmax,nzmax,i
double precision pp, dum

double precision, dimension(:), allocatable :: ray3Di, ray3Dst
double precision, dimension(:,:), allocatable, save :: grad1, grad2
double precision, dimension(:), allocatable, save :: r3

double precision, save :: qliqmax,r3max
logical, save :: r3_is_defined = .FALSE.
integer, save :: treated_scalars=0

double precision, dimension(:), allocatable :: pphy
double precision, dimension(:), allocatable :: refrad

double precision ddd11,ddd12,ddd13,ddd21,ddd22,ddd23

!===============================================================================
!===============================================================================
! 1. INITIALISATION
!===============================================================================

! --- Numero du scalaire a traiter : ISCAL
! --- Numero de la variable associee au scalaire a traiter ISCAL
ivar = isca(iscal)

! --- Nom de la variable associee au scalaire a traiter ISCAL
chaine = nomvar(ipprtp(ivar))

! --- Index number of the density in the propce array
ipcrom = ipproc(irom)

!===============================================================================
! 2. TAKING INTO ACOUNT RADIATIVE FORCING FOR THE 1D RADIATIVE MODULE :
!===============================================================================

if (ippmod(iatmos).ge.1.and.iatra1.ge.1) then

  !   2.1 Source terms in the equation of the liquid potential temperature :
  !  -----------------------------------------------------------------------

  if (ivar.eq.isca(iscalt)) then

    allocate(ray3Di(ncel))
    allocate(ray3Dst(ncel))

    ! --- Calls the 1D raditive model
    ! --- Computes the divergence of the ir and solar radiative fluxes :

    ! --- Cressman interpolation of the 1D radiative fluxes on the 3D mesh:
    call atr1vf   &
         (rtpa, rtp, propce )

    call mscrss   &
         (idrayi, 1, ray3Di)

    call mscrss   &
         (idrayst, 1, ray3Dst)

    ! --- Explicite source term for the thermal scalar equation:

    do iel = 1, ncel
      crvexp(iel) = crvexp(iel) +                                                &
           cp0*volume(iel)*propce(iel,ipcrom)*(-ray3Di(iel) + ray3Dst(iel))
    enddo

    deallocate(ray3Di)
    deallocate(ray3Dst)

  endif

endif

!===============================================================================
! 3. TAKING INTO SOURCE TERMS FORT THETAL, QW and NC DUE TO SEDIMENTATION OF DROPS
!===============================================================================
! we assume that the vertical direction (given by the gravity)
! is ALWAYS oriented along the z axis.

if ( ippmod(iatmos).eq.2.and.modsedi.eq.1 ) then ! for humid atmosphere physics only

  ! Test minimum liquid water to carry out drop sedimentation
  qliqmax = 0.d0
  do iel = 1, ncelet
    qliqmax = max(propce(iel,ipproc(iliqwt)),qliqmax)
  enddo

  if(qliqmax.gt.1e-8)then

    if (.not.r3_is_defined)then

      ! First : diagnose the droplet number

      if(modnuc.gt.0)then
        ! nucleation : when liquid water present calculate the
        ! number of condensation nucleii (ncc) and if the droplet number (nc)
        ! is smaller than ncc set it to ncc.
        allocate(pphy(ncelet))

        if (imeteo.eq.0) then
            ! calculate pressure from standard atm
          do iel = 1, ncel
            call atmstd(xyzcen(3,iel),pphy(iel),dum,dum)
          enddo
        else
            ! calculate pressure from meteo file
          do iel = 1, ncel
            call intprf                                                 &
                 ( nbmett, nbmetm,                                      &
                 ztmet , tmmet , phmet , xyzcen(3,iel), ttcabs,         &
                 pphy(iel) )
          enddo
        endif

        allocate(refrad(ncelet))
        do iel = 1, ncel
          refrad(iel) = 0.d+00
        enddo

        call nuclea (                                                 &
             rtp(1,isca(iscapp(3))),                                  &
             rtp(1,iw),                                               &
             propce(1,ipproc(irom)),                                  &
             propce(1,ipproc(itempc)),                                &
             propce(1,ipproc(iliqwt)),                                &
             pphy, refrad)

        deallocate(pphy)
        deallocate(refrad)
      endif ! (modnuc.gt.0)

      allocate(r3(ncelet))
      call define_r3()
      r3_is_defined=.TRUE.

      allocate(grad1(ncelet,3))
      call grad_sed_ql(grad1)

      allocate(grad2(ncelet,3))
      call grad_sed_nc(grad2)

    endif ! r3_not_defined

    ivar = isca(iscal)
    if (ivar.eq.isca(iscalt) )then

      do iel = 1, ncel
        if (imeteo.eq.0) then
          call atmstd(xyzcen(3,iel),pp,dum,dum)
        else
          call intprf &
               ( nbmett, nbmetm,                                        &
                 ztmet , tmmet , phmet , xyzcen(3,iel) , ttcabs, pp )
        endif

        crvexp(iel) = crvexp(iel) -clatev*(ps/pp)**(rair/cp0)           &
                    *(volume(iel)*grad1(iel,3)/propce(iel,ipproc(irom)))
      enddo
      treated_scalars=treated_scalars + 1

    elseif (ivar.eq.isca(iscapp(2))) then

      do iel = 1, ncel
        crvexp(iel) = crvexp(iel) - volume(iel)*grad1(iel,3)          &
                    / propce(iel,ipproc(irom))
      enddo

      treated_scalars = treated_scalars + 1
    elseif(ivar.eq.isca(iscapp(3)))then

      do iel = 1, ncel
        crvexp(iel) = crvexp(iel) + volume(iel)*grad2(iel,3)
      enddo

      treated_scalars = treated_scalars + 1

    endif

    treated_scalars = mod(treated_scalars,3)

    if(treated_scalars.eq.0) then ! keep the same gradients for the 3 atm. var.
      do iel = 1, ncel    ! clean the arrays
        r3(iel) = 0.d0
        do i = 1, 3
          grad1(iel,i) = 0.d0
          grad1(iel,i) = 0.d0
        enddo
      enddo
      deallocate(r3)
      r3_is_defined=.FALSE.
      deallocate(grad1)
      deallocate(grad2)
    endif
  endif ! qliqmax.gt.1.d-8
endif! ( ippmod(iatmos).eq.2 ) then ! for humid atmosphere physics only

!--------
! FORMATS
!--------

1000 format(                                                           &
     '  Calcul des termes sources pour la variable : ',A8             )
return
contains

! ***********************************************************************
! *
! ***********************************************************************
subroutine define_r3()

!computes the mean volumic radius of the droplets

double precision rho
double precision qliq
double precision nc
double precision rho_water
parameter (rho_water=1d+3)
double precision a_const
parameter (a_const=0.620350490899d0 ) ! (3/4*PI)**(1/3)
double precision conversion
parameter (conversion=1d+6)! passing from 1/cm**3 to 1/m**3

r3max = 0.d0
do iel = 1, ncel
  rho = propce(iel,ipproc(irom))
  qliq = propce(iel,ipproc(iliqwt))
  nc = rtp(iel,isca(iscapp(3)))
  if(qliq.ge.1e-8)then
    nc = max(nc,1.d0)
    r3(iel) = ((rho*qliq)/(rho_water*nc*conversion))**(1.d0/3.d0)
    r3(iel) = r3(iel)*a_const
  else
    r3(iel) = 0.d0
  endif
  r3max = max(r3(iel),r3max)
enddo
end subroutine define_r3

! *******************************************************************
! *
! *******************************************************************
double precision function vit_sed(r)
implicit none
double precision r
vit_sed = 1.19d+08*r**2
end function vit_sed

! *******************************************************************
! *
! *******************************************************************

subroutine grad_sed_ql(grad)

! Computation of the gradient of rho*qliq*V(r3)*exp(5*sc)

implicit none
double precision grad(ncelet,3)

double precision climgp
double precision epsrgp
double precision extrap

integer    iccocg
integer    iivar
integer    imligp
integer    inc
integer    iphydp
integer    iqpp
integer    iwarnp
integer    nswrgp
double precision,dimension(:),allocatable :: local_coefa
double precision,dimension(:),allocatable :: local_coefb
double precision,dimension(:),allocatable :: local_field

if(r3max.lt.1.d-10) then
  do iel = 1, ncel
    do i = 1, 3
      grad(iel,i) = 0.d0
    enddo
  enddo
  return
endif

! Homogeneous Neumann Boundary Conditions
!----------------------------------------

allocate(local_coefa(nfabor))
do i = 1, nfabor
  local_coefa(i) = 0.d0
enddo
allocate(local_coefb(nfabor))
do i = 1, nfabor
  local_coefb(i) = 1.d0
enddo
allocate(local_field(ncelet))

! --------------------------------------------------------
! Computation of the gradient of rho*qliq*V(r3)*exp(5*sc)
! --------------------------------------------------------

do iel = 1, ncel
  local_field(iel) = propce(iel,ipproc(irom)) & ! volumic mass of the air kg/m3
       *propce(iel,ipproc(iliqwt))   & ! total liquid water content kg/kg
       *vit_sed( r3(iel) )           & ! deposition velocity m/s
       *exp(5*sigc**2)                 ! coefficient coming from log-norm
                                       ! law of the droplet spectrum
enddo

iqpp = isca(iscapp(2))

! options for gradient calculation

iccocg = 1
inc = 1

nswrgp = nswrgr(iqpp)
epsrgp = epsrgr(iqpp)
imligp = imligr(iqpp)
iwarnp = iwarni(iqpp)
climgp = climgr(iqpp)
extrap = extrag(iqpp)

iivar = 0

call grdcel                                                         &
     !==========
     ( iivar  , imrgra , inc    , iccocg , nswrgp ,imligp,          &
     iwarnp , nfecra , epsrgp , climgp , extrap ,                   &
     local_field     , local_coefa , local_coefb ,                  &
     grad   )

deallocate(local_coefa)
deallocate(local_coefb)
deallocate(local_field)

end subroutine grad_sed_ql

! *******************************************************************
! *
! *******************************************************************
subroutine grad_sed_nc(grad)

! Computation of the gradient of rho*qliq*V(r3)*exp(5*sc)

implicit none
double precision grad(ncelet,3)

double precision climgp
double precision epsrgp
double precision extrap

integer    iccocg
integer    iivar
integer    imligp
integer    inc
integer    iphydp
integer    iqpp
integer    iwarnp
integer    nswrgp

double precision,dimension(:),allocatable :: local_coefa
double precision,dimension(:),allocatable :: local_coefb
double precision,dimension(:),allocatable :: local_field

if(r3max.lt.1.d-10) then
  do iel = 1, ncel
    do i = 1, 3
      grad(iel,i) = 0.d0
    enddo
  enddo
  return
endif

! Homogeneous Neumann Boundary Conditions
!----------------------------------------

allocate(local_coefa(nfabor))
do i = 1, nfabor
  local_coefa(i) = 0.d0
enddo
allocate(local_coefb(nfabor))
do i = 1, nfabor
  local_coefb(i) = 1.d0
enddo
allocate(local_field(ncelet))

! --------------------------------------------------------
! Computation of the gradient of Nc*V(r3)*exp(-sc)
! --------------------------------------------------------

do iel = 1, ncel
  local_field(iel) = rtp(iel,isca(iscapp(3))) & ! number of droplets 1/cm**3
       *vit_sed( r3(iel) )                    & ! deposition velocity m/s
       *exp(-sigc**2)                     ! coefficient coming from log-normal
                                          ! law of the droplet spectrum
enddo

iqpp = isca(iscapp(2))

! options for gradient calculation

iccocg = 1
inc = 1

nswrgp = nswrgr(iqpp)
epsrgp = epsrgr(iqpp)
imligp = imligr(iqpp)
iwarnp = iwarni(iqpp)
climgp = climgr(iqpp)
extrap = extrag(iqpp)

iivar = 0

call grdcel                                                         &
     !==========
     ( iivar  , imrgra , inc    , iccocg , nswrgp ,imligp,          &
     iwarnp , nfecra , epsrgp , climgp , extrap ,                   &
     local_field     , local_coefa , local_coefb ,                  &
     grad   )

deallocate(local_coefa)
deallocate(local_coefb)
deallocate(local_field)

end subroutine grad_sed_nc
end subroutine attssc
