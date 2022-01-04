/*============================================================================
 * Main functions dedicated to soil management in groundwater flows
 *============================================================================*/

/* VERS */

/*
  This file is part of Code_Saturne, a general-purpose CFD tool.

  Copyright (C) 1998-2022 EDF S.A.

  This program is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License as published by the Free Software
  Foundation; either version 2 of the License, or (at your option) any later
  version.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
  details.

  You should have received a copy of the GNU General Public License along with
  this program; if not, write to the Free Software Foundation, Inc., 51 Franklin
  Street, Fifth Floor, Boston, MA 02110-1301, USA.
*/

/*----------------------------------------------------------------------------*/

/*----------------------------------------------------------------------------
 * Standard C library headers
 *----------------------------------------------------------------------------*/

#include <assert.h>
#include <ctype.h>
#include <float.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>

/*----------------------------------------------------------------------------
 *  Local headers
 *----------------------------------------------------------------------------*/

#include <bft_mem.h>
#include <bft_printf.h>

#include "cs_field.h"
#include "cs_gwf_priv.h"
#include "cs_hodge.h"
#include "cs_log.h"
#include "cs_math.h"
#include "cs_mesh_location.h"
#include "cs_parall.h"
#include "cs_param_types.h"
#include "cs_post.h"
#include "cs_prototypes.h"
#include "cs_reco.h"
#include "cs_volume_zone.h"

/*----------------------------------------------------------------------------
 * Header for the current file
 *----------------------------------------------------------------------------*/

#include "cs_gwf_soil.h"

/*----------------------------------------------------------------------------*/

BEGIN_C_DECLS

/*!
  \file cs_gwf_soil.c

  \brief Main functions dedicated to soil management in groundwater flows when
         using CDO schemes

*/

/*============================================================================
 * Local macro definitions
 *============================================================================*/

#define CS_GWF_SOIL_DBG 0

/*============================================================================
 * Structure definitions
 *============================================================================*/

/*! \cond DOXYGEN_SHOULD_SKIP_THIS */

/*============================================================================
 * Static global variables
 *============================================================================*/

static const char _err_empty_soil[] =
  " Stop execution. The structure related to a soil is empty.\n"
  " Please check your settings.\n";

static int  _n_soils = 0;
static cs_gwf_soil_t  **_soils = NULL;

/* The following array enables to get the soil id related to each cell.
   The array size is equal to n_cells */
static short int *_cell2soil_ids = NULL;

/*============================================================================
 * Private function prototypes
 *============================================================================*/

/*----------------------------------------------------------------------------*/
/*!
 * \brief  Function that compute the new values of the properties related to
 *         a soil with a Van Genuchten-Mualen.
 *         Case of an isotropic permeability and an unsteady Richards eq.
 *
 * \param[in]      t_eval        time at which one performs the evaluation
 * \param[in]      mesh          pointer to a cs_mesh_t structure
 * \param[in]      connect       pointer to a cs_cdo_connect_t structure
 * \param[in]      quant         pointer to a cs_cdo_quantities_t structure
 * \param[in]      head_values   array of values for head used in law
 * \param[in]      zone          pointer to a cs_zone_t
 * \param[in, out] soil          pointer to a soil structure
 */
/*----------------------------------------------------------------------------*/

static inline void
_update_soil_genuchten_iso(const cs_real_t              t_eval,
                           const cs_mesh_t             *mesh,
                           const cs_cdo_connect_t      *connect,
                           const cs_cdo_quantities_t   *quant,
                           const cs_zone_t             *zone,
                           cs_gwf_soil_t               *soil)
{
  CS_UNUSED(t_eval);
  CS_UNUSED(mesh);
  CS_UNUSED(connect);
  CS_UNUSED(quant);

  if (soil == NULL)
    return;

  assert(soil->hydraulic_model ==  CS_GWF_MODEL_UNSATURATED_SINGLE_PHASE);

  /* Retrieve the soil parameters */

  cs_gwf_soil_param_genuchten_t  *sp = soil->param;

  /* Retrieve the hydraulic context */

  cs_gwf_unsaturated_single_phase_t  *hc = soil->hydraulic_context;

  /* Only isotropic values are considered in this case */

  const double  iso_satval = sp->saturated_permeability[0][0];
  const double  delta_m = soil->saturated_moisture - sp->residual_moisture;
  const cs_real_t  *head = hc->head_in_law;

  /* Retrieve field values associated to properties to update */

  cs_real_t  *permeability = hc->permeability_field->val;
  cs_real_t  *moisture = hc->moisture_field->val;
  cs_real_t  *capacity = hc->capacity_field->val;

  assert(capacity != NULL && permeability != NULL && moisture != NULL);

  /* Main loop on cells belonging to this soil */

# pragma omp parallel for if (zone->n_elts > CS_THR_MIN)                \
  shared(head, zone, sp, permeability, moisture, capacity)              \
  firstprivate(iso_satval, delta_m)
  for (cs_lnum_t i = 0; i < zone->n_elts; i++) {

    const cs_lnum_t  c_id = zone->elt_ids[i];
    const cs_real_t  h = head[c_id];

    if (h < 0) { /* S_e(h) = [1 + |alpha*h|^n]^(-m) */

      const double  coef = pow(fabs(sp->scale * h), sp->n);
      const double  se = pow(1 + coef, -sp->m);
      const double  se_pow_overm = pow(se, 1/sp->m);
      const double  coef_base = 1 - pow(1 - se_pow_overm, sp->m);

      /* Set the permeability value */

      permeability[c_id] =
        iso_satval * pow(se, sp->tortuosity) * coef_base*coef_base;

      /* Set the moisture content */

      moisture[c_id] = se*delta_m + sp->residual_moisture;

      /* Set the soil capacity */

      const double  ccoef = -sp->n * sp->m * delta_m;
      const double  se_m1 = se/(1. + coef);

      capacity[c_id] = ccoef * coef/h * se_m1;

    }
    else {

      /* Set the permeability value to the saturated values */

      permeability[c_id] = iso_satval;

      /* Set the moisture content (Se = 1 in this case)*/

      moisture[c_id] = delta_m + sp->residual_moisture;

      /* Set the soil capacity */

      capacity[c_id] = 0.;

    }

  } /* Loop on selected cells */

}

/*! (DOXYGEN_SHOULD_SKIP_THIS) \endcond */

/*============================================================================
 * Public function prototypes
 *============================================================================*/

/*----------------------------------------------------------------------------*/
/*!
 * \brief  Get the number of allocated soils
 *
 * \return the number of allocated soils
 */
/*----------------------------------------------------------------------------*/

int
cs_gwf_get_n_soils(void)
{
  return _n_soils;
}

/*----------------------------------------------------------------------------*/
/*!
 * \brief  Retrieve a soil structure from its id
 *
 * \param[in]  id      id to look for
 *
 * \return a pointer to a cs_gwf_soil_t structure
 */
/*----------------------------------------------------------------------------*/

cs_gwf_soil_t *
cs_gwf_soil_by_id(int   id)
{
  if (id > -1 && id < _n_soils)
    return _soils[id];
  else
    return NULL;
}

/*----------------------------------------------------------------------------*/
/*!
 * \brief  Retrieve a soil structure from its name
 *
 * \param[in]  name      name to look for
 *
 * \return a pointer to a cs_gwf_soil_t structure
 */
/*----------------------------------------------------------------------------*/

cs_gwf_soil_t *
cs_gwf_soil_by_name(const char    *name)
{
  if (name == NULL)
    return NULL;

  for (int i = 0; i < _n_soils; i++) {

    cs_gwf_soil_t  *s = _soils[i];
    const cs_zone_t  *zone = cs_volume_zone_by_id(s->zone_id);

    if (strcmp(zone->name, name) == 0)
      return s;
  }

  /* Not found among the list */
  return NULL;
}

/*----------------------------------------------------------------------------*/
/*!
 * \brief  Get the saturated moisture for the given soil id
 *
 * \param[in]  soil_id     id of the requested soil
 *
 * \return the value of the saturated moisture
 */
/*----------------------------------------------------------------------------*/

cs_real_t
cs_gwf_soil_get_saturated_moisture(int   soil_id)
{
  cs_gwf_soil_t  *soil = cs_gwf_soil_by_id(soil_id);

  if (soil == NULL)
    bft_error(__FILE__, __LINE__, 0, "%s: Empty soil.\n", __func__);

  return soil->saturated_moisture;
}

/*----------------------------------------------------------------------------*/
/*!
 * \brief  Check if all soils have been set as CS_GWF_SOIL_SATURATED
 *
 * \return true or false
 */
/*----------------------------------------------------------------------------*/

bool
cs_gwf_soil_all_are_saturated(void)
{
  for (int soil_id = 0; soil_id < _n_soils; soil_id++) {

    const cs_gwf_soil_t  *soil = _soils[soil_id];
    if (soil->model != CS_GWF_SOIL_SATURATED)
      return false;

  }

  return true;
}

/*----------------------------------------------------------------------------*/
/*!
 * \brief  Check that at least one soil has been defined and the model of soil
 *         exists.
 *         Raise an error if a problem is encoutered.
 */
/*----------------------------------------------------------------------------*/

void
cs_gwf_soil_check(void)
{
  if (_n_soils < 1)
    bft_error(__FILE__, __LINE__, 0,
              "%s: Groundwater module is activated but no soil is defined.",
              __func__);
  if (_soils == NULL)
    bft_error(__FILE__, __LINE__, 0,
              "%s: The soil structure is not allocated whereas %d soils"
              " have been added.\n", __func__, _n_soils);

  for (int i = 0; i < _n_soils; i++) {

    if (_soils[i]->model == CS_GWF_SOIL_N_HYDRAULIC_MODELS) {
      const cs_zone_t  *z = cs_volume_zone_by_id(_soils[i]->zone_id);
      bft_error(__FILE__, __LINE__, 0,
                "%s: Invalid model of soil attached to zone %s\n",
                __func__, z->name);
    }

  } /* Loop on soils */
}

/*----------------------------------------------------------------------------*/
/*!
 * \brief  Create a new cs_gwf_soil_t structure and add it to the array of
 *         soils. An initialization by default of all members is performed.
 *
 * \param[in] zone                pointer to a volume zone structure
 * \param[in] hydraulic_model     main hydraulic model for the module
 * \param[in] model               type of model for the soil behavior
 * \param[in] perm_type           type of permeability (iso/anisotropic)
 * \param[in] saturated_moisture  moisture content
 * \param[in] bulk_density        value of the mass density
 * \param[in] hydraulic_context   pointer to the context structure
 *
 * \return a pointer to the new allocated structure
 */
/*----------------------------------------------------------------------------*/

cs_gwf_soil_t *
cs_gwf_soil_create(const cs_zone_t                 *zone,
                   cs_gwf_model_type_t              hydraulic_model,
                   cs_gwf_soil_model_t              model,
                   cs_property_type_t               perm_type,
                   double                           saturated_moisture,
                   double                           bulk_density,
                   void                            *hydraulic_context)
{
  cs_gwf_soil_t  *soil = NULL;

  BFT_MALLOC(soil, 1, cs_gwf_soil_t);

  soil->id = _n_soils;

  /* Attached a volume zone to the current soil */

  assert(zone != NULL);
  soil->zone_id = zone->id;

  /* Members related to the hydraulic model */

  soil->hydraulic_model = hydraulic_model;
  soil->hydraulic_context = hydraulic_context;

  /* Members relaated to the soil parameters/model */

  soil->model = model;
  soil->bulk_density = bulk_density;
  soil->saturated_moisture = saturated_moisture;

  soil->update_properties = NULL;
  soil->free_param = NULL;
  soil->param = NULL;

  switch (model) {

  case CS_GWF_SOIL_SATURATED:
    {
      if (hydraulic_model != CS_GWF_MODEL_SATURATED_SINGLE_PHASE)
        bft_error(__FILE__, __LINE__, 0,
                  "%s: Invalid type of soil with the general hydraulic model.\n"
                  " In a saturated single-phase model, all soils have to be"
                  " of type CS_GWF_SOIL_SATURATED.\n", __func__);

      cs_gwf_soil_param_saturated_t  *sp = NULL;

      BFT_MALLOC(sp, 1, cs_gwf_soil_param_saturated_t);

      /* Default initialization */

      for (int ki = 0; ki < 3; ki++)
        for (int kj = 0; kj < 3; kj++)
          sp->saturated_permeability[ki][kj] = 0.0;

      sp->saturated_permeability[0][0] = 1.0;
      sp->saturated_permeability[1][1] = 1.0;
      sp->saturated_permeability[2][2] = 1.0;

      soil->param = sp;
    }
    break;

  case CS_GWF_SOIL_GENUCHTEN:
    {
      cs_gwf_soil_param_genuchten_t  *sp = NULL;

      BFT_MALLOC(sp, 1, cs_gwf_soil_param_genuchten_t);

      sp->residual_moisture = 0.;

      for (int ki = 0; ki < 3; ki++)
        for (int kj = 0; kj < 3; kj++)
          sp->saturated_permeability[ki][kj] = 0.0;

      sp->saturated_permeability[0][0] = 1.0;
      sp->saturated_permeability[1][1] = 1.0;
      sp->saturated_permeability[2][2] = 1.0;

      sp->n = 1.25;
      sp->m = 1 - 1./sp->n;
      sp->scale = 1.;
      sp->tortuosity = 1.;

      soil->param = sp;

      if (perm_type & CS_PROPERTY_ISO)
        if (hydraulic_model == CS_GWF_MODEL_UNSATURATED_SINGLE_PHASE)
          soil->update_properties = _update_soil_genuchten_iso;
        else
          bft_error(__FILE__, __LINE__, 0,
                    "%s: Invalid type of hydraulic model.\n"
                    " Please check your settings.", __func__);
      else
        bft_error(__FILE__, __LINE__, 0,
                  "%s: Invalid type of property for the permeability.\n"
                  " Please check your settings.", __func__);
    }
    break;

  case CS_GWF_SOIL_USER:
    break; /* All has to be done by the user */

  default:
    bft_error(__FILE__, __LINE__, 0,
              "%s: Invalid type of soil model\n", __func__);
    break; /* Nothing to do */

  } /* Switch on the soil model */

  /* Store the new soils in the soil array */

  _n_soils++;
  BFT_REALLOC(_soils, _n_soils, cs_gwf_soil_t *);
  _soils[soil->id] = soil;

  return soil;
}

/*----------------------------------------------------------------------------*/
/*!
 * \brief  Build an array storing the associated soil for each cell
 *
 * \param[in] n_cells      number of cells
 */
/*----------------------------------------------------------------------------*/

void
cs_gwf_build_cell2soil(cs_lnum_t    n_cells)
{
  BFT_MALLOC(_cell2soil_ids, n_cells, short int);

  if (_n_soils == 1)
    memset(_cell2soil_ids, 0, sizeof(short int)*n_cells);

  else {

    assert(_n_soils > 1);
#   pragma omp parallel for if (n_cells > CS_THR_MIN)
    for (cs_lnum_t j = 0; j < n_cells; j++)
      _cell2soil_ids[j] = -1; /* unset by default */

    for (int soil_id = 0; soil_id < _n_soils; soil_id++) {

      const cs_gwf_soil_t  *soil = _soils[soil_id];
      const cs_zone_t  *z = cs_volume_zone_by_id(soil->zone_id);

      assert(z != NULL);

#     pragma omp parallel for if (z->n_elts > CS_THR_MIN)
      for (cs_lnum_t j = 0; j < z->n_elts; j++)
        _cell2soil_ids[z->elt_ids[j]] = soil_id;

    } /* Loop on soils */

    /* Chcek if every cells is associated to a soil */

    for (cs_lnum_t j = 0; j < n_cells; j++)
      if (_cell2soil_ids[j] == -1)
        bft_error(__FILE__, __LINE__, 0,
                  " %s: At least cell %ld has no related soil.\n",
                  __func__, (long)j);

  } /* n_soils > 1 */

}

/*----------------------------------------------------------------------------*/
/*!
 * \brief Get the array storing the associated soil for each cell
 */
/*----------------------------------------------------------------------------*/

const short int *
cs_gwf_get_cell2soil(void)
{
  return _cell2soil_ids;
}

/*----------------------------------------------------------------------------*/
/*!
 * \brief  Free all cs_gwf_soil_t structures
 */
/*----------------------------------------------------------------------------*/

void
cs_gwf_soil_free_all(void)
{
  if (_n_soils < 1)
    return;
  assert(_soils != NULL);

  for (int i = 0; i < _n_soils; i++) {

    cs_gwf_soil_t  *soil = _soils[i];

    if (soil->free_param != NULL)
      soil->free_param(&(soil->param));

    if (soil->param != NULL) {

      switch (soil->model) {

      case CS_GWF_SOIL_SATURATED:
        {
          cs_gwf_soil_param_saturated_t  *sp = soil->param;

          BFT_FREE(sp);
          sp = NULL;
        }
        break;

      case CS_GWF_SOIL_GENUCHTEN:
        {
          cs_gwf_soil_param_genuchten_t  *sp = soil->param;

          BFT_FREE(sp);
          sp = NULL;
        }
        break;

      default:
        cs_base_warn(__FILE__, __LINE__);
        bft_printf("%s: The context structure of a soil may not be freed.\n",
                   __func__);
        break;

      } /* Switch on predefined soil context */

    }

    /* The hydraulic context is shared and thus is freed during the free of the
       cs_gwf_t structure */

    BFT_FREE(soil);

  } /* Loop on soils */

  BFT_FREE(_soils);
  BFT_FREE(_cell2soil_ids);
}

/*----------------------------------------------------------------------------*/
/*!
 * \brief  Summary of the settings related to all cs_gwf_soil_t structures
 */
/*----------------------------------------------------------------------------*/

void
cs_gwf_soil_log_setup(void)
{
  cs_log_printf(CS_LOG_SETUP, "  * GWF | Number of soils: %d\n", _n_soils);

  char  meta[64];
  for (int i = 0; i < _n_soils; i++) {

    const cs_gwf_soil_t  *soil = _soils[i];
    const cs_zone_t  *z = cs_volume_zone_by_id(soil->zone_id);

    cs_log_printf(CS_LOG_SETUP, "\n        Soil.%d | Zone: %s",
                  soil->id, z->name);
    cs_log_printf(CS_LOG_SETUP, "\n        Soil.%d | Bulk.density: %6.3e",
                  soil->id, soil->bulk_density);
    cs_log_printf(CS_LOG_SETUP, "\n        Soil.%d | Max.porosity: %6.3e"
                  " (=saturated_moisture)\n",
                  soil->id, soil->saturated_moisture);

    sprintf(meta, "        Soil.%d |", soil->id);

    switch (soil->model) {

    case CS_GWF_SOIL_GENUCHTEN:
      {
        const cs_gwf_soil_param_genuchten_t  *sp = soil->param;

        cs_log_printf(CS_LOG_SETUP, "%s Model: VanGenuchten-Mualen\n", meta);
        cs_log_printf(CS_LOG_SETUP, "%s Parameters:", meta);
        cs_log_printf(CS_LOG_SETUP,
                      " residual_moisture %5.3e\n", sp->residual_moisture);
        cs_log_printf(CS_LOG_SETUP, "%s Parameters:", meta);
        cs_log_printf(CS_LOG_SETUP, " n= %f, scale= %f, tortuosity= %f\n",
                      sp->n, sp->scale, sp->tortuosity);
        cs_log_printf(CS_LOG_SETUP, "%s Saturated permeability\n", meta);
        cs_log_printf(CS_LOG_SETUP, "%s [%-4.2e %4.2e %4.2e;\n", meta,
                      sp->saturated_permeability[0][0],
                      sp->saturated_permeability[0][1],
                      sp->saturated_permeability[0][2]);
        cs_log_printf(CS_LOG_SETUP, "%s  %-4.2e %4.2e %4.2e;\n", meta,
                      sp->saturated_permeability[1][0],
                      sp->saturated_permeability[1][1],
                      sp->saturated_permeability[1][2]);
        cs_log_printf(CS_LOG_SETUP, "%s  %-4.2e %4.2e %4.2e]\n", meta,
                      sp->saturated_permeability[2][0],
                      sp->saturated_permeability[2][1],
                      sp->saturated_permeability[2][2]);
      }
      break;

    case CS_GWF_SOIL_SATURATED:
      {
        const cs_gwf_soil_param_saturated_t  *sp = soil->param;

        cs_log_printf(CS_LOG_SETUP, "%s Model: Saturated\n", meta);
        cs_log_printf(CS_LOG_SETUP, "%s Parameters", meta);
        cs_log_printf(CS_LOG_SETUP, "%s Saturated permeability\n", meta);
        cs_log_printf(CS_LOG_SETUP, "%s [%-4.2e %4.2e %4.2e;\n", meta,
                      sp->saturated_permeability[0][0],
                      sp->saturated_permeability[0][1],
                      sp->saturated_permeability[0][2]);
        cs_log_printf(CS_LOG_SETUP, "%s  %-4.2e %4.2e %4.2e;\n", meta,
                      sp->saturated_permeability[1][0],
                      sp->saturated_permeability[1][1],
                      sp->saturated_permeability[1][2]);
        cs_log_printf(CS_LOG_SETUP, "%s  %-4.2e %4.2e %4.2e]\n", meta,
                      sp->saturated_permeability[2][0],
                      sp->saturated_permeability[2][1],
                      sp->saturated_permeability[2][2]);
      }
      break;

    case CS_GWF_SOIL_USER:
      cs_log_printf(CS_LOG_SETUP, "%s Model: User-defined\n", meta);
      break;

    default:
      bft_error(__FILE__, __LINE__, 0,
                " Invalid model for groundwater module.\n"
                " Please check your settings.");

    } /* Switch model */

  } /* Loop on soils */

  cs_log_printf(CS_LOG_SETUP, "\n");
}

/*----------------------------------------------------------------------------*/
/*!
 * \brief  Set a soil defined by a saturated hydraulic model and attached to
 *         an isotropic permeability (single-phase flow)
 *
 * \param[in, out] soil       pointer to a cs_gwf_soil_t structure
 * \param[in]      k_s        value of the saturated permeability
 */
/*----------------------------------------------------------------------------*/

void
cs_gwf_soil_set_iso_saturated(cs_gwf_soil_t              *soil,
                              double                      k_s)
{
  if (soil == NULL) bft_error(__FILE__, __LINE__, 0, _(_err_empty_soil));

  cs_gwf_soil_param_saturated_t  *sp = soil->param;

  if (soil->model != CS_GWF_SOIL_SATURATED)
    bft_error(__FILE__, __LINE__, 0,
              "%s: soil model is not saturated\n", __func__);
  if (sp == NULL)
    bft_error(__FILE__, __LINE__, 0,
              "%s: soil context not allocated\n", __func__);

  /* Default initialization is the identity matrix */

  for (int i = 0; i < 3; i++)
    sp->saturated_permeability[i][i] = k_s;
}

/*----------------------------------------------------------------------------*/
/*!
 * \brief  Set a soil defined by a saturated hydraulic model and attached to
 *         an anisotropic permeability (single-phase flow)
 *
 * \param[in, out] soil       pointer to a cs_gwf_soil_t structure
 * \param[in]      k_s        value of the anisotropic saturated permeability
 */
/*----------------------------------------------------------------------------*/

void
cs_gwf_soil_set_aniso_saturated(cs_gwf_soil_t              *soil,
                                double                      k_s[3][3])
{
  if (soil == NULL) bft_error(__FILE__, __LINE__, 0, _(_err_empty_soil));

  cs_gwf_soil_param_saturated_t  *sp = soil->param;

  if (soil->model != CS_GWF_SOIL_SATURATED)
    bft_error(__FILE__, __LINE__, 0,
              "%s : soil model is not saturated\n", __func__);
  if (sp == NULL)
    bft_error(__FILE__, __LINE__, 0,
              "%s: soil context not allocated\n", __func__);

  for (int i = 0; i < 3; i++)
    for (int j = 0; j < 3; j++)
      sp->saturated_permeability[i][j] =  k_s[i][j];
}

/*----------------------------------------------------------------------------*/
/*!
 * \brief  Set a soil defined by a Van Genuchten-Mualen hydraulic model and
 *         attached to an isotropic saturated permeability (single-phase flow)
 *
 *         The (effective) liquid saturation (also called moisture content)
 *         follows the identity
 *         S_l,eff = (S_l - theta_r)/(theta_s - theta_r)
 *                 = (1 + |alpha . h|^n)^(-m)
 *
 *         The isotropic relative permeability is defined as:
 *         k_r = S_l,eff^L * (1 - (1 - S_l,eff^(1/m))^m))^2
 *         where m = 1 -  1/n
 *
 * \param[in, out] soil       pointer to a cs_gwf_soil_t structure
 * \param[in]      k_s        value of the isotropic saturated permeability
 * \param[in]      theta_r    residual moisture
 * \param[in]      alpha      scale parameter (in m^-1)
 * \param[in]      n          shape parameter
 * \param[in]      L          turtuosity parameter
 */
/*----------------------------------------------------------------------------*/

void
cs_gwf_soil_set_iso_genuchten(cs_gwf_soil_t              *soil,
                              double                      k_s,
                              double                      theta_r,
                              double                      alpha,
                              double                      n,
                              double                      L)
{
  if (soil == NULL) bft_error(__FILE__, __LINE__, 0, _(_err_empty_soil));

  cs_gwf_soil_param_genuchten_t  *sp = soil->param;

  if (soil->model != CS_GWF_SOIL_GENUCHTEN)
    bft_error(__FILE__, __LINE__, 0,
              "%s: soil model is not Van Genuchten\n", __func__);
  if (sp == NULL)
    bft_error(__FILE__, __LINE__, 0,
              "%s: soil context not allocated\n", __func__);
  if (n <= FLT_MIN)
    bft_error(__FILE__, __LINE__, 0,
              "%s: Invalid value for n = %6.4e (the shape parameter).\n"
              "This value should be > 0.\n", __func__, n);

  sp->residual_moisture = theta_r;

  /* Default initialization is the identity matrix */

  for (int i = 0; i < 3; i++)
    sp->saturated_permeability[i][i] = k_s;

  /* Additional advanced settings */

  sp->n = n;
  sp->m = 1 - 1/sp->n;
  sp->scale = alpha;
  sp->tortuosity = L;
}

/*----------------------------------------------------------------------------*/
/*!
 * \brief Set a soil defined by a Van Genuchten-Mualen hydraulic model and
 *        attached to an anisotropic saturated permeability (single-phase flow)
 *
 *        The (effective) liquid saturation (also called moisture content)
 *        follows the identity
 *        S_l,eff = (S_l - theta_r)/(theta_s - theta_r)
 *                = (1 + |alpha . h|^n)^(-m)
 *
 *        The isotropic relative permeability is defined as:
 *        k_r = S_l,eff^L * (1 - (1 - S_l,eff^(1/m))^m))^2
 *        where m = 1 -  1/n
 *
 * \param[in, out] soil       pointer to a cs_gwf_soil_t structure
 * \param[in]      k_s        value of the isotropic saturated permeability
 * \param[in]      theta_r    residual moisture/liquid saturation
 * \param[in]      alpha      scale parameter (in m^-1)
 * \param[in]      n          shape parameter
 * \param[in]      L          turtuosity parameter
 */
/*----------------------------------------------------------------------------*/

void
cs_gwf_soil_set_aniso_genuchten(cs_gwf_soil_t              *soil,
                                double                      k_s[3][3],
                                double                      theta_r,
                                double                      alpha,
                                double                      n,
                                double                      L)
{
  if (soil == NULL) bft_error(__FILE__, __LINE__, 0, _(_err_empty_soil));

  cs_gwf_soil_param_genuchten_t  *sp = soil->param;

  if (soil->model != CS_GWF_SOIL_GENUCHTEN)
    bft_error(__FILE__, __LINE__, 0,
              "%s: soil model is not Van Genuchten\n", __func__);
  if (sp == NULL)
    bft_error(__FILE__, __LINE__, 0,
              "%s: soil context not allocated\n", __func__);
  if (n <= FLT_MIN)
    bft_error(__FILE__, __LINE__, 0,
              "%s: Invalid value for n = %6.4e (the shape parameter).\n"
              "This value should be > 0.\n", __func__, n);

  sp->residual_moisture = theta_r;

  for (int i = 0; i < 3; i++)
    for (int j = 0; j < 3; j++)
      sp->saturated_permeability[i][j] = k_s[i][j];

  /* Additional advanced settings */

  sp->n = n;
  sp->m = 1 - 1/sp->n;
  sp->scale = alpha;
  sp->tortuosity = L;
}

/*----------------------------------------------------------------------------*/
/*!
 * \brief  Set a soil defined by a user-defined model
 *
 * \param[in, out] soil              pointer to a cs_gwf_soil_t structure
 * \param[in]      param             pointer to a structure cast on-the-fly
 * \param[in]      update_func       function pointer to update propoerties
 * \param[in]      free_param_func   function pointer to free the param struct.
 */
/*----------------------------------------------------------------------------*/

void
cs_gwf_soil_set_user(cs_gwf_soil_t                *soil,
                     void                         *param,
                     cs_gwf_soil_update_t         *update_func,
                     cs_gwf_soil_free_param_t     *free_param_func)
{
  if (soil == NULL) bft_error(__FILE__, __LINE__, 0, _(_err_empty_soil));

  if (soil->model != CS_GWF_SOIL_USER)
    bft_error(__FILE__, __LINE__, 0,
              " %s: soil model is not user-defined.\n", __func__);

  /* Set pointers */

  soil->param = param;
  soil->update_properties = update_func;
  soil->free_param = free_param_func;
}

/*----------------------------------------------------------------------------*/
/*!
 * \brief  Set the parameter values when all soils are considered as saturated.
 *         Use predefined properties of the groundwater flow module.
 *
 * \param[in, out]  permeability      pointer to a cs_property_t structure
 * \param[in, out]  moisture_content  pointer to a cs_property_t structure
 */
/*----------------------------------------------------------------------------*/

void
cs_gwf_soil_saturated_set_param(cs_property_t      *permeability,
                                cs_property_t      *moisture_content)
{
  assert(permeability != NULL && moisture_content != NULL);

  for (int i = 0; i < _n_soils; i++) {

    cs_gwf_soil_t  *soil = _soils[i];

    if (soil->model != CS_GWF_SOIL_SATURATED)
      bft_error(__FILE__, __LINE__, 0,
                " %s: Invalid way of setting soil parameter.\n"
                " All soils are not considered as saturated.", __func__);

    const cs_zone_t  *z = cs_volume_zone_by_id(soil->zone_id);

    cs_gwf_soil_param_saturated_t  *sp = soil->param;

    /* Set the permeability */

    if (permeability->type & CS_PROPERTY_ISO)
      cs_property_def_iso_by_value(permeability,
                                   z->name,
                                   sp->saturated_permeability[0][0]);

    else if (permeability->type & CS_PROPERTY_ORTHO) {

      cs_real_3_t  val = {sp->saturated_permeability[0][0],
                          sp->saturated_permeability[1][1],
                          sp->saturated_permeability[2][2]};

      cs_property_def_ortho_by_value(permeability, z->name, val);

    }
    else if (permeability->type & CS_PROPERTY_ANISO) {

      cs_property_def_aniso_by_value(permeability,
                                     z->name,
                      (double (*)[3])sp->saturated_permeability);

    }
    else
      bft_error(__FILE__, __LINE__, 0,
                " %s: Invalid type of property.\n", __func__);

    /* Set the moisture content */

    cs_property_def_iso_by_value(moisture_content,
                                 z->name,
                                 soil->saturated_moisture);

  } /* Loop on soils */
}

/*----------------------------------------------------------------------------*/
/*!
 * \brief  Update the soil properties
 *
 * \param[in]  time_eval         time at which one evaluates properties
 * \param[in]  mesh              pointer to the mesh structure
 * \param[in]  connect           pointer to the cdo connectivity
 * \param[in]  quant             pointer to the cdo quantities
 */
/*----------------------------------------------------------------------------*/

void
cs_gwf_soil_update(cs_real_t                     time_eval,
                   const cs_mesh_t              *mesh,
                   const cs_cdo_connect_t       *connect,
                   const cs_cdo_quantities_t    *quant)
{
  for (int i = 0; i < _n_soils; i++) {

    cs_gwf_soil_t  *soil = _soils[i];
    assert(soil != NULL);

    switch (soil->model) {

    case CS_GWF_SOIL_GENUCHTEN:
    case CS_GWF_SOIL_USER:
      {
        assert(soil->update_properties != NULL);

        const cs_zone_t  *zone = cs_volume_zone_by_id(soil->zone_id);

        soil->update_properties(time_eval,
                                mesh, connect, quant,
                                zone,
                                soil);
      }
      break;

    default:
      break; /* Do nothing (for instance in the case of a saturated soil which
                is constant (steady and uniform) */

    } /* Switch on the soil model */

  } /* Loop on soils */

}

/*----------------------------------------------------------------------------*/
/*!
 * \brief  Update arrays associated to the definition of terms involved in the
 *         miscible two-phase flow model
 *
 * \param[in]      mesh          pointer to the mesh structure
 * \param[in]      connect       pointer to the cdo connectivity
 * \param[in]      quant         pointer to the cdo quantities
 * \param[in, out] mc            pointer to the model context to update
 */
/*----------------------------------------------------------------------------*/

void
cs_gwf_soil_update_mtpf_terms(const cs_mesh_t              *mesh,
                              const cs_cdo_connect_t       *connect,
                              const cs_cdo_quantities_t    *quant,
                              cs_gwf_miscible_two_phase_t  *mc)
{
  if (mc == NULL)
    return;


  for (int i = 0; i < _n_soils; i++) {

    cs_gwf_soil_t  *soil = _soils[i];
    assert(soil != NULL);

  } /* Loop on soils */

}
/*----------------------------------------------------------------------------*/

END_C_DECLS
