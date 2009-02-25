!-------------------------------------------------------------------------------

!     This file is part of the Code_Saturne Kernel, element of the
!     Code_Saturne CFD tool.

!     Copyright (C) 1998-2008 EDF S.A., France

!     contact: saturne-support@edf.fr

!     The Code_Saturne Kernel is free software; you can redistribute it
!     and/or modify it under the terms of the GNU General Public License
!     as published by the Free Software Foundation; either version 2 of
!     the License, or (at your option) any later version.

!     The Code_Saturne Kernel is distributed in the hope that it will be
!     useful, but WITHOUT ANY WARRANTY; without even the implied warranty
!     of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
!     GNU General Public License for more details.

!     You should have received a copy of the GNU General Public License
!     along with the Code_Saturne Kernel; if not, write to the
!     Free Software Foundation, Inc.,
!     51 Franklin St, Fifth Floor,
!     Boston, MA  02110-1301  USA

!-------------------------------------------------------------------------------

subroutine ecrhis &
!================

 ( idbia0 , idbra0 , ndim   , ncelet , ncel ,                     &
   nideve , nrdeve , nituse , nrtuse , modhis ,                   &
   idevel , ituser , ia     ,                                     &
   xyzcen , rdevel , rtuser , ra )

!===============================================================================
!  FONCTION  :
!  ---------

! ROUTINE D'ECRITURE DES HISTORIQUES

!-------------------------------------------------------------------------------
! Arguments
!__________________.____._____.________________________________________________.
!    nom           !type!mode !                   role                         !
!__________________!____!_____!________________________________________________!
! idbia0           ! e  ! <-- ! numero de la 1ere case libre dans ia           !
! idbra0           ! e  ! <-- ! numero de la 1ere case libre dans ra           !
! ndim             ! e  ! <-- ! dimension de l'espace                          !
! ncelet           ! e  ! <-- ! nombre d'elements halo compris                 !
! ncel             ! e  ! <-- ! nombre d'elements actifs                       !
! nideve nrdeve    ! e  ! <-- ! longueur de idevel rdevel                      !
! nituse nrtuse    ! e  ! <-- ! longueur de ituser rtuser                      !
! modhis           ! e  ! <-- ! indicateur valant 0,1 ou 2                     !
!                  !    !               ! 1,2 = ecriture intermediaire, finale |
! idevel(nideve    ! te ! <-- ! tab entier complementaire developemt           !
! ituser(nituse    ! te ! <-- ! tab entier complementaire utilisateur          !
! ia(*)            ! tr ! --- ! macro tableau entier                           !
! xyzcen           ! tr ! <-- ! point associes aux volumes de control          !
! (ndim,ncelet)    !    !     !                                                !
! rdevel(nrdeve    ! tr ! <-- ! tab reel complementaire developemt             !
! rtuser(nrtuse    ! tr ! <-- ! tab reel complementaire utilisateur            !
! ra               ! tr !  -- ! tableau des reels                              !
!__________________!____!_____!________________________________________________!

!     TYPE : E (ENTIER), R (REEL), A (ALPHANUMERIQUE), T (TABLEAU)
!            L (LOGIQUE)   .. ET TYPES COMPOSES (EX : TR TABLEAU REEL)
!     MODE : <-- donnee, --> resultat, <-> Donnee modifiee
!            --- tableau de travail
!===============================================================================

implicit none

!===============================================================================
!     DONNEES EN COMMON
!===============================================================================

include "paramx.h"
include "numvar.h"
include "entsor.h"
include "cstnum.h"
include "optcal.h"
include "parall.h"

!===============================================================================

! Arguments

integer          idbia0, idbra0
integer          ndim, ncelet, ncel
integer          nideve , nrdeve , nituse , nrtuse
integer          modhis
integer          idevel(nideve), ituser(nituse), ia(*)
double precision xyzcen(ndim,ncelet)
double precision rdevel(nrdeve), rtuser(nrtuse), ra(*)

! VARIABLES LOCALES

character        nomfic*300, nenvar*300
integer          ii, ii1, ii2, lpos, inam1, inam2, lng
integer          icap,ncap,ipp,ira,ipp2,nbpdte, jtcabs
integer          idivdt, ixmsdt, idebia, idebra, ifinra, iel
integer          nbcap(nvppmx)
double precision xtcabs,xyztmp(3)
double precision varcap(ncaptm)

! NOMBRE DE PASSAGES DANS LA ROUTINE

integer          ipass
data             ipass /0/
save             ipass

!===============================================================================
! 0. INITIALISATIONS LOCALES
!===============================================================================

ipass = ipass + 1

idebia = idbia0
idebra = idbra0

!--> Il n'y a pas eu d'historiques ou s'il n'y a pas de capteur
if((ipass.eq.1.and.modhis.eq.2) .or. ncapt.eq.0) return

!===============================================================================
! 1. RECHERCHE DES NOEUDS PROCHES -> NODCAP
!===============================================================================

if(ipass.eq.1) then

  do ii = 1, ncapt
    call findpt                                                   &
    !==========
   ( ncelet, ncel, xyzcen ,                                       &
     xyzcap(1,ii), xyzcap(2,ii), xyzcap(3,ii),                    &
     nodcap(ii), ndrcap(ii))
  enddo

endif

!===============================================================================
! 2. OUVERTURE DU FICHIER DE STOCKAGE hist.tmp
!===============================================================================

if(ipass.eq.1 .and. irangp.le.0) then
  NOMFIC = ' '
  nomfic = emphis
  call verlon ( nomfic,ii1,ii2,lpos)
  !==========

  NOMFIC(II2+1:II2+8) = 'hist.tmp'
  ii2 = ii2+8
  open ( unit=imphis(1), file=nomfic (ii1:ii2),                   &
         STATUS='UNKNOWN', FORM='UNFORMATTED',                    &
         ACCESS='SEQUENTIAL')
endif

!===============================================================================
! 3. ECRITURE DES RESULTATS dans le FICHIER DE STOCKAGE
!===============================================================================

if(modhis.eq.0.or.modhis.eq.1) then

  do ipp = 2, nvppmx
    if(ihisvr(ipp,1).ne.0) then
      ira = abs(ipp2ra(ipp))

!     Pour les moments, il faut eventuellement diviser par le temps cumule
      idivdt = ippmom(ipp)
      if(idivdt.eq.0) then
        ixmsdt = ira
      else
        ixmsdt = idebra
        ifinra = ixmsdt + ncel
        CALL RASIZE ('ECRHIS', IFINRA)
        !==========
      endif
      if(idivdt.gt.0) then
        do iel = 1, ncel
          ra(ixmsdt+iel-1) = ra(ira+iel-1)/                       &
               max(ra(idivdt+iel-1),epzero)
        enddo
      elseif(idivdt.lt.0) then
        do iel = 1, ncel
          ra(ixmsdt+iel-1) = ra(ira+iel-1)/                       &
               max(dtcmom(-idivdt),epzero)
        enddo
!           ELSE
!             RA(IXMSDT+IEL-1) = RA(IRA+IEL-1)
!             inutile car on a pose IXMSDT = IRA
      endif

      if(ihisvr(ipp,1).lt.0) then
        do icap = 1, ncapt
          if (irangp.lt.0) then
            varcap(icap) = ra(ixmsdt+nodcap(icap)-1)
          else
            call parhis(nodcap(icap), ndrcap(icap),               &
            !==========
                        ra(ixmsdt), varcap(icap))
          endif
        enddo
        ncap = ncapt
      else
        do icap = 1, ihisvr(ipp,1)
          if (irangp.lt.0) then
            varcap(icap) = ra(ixmsdt+nodcap(ihisvr(ipp,icap+1))-1)
          else
            call parhis(nodcap(ihisvr(ipp,icap+1)),               &
            !==========
                        ndrcap(ihisvr(ipp,icap+1)),               &
                        ra(ixmsdt), varcap(icap))
          endif
        enddo
        ncap = ihisvr(ipp,1)
      endif
      if (irangp.le.0) then
        write(imphis(1)) ntcabs, ttcabs, (varcap(icap),           &
                                           icap=1,ncap)
      endif
    endif
  enddo

endif

!===============================================================================
! 4. EN CAS DE SAUVEGARDE INTERMEDIAIRE OU FINALE,
!    TRANSMISSION DES INFORMATIONS DANS LES DIFFERENTS FICHIERS
!===============================================================================

! On sauve aussi au premier passage pour permettre une
!     verification des le debut du calcul

if(modhis.eq.1.or.modhis.eq.2.or.ipass.eq.1) then

!       --> nombre de pas de temps enregistres

  if(modhis.eq.2) then
    nbpdte = ipass - 1
  else
    nbpdte = ipass
  endif

!       --> nombre de capteur par variable
  do ipp = 2, nvppmx
    nbcap(ipp) = ihisvr(ipp,1)
    if(nbcap(ipp).lt.0) nbcap(ipp) = ncapt
  enddo

!       --> ecriture un fichier par variable

  do ipp = 2, nvppmx
    if(ihisvr(ipp,1).ne.0) then

      if(irangp.le.0) then
!           --> nom du fichier
        NOMFIC = ' '
        nomfic = emphis
        call verlon ( nomfic,ii1,ii2,lpos)
        !==========
        nenvar = nomvar(ipp)
        call verlon(nenvar,inam1,inam2,lpos)
        !==========
        call undscr(inam1,inam2,nenvar)
        !==========
        nomfic(ii2+1:ii2+lpos) = nenvar(inam1:inam2)
        ii2 = ii2+lpos
        NOMFIC(II2+1:II2+1) = '.'
        ii2 = ii2+1
        nenvar = exthis
        call verlon(nenvar,inam1,inam2,lpos)
        !==========
        call undscr(inam1,inam2,nenvar)
        !==========
        nomfic(ii2+1:ii2+lpos) = nenvar(inam1:inam2)
        ii2 = ii2+lpos
!           --> ouverture
        open ( unit=imphis(2), file=nomfic (ii1:ii2),             &
               STATUS='UNKNOWN', FORM='FORMATTED',                &
               ACCESS='SEQUENTIAL')
!           --> entete
        write(imphis(2),100)
        write(imphis(2),101)
        write(imphis(2),102) nomvar(ipp)
        write(imphis(2),100)
        write(imphis(2),103)
        write(imphis(2),104)
        write(imphis(2),103)
      endif

      if(ihisvr(ipp,1).gt.0) then
        do ii=1,ihisvr(ipp,1)
          if (irangp.lt.0 .or.                                    &
              irangp.eq.ndrcap(ihisvr(ipp,ii+1))) then
            xyztmp(1) = xyzcen(1,nodcap(ihisvr(ipp,ii+1)))
            xyztmp(2) = xyzcen(2,nodcap(ihisvr(ipp,ii+1)))
            xyztmp(3) = xyzcen(3,nodcap(ihisvr(ipp,ii+1)))
          endif
          if (irangp.ge.0) then
            lng = 3
            call parbcr(ndrcap(ihisvr(ipp,ii+1)), lng , xyztmp)
            !==========
          endif
          if(irangp.le.0) then
            write(imphis(2),105) ihisvr(ipp,ii+1),                &
                                 xyztmp(1), xyztmp(2), xyztmp(3)
          endif
        enddo
      elseif(ihisvr(ipp,1).lt.0) then
        do ii=1,ncapt
          if (irangp.lt.0 .or.                                    &
              irangp.eq.ndrcap(ii)) then
            xyztmp(1) = xyzcen(1,nodcap(ii))
            xyztmp(2) = xyzcen(2,nodcap(ii))
            xyztmp(3) = xyzcen(3,nodcap(ii))
          endif
          if (irangp.ge.0) then
            lng = 3
            call parbcr(ndrcap(ii), lng , xyztmp)
            !==========
          endif
          if(irangp.le.0) then
            write(imphis(2),105) ii,                              &
                                 xyztmp(1), xyztmp(2), xyztmp(3)
          endif
        enddo
      endif

      if(irangp.le.0) then

        write(imphis(2),103)
        write(imphis(2),106) nbpdte
        write(imphis(2),103)

        write(imphis(2),103)
        write(imphis(2),107)
        write(imphis(2),103)

        write(imphis(2),100)
        write(imphis(2),103)

!           --> boucle sur les differents enregistrements
!               et les variables
        rewind(imphis(1))
        do ii = 1, nbpdte
          do ipp2 = 2, nvppmx
            if(ihisvr(ipp2,1).ne.0) then
              read(imphis(1))                                     &
                jtcabs, xtcabs, (varcap(icap),icap=1,nbcap(ipp2))
              if(ipp2.eq.ipp)                                     &
                write(imphis(2),1000)                             &
                jtcabs, xtcabs, (varcap(icap),icap=1,nbcap(ipp))
            endif
          enddo
        enddo

!           --> fermeture fichier
        close(imphis(2))

      endif

    endif
  enddo

endif

!===============================================================================
! 5. AFFICHAGES
!===============================================================================

#if defined(_CS_LANG_FR)

 100  FORMAT ('# ---------------------------------------------------')
 101  FORMAT ('#      FICHIER HISTORIQUE EN TEMPS')
 102  FORMAT ('#      VARIABLE    ',A16)
 103  FORMAT ('# ')
 104  FORMAT ('#      POSITION DES CAPTEURS (colonne)')
 105  FORMAT ('# ',I6,')',3(1X,E14.7))
 106  FORMAT ('#      NOMBRE D''ENREGISTREMENTS :',I7)
 107  format (                                                          &
'# COLONNE 1       : NUMERO DU PAS DE TEMPS ',/,            &
'#         2       : TEMPS PHYSIQUE (ou No pas de temps*DTREF ',/,&
'#                               en pas de temps non uniforme)',/,&
'#         3 A 100 : VALEUR AUX CAPTEURS')
 1000 format ( 1(1x,i7,1x),101(1x,e14.7))

#else

 100  FORMAT ('# ---------------------------------------------------')
 101  FORMAT ('#      TIME MONITORING FILE')
 102  FORMAT ('#      VARIABLE    ',A16)
 103  FORMAT ('# ')
 104  FORMAT ('#      MONITORING POINTS COORDINATES (column)')
 105  FORMAT ('# ',I6,')',3(1X,E14.7))
 106  FORMAT ('#      NUMBER OF RECORDS:',I7)
 107  format (                                                          &
'# COLUMN 1        : TIME STEP NUMBER ',/,                  &
'#        2        : PHYSICAL TIME (or Nb of time steps*DTREF ',/,&
'#                                with non uniform time step)',/, &
'#        3 TO 100 : VALUE AT MONITORING POINTS')
 1000 format ( 1(1x,i7,1x),101(1x,e14.7))

#endif

return
end
