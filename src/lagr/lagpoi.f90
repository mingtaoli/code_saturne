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

subroutine lagpoi &
!================

 ( idbia0 , idbra0 ,                                              &
   ndim   , ncelet , ncel   , nfac   , nfabor , nfml   , nprfml , &
   nnod   , lndnod , lndfac ,lndfbr , ncelbr ,                    &
   nvar   , nscal  , nphas  ,                                     &
   nbpmax , nvp    , nvp1   , nvep   , nivep  ,                   &
   ntersl , nvlsta , nvisbr ,                                     &
   nideve , nrdeve , nituse , nrtuse ,                            &
   ifacel , ifabor , ifmfbr , ifmcel , iprfml ,                   &
   ipnfac , nodfac , ipnfbr , nodfbr ,                            &
   icocel , itycel , ifrlag , itepa  ,                            &
   idevel , ituser , ia     ,                                     &
   xyzcen , surfac , surfbo , cdgfac , cdgfbo , xyznod , volume , &
   dt     , rtpa   , rtp    , propce , propfa , propfb ,          &
   coefa  , coefb  ,                                              &
   ettp   , tepa   , statis ,                                     &
   w1     , w2     , w3     ,                                     &
   rdevel , rtuser , ra     )

!===============================================================================
! FONCTION :
! ----------

!   SOUS-PROGRAMME DU MODULE LAGRANGIEN :
!   -------------------------------------

!     RESOLUTION DE L'EQUATION DE POISSON POUR LES VITESSE MOYENNES
!                 DES PARTICULES
!       ET CORRECTION DES VITESSES INSTANTANNEES
!                 DES PARTICULES

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
! nfac             ! e  ! <-- ! nombre de faces internes                       !
! nfabor           ! e  ! <-- ! nombre de faces de bord                        !
! nfml             ! e  ! <-- ! nombre de familles d entites                   !
! nprfml           ! e  ! <-- ! nombre de proprietese des familles             !
! nnod             ! e  ! <-- ! nombre de sommets                              !
! lndnod           ! e  ! <-- ! dim. connectivite cellules->faces              !
! lndfac           ! e  ! <-- ! longueur du tableau nodfac                     !
! lndfbr           ! e  ! <-- ! longueur du tableau nodfbr                     !
! ncelbr           ! e  ! <-- ! nombre d'elements ayant au moins une           !
!                  !    !     ! face de bord                                   !
! nvar             ! e  ! <-- ! nombre total de variables                      !
! nscal            ! e  ! <-- ! nombre total de scalaires                      !
! nphas            ! e  ! <-- ! nombre de phases                               !
! nbpmax           ! e  ! <-- ! nombre max de particulies autorise             !
! nvp              ! e  ! <-- ! nombre de variables particulaires              !
! nvp1             ! e  ! <-- ! nvp sans position, vfluide, vpart              !
! nvep             ! e  ! <-- ! nombre info particulaires (reels)              !
! nivep            ! e  ! <-- ! nombre info particulaires (entiers)            !
! ntersl           ! e  ! <-- ! nbr termes sources de couplage retour          !
! nvlsta           ! e  ! <-- ! nombre de var statistiques lagrangien          !
! nvisbr           ! e  ! <-- ! nombre de statistiques aux frontieres          !
! nideve nrdeve    ! e  ! <-- ! longueur de idevel rdevel                      !
! nituse nrtuse    ! e  ! <-- ! longueur de ituser rtuser                      !
! ifacel           ! te ! <-- ! elements voisins d'une face interne            !
! (2, nfac)        !    !     !                                                !
! ifabor           ! te ! <-- ! element  voisin  d'une face de bord            !
! (nfabor)         !    !     !                                                !
! ifmfbr           ! te ! <-- ! numero de famille d'une face de bord           !
! (nfabor)         !    !     !                                                !
! ifmcel           ! te ! <-- ! numero de famille d'une cellule                !
! (ncelet)         !    !     !                                                !
! iprfml           ! te ! <-- ! proprietes d'une famille                       !
!  (nfml,nprfml    !    !     !                                                !
! ipnfac           ! te ! <-- ! position du premier noeud de chaque            !
!   (lndfac)       !    !     !  face interne dans nodfac                      !
! nodfac           ! te ! <-- ! connectivite faces internes/noeuds             !
!   (nfac+1)       !    !     !                                                !
! ipnfbr           ! te ! <-- ! position du premier noeud de chaque            !
!   (lndfbr)       !    !     !  face de bord dans nodfbr                      !
! nodfbr           ! te ! <-- ! connectivite faces de bord/noeuds              !
!   (nfabor+1)     !    !     !                                                !
! icocel           ! te ! --> ! connectivite cellules -> faces                 !
! (lndnod)         !    !     !    face de bord si numero negatif              !
! itycel           ! te ! --> ! connectivite cellules -> faces                 !
! (ncelet+1)       !    !     !    pointeur du tableau icocel                  !
! ifrlag           ! te ! --> ! numero de zone de la face de bord              !
! (nfabor)         !    !     !  pour le module lagrangien                     !
! itepa            ! te ! --> ! info particulaires (entiers)                   !
! (nbpmax,nivep    !    !     !   (cellule de la particule,...)                !
! idevel(nideve    ! te ! <-- ! tab entier complementaire developemt           !
! ituser(nituse    ! te ! <-- ! tab entier complementaire utilisateur          !
! ia(*)            ! tr ! --- ! macro tableau entier                           !
! xyzcen           ! tr ! <-- ! point associes aux volumes de control          !
! (ndim,ncelet     !    !     !                                                !
! surfac           ! tr ! <-- ! vecteur surface des faces internes             !
! (ndim,nfac)      !    !     !                                                !
! surfbo           ! tr ! <-- ! vecteur surface des faces de bord              !
! (ndim,nfabor)    !    !     !                                                !
! cdgfac           ! tr ! <-- ! centre de gravite des faces internes           !
! (ndim,nfac)      !    !     !                                                !
! cdgfbo           ! tr ! <-- ! centre de gravite des faces de bord            !
! (ndim,nfabor)    !    !     !                                                !
! xyznod           ! tr ! <-- ! coordonnes des noeuds                          !
! (ndim,nnod)      !    !     !                                                !
! volume(ncelet    ! tr ! <-- ! volume d'un des ncelet elements                !
! dt(ncelet)       ! tr ! <-- ! pas de temps                                   !
! rtp, rtpa        ! tr ! <-- ! variables de calcul au centre des              !
! (ncelet,*)       !    !     !    cellules (instant courant ou prec)          !
! propce           ! tr ! <-- ! proprietes physiques au centre des             !
! (ncelet,*)       !    !     !    cellules                                    !
! propfa           ! tr ! <-- ! proprietes physiques au centre des             !
!  (nfac,*)        !    !     !    faces internes                              !
! propfb           ! tr ! <-- ! proprietes physiques au centre des             !
!  (nfabor,*)      !    !     !    faces de bord                               !
! coefa, coefb     ! tr ! <-- ! conditions aux limites aux                     !
!  (nfabor,*)      !    !     !    faces de bord                               !
! ettp             ! tr ! <-- ! tableaux des variables liees                   !
!  (nbpmax,nvp)    !    !     !   aux particules etape courante                !
! tepa             ! tr ! <-- ! info particulaires (reels)                     !
! (nbpmax,nvep)    !    !     !   (poids statistiques,...)                     !
! statis           ! tr ! <-- ! moyennes statistiques                          !
!(ncelet,nvlsta    !    !     !                                                !
! w1...w3(ncel)    ! tr ! --- ! tableau de travail                             !
! rdevel(nrdeve    ! tr ! <-- ! tab reel complementaire developemt             !
! rtuser(nrtuse    ! tr ! <-- ! tab reel complementaire utilisateur            !
! ra(*)            ! tr ! --- ! macro tableau reel                             !
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
include "optcal.h"
include "entsor.h"
include "cstphy.h"
include "cstnum.h"
include "pointe.h"
include "period.h"
include "parall.h"
include "lagpar.h"
include "lagran.h"

!===============================================================================

! Arguments

integer          idbia0 , idbra0
integer          ndim   , ncelet , ncel   , nfac   , nfabor
integer          nfml   , nprfml
integer          nnod   , lndnod , lndfac , lndfbr , ncelbr
integer          nvar   , nscal  , nphas
integer          nbpmax , nvp    , nvp1   , nvep  , nivep
integer          ntersl , nvlsta , nvisbr
integer          nideve , nrdeve , nituse , nrtuse
integer          ifacel(2,nfac) , ifabor(nfabor)
integer          ifmfbr(nfabor) , ifmcel(ncelet)
integer          iprfml(nfml,nprfml)
integer          ipnfac(nfac+1) , nodfac(lndfac)
integer          ipnfbr(nfabor+1) , nodfbr(lndfbr)
integer          icocel(lndnod) , itycel(ncelet+1)
integer          ifrlag(nfabor) ,  itepa(nbpmax,nivep)
integer          idevel(nideve), ituser(nituse)
integer          ia(*)

double precision xyzcen(ndim,ncelet)
double precision surfac(ndim,nfac), surfbo(ndim,nfabor)
double precision cdgfac(ndim,nfac), cdgfbo(ndim,nfabor)
double precision xyznod(ndim,nnod), volume(ncelet)
double precision dt(ncelet), rtp(ncelet,*), rtpa(ncelet,*)
double precision propce(ncelet,*)
double precision propfa(nfac,*), propfb(nfabor,*)
double precision coefa(nfabor,*) , coefb(nfabor,*)
double precision ettp(nbpmax,nvp) , tepa(nbpmax,nvep)
double precision statis(ncelet,nvlsta)
double precision w1(ncelet) ,  w2(ncelet) ,  w3(ncelet)
double precision rdevel(nrdeve), rtuser(nrtuse)
double precision ra(*)

! VARIABLES LOCALES

integer          idebia, idebra
integer          ifinia, ifinra
integer          npt , iel , ifac
integer          iphila , iphil
integer          iw1   , iw2   , iw3   , iw4 , iw5
integer          iw6   , iw7   , iw8   , iw9
integer          idtr   , ifmala , ifmalb
integer          iviscf , iviscb , idam   , ixam
integer          idrtp  , ismbr  , irovsd
integer          icoefap , icoefbp
integer          ivar0
integer          inc, iccocg
integer          nswrgp , imligp , iwarnp
integer          idimte , itenso , iphydp
double precision epsrgp , climgp , extrap

!===============================================================================
! 0.  GESTION MEMOIRE
!===============================================================================

idebia = idbia0
idebra = idbra0

!===============================================================================
! 1.  INITIALISATIONS
!===============================================================================

idtr   = idebra
iviscf = idtr   + ncelet
iviscb = iviscf + nfac
idam   = iviscb + nfabor
ixam   = idam   + ncelet
idrtp  = ixam   + nfac*2
ismbr  = idrtp  + ncelet
irovsd = ismbr  + ncelet
ifmala = irovsd + ncelet
ifmalb = ifmala + nfac

iphila  = ifmalb + nfabor
iphil   = iphila  + ncelet
iw1    = iphil   + ncelet
iw2    = iw1    + ncelet
iw3    = iw2    + ncelet
iw4    = iw3    + ncelet
iw5    = iw4    + ncelet
iw6    = iw5    + ncelet
iw7    = iw6    + ncelet
iw8    = iw7    + ncelet
iw9    = iw8    + ncelet
ifinra = iw9    + ncelet
CALL RASIZE('LAGPOI',IFINRA)
!     ==========

do iel=1,ncel
  if ( statis(iel,ilpd) .gt. seuil ) then
    statis(iel,ilvx) = statis(iel,ilvx)                           &
                      /statis(iel,ilpd)
    statis(iel,ilvy) = statis(iel,ilvy)                           &
                      /statis(iel,ilpd)
    statis(iel,ilvz) = statis(iel,ilvz)                           &
                      /statis(iel,ilpd)
    statis(iel,ilfv) = statis(iel,ilfv)                           &
                      /( dble(npst) * volume(iel) )
  else
    statis(iel,ilvx) = 0.d0
    statis(iel,ilvy) = 0.d0
    statis(iel,ilvz) = 0.d0
    statis(iel,ilfv) = 0.d0
  endif
enddo

call lageqp                                                       &
!==========
 ( ifinia , ifinra ,                                              &
   ndim   , ncelet , ncel   , nfac   , nfabor , nfml   , nprfml , &
   nnod   , lndfac , lndfbr , ncelbr ,                            &
   nvar   , nscal  , nphas  ,                                     &
   nideve , nrdeve , nituse , nrtuse ,                            &
   ifacel , ifabor , ifmfbr , ifmcel , iprfml ,                   &
   ipnfac , nodfac , ipnfbr , nodfbr ,                            &
   idevel , ituser , ia     ,                                     &
   xyzcen , surfac , surfbo , cdgfac , cdgfbo , xyznod , volume , &
   dt     , propce , propfa , propfb ,                            &
   ra(iviscf) , ra(iviscb) ,                                      &
   ra(idam) , ra(ixam) ,                                          &
   ra(idrtp) , ra(ismbr) , ra(irovsd) ,                           &
   ra(ifmala) , ra(ifmalb) ,                                      &
   statis(1,ilvx) , statis(1,ilvy) , statis(1,ilvz) ,             &
   statis(1,ilfv) ,                                               &
   ra(iphila) , ra(iphil) ,                                       &
   w1     , w2     , w3     , ra(iw1) , ra(iw2) ,                 &
   ra(iw3) , ra(iw4) , ra(iw5) , ra(iw6) ,                        &
   ra(iw7) , ra(iw8) , ra(iw9) ,                                  &
   rdevel , rtuser ,                                              &
   ra     )

! Calcul du gradient du Correcteur PHI
! ====================================


!       On alloue localement 2 tableaux de NFABOR pour le calcul
!         de COEFA et COEFB de W1,W2,W3

icoefap = ifinra
icoefbp = icoefap + nfabor
ifinra  = icoefbp + nfabor
CALL RASIZE ('LAGEQP',IFINRA)
!==========

do ifac = 1, nfabor
  iel = ifabor(ifac)
  ra(icoefap+ifac-1) = ra(iphil+iel-1)
  ra(icoefbp+ifac-1) = zero
enddo

inc = 1
iccocg = 1
nswrgp = 100
imligp = -1
iwarnp = 2
epsrgp = 1.d-8
climgp = 1.5d0
extrap = 0.d0


! En periodique et parallele, echange avant calcul du gradient

!    Parallele
if(irangp.ge.0) then
  call parcom(ra(iphil))
  !==========
endif

!    Periodique
if(iperio.eq.1) then
  idimte = 0
  itenso = 0
  call percom                                                     &
  !==========
  ( idimte , itenso ,                                             &
    ra(iphil) , ra(iphil) , ra(iphil) ,                           &
    ra(iphil) , ra(iphil) , ra(iphil) ,                           &
    ra(iphil) , ra(iphil) , ra(iphil)  )
endif

!  IVAR0 = 0 (indique pour la periodicite de rotation que la variable
!     n'est pas la vitesse ni Rij)
ivar0 = 0

!    Sans prise en compte de la pression hydrostatique

iphydp = 0

call grdcel                                                       &
!==========
 ( ifinia , ifinra ,                                              &
   ndim   , ncelet , ncel   , nfac   , nfabor , nfml   , nprfml , &
   nnod   , lndfac , lndfbr , ncelbr , nphas  ,                   &
   nideve , nrdeve , nituse , nrtuse ,                            &
   ivar0  , imrgra , inc    , iccocg , nswrgp , imligp , iphydp , &
   iwarnp , nfecra , epsrgp , climgp , extrap ,                   &
   ifacel , ifabor , ifmfbr , ifmcel , iprfml ,                   &
   ipnfac , nodfac , ipnfbr , nodfbr ,                            &
   idevel , ituser , ia     ,                                     &
   xyzcen , surfac , surfbo , cdgfac , cdgfbo , xyznod , volume , &
   ra(iphil) , ra(iphil) , ra(iphil)    ,                         &
   ra(iphil) , ra(icoefap) , ra(icoefbp) ,                        &
   w1       , w2    , w3 ,                                        &
   ra(iw1)  , ra(iw2) , ra(iw3) ,                                 &
   rdevel , rtuser , ra     )

! CORRECTION DES VITESSES MOYENNES ET RETOUR AU CUMUL

do iel = 1,ncel
  if ( statis(iel,ilpd) .gt. seuil ) then
    statis(iel,ilvx) = statis(iel,ilvx) - w1(iel)
    statis(iel,ilvy) = statis(iel,ilvy) - w2(iel)
    statis(iel,ilvz) = statis(iel,ilvz) - w3(iel)
  endif
enddo

do iel = 1,ncel
  if ( statis(iel,ilpd) .gt. seuil ) then
    statis(iel,ilvx) = statis(iel,ilvx)*statis(iel,ilpd)
    statis(iel,ilvy) = statis(iel,ilvy)*statis(iel,ilpd)
    statis(iel,ilvz) = statis(iel,ilvz)*statis(iel,ilpd)
    statis(iel,ilfv) = statis(iel,ilfv)                           &
                      *( dble(npst) * volume(iel) )
  endif
enddo

! CORRECTION DES VITESSES INSTANTANNES

do npt = 1,nbpart
  if ( itepa(npt,jisor).gt.0 ) then
    iel = itepa(npt,jisor)
    ettp(npt,jup) = ettp(npt,jup) - w1(iel)
    ettp(npt,jvp) = ettp(npt,jvp) - w2(iel)
    ettp(npt,jwp) = ettp(npt,jwp) - w3(iel)
  endif
enddo

!===============================================================================

!--------
! FORMATS
!--------

!----
! FIN
!----

end
