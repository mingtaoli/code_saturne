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

subroutine cfxtcl &
!================

 ( idbia0 , idbra0 ,                                              &
   ndim   , ncelet , ncel   , nfac   , nfabor , nfml   , nprfml , &
   nnod   , lndfac , lndfbr , ncelbr ,                            &
   nvar   , nscal  , nphas  ,                                     &
   nideve , nrdeve , nituse , nrtuse ,                            &
   ifacel , ifabor , ifmfbr , ifmcel , iprfml ,                   &
   ipnfac , nodfac , ipnfbr , nodfbr ,                            &
   icodcl , itrifb , itypfb , izfppp ,                            &
   idevel , ituser , ia     ,                                     &
   xyzcen , surfac , surfbo , cdgfac , cdgfbo , xyznod , volume , &
   dt     , rtp    , rtpa   , propce , propfa , propfb ,          &
   coefa  , coefb  , rcodcl ,                                     &
   w1     , w2     , w3     , w4     , w5     , w6     , coefu  , &
   rdevel , rtuser , ra     )

!===============================================================================
! FONCTION :
! --------

!    CONDITIONS AUX LIMITES AUTOMATIQUES

!           COMPRESSIBLE SANS CHOC


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
! lndfac           ! e  ! <-- ! longueur du tableau nodfac (optionnel          !
! lndfbr           ! e  ! <-- ! longueur du tableau nodfbr (optionnel          !
! ncelbr           ! e  ! <-- ! nombre d'elements ayant au moins une           !
!                  !    !     ! face de bord                                   !
! nvar             ! e  ! <-- ! nombre total de variables                      !
! nscal            ! e  ! <-- ! nombre total de scalaires                      !
! nphas            ! e  ! <-- ! nombre de phases                               !
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
! nfml  ,nprfml    !    !     !                                                !
! ipnfac           ! te ! <-- ! position du premier noeud de chaque            !
!   (lndfac)       !    !     !  face interne dans nodfac (optionnel)          !
! nodfac           ! te ! <-- ! connectivite faces internes/noeuds             !
!   (nfac+1)       !    !     !  (optionnel)                                   !
! ipnfbr           ! te ! <-- ! position du premier noeud de chaque            !
!   (lndfbr)       !    !     !  face de bord dans nodfbr (optionnel)          !
! nodfbr           ! te ! <-- ! connectivite faces de bord/noeuds              !
!   (nfabor+1)     !    !     !  (optionnel)                                   !
! icodcl           ! te ! --> ! code de condition limites aux faces            !
!  (nfabor,nvar    !    !     !  de bord                                       !
!                  !    !     ! = 1   -> dirichlet                             !
!                  !    !     ! = 3   -> densite de flux                       !
!                  !    !     ! = 4   -> glissemt et u.n=0 (vitesse)           !
!                  !    !     ! = 5   -> frottemt et u.n=0 (vitesse)           !
!                  !    !     ! = 6   -> rugosite et u.n=0 (vitesse)           !
!                  !    !     ! = 9   -> entree/sortie libre (vitesse          !
! itrifb(nfabor    ! te ! <-- ! indirection pour tri des faces de brd          !
!  nphas      )    !    !     !                                                !
! itypfb(nfabor    ! te ! <-- ! type des faces de bord                         !
!  nphas      )    !    !     !                                                !
! izfppp           ! te ! <-- ! numero de zone de la face de bord              !
! (nfabor)         !    !     !  pour le module phys. part.                    !
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
! xyznod           ! tr ! <-- ! coordonnes des noeuds (optionnel)              !
! (ndim,nnod)      !    !     !                                                !
! volume           ! tr ! <-- ! volume d'un des ncelet elements                !
! (ncelet          !    !     !                                                !
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
! rcodcl           ! tr ! --> ! valeur des conditions aux limites              !
!  (nfabor,nvar    !    !     !  aux faces de bord                             !
!                  !    !     ! rcodcl(1) = valeur du dirichlet                !
!                  !    !     ! rcodcl(2) = valeur du coef. d'echange          !
!                  !    !     !  ext. (infinie si pas d'echange)               !
!                  !    !     ! rcodcl(3) = valeur de la densite de            !
!                  !    !     !  flux (negatif si gain) w/m2 ou                !
!                  !    !     !  hauteur de rugosite (m) si icodcl=6           !
!                  !    !     ! pour les vitesses (vistl+visct)*gradu          !
!                  !    !     ! pour la pression             dt*gradp          !
!                  !    !     ! pour les scalaires                             !
!                  !    !     !        cp*(viscls+visct/sigmas)*gradt          !
! w1,2,3,4,5,6     ! tr ! --- ! tableaux de travail                            !
!  (ncelet         !    !     !  (calcul du gradient de pression)              !
! coefu            ! tr ! --- ! tab de trav                                    !
!  (nfabor,3)      !    !     !  (calcul du gradient de pression)              !
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

! Arguments

include "paramx.h"
include "numvar.h"
include "optcal.h"
include "cstphy.h"
include "cstnum.h"
include "pointe.h"
include "entsor.h"
include "parall.h"
include "ppppar.h"
include "ppthch.h"
include "ppincl.h"
include "cfpoin.h"

!===============================================================================

! Arguments

integer          idbia0 , idbra0
integer          ndim   , ncelet , ncel   , nfac   , nfabor
integer          nfml   , nprfml
integer          nnod   , lndfac , lndfbr , ncelbr
integer          nvar   , nscal  , nphas
integer          nideve , nrdeve , nituse , nrtuse

integer          ifacel(2,nfac) , ifabor(nfabor)
integer          ifmfbr(nfabor) , ifmcel(ncelet)
integer          iprfml(nfml,nprfml)
integer          ipnfac(nfac+1), nodfac(lndfac)
integer          ipnfbr(nfabor+1), nodfbr(lndfbr)
integer          icodcl(nfabor,nvar)
integer          itrifb(nfabor,nphas), itypfb(nfabor,nphas)
integer          izfppp(nfabor)
integer          idevel(nideve), ituser(nituse), ia(*)

double precision xyzcen(ndim,ncelet)
double precision surfac(ndim,nfac), surfbo(ndim,nfabor)
double precision cdgfac(ndim,nfac), cdgfbo(ndim,nfabor)
double precision xyznod(ndim,nnod), volume(ncelet)
double precision dt(ncelet), rtp(ncelet,*), rtpa(ncelet,*)
double precision propce(ncelet,*)
double precision propfa(nfac,*), propfb(nfabor,*)
double precision coefa(nfabor,*), coefb(nfabor,*)
double precision rcodcl(nfabor,nvar,3)
double precision w1(ncelet),w2(ncelet),w3(ncelet)
double precision w4(ncelet),w5(ncelet),w6(ncelet)
double precision coefu(nfabor,ndim)
double precision rdevel(nrdeve), rtuser(nrtuse), ra(*)

! VARIABLES LOCALES

integer          idebia, idebra
integer          iphas , ivar  , ifac  , iel
integer          ii    , iii   , imodif, iccfth
integer          icalep, icalgm
integer          iflmab
integer          ipriph, iuiph , iviph , iwiph
integer          irhiph, ieniph, itkiph
integer          iclp  , iclr
integer          iclu  , iclv  , iclw
integer          nvarcf

integer          nvcfmx
parameter       (nvcfmx=7)
integer          ivarcf(nvcfmx)

double precision hint  , gammag

!===============================================================================
!===============================================================================
! 1.  INITIALISATIONS
!===============================================================================

idebia = idbia0
idebra = idbra0


do iphas = 1, nphas

  ipriph = ipr   (iphas)
  iuiph  = iu    (iphas)
  iviph  = iv    (iphas)
  iwiph  = iw    (iphas)
  irhiph = isca(irho  (iphas))
  ieniph = isca(ienerg(iphas))
  itkiph = isca(itempk(iphas))
  iclp   = iclrtp(ipriph,icoef)
  iclr   = iclrtp(irhiph,icoef)
  iclu   = iclrtp(iuiph ,icoef)
  iclv   = iclrtp(iviph ,icoef)
  iclw   = iclrtp(iwiph ,icoef)

  iflmab = ipprob(ifluma(ieniph))

!     Liste des variables compressible :
  ivarcf(1) = ipriph
  ivarcf(2) = iuiph
  ivarcf(3) = iviph
  ivarcf(4) = iwiph
  ivarcf(5) = irhiph
  ivarcf(6) = ieniph
  ivarcf(7) = itkiph
  nvarcf    = 7

!     Calcul de epsilon_sup = e - CvT
!       On en a besoin si on a des parois a temperature imposee.
!       Il est calcul� aux cellules W5 et aux faces de bord COEFU.
!       On n'en a besoin ici qu'aux cellules de bord : s'il est
!         n�cessaire de gagner de la m�moire, on pourra modifier
!         uscfth.

  icalep = 0
  do ifac = 1, nfabor
    if(icodcl(ifac,itkiph).eq.5) then
      icalep = 1
    endif
  enddo
  if(icalep.ne.0) then
    iccfth = 7
    imodif = 0
    call uscfth                                                   &
    !==========
 ( idebia , idebra ,                                              &
   ndim   , ncelet , ncel   , nfac   , nfabor , nfml   , nprfml , &
   nnod   , lndfac , lndfbr , ncelbr ,                            &
   nvar   , nscal  , nphas  ,                                     &
   iccfth , imodif , iphas  ,                                     &
   nideve , nrdeve , nituse , nrtuse ,                            &
   ifacel , ifabor , ifmfbr , ifmcel , iprfml ,                   &
   ipnfac , nodfac , ipnfbr , nodfbr ,                            &
   idevel , ituser , ia     ,                                     &
   xyzcen , surfac , surfbo , cdgfac , cdgfbo , xyznod , volume , &
   dt     , rtp    , rtpa   , propce , propfa , propfb ,          &
   coefa  , coefb  ,                                              &
   w5     , coefu(1,1) , w3 , w4     ,                            &
!        ------   ---------
   rdevel , rtuser , ra     )
  endif


!     Calcul de gamma (constant ou variable ; pour le moment : cst)
!       On en a besoin pour les entrees sorties avec rusanov

  icalgm = 0
  do ifac = 1, nfabor
    if ( ( itypfb(ifac,iphas).eq.iesicf ) .or.                    &
         ( itypfb(ifac,iphas).eq.isopcf ) .or.                    &
         ( itypfb(ifac,iphas).eq.ierucf ) .or.                    &
         ( itypfb(ifac,iphas).eq.ieqhcf ) ) then
      icalgm = 1
    endif
  enddo
  if(icalgm.ne.0) then
    iccfth = 1
    imodif = 0
    call uscfth                                                   &
    !==========
 ( idebia , idebra ,                                              &
   ndim   , ncelet , ncel   , nfac   , nfabor , nfml   , nprfml , &
   nnod   , lndfac , lndfbr , ncelbr ,                            &
   nvar   , nscal  , nphas  ,                                     &
   iccfth , imodif , iphas  ,                                     &
   nideve , nrdeve , nituse , nrtuse ,                            &
   ifacel , ifabor , ifmfbr , ifmcel , iprfml ,                   &
   ipnfac , nodfac , ipnfbr , nodfbr ,                            &
   idevel , ituser , ia     ,                                     &
   xyzcen , surfac , surfbo , cdgfac , cdgfbo , xyznod , volume , &
   dt     , rtp    , rtpa   , propce , propfa , propfb ,          &
   coefa  , coefb  ,                                              &
   w1     , w2     , w6     , w4     ,                            &
   rdevel , rtuser , ra     )

    if(ieos(iphas).eq.1) then
      gammag = w6(1)
    else
!     Gamma doit etre passe a cfrusb ; s'il est variable
!       il est dans le tableau W6 et il faut ajouter
!           GAMMAG = W6(IFABOR(IFAC)) selon IEOS
!       dans la boucle sur les faces.
!     En attendant que IEOS different de 1 soit code, on stoppe
      write(nfecra,7000)
      call csexit (1)
    endif

  endif



!     Boucle sur les faces

  do ifac = 1, nfabor
    iel = ifabor(ifac)

!===============================================================================
! 2.  REMPLISSAGE DU TABLEAU DES CONDITIONS LIMITES
!       ON BOUCLE SUR TOUTES LES FACES DE PAROI
!===============================================================================

    if ( itypfb(ifac,iphas).eq.iparoi) then

!     Les RCODCL ont ete initialises a -RINFIN pour permettre de
!       verifier ceux que l'utilisateur a modifies. On les remet a zero
!       si l'utilisateur ne les a pas modifies.
!       En paroi, on traite toutes les variables.
      do ivar = 1, nvar
        if(rcodcl(ifac,ivar,1).le.-rinfin*0.5d0) then
          rcodcl(ifac,ivar,1) = 0.d0
        endif
      enddo

!     Le flux de masse est nul

      propfb(ifac,iflmab) = 0.d0

!     Pression :

!       Si la gravite est predominante : pression hydrostatique
!         (approximatif et surtout explicite en rho)

      if(icfgrp(iphas).eq.1) then

        icodcl(ifac,ipriph) = 3
        hint = dt(iel)/ra(idistb-1+ifac)
        rcodcl(ifac,ipriph,3) = -hint                             &
         * ( gx*(cdgfbo(1,ifac)-xyzcen(1,iel))                    &
           + gy*(cdgfbo(2,ifac)-xyzcen(2,iel))                    &
           + gz*(cdgfbo(3,ifac)-xyzcen(3,iel)) )                  &
         * rtp(iel,irhiph)

      else

!       En g�n�ral : proportionnelle a la valeur interne
!         (Pbord = COEFB*Pi)
!       Si on d�tend trop : Dirichlet homogene

        iccfth = 91

        call uscfth                                               &
        !==========
 ( idebia , idebra ,                                              &
   ndim   , ncelet , ncel   , nfac   , nfabor , nfml   , nprfml , &
   nnod   , lndfac , lndfbr , ncelbr ,                            &
   nvar   , nscal  , nphas  ,                                     &
   iccfth , ifac   , iphas  ,                                     &
   nideve , nrdeve , nituse , nrtuse ,                            &
   ifacel , ifabor , ifmfbr , ifmcel , iprfml ,                   &
   ipnfac , nodfac , ipnfbr , nodfbr ,                            &
   idevel , ituser , ia     ,                                     &
   xyzcen , surfac , surfbo , cdgfac , cdgfbo , xyznod , volume , &
   dt     , rtp    , rtpa   , propce , propfa , propfb ,          &
   coefa  , coefb  ,                                              &
   w1     , w2     , w3     , w4     ,                            &
   rdevel , rtuser , ra     )

!       En outre, il faut appliquer une pre-correction pour compenser
!        le traitement fait dans condli... Si on pouvait remplir COEFA
!        et COEFB directement, on gagnerait en simplicite, mais cela
!        demanderait un test sur IPPMOD dans condli : � voir)

        icodcl(ifac,ipriph) = 1
        if(coefb(ifac,iclp).lt.rinfin*0.5d0.and.                  &
           coefb(ifac,iclp).gt.0.d0  ) then
          hint = dt(iel)/ra(idistb-1+ifac)
          rcodcl(ifac,ipriph,1) = 0.d0
          rcodcl(ifac,ipriph,2) =                                 &
               hint*(1.d0/coefb(ifac,iclp)-1.d0)
        else
          rcodcl(ifac,ipriph,1) = 0.d0
        endif

      endif


!       La vitesse et la turbulence sont trait�es de mani�re standard,
!         dans condli.

!       Pour la thermique, on doit effectuer ici un pr�traitement,
!         la variable r�solue �tant l'energie
!         (energie interne+epsilon sup+energie cin�tique). En particulier
!         lorsque la paroi est � temp�rature impos�e, on pr�pare le
!         travail de clptur. Hormis l'�nergie r�solue, toutes les
!         variables rho et s prendront arbitrairement une condition de
!         flux nul (leurs conditions aux limites ne servent qu'� la
!         reconstruction des gradients et il parait d�licat d'imposer
!         autre chose qu'un flux nul sans risque de cr�er des valeurs
!         aberrantes au voisinage de la couche limite)

!       Par d�faut : adiabatique
      if(  icodcl(ifac,itkiph).eq.0.and.                          &
           icodcl(ifac,ieniph).eq.0) then
        icodcl(ifac,itkiph) = 3
        rcodcl(ifac,itkiph,3) = 0.d0
      endif

!       Temperature imposee
      if(icodcl(ifac,itkiph).eq.5) then

!           On impose la valeur de l'energie qui conduit au bon flux.
!             On notera cependant qu'il s'agit de la condition � la
!               limite pour le flux diffusif. Pour la reconstruction
!               des gradients, il faudra utiliser autre chose.
!               Par exemple un flux nul ou encore toute autre
!               condition respectant un profil : on se calquera sur
!               ce qui sera fait pour la temp�rature si c'est possible,
!               sachant que l'energie contient l'energie cinetique,
!               ce qui rend le choix du profil d�licat.

        icodcl(ifac,ieniph) = 5
        if(icv(iphas).eq.0) then
          rcodcl(ifac,ieniph,1) =                                 &
               cv0(iphas)*rcodcl(ifac,itkiph,1)
        else
          rcodcl(ifac,ieniph,1) = propce(iel,ipproc(icv(iphas)))  &
               *rcodcl(ifac,itkiph,1)
        endif
        rcodcl(ifac,ieniph,1) = rcodcl(ifac,ieniph,1)             &
           + 0.5d0*(rtp(iel,iuiph)**2+                            &
                    rtp(iel,iviph)**2+rtp(iel,iwiph)**2)          &
           + w5(iel)
!                   ^epsilon sup (cf USCFTH)

!           Les flux en grad epsilon sup et �nergie cin�tique doivent
!             �tre nuls puisque tout est pris par le terme de
!             diffusion d'energie.
        ia(iifbet+ifac-1+(iphas-1)*nfabor) = 1

!           Flux nul pour la reconstruction �ventuelle de temp�rature
        icodcl(ifac,itkiph) = 3
        rcodcl(ifac,itkiph,3) = 0.d0

!       Flux impose
      elseif(icodcl(ifac,itkiph).eq.3) then

!           On impose le flux sur l'energie
        icodcl(ifac,ieniph) = 3
        rcodcl(ifac,ieniph,3) = rcodcl(ifac,itkiph,3)

!           Les flux en grad epsilon sup et �nergie cin�tique doivent
!             �tre nuls puisque tout est pris par le terme de
!             diffusion d'energie.
        ia(iifbet+ifac-1+(iphas-1)*nfabor) = 1

!           Flux nul pour la reconstruction �ventuelle de temp�rature
        icodcl(ifac,itkiph) = 3
        rcodcl(ifac,itkiph,3) = 0.d0

      endif


!     Scalaires : flux nul (par defaut dans typecl pour iparoi)


!===============================================================================
! 3.  REMPLISSAGE DU TABLEAU DES CONDITIONS LIMITES
!       ON BOUCLE SUR TOUTES LES FACES DE SYMETRIE
!===============================================================================

    elseif ( itypfb(ifac,iphas).eq.isymet ) then

!     Les RCODCL ont ete initialises a -RINFIN pour permettre de
!       verifier ceux que l'utilisateur a modifies. On les remet a zero
!       si l'utilisateur ne les a pas modifies.
!       En symetrie, on traite toutes les variables.
      do ivar = 1, nvar
        if(rcodcl(ifac,ivar,1).le.-rinfin*0.5d0) then
          rcodcl(ifac,ivar,1) = 0.d0
        endif
      enddo

!     Le flux de masse est nul

      propfb(ifac,iflmab) = 0.d0

!     Condition de Pression

      iccfth = 90

      call uscfth                                                 &
      !==========
 ( idebia , idebra ,                                              &
   ndim   , ncelet , ncel   , nfac   , nfabor , nfml   , nprfml , &
   nnod   , lndfac , lndfbr , ncelbr ,                            &
   nvar   , nscal  , nphas  ,                                     &
   iccfth , ifac   , iphas  ,                                     &
   nideve , nrdeve , nituse , nrtuse ,                            &
   ifacel , ifabor , ifmfbr , ifmcel , iprfml ,                   &
   ipnfac , nodfac , ipnfbr , nodfbr ,                            &
   idevel , ituser , ia     ,                                     &
   xyzcen , surfac , surfbo , cdgfac , cdgfbo , xyznod , volume , &
   dt     , rtp    , rtpa   , propce , propfa , propfb ,          &
   coefa  , coefb  ,                                              &
   w1     , w2     , w3     , w4     ,                            &
   rdevel , rtuser , ra     )


!     Pression :
!       En g�n�ral : proportionnelle a la valeur interne
!         (Pbord = COEFB*Pi)
!       Si on d�tend trop : Dirichlet homogene

!       En outre, il faut appliquer une pre-correction pour compenser le
!        traitement fait dans condli... Si on pouvait remplir COEFA
!        et COEFB directement, on gagnerait en simplicite, mais cela
!        demanderait un test sur IPPMOD dans condli : � voir)

      icodcl(ifac,ipriph) = 3
      rcodcl(ifac,ipriph,1) = 0.d0
      rcodcl(ifac,ipriph,2) = rinfin
      rcodcl(ifac,ipriph,3) = 0.d0

!       Toutes les autres variables prennent un flux nul (sauf la vitesse
!         normale, qui est nulle) : par defaut dans typecl pour isymet.

!===============================================================================
! 4.  REMPLISSAGE DU TABLEAU DES CONDITIONS LIMITES
!       ON BOUCLE SUR TOUTES LES FACES D'ENTREE/SORTIE
!       ETAPE DE THERMO
!===============================================================================


!===============================================================================
!     4.1 Entree/sortie impos�e (par exemple : entree supersonique)
!===============================================================================

    elseif ( itypfb(ifac,iphas).eq.iesicf ) then

!     On a
!       - la vitesse,
!       - 2 variables parmi P, rho, T, E (mais pas (T,E)),
!       - la turbulence
!       - les scalaires

!     On recherche la variable a initialiser
!       (si on a donne une valeur nulle, c'est pas adapte : on supposera
!        qu'on n'a pas initialise et on sort en erreur)
      iccfth = 10000
      if(rcodcl(ifac,ipriph,1).gt.0.d0) iccfth = 2*iccfth
      if(rcodcl(ifac,irhiph,1).gt.0.d0) iccfth = 3*iccfth
      if(rcodcl(ifac,itkiph,1).gt.0.d0) iccfth = 5*iccfth
      if(rcodcl(ifac,ieniph,1).gt.0.d0) iccfth = 7*iccfth
      if((iccfth.le.70000.and.iccfth.ne.60000).or.                &
         (iccfth.eq.350000)) then
        write(nfecra,1000)iccfth
        call csexit (1)
      endif
      iccfth = iccfth + 900

!     Les RCODCL ont ete initialises a -RINFIN pour permettre de
!       verifier ceux que l'utilisateur a modifies. On les remet a zero
!       si l'utilisateur ne les a pas modifies.
!       On traite d'abord les variables autres que la turbulence et les
!       scalaires passifs : celles-ci sont traitees plus bas.
      do iii = 1, nvarcf
        ivar = ivarcf(iii)
        if(rcodcl(ifac,ivar,1).le.-rinfin*0.5d0) then
          rcodcl(ifac,ivar,1) = 0.d0
        endif
      enddo

!     On calcule les variables manquantes parmi P,rho,T,E
!     COEFA sert de tableau de transfert dans USCFTH

      do ivar = 1, nvar
        coefa(ifac,iclrtp(ivar,icoef)) = rcodcl(ifac,ivar,1)
      enddo

      call uscfth                                                 &
      !==========
 ( idebia , idebra ,                                              &
   ndim   , ncelet , ncel   , nfac   , nfabor , nfml   , nprfml , &
   nnod   , lndfac , lndfbr , ncelbr ,                            &
   nvar   , nscal  , nphas  ,                                     &
   iccfth , ifac   , iphas  ,                                     &
   nideve , nrdeve , nituse , nrtuse ,                            &
   ifacel , ifabor , ifmfbr , ifmcel , iprfml ,                   &
   ipnfac , nodfac , ipnfbr , nodfbr ,                            &
   idevel , ituser , ia     ,                                     &
   xyzcen , surfac , surfbo , cdgfac , cdgfbo , xyznod , volume , &
   dt     , rtp    , rtpa   , propce , propfa , propfb ,          &
   coefa  , coefb  ,                                              &
   w1     , w2     , w3     , w4     ,                            &
   rdevel , rtuser , ra     )


!     Rusanov, flux de masse et type de conditions aux limites :
!       voir plus bas


!===============================================================================
!     4.2 Sortie supersonique
!===============================================================================

    elseif ( itypfb(ifac,iphas).eq.isspcf ) then

!     On impose un Dirichlet �gal � la valeur interne pour rho u E
!       (on impose des Dirichlet d�duit pour les autres variables).
!       Il est inutile de passer dans Rusanov.
!     Il serait n�cessaire de reconstruire ces valeurs en utilisant
!       leur gradient dans la cellule de bord : dans un premier temps,
!       on utilise des valeurs non reconstruites (non consistant mais
!       potentiellement plus stable).
!     On pourrait imposer des flux nuls (a tester), ce qui �viterait
!       la n�cessit� de reconstruire les valeurs.

!     Les RCODCL ont ete initialises a -RINFIN pour permettre de
!       verifier ceux que l'utilisateur a modifies. On les remet a zero
!       si l'utilisateur ne les a pas modifies.
!       On traite d'abord les variables autres que la turbulence et les
!       scalaires passifs : celles-ci sont traitees plus bas.
      do iii = 1, nvarcf
        ivar = ivarcf(iii)
        if(rcodcl(ifac,ivar,1).le.-rinfin*0.5d0) then
          rcodcl(ifac,ivar,1) = 0.d0
        endif
      enddo

!     Valeurs de rho u E
      rcodcl(ifac,irhiph,1) = rtp(iel,irhiph)
      rcodcl(ifac,iuiph ,1) = rtp(iel,iuiph)
      rcodcl(ifac,iviph ,1) = rtp(iel,iviph)
      rcodcl(ifac,iwiph ,1) = rtp(iel,iwiph)
      rcodcl(ifac,ieniph,1) = rtp(iel,ieniph)

!     Valeurs de P et s d�duites
      iccfth = 924

      do ivar = 1, nvar
        coefa(ifac,iclrtp(ivar,icoef)) = rcodcl(ifac,ivar,1)
      enddo

      call uscfth                                                 &
      !==========
 ( idebia , idebra ,                                              &
   ndim   , ncelet , ncel   , nfac   , nfabor , nfml   , nprfml , &
   nnod   , lndfac , lndfbr , ncelbr ,                            &
   nvar   , nscal  , nphas  ,                                     &
   iccfth , ifac   , iphas  ,                                     &
   nideve , nrdeve , nituse , nrtuse ,                            &
   ifacel , ifabor , ifmfbr , ifmcel , iprfml ,                   &
   ipnfac , nodfac , ipnfbr , nodfbr ,                            &
   idevel , ituser , ia     ,                                     &
   xyzcen , surfac , surfbo , cdgfac , cdgfbo , xyznod , volume , &
   dt     , rtp    , rtpa   , propce , propfa , propfb ,          &
   coefa  , coefb  ,                                              &
   w1     , w2     , w3     , w4     ,                            &
   rdevel , rtuser , ra     )

!               flux de masse et type de conditions aux limites :
!       voir plus bas


!===============================================================================
!     4.3 Sortie a pression imposee
!===============================================================================

    elseif ( itypfb(ifac,iphas).eq.isopcf ) then

!       Sortie subsonique a priori (si c'est supersonique dans le
!         domaine, ce n'est pas pour autant que c'est supersonique
!         � la sortie, selon la pression que l'on a impos�e)

!     On utilise un scenario dans lequel on a une 1-d�tente et un
!       2-contact entrant dans le domaine. On d�termine les conditions
!       sur l'interface selon la thermo et on passe dans Rusanov
!       ensuite pour lisser.

!     Si P n'est pas donn�, erreur ; on sort aussi en erreur si P
!       n�gatif, m�me si c'est possible, dans la plupart des cas ce
!       sera une erreur
      if(rcodcl(ifac,ipriph,1).lt.-rinfin*0.5d0) then
        write(nfecra,1100)
        call csexit (1)
      endif

!     Les RCODCL ont ete initialises a -RINFIN pour permettre de
!       verifier ceux que l'utilisateur a modifies. On les remet a zero
!       si l'utilisateur ne les a pas modifies.
!       On traite d'abord les variables autres que la turbulence et les
!       scalaires passifs : celles-ci sont traitees plus bas.
      do iii = 1, nvarcf
        ivar = ivarcf(iii)
        if(rcodcl(ifac,ivar,1).le.-rinfin*0.5d0) then
          rcodcl(ifac,ivar,1) = 0.d0
        endif
      enddo

!     Valeurs de rho, u, E, s
      iccfth = 93

      do ivar = 1, nvar
        coefa(ifac,iclrtp(ivar,icoef)) = rcodcl(ifac,ivar,1)
      enddo

      call uscfth                                                 &
      !==========
 ( idebia , idebra ,                                              &
   ndim   , ncelet , ncel   , nfac   , nfabor , nfml   , nprfml , &
   nnod   , lndfac , lndfbr , ncelbr ,                            &
   nvar   , nscal  , nphas  ,                                     &
   iccfth , ifac   , iphas  ,                                     &
   nideve , nrdeve , nituse , nrtuse ,                            &
   ifacel , ifabor , ifmfbr , ifmcel , iprfml ,                   &
   ipnfac , nodfac , ipnfbr , nodfbr ,                            &
   idevel , ituser , ia     ,                                     &
   xyzcen , surfac , surfbo , cdgfac , cdgfbo , xyznod , volume , &
   dt     , rtp    , rtpa   , propce , propfa , propfb ,          &
   coefa  , coefb  ,                                              &
   w1     , w2     , w3     , w4     ,                            &
   rdevel , rtuser , ra     )

!     Rusanov, flux de masse et type de conditions aux limites :
!       voir plus bas


!===============================================================================
!     4.4 Entree � rho et U imposes
!===============================================================================

    elseif ( itypfb(ifac,iphas).eq.ierucf ) then

!       Entree subsonique a priori (si c'est supersonique dans le
!         domaine, ce n'est pas pour autant que c'est supersonique
!         � l'entree, selon les valeurs que l'on a impos�es)

!     On utilise un scenario d�tente ou choc.
!       On d�termine les conditions sur l'interface
!       selon la thermo et on passe dans Rusanov ensuite pour lisser.

!     Si rho et u ne sont pas donn�s, erreur
      if(rcodcl(ifac,irhiph,1).lt.-rinfin*0.5d0.or.               &
         rcodcl(ifac,iuiph ,1).lt.-rinfin*0.5d0.or.               &
         rcodcl(ifac,iviph ,1).lt.-rinfin*0.5d0.or.               &
         rcodcl(ifac,iwiph ,1).lt.-rinfin*0.5d0) then
        write(nfecra,1200)
        call csexit (1)
      endif

!     Les RCODCL ont ete initialises a -RINFIN pour permettre de
!       verifier ceux que l'utilisateur a modifies. On les remet a zero
!       si l'utilisateur ne les a pas modifies.
!       On traite d'abord les variables autres que la turbulence et les
!       scalaires passifs : celles-ci sont traitees plus bas.
      do iii = 1, nvarcf
        ivar = ivarcf(iii)
        if(rcodcl(ifac,ivar,1).le.-rinfin*0.5d0) then
          rcodcl(ifac,ivar,1) = 0.d0
        endif
      enddo

!     Valeurs de P, E, s
      iccfth = 92

      do ivar = 1, nvar
        coefa(ifac,iclrtp(ivar,icoef)) = rcodcl(ifac,ivar,1)
      enddo

      call uscfth                                                 &
      !==========
 ( idebia , idebra ,                                              &
   ndim   , ncelet , ncel   , nfac   , nfabor , nfml   , nprfml , &
   nnod   , lndfac , lndfbr , ncelbr ,                            &
   nvar   , nscal  , nphas  ,                                     &
   iccfth , ifac   , iphas  ,                                     &
   nideve , nrdeve , nituse , nrtuse ,                            &
   ifacel , ifabor , ifmfbr , ifmcel , iprfml ,                   &
   ipnfac , nodfac , ipnfbr , nodfbr ,                            &
   idevel , ituser , ia     ,                                     &
   xyzcen , surfac , surfbo , cdgfac , cdgfbo , xyznod , volume , &
   dt     , rtp    , rtpa   , propce , propfa , propfb ,          &
   coefa  , coefb  ,                                              &
   w1     , w2     , w3     , w4     ,                            &
   rdevel , rtuser , ra     )

!     Rusanov, flux de masse et type de conditions aux limites :
!       voir plus bas


!===============================================================================
!     4.5 Entree � rho*U et rho*U*H imposes
!===============================================================================

    elseif ( itypfb(ifac,iphas).eq.ieqhcf ) then

!       Entree subsonique a priori (si c'est supersonique dans le
!         domaine, ce n'est pas pour autant que c'est supersonique
!         � l'entree, selon les valeurs que l'on a impos�es)

!     On utilise un scenario dans lequel on a un 2-contact et une
!       3-d�tente entrant dans le domaine. On d�termine les conditions
!       sur l'interface selon la thermo et on passe dans Rusanov
!       ensuite pour lisser.

!     Si rho et u ne sont pas donn�s, erreur
      if(rcodcl(ifac,irun (iphas),1).lt.-rinfin*0.5d0.or.         &
         rcodcl(ifac,irunh(iphas),1).lt.-rinfin*0.5d0) then
        write(nfecra,1300)
        call csexit (1)
      endif

!     Les RCODCL ont ete initialises a -RINFIN pour permettre de
!       verifier ceux que l'utilisateur a modifies. On les remet a zero
!       si l'utilisateur ne les a pas modifies.
!       On traite d'abord les variables autres que la turbulence et les
!       scalaires passifs : celles-ci sont traitees plus bas.
      do iii = 1, nvarcf
        ivar = ivarcf(iii)
        if(rcodcl(ifac,ivar,1).le.-rinfin*0.5d0) then
          rcodcl(ifac,ivar,1) = 0.d0
        endif
      enddo

!     A coder

!     Noter que IRUN(IPHAS)  = ISCA(IRHO (IPHAS))
!            et IRUNH(IPHAS) = ISCA(IENER(IPHAS))
!     (aliases pour simplifier uscfcl)

      write(nfecra,1301)
      call csexit (1)

!===============================================================================
! 5. CONDITION NON PREVUE
!===============================================================================
!     Stop
    else

      write(nfecra,1400)
      call csexit (1)

! --- Fin de test sur les types de faces
    endif


!===============================================================================
! 6. FIN DU TRAITEMENT DES ENTREE/SORTIES
!     CALCUL DU FLUX DE MASSE,
!     CALCUL DES FLUX DE BORD AVEC RUSANOV (SI BESOIN)
!     TYPE DE C    .L. (DIRICHLET NEUMANN)
!===============================================================================

    if ( ( itypfb(ifac,iphas).eq.iesicf ) .or.                    &
         ( itypfb(ifac,iphas).eq.isspcf ) .or.                    &
         ( itypfb(ifac,iphas).eq.isopcf ) .or.                    &
         ( itypfb(ifac,iphas).eq.ierucf ) .or.                    &
         ( itypfb(ifac,iphas).eq.ieqhcf ) ) then

!===============================================================================
!     6.1 Flux de bord Rusanov ou simplement flux de masse
!         Attention a bien avoir calcule gamma pour Rusanov
!===============================================================================

!     Sortie supersonique :
      if ( itypfb(ifac,iphas).eq.isspcf ) then

!     Seul le flux de masse est calcule (on n'appelle pas Rusanov)
!       (toutes les variables sont connues)

        propfb(ifac,iflmab) = coefa(ifac,iclr)*                   &
             ( coefa(ifac,iclu)*surfbo(1,ifac)                    &
             + coefa(ifac,iclv)*surfbo(2,ifac)                    &
             + coefa(ifac,iclw)*surfbo(3,ifac) )

!     Entree subsonique

      else if ( itypfb(ifac,iphas).eq.ierucf ) then

!     Seul le flux de masse est calcule (on n'appelle pas Rusanov)

        propfb(ifac,iflmab) = coefa(ifac,iclr)*                   &
             ( coefa(ifac,iclu)*surfbo(1,ifac)                    &
             + coefa(ifac,iclv)*surfbo(2,ifac)                    &
             + coefa(ifac,iclw)*surfbo(3,ifac) )



!     Autres entrees/sorties :
      else

!     On calcule des flux par Rusanov (PROPFB)
!       (en particulier, le flux de masse est complete)

        call cfrusb                                               &
        !==========
 ( idebia , idebra ,                                              &
   ndim   , ncelet , ncel   , nfac   , nfabor , nfml   , nprfml , &
   nnod   , lndfac , lndfbr , ncelbr ,                            &
   nvar   , nscal  , nphas  ,                                     &
   ifac   , iphas  ,                                              &
   nideve , nrdeve , nituse , nrtuse ,                            &
   ifacel , ifabor , ifmfbr , ifmcel , iprfml ,                   &
   ipnfac , nodfac , ipnfbr , nodfbr ,                            &
   idevel , ituser , ia     ,                                     &
   gammag ,                                                       &
   xyzcen , surfac , surfbo , cdgfac , cdgfbo , xyznod , volume , &
   dt     , rtp    , rtpa   , propce , propfa , propfb ,          &
   coefa  , coefb  ,                                              &
   w1     , w2     , w3     , w4     ,                            &
   rdevel , rtuser , ra     )

      endif

!===============================================================================
!     6.2 Recuperation de COEFA
!===============================================================================

!     On r�tablit COEFA dans RCODCL
      do ivar = 1, nvar
        rcodcl(ifac,ivar,1) = coefa(ifac,iclrtp(ivar,icoef))
      enddo

!===============================================================================
!     6.3 Types de C.L.
!===============================================================================

!     P               : Dirichlet sauf IESICF : Neumann (choix arbitraire)
!     rho, U, E, T    : Dirichlet
!     k, R, eps, scal : Dirichlet/Neumann selon flux de masse

!     Pour P, le Neumann est cens� etre moins genant pour les
!       reconstructions de gradient si la valeur de P fournie par
!       l'utilisateur est tres differente de la valeur interne.
!       Le choix est cependant arbitraire.

!     On suppose que par defaut,
!            RCODCL(IFAC,X,1) = utilisateur ou calcule ci-dessus
!            RCODCL(IFAC,X,2) = RINFIN
!            RCODCL(IFAC,X,3) = 0.D0
!       et si ICODCL(IFAC,X) = 3, seul RCODCL(IFAC,X,3) est utilis�


!-------------------------------------------------------------------------------
!     Pression : Dirichlet ou Neumann homogene
!-------------------------------------------------------------------------------

!       Entree sortie imposee : Neumann
      if ( itypfb(ifac,iphas).eq.iesicf ) then
        icodcl(ifac,ipriph)   = 3
!       Entree subsonique
      else if ( itypfb(ifac,iphas).eq.ierucf ) then
        icodcl(ifac,ipriph)   = 3
        rcodcl(ifac,ipriph,3) = 0.d0
!       Autres entrees/sorties : Dirichlet
      else
        icodcl(ifac,ipriph)   = 1
      endif

!-------------------------------------------------------------------------------
!     rho U E T : Dirichlet
!-------------------------------------------------------------------------------

!     Masse volumique
      icodcl(ifac,irhiph)   = 1
!     Vitesse
      icodcl(ifac,iuiph)    = 1
      icodcl(ifac,iviph)    = 1
      icodcl(ifac,iwiph)    = 1
!     Energie totale
      icodcl(ifac,ieniph)   = 1
!     Temperature
      icodcl(ifac,itkiph)   = 1

!-------------------------------------------------------------------------------
!     turbulence et scalaires passifs : Dirichlet/Neumann selon flux
!-------------------------------------------------------------------------------

!       Dirichlet ou Neumann homog�ne
!       On choisit un Dirichlet si le flux de masse est entrant et
!       que l'utilisateur a donn� une valeur dans RCODCL

      if(propfb(ifac,iflmab).ge.0.d0) then
        if(itytur(iphas).eq.2) then
          icodcl(ifac,ik (iphas)) = 3
          icodcl(ifac,iep(iphas)) = 3
        elseif(itytur(iphas).eq.3) then
          icodcl(ifac,ir11(iphas)) = 3
          icodcl(ifac,ir22(iphas)) = 3
          icodcl(ifac,ir33(iphas)) = 3
          icodcl(ifac,ir12(iphas)) = 3
          icodcl(ifac,ir13(iphas)) = 3
          icodcl(ifac,ir23(iphas)) = 3
          icodcl(ifac,iep (iphas)) = 3
        elseif(iturb(iphas).eq.50) then
          icodcl(ifac,ik  (iphas)) = 3
          icodcl(ifac,iep (iphas)) = 3
          icodcl(ifac,iphi(iphas)) = 3
          icodcl(ifac,ifb (iphas)) = 3
        elseif(iturb(iphas).eq.60) then
          icodcl(ifac,ik  (iphas)) = 3
          icodcl(ifac,iomg(iphas)) = 3
        endif
        if(nscaus.gt.0) then
          do ii = 1, nscaus
            icodcl(ifac,isca(ii)) = 3
          enddo
        endif
      else
        if(itytur(iphas).eq.2) then
          if(rcodcl(ifac,ik (iphas),1).gt.0.d0.and.               &
             rcodcl(ifac,iep(iphas),1).gt.0.d0) then
            icodcl(ifac,ik (iphas)) = 1
            icodcl(ifac,iep(iphas)) = 1
          else
            icodcl(ifac,ik (iphas)) = 3
            icodcl(ifac,iep(iphas)) = 3
          endif
        elseif(itytur(iphas).eq.3) then
          if(rcodcl(ifac,ir11(iphas),1).gt.0.d0.and.              &
             rcodcl(ifac,ir22(iphas),1).gt.0.d0.and.              &
             rcodcl(ifac,ir33(iphas),1).gt.0.d0.and.              &
             rcodcl(ifac,ir12(iphas),1).gt.-rinfin*0.5d0.and.     &
             rcodcl(ifac,ir13(iphas),1).gt.-rinfin*0.5d0.and.     &
             rcodcl(ifac,ir23(iphas),1).gt.-rinfin*0.5d0.and.     &
             rcodcl(ifac,iep (iphas),1).gt.0.d0) then
            icodcl(ifac,ir11(iphas)) = 1
            icodcl(ifac,ir22(iphas)) = 1
            icodcl(ifac,ir33(iphas)) = 1
            icodcl(ifac,ir12(iphas)) = 1
            icodcl(ifac,ir13(iphas)) = 1
            icodcl(ifac,ir23(iphas)) = 1
            icodcl(ifac,iep (iphas)) = 1
          else
            icodcl(ifac,ir11(iphas)) = 3
            icodcl(ifac,ir22(iphas)) = 3
            icodcl(ifac,ir33(iphas)) = 3
            icodcl(ifac,ir12(iphas)) = 3
            icodcl(ifac,ir13(iphas)) = 3
            icodcl(ifac,ir23(iphas)) = 3
            icodcl(ifac,iep (iphas)) = 3
          endif
        elseif(iturb(iphas).eq.50) then
          if(rcodcl(ifac,ik  (iphas),1).gt.0.d0.and.              &
             rcodcl(ifac,iep (iphas),1).gt.0.d0.and.              &
             rcodcl(ifac,iphi(iphas),1).gt.0.d0.and.              &
             rcodcl(ifac,ifb (iphas),1).gt.-rinfin*0.5d0 ) then
            icodcl(ifac,ik  (iphas)) = 1
            icodcl(ifac,iep (iphas)) = 1
            icodcl(ifac,iphi(iphas)) = 1
            icodcl(ifac,ifb (iphas)) = 1
          else
            icodcl(ifac,ik  (iphas)) = 3
            icodcl(ifac,iep (iphas)) = 3
            icodcl(ifac,iphi(iphas)) = 3
            icodcl(ifac,ifb (iphas)) = 3
          endif
        elseif(iturb(iphas).eq.60) then
         if(rcodcl(ifac,ik  (iphas),1).gt.0.d0.and.               &
            rcodcl(ifac,iomg(iphas),1).gt.0.d0 ) then
            icodcl(ifac,ik  (iphas)) = 1
            icodcl(ifac,iomg(iphas)) = 1
          else
            icodcl(ifac,ik  (iphas)) = 3
            icodcl(ifac,iomg(iphas)) = 3
          endif
        endif
        if(nscaus.gt.0) then
          do ii = 1, nscaus
            if(rcodcl(ifac,isca(ii),1).gt.-rinfin*0.5d0) then
              icodcl(ifac,isca(ii)) = 1
            else
              icodcl(ifac,isca(ii)) = 3
            endif
          enddo
        endif
      endif


!     Les RCODCL ont ete initialises a -RINFIN pour permettre de
!       verifier ceux que l'utilisateur a modifies. On les remet a zero
!       si l'utilisateur ne les a pas modifies.
!       On traite la turbulence et les scalaires passifs (pour
!       simplifier la boucle, on traite toutes les variables : les
!       variables du compressible sont donc vues deux fois, mais ce
!       n'est pas grave).
      do ivar = 1, nvar
        if(rcodcl(ifac,ivar,1).le.-rinfin*0.5d0) then
          rcodcl(ifac,ivar,1) = 0.d0
        endif
      enddo


! --- Fin de test sur les faces d'entree sortie
    endif

! --- Fin de boucle sur les faces de bord
  enddo

! --- Fin de boucle sur les phases
enddo

!----
! FORMATS
!----

 1000 format(                                                           &
'@                                                            ',/,&
'@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@',/,&
'@                                                            ',/,&
'@ @@ ATTENTION : ARRET A L''EXECUTION                        ',/,&
'@    =========                                               ',/,&
'@    Deux variables independantes et deux seulement parmi    ',/,&
'@    P, rho, T et E doivent etre imposees aux bords de type  ',/,&
'@    IESICF dans uscfcl (ICCFTH = ',I10,').                  ',/,&
'@                                                            ',/,&
'@  Le calcul ne sera pas execute.                            ',/,&
'@                                                            ',/,&
'@  Verifier les conditions aux limites dans uscfcl.          ',/,&
'@                                                            ',/,&
'@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@',/,&
'@                                                            ',/)
 1100 format(                                                           &
'@                                                            ',/,&
'@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@',/,&
'@                                                            ',/,&
'@ @@ ATTENTION : ARRET A L''EXECUTION                        ',/,&
'@    =========                                               ',/,&
'@    La pression n''a pas ete fournie en sortie a pression   ',/,&
'@    impos�e.                                                ',/,&
'@                                                            ',/,&
'@  Le calcul ne sera pas execute.                            ',/,&
'@                                                            ',/,&
'@  Verifier les conditions aux limites dans uscfcl.          ',/,&
'@                                                            ',/,&
'@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@',/,&
'@                                                            ',/)
 1200 format(                                                           &
'@                                                            ',/,&
'@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@',/,&
'@                                                            ',/,&
'@ @@ ATTENTION : ARRET A L''EXECUTION                        ',/,&
'@    =========                                               ',/,&
'@    La masse volumique ou la vitesse n''a pas �t� fournie   ',/,&
'@    en entree a masse volumique et vitesse imposee.         ',/,&
'@                                                            ',/,&
'@  Le calcul ne sera pas execute.                            ',/,&
'@                                                            ',/,&
'@  Verifier les conditions aux limites dans uscfcl.          ',/,&
'@                                                            ',/,&
'@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@',/,&
'@                                                            ',/)
 1300 format(                                                           &
'@                                                            ',/,&
'@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@',/,&
'@                                                            ',/,&
'@ @@ ATTENTION : ARRET A L''EXECUTION                        ',/,&
'@    =========                                               ',/,&
'@    Le debit massique ou le debit enthalpique n''a pas �t�  ',/,&
'@    fourni en entree a debit massique et enthalpique impos�.',/,&
'@                                                            ',/,&
'@  Le calcul ne sera pas execute.                            ',/,&
'@                                                            ',/,&
'@  Verifier les conditions aux limites dans uscfcl.          ',/,&
'@                                                            ',/,&
'@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@',/,&
'@                                                            ',/)
 1301 format(                                                           &
'@                                                            ',/,&
'@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@',/,&
'@                                                            ',/,&
'@ @@ ATTENTION : ARRET A L''EXECUTION                        ',/,&
'@    =========                                               ',/,&
'@    Entree � debit massique et debit enthalpique non prevue ',/,&
'@                                                            ',/,&
'@  Le calcul ne sera pas execute.                            ',/,&
'@                                                            ',/,&
'@  Contacter l''equipe de developpement pour uscfcl.         ',/,&
'@                                                            ',/,&
'@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@',/,&
'@                                                            ',/)
 1400 format(                                                           &
'@                                                            ',/,&
'@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@',/,&
'@                                                            ',/,&
'@ @@ ATTENTION : ARRET A L''EXECUTION                        ',/,&
'@    =========                                               ',/,&
'@    Une condition a la limite ne fait pas partie des        ',/,&
'@      conditions aux limites predefinies en compressible.   ',/,&
'@                                                            ',/,&
'@  Le calcul ne sera pas execute.                            ',/,&
'@                                                            ',/,&
'@  Verifier les conditions aux limites dans uscfcl.          ',/,&
'@                                                            ',/,&
'@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@',/,&
'@                                                            ',/)
 7000 format(                                                           &
'@                                                            ',/,&
'@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@',/,&
'@                                                            ',/,&
'@ @@ ATTENTION : ARRET A L''EXECUTION                        ',/,&
'@    =========                                               ',/,&
'@    cfxtcl doit etre modifie pour prendre en compte une loi ',/,&
'@      d''etat a gamma variable. Seul est pris en compte le  ',/,&
'@      cas IEOS = 1                                          ',/,&
'@                                                            ',/,&
'@  Le calcul ne sera pas execute.                            ',/,&
'@                                                            ',/,&
'@  Verifier IEOS dans uscfth.                                ',/,&
'@                                                            ',/,&
'@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@',/,&
'@                                                            ',/)
!----
! FIN
!----

return
end
