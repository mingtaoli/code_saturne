/*============================================================================
 *
 *     This file is part of the Code_Saturne Kernel, element of the
 *     Code_Saturne CFD tool.
 *
 *     Copyright (C) 1998-2008 EDF S.A., France
 *
 *     contact: saturne-support@edf.fr
 *
 *     The Code_Saturne Kernel is free software; you can redistribute it
 *     and/or modify it under the terms of the GNU General Public License
 *     as published by the Free Software Foundation; either version 2 of
 *     the License, or (at your option) any later version.
 *
 *     The Code_Saturne Kernel is distributed in the hope that it will be
 *     useful, but WITHOUT ANY WARRANTY; without even the implied warranty
 *     of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with the Code_Saturne Kernel; if not, write to the
 *     Free Software Foundation, Inc.,
 *     51 Franklin St, Fifth Floor,
 *     Boston, MA  02110-1301  USA
 *
 *============================================================================*/

#ifndef __CS_MESH_CONNECT_H__
#define __CS_MESH_CONNECT_H__

/*============================================================================
 * Passage d'une connectivit� noyau � une connecitvit� nodale de la
 * structure principale associ�e � un maillage
 *============================================================================*/

/*----------------------------------------------------------------------------
 * FVM library headers
 *----------------------------------------------------------------------------*/

#include "fvm_nodal.h"

/*----------------------------------------------------------------------------
 *  Local headers
 *----------------------------------------------------------------------------*/

#include "cs_base.h"
#include "cs_mesh.h"

/*----------------------------------------------------------------------------*/

BEGIN_C_DECLS

/*=============================================================================
 * Macro definitions
 *============================================================================*/

/*============================================================================
 * Type definitions
 *============================================================================*/

/*============================================================================
 * Static global variables
 *============================================================================*/

/*=============================================================================
 * Public function prototypes
 *============================================================================*/

/*----------------------------------------------------------------------------
 * Extract a mesh's "cells -> faces" connectivity.
 *
 * We consider a common numbering for internal and boundary faces, in which
 * boundary faces are defined first. The common id for the i-th boundary
 * face is thus i, and that of the j-th interior face is n_b_faces + j.
 *
 * If ind_cel_extr != NULL, then:
 * --- ind_cel_extr[cell_id] = id in the list to extract (0 to n-1)
 *     if cell cell_id should be extracted
 * --- ind_cel_extr[cell_id] = -1 if cells cell_id should be ignored
 *
 * parameters:
 *   mesh             <-- pointer to mesh structure
 *   extr_cell_size   <-- size of extr_cell_id[] array
 *   extr_cell_id     <-- extr_cell_id = ids of extracted cells, or -1
 *   p_cell_faces_idx --> cells -> faces index
 *   p_cell_faces_val --> cells -> faces connectivity
 *----------------------------------------------------------------------------*/

void
cs_mesh_connect_get_cell_faces(const cs_mesh_t             *mesh,
                               fvm_lnum_t                   extr_cell_size,
                               const fvm_lnum_t             extr_cell_id[],
                               fvm_lnum_t          * *const p_cell_faces_idx,
                               fvm_lnum_t          * *const p_cell_faces_val);

/*----------------------------------------------------------------------------
 * Build a nodal connectivity structure from a subset of a mesh's cells.
 *
 * The list of cells to extract is optional (if none is given, all cells
 * faces are extracted by default); it does not need to be ordered on input,
 * but is always ordered on exit (as cells are extracted by increasing number
 * traversal, the list is reordered to ensure the coherency of the extracted
 * mesh's link to its parent cells, built using this list).
 *
 * parameters:
 *   mesh           <-- base mesh
 *   name           <-- extracted mesh name
 *   cell_list_size <-- size of cell_list[] array
 *   cell_list      <-> list of cells (1 to n), or NULL
 *
 * returns:
 *   pointer to extracted nodal mesh
 *----------------------------------------------------------------------------*/

fvm_nodal_t *
cs_mesh_connect_cells_to_nodal(const cs_mesh_t  *mesh,
                               const char       *name,
                               fvm_lnum_t        cell_list_size,
                               fvm_lnum_t        cell_list[]);

/*----------------------------------------------------------------------------
 * Build a nodal connectivity structure from a subset of a mesh's faces.
 *
 * The lists of faces to extract are optional (if none is given, boundary
 * faces are extracted by default); they do not need to be ordered on input,
 * but they are always ordered on exit (as faces are extracted by increasing
 * number traversal, the lists are reordered to ensure the coherency of
 * the extracted mesh's link to its parent faces, built using these lists).
 *
 * parameters:
 *   mesh             <-- base mesh
 *   name             <-- extracted mesh name
 *   i_face_list_size <-- size of i_face_list[] array
 *   b_face_list_size <-- size of b_face_list[] array
 *   i_face_list      <-> list of interior faces (1 to n), or NULL
 *   b_face_list      <-> list of boundary faces (1 to n), or NULL
 *
 * returns:
 *   pointer to extracted nodal mesh
 *----------------------------------------------------------------------------*/

fvm_nodal_t *
cs_mesh_connect_faces_to_nodal(const cs_mesh_t  *mesh,
                               const char       *name,
                               fvm_lnum_t        i_face_list_size,
                               fvm_lnum_t        b_face_list_size,
                               fvm_lnum_t        i_face_list[],
                               fvm_lnum_t        b_face_list[]);

/*----------------------------------------------------------------------------*/

END_C_DECLS

#endif /* __CS_MESH_CONNECT_H__ */
