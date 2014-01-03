!-------------------------------------------------------------------------------

! This file is part of Code_Saturne, a general-purpose CFD tool.
!
! Copyright (C) 1998-2013 EDF S.A.
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

!> \file entsor.f90
!> \brief Module for input/output

module entsor

  !=============================================================================

  use paramx

  implicit none

  !=============================================================================

  !> \defgroup entsor Module for input/output

  !> \addtogroup entsor
  !> \{

  !> standard output
  integer, save :: nfecra

  !> characterises the level of detail of the outputs for the
  !> variable \ref ivar (from 1 to \ref nvar). The quantity of information
  !> increases with its value.
  !> Impose the value 0 or 1 for a reasonable listing size. Impose the value 2
  !> to get a maximum quantity of information, in case of problem during the
  !> execution.  Always useful.
  integer, save :: iwarni(nvarmx)

  !> unit of the upstream restart file for the vortex method.
  !> Useful if and only if isuivo=1 and  ivrtex=1.
  integer, save :: impmvo

  !> unit of the downstream restart file for the vortex method.
  !> Useful if and only if ivrtex=1.
  integer, save :: impvvo

  !> unit of the \ref ficvor data files for the vortex method. These
  !> files are text files. Their number and names are specified by the user in
  !> the \ref usvort subroutine.
  !> (Although it corresponds to an 'upstream' data file, \ref impdvo is
  !> initialized to 20 because, in case of multiple vortex entries,
  !> it is opened at the same time as the \ref ficmvo upstream restart file,
  !> which already uses unit 11)
  !> useful if and only if \ref ivrtex=1
  integer, save :: impdvo

  !> name of file, see usvort module.
  character*13, save :: ficdat

  !> saving period of the restart filesy5
  !>   - -2: no restart at all
  !>   - -1: only at the end of the calculation
  !>   - 0: by default (four times during the calculation)
  !>   - \>0: period
  integer, save :: ntsuit

  !> in post post processing output nth variable if ichrvr(n)=1
  !> for each quantity defined at the cell centres (physical or numerical
  !> variable), indicator of whether it should be post-processed or not
  !>   * -999: not initialised. By default, the post-processed
  !> quantities are the unknowns (pressure, velocity, \f$k\f$, \f$\varepsilon\f$,
  !> \f$R_{ij}\f$, \f$\omega\f$, \f$\varphi\f$, \f$\overline{f}\f$, scalars),
  !> density,turbulent viscosity and the time step if is not uniform.
  !>   * 0: not post-processed.
  !>   * 1: post-processed.
  !>
  !> Useful if and only if the variable is defined at the cell centers:
  !> calculation variable, physical property (time step, density,
  !> viscosity, specific heat) or turbulent viscosity if \ref iturb >= 10
  integer, save :: ichrvr(nvppmx)

  !> field key for output label
  integer, save :: keylbl = -1

  !> field keys for logging and postprocessing output
  integer, save :: keylog = -1
  integer, save :: keyvis = -1

  !> field key for start position in global postprocessing (ipp index) arrays
  integer, save :: keyipp = -1

  !> \defgroup userfile Additional user files

  !> \addtogroup userfile
  !> \{

  !> name of the thermochemical data file. The launch script is designed
  !> to copy the user specified thermochemical data file in the temporary
  !> execution directory under the name \ref dp_tch, for \ref CS to open it
  !> properly.  Should the value of \ref ficfpp be changed, the launch script
  !> would have to be adapted.
  !> Useful in case of gas or pulverised coal combustion.
  character*32, save :: ficfpp

  !> logical unit of the thermochemical data file.
  !> Useful in case of gas or pulverised coal combustion or electric arcs;
  integer, save :: impfpp

  !> perform Janaf (=1) or not (=0)
  integer, save :: indjon

  !> Input files for the atmospheric specific physics
  !> (name of the meteo profile file)
  character*32, save :: ficmet
  !> logical unit of the meteo profile file
  integer, save :: impmet

  !> \}

  !> \defgroup history History user files

  !> \addtogroup history
  !> \{

  !> Maximum number of user chronological files.
  !> In the case where \ref ushist is used.
  integer    nushmx
  parameter(nushmx=16)

  !> directory in which the potential chronological record files generated by
  !> the Kernel will be written (path related to the execution directory)
  !> - it is recommended to keep the default value and, if necessary, to modify
  !> the launch script to copy the files in the alternate destination directory
  !> - useful if and only if chronological record files are generated
  !> (i.e. there is \ref n for which \ref ihisvr "ihisvr(n, 1)" \f$\ne\f$ 0)
  character*80, save :: emphis

  !> prefix of history files
  character*80, save :: prehis

  !> units of the user chronological record files.
  !> Useful if and only if the subroutine \ref ushist is used.
  integer, save :: impush(nushmx)

  !> names of the user chronological record files.
  !> In the case of a non-parallel
  !> calculation, the suffix applied the file name is a three digit number:
  !> \f$ \texttt{ush001}\f$, \f$\texttt{ush002}\f$, \f$\texttt{ush003}\f$...
  !> In the case of a parallel-running calculation,
  !> the four digit processor index-number is added to the suffix.
  !> For instance, for a calculation running on two processors:
  !>  -from \f$ \texttt{ush001.n\_0001} \f$ to  \f$ \texttt{ush010.n\_0001} \f$
  !>  -and \f$ \texttt{ush001.n\_0002} \f$ to \f$ \texttt{ush010.n\_0002} \f$.
  !>  - ush001.n_0002, ush002.n_0002, ush003.n_0002...
  !> The opening, closing, format and location of these files must be managed
  !> by the user. Useful if and only if the subroutine \ref ushist is used
  character*13, save :: ficush(nushmx)

  !> sytock file and mobile structure varibles output unit
  integer, save :: impsth(2)

  !> maximum number of probes
  !> see associated format in \ref ecrhis
  integer    ncaptm
  parameter(ncaptm=100)

  !> time plot format (1: .dat, 2: .csv, 3: both)
  integer, save :: tplfmt

  !> total number of probes (limited to \ref ncaptm=100)
  integer, save :: ncapt

  !> output period of the chronological record files:
  !> - -1: no output
  !> - \>0: period  (every \ref nthist time step)
  !>
  !> The default value is -1 if there is no chronological record file to
  !> generate (if there is no probe, \ref ncapt = 0, or if \ref ihisvr(n, 1)=0 for
  !> all the variables) and 1 otherwise.
  !> If chronological records are generated, it is usually wise to keep the default
  !> value \ref nthist=1, in order to avoid missing any high frequency evolution (unless
  !> the total number of time steps is much too big).
  !> Useful if and only if chronological record files are generated (
  !> i.e. there are probes (\ref ncapt>0) there is \ref n for which
  !> \ref ihisvr(n, 1) \f$\ne\f$ 0)
  integer, save :: nthist

  !> frhist : output frequency in seconds
  double precision, save :: frhist

  !> saving period the chronological record files (they are first stored in a
  !> temporary file and then saved every \ref nthsav time step):
  !>    - 0: by default (4 times during a calculation)
  !>    - -1: saving at the end of the calculation
  !>    - >0: period (every \ref nthsav time step)
  !>
  !> During the calculation, the user can read the chronological record files
  !> in the execution directory when they have been saved, i.e. at the first
  !> time step, at the tenth time step and when the time step number is a multiple of
  !> \ref nthsav (multiple of \ref (ntmabs-ntpabs)/4 if \ref nthsav=0).
  !> \note Using the \ref control_file file allows to update the value of
  !> \ref ntmabs. Hence, if the calculation is at the time step n, the saving of the
  !> chronological record files can be forced by changing \ref ntmabs to
  !> \ref ntpabs+4(n+1)
  !>
  !> Using \ref control_file; after the files have been saved, \ref ntmabs can be
  !> reset to its original value, still using \ref control_file.
  !> Useful if and only if chronological record files are generated (\em
  !> i.e. there are probes (\ref ncapt>0) there is n for which
  !> \ref ihisvr(n, 1) \f$\ne\f$ 0)
  integer, save :: nthsav

  !> number \ref ihisvr "ihisvr(n, 1)" and index-numbers \ref ihisvr "ihisvr(n, j>1)"
  !> of the record probes to be used for each variable, em i.e. calculation variable
  !> or physical property defined at the cell centers.
  !> With \ref ihisvr "ihisvr(n, 1)"=-999 or -1, \ref ihisvr(n, j>1) is useless.
  !>  - \ref ihisvr "ihisvr(n, 1)": number of record probes to use
  !> for the variable N.
  !>     * = -999: by default: chronogical records are generated on
  !> all the probes if N is one of the main variables (pressure, velocity,
  !> turbulence, scalars), the local time step or the turbulent
  !> viscosity. For the other quantities, no chronological record is generated.
  !>     * = -1: chronological records are produced on all the probes.
  !>     * = 0: no chronological record on any probe.
  !>     * > 0: chronological record on \ref ihisvr "ihisvr(n, 1)" probes to be
  !> specified with  \ref ihisvr "ihisvr(n, j>1)".
  !> always useful, must be inferior or equal to \ref ncapt.
  !>  - \ref ihisvr "ihisvr(n, j>1)": index-numbers of the probes
  !> used for the variable n.
  !> (with j <= \ref ihisvr "ihisvr(n,1)+1").
  !>     * = -999: by default: if \ref ihisvr "ihisvr(n, 1)" \f$\ne\f$ -999
  !> the  code stops. Otherwise, refer to the description of the case
  !> \ref ihisvr "ihisvr(n, 1)"=-999.
  !>
  !> Useful if and only if \ref ihisvr "ihisvr(n, 1)" > 0 .
  !>
  !> The condition \ref ihisvr "ihisvr(n, j)" <= \ref ncapt must be respected.
  !> For an easier use, it is recommended to simply specify \ref ihisvr "ihisvr(n,1)"=-1 for
  !> all the interesting variables.
  integer, save :: ihisvr(nvppmx,ncaptm+1)

  !> write indicator (O or 1) for history of internal mobile structures
  integer, save :: ihistr

  !> probes corresponding element
  integer, save :: nodcap(ncaptm)

  !> row of process containing nodcap (in parallel processing)
  integer, save :: ndrcap(ncaptm)

  !> xyzcap : required position for a probe
  !> 3D-coordinates of the probes.
  !> the coordinates are written: \ref xyzcap(i,j), with i = 1,2 or 3
  !> and j <= \ref ncapt.
  !> Useful if and only if \ref ncapt > 0.
  double precision, save :: xyzcap(3,ncaptm)

  !> tplflw : time plot flush wall-time interval (none if <= 0)
  double precision, save :: tplflw

  !> \}

  !> \defgroup lagrange Lagrange files

  !> \addtogroup lagrange
  !> \{

  !> name of Lagrange listing
  character*6, save :: ficlal

  !> logical unit of Lagrange listing
  integer, save :: implal
  !> output period of Lagrange listing
  integer, save :: ntlal


  !> unit of a file specific to Lagrangian modelling.
  !> Useful in case of Lagrangian modelling.
  integer, save :: impla1

  !> unit of a file specific to Lagrangian modelling.
  !> Useful in case of Lagrangian modelling.
  integer, save :: impla2

  !> unit of a file specific to Lagrangian modelling.
  !> Useful in case of Lagrangian modelling.
  integer, save :: impla3

  !> unit of a file specific to Lagrangian modelling.
  !> Useful in case of Lagrangian modelling.
  integer, save :: impla4

  !> units of files specific to Lagrangian modelling. 15-dimension array.
  !> Useful in case of Lagrangian modelling.
  integer, save :: impla5(15)

  !> \}

  !> \addtogroup userfile
  !> \{

  ! --- Fichiers utilisateurs

  !> maximal number of user files
  integer    nusrmx
  parameter(nusrmx=10)

  !> unit numbers for potential user specified files.
  !> Useful if and only if the user needs files
  !> (therefore always useful, by security)
  integer, save ::      impusr(nusrmx)

  !> name of the potential user specified files. In the case of a non-parallel
  !> calculation, the suffix applied the file name is a two digit number:
  !> from \f$ \texttt{usrf01} \f$ to \f$ \texttt{usrf10} \f$ .
  !> In the case of a parallel-running calculation, the four digit processor index-number is
  !> added to the suffix. For instance, for a calculation running on two
  !> processors: from \f$ \texttt{usrf01.n\_0001} \f$ to  \f$ \texttt{usrf10.n\_0001} \f$ and
  !> from \f$ \texttt{usrf01.n\_0002} \f$ to \f$ \texttt{usrf10.n\_0002} \f$ . The opening,
  !> closing, format and location of these files must be managed by the user.
  !> useful if and only if the user needs files (therefore always useful, by security)
  character*13, save :: ficusr(nusrmx)

  !> \}

  !> \defgroup listing Output listing

  !> \addtogroup listing
  !> \{

  !> temporary variable name for some algebraic operations

  character*80, save :: nomva0

  !> name physical properties: used in the
  !> execution listing, in the post-processing files, etc.
  !> If not initialised,  the code chooses the manes by default.
  !> It is recommended not to define property names of more than 16
  !> characters, to get a clear execution listing (some advanced writing
  !> levels take into account only the first 16 characters).
  !> always useful}
  character*80, save :: nomprp(npromx)

  !> locator pointer vor variables output
  integer, save :: ipprtp(nvarmx)
  !> locator pointer vor variables output
  integer, save :: ipppro(npromx)
  !> locator pointer vor variables output
  integer, save :: ippdt
  !> locator pointer vor variables output
  integer, save :: ipptx
  !> locator pointer vor variables output
  integer, save :: ippty
  !> locator pointer vor variables output
  integer, save :: ipptz

  !> for every quantity (variable, physical or numerical property ...),
  !> indicator concerning the writing in the execution report file
  !> default value (-999) is automatically converted into 1 if the concerned
  !> quantity is one of the main variables (pressure, velocity, turbulence,
  !> scalar), the density, the time step if \ref idtvar > 0 or the turbulent
  !> viscosity. Otherwise converted into 0.
  !> = 1: writing in the execution listing.
  !> = 0: no writing.
  integer, save :: ilisvr(nvppmx)

  !> writing period in the execution report file.
  !>   - -1: no writing
  !>   - \> 0: period (every \ref ntlist time step). The value of
  !> \ref ntlist must be adapted according to the number of iterations
  !> carried out in the calculation. Keeping \ref ntlist to 1 will indeed provide
  !> a maximum volume of information, but if the number of time steps
  !> is too large the execution report file might become too big and unusable
  !> (problems with disk space, memory problems while opening the file with a
  !> text editor, problems finding the desired information in the file, ...).
  integer, save :: ntlist

  !> \defgroup convergence Convergence information

  !> \addtogroup convergence
  !> \{

  !> number of iterations
  integer, save :: nbivar(nvppmx)
  !> right-hand-side norm
  double precision, save :: rnsmbr(nvppmx)
  !> normed residual
  double precision, save :: resvar(nvppmx)
  !> norm of drift in time
  double precision, save :: dervar(nvppmx)

  !> \}
  !> \}

  !> \defgroup other_output Boundary post-processing

  !> \addtogroup other_output
  !> \{

  !> indicates the data to post-process on the boundary mesh (the boundary mesh must
  !> have been activated with \ref ichrbo=1. Its value is
  !> the product of the following integers, depending on the variables
  !> that should be post-processed:
  !> \ref ipstyp: \f$ y^+ \f$ at the boundary
  !> \ref ipstcl: value of the variables at the
  !> boundary (using the boundary conditions but without reconstruction)
  !> \ref ipstft}: thermal flux at the boundary
  !> ( \f$ W\,m^{-2} \f$ ), if a thermal scalar has been defined (\ref iscalt)
  !> For instance, with \ref ipstdv=ipstyp*ipstcl,
  !> \f$ y^+ \f$ and the variables will be post-processed at the boundaries.
  !> With \ref ipstdv=1, none of these data are post-processed at the boundaries.
  !> always useful if \ref ichrbo=1
  integer, save :: ipstdv(6)

  !> post-processed property: Efforts (1: all; 2: tangent; 4: normal)
  integer    ipstfo
  !> post-processed property: yplus
  integer    ipstyp
  !> post-processed property: Tplus
  integer    ipsttp
  !> post-processed property: thermal flux rebuilt
  integer    ipstft
  !> post-processed property: boundary temperature
  integer    ipsttb
  !> post-processed property: Nusselt
  integer    ipstnu
  parameter (ipstfo=1, ipstyp=2, ipsttp= 3, ipstft=4, ipsttb=5, ipstnu=6)

  !> margin in seconds on the remaining CPU time which is necessary to allow
  !> the calculation to stop automatically and write all the required results
  !> (for the machines having a queue manager).
  !>   - -1: calculated automatically,
  !>   - 0: margin defined by the user.
  !> Always useful, but the default value should not be changed.
  double precision, save :: tmarus
  !> \}
  !> \}

  !=============================================================================

end module entsor
