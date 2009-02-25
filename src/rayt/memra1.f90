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

                  subroutine memra1                               &
!================

 ( idbia0 , idbra0 ,                                              &
   ndim   , ncelet , ncel   , nfac   , nfabor ,                   &
   nvar   , nscal  , nphas  ,                                     &
   ifinia , ifinra )

!===============================================================================
!  FONCTION
!  --------

!   SOUS-PROGRAMME DU MODULE RAYONNEMENT :
!   --------------------------------------

!  GESTION MEMOIRE DES VARIABLES LIEES AU RAYONNEMENT

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
! nvar             ! e  ! <-- ! nombre total de variables                      !
! nscal            ! e  ! <-- ! nombre total de scalaires                      !
! nphas            ! e  ! <-- ! nombre de phases                               !
! ifinia           ! e  ! --> ! pointeur de la premiere cas libre dan          !
!                  !    !     !  dans ia en sortie                             !
! ifinra           ! e  ! --> ! pointeur de la premiere cas libre dan          !
!                  !    !     !  dans ia en sortie                             !
!__________________.____._____.________________________________________________.

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
include "entsor.h"
include "numvar.h"
include "optcal.h"
include "radiat.h"

!===============================================================================

! Arguments

integer          idbia0 , idbra0
integer          ndim   , ncelet , ncel   , nfac   , nfabor
integer          nvar   , nscal  , nphas
integer          ifinia , ifinra

! VARIALBES LOCALES

integer          idebia , idebra

!===============================================================================

!---> INITIALISATION

idebia = idbia0
idebra = idbra0

!--> NOMBRE DE PHASES POUR LESQUELLES ON FAIT DU RAYONNEMENT

iizfrd =       idebia
ifinia =       iizfrd + nfabor * nphast

itsre  =       idebra
itsri  =       itsre  + ncelet * nphasc
iqx    =       itsri  + ncelet * nphasc
iqy    =       iqx    + ncelet * nphast
iqz    =       iqy    + ncelet * nphast
iabs   =       iqz    + ncelet * nphast
iemi   =       iabs   + ncelet * nphasc
icak   =       iemi   + ncelet * nphasc
ifinra =       icak   + ncelet * nphasc

itparo =       ifinra
iqinci =       itparo + nfabor * nphast
ixlam  =       iqinci + nfabor * nphast
iepa   =       ixlam  + nfabor * nphast
ieps   =       iepa   + nfabor * nphast
ifnet  =       ieps   + nfabor * nphast
ifconv =       ifnet  + nfabor * nphast
ihconv =       ifconv + nfabor * nphast
ifinra =       ihconv + nfabor * nphast

!---> VERIFICATION

CALL IASIZE('MEMRA1',IFINIA)
!     ==========

CALL RASIZE('MEMRA1',IFINRA)
!     ==========

return
end
