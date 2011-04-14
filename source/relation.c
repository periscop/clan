
   /*+------- <| --------------------------------------------------------**
    **         A                     Clan                                **
    **---     /.\   -----------------------------------------------------**
    **   <|  [""M#                 relation.c                              **
    **-   A   | #   -----------------------------------------------------**
    **   /.\ [""M#         First version: 30/04/2008                     **
    **- [""M# | #  U"U#U  -----------------------------------------------**
         | #  | #  \ .:/
         | #  | #___| #
 ******  | "--'     .-"  ******************************************************
 *     |"-"-"-"-"-#-#-##   Clan : the Chunky Loop Analyzer (experimental)     *
 ****  |     # ## ######  *****************************************************
 *      \       .::::'/                                                       *
 *       \      ::::'/     Copyright (C) 2008 University Paris-Sud 11         *
 *     :8a|    # # ##                                                         *
 *     ::88a      ###      This is free software; you can redistribute it     *
 *    ::::888a  8a ##::.   and/or modify it under the terms of the GNU Lesser *
 *  ::::::::888a88a[]:::   General Public License as published by the Free    *
 *::8:::::::::SUNDOGa8a::. Software Foundation, either version 2.1 of the     *
 *::::::::8::::888:Y8888:: License, or (at your option) any later version.    *
 *::::':::88::::888::Y88a::::::::::::...                                      *
 *::'::..    .   .....   ..   ...  .                                          *
 * This software is distributed in the hope that it will be useful, but       *
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY *
 * or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License   *
 * for more details.							      *
 *                                                                            *
 * You should have received a copy of the GNU Lesser General Public License   *
 * along with software; if not, write to the Free Software Foundation, Inc.,  *
 * 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA                     *
 *                                                                            *
 * Clan, the Chunky Loop Analyzer                                             *
 * Written by Cedric Bastoul, Cedric.Bastoul@u-psud.fr                        *
 *                                                                            *
 ******************************************************************************/


#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>

#include <osl/int.h>
#include <osl/relation.h>
#include <clan/macros.h>
#include <clan/relation.h>


/*+****************************************************************************
 *                            Processing functions                            *
 ******************************************************************************/


/**
 * clan_relation_tag_array function:
 * this function tags a relation to explicit it is describing the array index of
 * a given array. This means using OpenScop representation that the very first
 * output dimension will correspond to the constraint dim = array_id. It updates
 * directly the relation provided as parameter. A new row and a new column are
 * inserted to the existing relation and the number of output dimensions is
 * incremented.
 * \param[in,out] relation The relation to tag.
 * \param[in]     array    The array number.
 */
void
clan_relation_tag_array(osl_relation_p relation, int array)
{
  if (relation == NULL)
  {
    fprintf(stderr,"[Clan] Error: relation cannot be array-tagged\n");
    exit(1);
  }

  osl_relation_insert_blank_row(relation, 0);
  osl_relation_insert_blank_column(relation, 1);
  osl_int_set_si(CLAN_PRECISION, relation->m[0], 1, -1);
  osl_int_set_si(CLAN_PRECISION, relation->m[0], relation->nb_columns-1,array);
  relation->nb_output_dims++;
}


/**
 * clan_relation_scattering function:
 * this function builds the scattering relation for the clan_statement_t
 * structures thanks to the parser current state of parser_scattering (rank)
 * and parser_depth (depth). The "rank" vector gives the "position" of the
 * statement for every loop depth (see Feautrier's demonstration of existence
 * of a schedule for any SCoP or CLooG's manual for original scattering
 * function to understand if necessary). This function just "expands" this
 * vector to a (2*n+1)-dimensional schedule for a statement at depth n and
 * returns it.
 * \param rank  The position of the statement at every loop depth.
 * \param depth The depth of the statement.
 */
osl_relation_p
clan_relation_scattering(int * rank, int depth)
{
  int i, j, nb_rows, nb_columns;
  osl_relation_p scattering;

  nb_rows    = (2 * depth + 1);
  nb_columns = (2 * depth + 1) + (depth) + (CLAN_MAX_PARAMETERS) + 2;
  scattering = osl_relation_pmalloc(CLAN_PRECISION, nb_rows, nb_columns);
  osl_relation_set_type(scattering, OSL_TYPE_SCATTERING);
  osl_relation_set_attributes(scattering, 2 * depth + 1, depth, 0,
                              CLAN_MAX_PARAMETERS);  
  
  // The output dimension identity
  for (i = 0; i < 2 * depth + 1; i++)
    osl_int_set_si(CLAN_PRECISION, scattering->m[i], i+1, -1);

  // The beta and alpha.
  j = 0;
  for (i = 0; i < depth; i++)
  {
    osl_int_set_si(CLAN_PRECISION, scattering->m[j], nb_columns-1, rank[i]);
    osl_int_set_si(CLAN_PRECISION, scattering->m[j+1], (2*depth+1)+i+1, 1);
    j += 2;
  }
  osl_int_set_si(CLAN_PRECISION,
                 scattering->m[nb_rows-1], nb_columns-1, rank[depth]);

  return scattering;
}


/**
 * clan_relation_outputize function:
 * this function adds an output dimension to each row of an input
 * relation (they are all supposed to correspond to an output relation
 * expression). It amounts at adding a negative identity after the first
 * column of the constraint matrix and at updating the number of output
 * dimensions.
 * \param[in,out] relation The relation where to add output dimensions.
 */
void clan_relation_outputize(osl_relation_p relation) {
  int i;
  osl_relation_p neg_identity = osl_relation_pmalloc(CLAN_PRECISION,
    relation->nb_rows, relation->nb_rows);
  
  for (i = 0; i < relation->nb_rows; i++)
    osl_int_set_si(CLAN_PRECISION, neg_identity->m[i], i, -1);

  osl_relation_insert_columns(relation, neg_identity, 1);
  osl_relation_free(neg_identity);
  relation->nb_output_dims = relation->nb_rows;
}


/**
 * clan_relation_compact function:
 * This function compacts a relation such that it uses the right number
 * of columns (during construction we used CLAN_MAX_DEPTH and
 * CLAN_MAX_PARAMETERS to define relation and vector sizes). It modifies
 * directly the relation provided as parameter.
 * \param relation      The relation to compact.
 * \param nb_iterators  The true number of iterators for this relation.
 * \param nb_parameters The true number of parameters in the SCoP.
 */
void
clan_relation_compact(osl_relation_p relation, int nb_iterators, 
		      int nb_parameters)
{
  int i, j, nb_columns, nb_output_dims, nb_input_dims;
  osl_relation_p compacted;

  if (relation == NULL)
    return;

  nb_output_dims = relation->nb_output_dims;
  nb_input_dims  = relation->nb_input_dims;

  nb_columns = nb_output_dims + nb_input_dims + nb_parameters + 2;
  compacted = osl_relation_pmalloc(CLAN_PRECISION,
                                   relation->nb_rows, nb_columns);

  for (i = 0; i < relation->nb_rows; i++)
  {
    /* We copy the equality/inequality tag, the output and the input
     * coefficients
     */
    for (j = 0; j <= nb_output_dims + nb_input_dims; j++)
      osl_int_assign(CLAN_PRECISION, compacted->m[i], j, relation->m[i], j);

    /* Then we copy the parameter coefficients */
    for (j = 0; j < nb_parameters; j++)
      osl_int_assign(CLAN_PRECISION,
                     compacted->m[i], j + nb_output_dims + nb_input_dims + 1,
		     relation->m[i], relation->nb_columns - CLAN_MAX_PARAMETERS -1 +j);

    /* Lastly the scalar coefficient */
    osl_int_assign(CLAN_PRECISION,
                   compacted->m[i], nb_columns - 1,
		   relation->m[i], relation->nb_columns - 1);
  }

  osl_relation_free_inside(relation);

  /* Replace the inside of relation */
  relation->nb_rows       = compacted->nb_rows;
  relation->nb_columns    = compacted->nb_columns;
  relation->m             = compacted->m;
  relation->nb_parameters = nb_parameters;

  /* Free the compacted "container" */
  free(compacted);
}
