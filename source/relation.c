
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

int clan_parser_nb_ld(void);
void clan_parser_add_ld(void);


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
void clan_relation_tag_array(osl_relation_p relation, int array) {
  if (relation == NULL)
    CLAN_error("relation cannot be array-tagged");

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
 * and parser_depth (depth). The input scattering vector has 2depth+1
 * elements. Each even element gives the "position" of the statement for
 * every loop depth (see Feautrier's demonstration of existence of a schedule
 * for any SCoP or CLooG's manual for original scattering function to
 * understand if necessary). Each  This function just "expands" this
 * vector to a (2*n+1)-dimensional schedule for a statement at depth n and
 * returns it. Each odd element gives the loop direction: 1 for forward
 * (meaning the loop stride is positive) -1 for backward (the loop stride
 * is negative).
 * \param vector The statement position / loop direction vector.
 * \param depth  The depth of the statement.
 */
osl_relation_p clan_relation_scattering(int * vector, int depth) {
  int i, j, nb_rows, nb_columns;
  int beta_col, alpha_col;
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
  beta_col = nb_columns - 1;
  for (i = 0; i < depth; i++) {
    alpha_col = (2 * depth + 1) + i + 1;
    osl_int_set_si(CLAN_PRECISION, scattering->m[j], beta_col, vector[j]);
    osl_int_set_si(CLAN_PRECISION, scattering->m[j+1], alpha_col, vector[j+1]);
    j += 2;
  }
  osl_int_set_si(CLAN_PRECISION, scattering->m[nb_rows-1], beta_col,vector[j]);

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
 * clan_relation_new_output_vector function:
 * this function adds a new output dimension to a relation and a new
 * constraint corresponding to the new output dimension to an existing
 * relation. The new output dimension is added after the existing output
 * dimensions. It is supposed to be equal to the vector expression passed
 * as an argument. The input relation is direcly updated.
 * \param[in,out] relation The relation to add a new output dimension.
 * \param[in]     vector   The expression the new output dimension is equal to.
 */
void clan_relation_new_output_vector(osl_relation_p relation,
                                     osl_vector_p vector) {
  int i, new_col, new_row;

  if (relation == NULL)
    CLAN_error("cannot add a new output dimension to a NULL relation");
  else if (vector == NULL)
    CLAN_error("cannot add a NULL expression of an output dimension");
  else if (relation->precision != vector->precision)
    CLAN_error("incompatible precisions");

  if (relation->nb_output_dims == OSL_UNDEFINED)
    new_col = 1;
  else
    new_col = relation->nb_output_dims + 1;
  new_row = relation->nb_rows;

  if ((relation->nb_columns - (new_col - 1)) != vector->size)
    CLAN_error("incompatible sizes");
  else if (!osl_int_zero(vector->precision, vector->v, 0))
    CLAN_error("the output dimension expression should be an equality");

  // Prepare the space for the new output dimension and the vector.
  osl_relation_insert_blank_column(relation, new_col);
  osl_relation_insert_blank_row(relation, new_row);
  relation->nb_output_dims = new_col;

  // Insert the new output dimension.
  osl_int_set_si(relation->precision, relation->m[new_row], new_col, -1);
  for (i = 1; i < vector->size; i++)
    osl_int_assign(relation->precision,
                   relation->m[new_row], new_col + i, vector->v, i);
}


/**
 * clan_relation_new_output_scalar function:
 * this function adds a new output dimension to a relation and a new
 * constraint corresponding to the new output dimension to an existing
 * relation. The new output dimension is added after the existing output
 * dimensions. It is supposed to be equal to a scalar value passed
 * as an argument. The input relation is direcly updated.
 * \param[in,out] relation The relation to add a new output dimension.
 * \param[in]     scalar   The scalar the new output dimension is equal to.
 */
void clan_relation_new_output_scalar(osl_relation_p relation, int scalar) {
  int new_col, new_row;
  
  if (relation == NULL)
    CLAN_error("cannot add a new output dimension to a NULL relation");

  if (relation->nb_output_dims == OSL_UNDEFINED)
    new_col = 1;
  else
    new_col = relation->nb_output_dims + 1;
  new_row = relation->nb_rows;

  // Prepare the space for the new output dimension and the vector.
  osl_relation_insert_blank_column(relation, new_col);
  osl_relation_insert_blank_row(relation, new_row);
  relation->nb_output_dims = new_col;

  // Insert the new output dimension.
  osl_int_set_si(relation->precision, relation->m[new_row], new_col, -1);
  osl_int_set_si(relation->precision, relation->m[new_row],
                 relation->nb_columns - 1, scalar);
}


/**
 * clan_relation_compact function:
 * This function compacts a relation such that it uses the right number
 * of columns (during construction we used CLAN_MAX_DEPTH, CLAN_MAX_LOCAL_DIMS
 * and CLAN_MAX_PARAMETERS to define relation and vector sizes). It modifies
 * directly the relation provided as parameter.
 * \param relation      The relation to compact.
 * \param nb_parameters The true number of parameters in the SCoP.
 */
void clan_relation_compact(osl_relation_p relation, 
                           int nb_parameters) {
  int i, j, nb_columns;
  int nb_output_dims, nb_input_dims, nb_local_dims, nb_out_in_loc;
  osl_relation_p compacted;

  while (relation != NULL) {
    nb_output_dims = relation->nb_output_dims;
    nb_input_dims  = relation->nb_input_dims;
    nb_local_dims  = relation->nb_local_dims;
    nb_out_in_loc  = nb_output_dims + nb_input_dims + nb_local_dims;

    nb_columns = nb_out_in_loc  + nb_parameters + 2;
    compacted = osl_relation_pmalloc(CLAN_PRECISION,
                                     relation->nb_rows, nb_columns);

    for (i = 0; i < relation->nb_rows; i++) {
      // We copy the equ/inequ tag, the output and input coefficients.
      for (j = 0; j <= nb_output_dims + nb_input_dims; j++)
        osl_int_assign(CLAN_PRECISION, compacted->m[i], j, relation->m[i], j);

      // Then we copy the local dimension coefficients.
      for (j = 0; j < nb_local_dims; j++)
        osl_int_assign(CLAN_PRECISION,
            compacted->m[i], nb_output_dims + nb_input_dims + 1 + j,
            relation->m[i], CLAN_MAX_DEPTH + 1 + j);

      // Then we copy the parameter coefficients.
      for (j = 0; j < nb_parameters; j++)
        osl_int_assign(CLAN_PRECISION,
            compacted->m[i], j + nb_out_in_loc + 1,
            relation->m[i], relation->nb_columns - CLAN_MAX_PARAMETERS -1 + j);

      // Lastly the scalar coefficient.
      osl_int_assign(CLAN_PRECISION,
          compacted->m[i], nb_columns - 1,
          relation->m[i], relation->nb_columns - 1);
    }

    osl_relation_free_inside(relation);

    // Replace the inside of relation.
    relation->nb_rows       = compacted->nb_rows;
    relation->nb_columns    = compacted->nb_columns;
    relation->m             = compacted->m;
    relation->nb_parameters = nb_parameters;

    // Free the compacted "container".
    free(compacted);

    relation = relation->next;
  }
}


/**
 * clan_relation_greater function:
 * this function generates a relation corresponding to the equivalent
 * constraint set of two linear expressions sets involved in a
 * condition "greater (or equal) to". min and max are two linear expression
 * sets, e.g. (a, b, c) for min and (d, e) for max, where a, b, c, d and e
 * are linear expressions. This function creates the constraint set
 * corresponding to, e.g., min(a, b, c) > max(d, e), i.e.:
 * (a > d && a > e && b > d && b > e && c > d && c > e). It may also create
 * the constraint set corresponding to min(a, b, c) >= max(d, e).
 * The relations max and min are not using the OpenScop/PolyLib format:
 * each row corresponds to a linear expression as usual but the first
 * element is not devoted to the equality/inequality marker but to store
 * the value of the ceild or floord divisor. Hence, each row may correspond
 * to a ceil of a linear expression divided by an integer in min or
 * to a floor of a linear expression divided by an integer in max.
 * \param[in] min    Set of (ceild) linear expressions corresponding
 *                   to the minimum of the (ceild) linear expressions.
 * \param[in] max    Set of (floord) linear expressions corresponding
 *                   to the maximum of the (floord) linear expressions.
 * \param[in] strict 1 if the condition is min > max, 0 if it is min >= max.
 * \return A set of linear constraints corresponding to min > (or >=) max.
 */
osl_relation_p clan_relation_greater(osl_relation_p min, osl_relation_p max,
                                     int strict) {
  int imin, imax, j;
  int a, b;
  osl_relation_p r;
  osl_int_p b_min, a_max;

  if ((min == NULL) || (max == NULL) || (strict < 0) || (strict > 1) ||
      (min->nb_columns != max->nb_columns))
    CLAN_error("cannot compose relations");
  
  r = osl_relation_pmalloc(CLAN_PRECISION,
                           min->nb_rows * max->nb_rows, min->nb_columns);
  b_min = osl_int_malloc(CLAN_PRECISION); 
  a_max = osl_int_malloc(CLAN_PRECISION);
  
  // For each row of min
  for (imin = 0; imin < min->nb_rows; imin++) {
    // For each row of max
    // We have a couple min/a >= max/b to translate to b*min - a*max >= 0
    //      or a couple min/a > max/b  to translate to b*min - a*max - 1 >= 0
    // TODO: here a and b are > 0, this may be generalized to avoid a
    //       problem if the grammar is updated. Plus it's debatable to use
    //       b*min - a*max -a*b >= 0 in the second case. 
    
    // -1. Find a
    a = osl_int_get_si(CLAN_PRECISION, min->m[imin], 0);
    a = (a == 0) ? 1 : a;

    for (imax = 0; imax < max->nb_rows; imax++) {
      // -2. Find b
      b = osl_int_get_si(CLAN_PRECISION, max->m[imax], 0);
      b = (b == 0) ? 1 : b;

      // -3. Compute b*min - a*max to the new relation.
      for (j = 1; j < max->nb_columns; j++) {
        // -3.1. Compute b*min
        osl_int_mul_si(CLAN_PRECISION, b_min, 0, min->m[imin], j, b);
        
        // -3.2. Compute a*max
        osl_int_mul_si(CLAN_PRECISION, a_max, 0, max->m[imax], j, a);
        
        // -3.3. Compute b*min - a*max
        osl_int_sub(CLAN_PRECISION,
                    r->m[imin * max->nb_rows + imax], j, b_min, 0, a_max, 0);
      }

      // -4. Add -1 if the condition is min/a > max/b, add 0 otherwise.
      osl_int_add_si(CLAN_PRECISION,
                     r->m[imin * max->nb_rows + imax], max->nb_columns - 1,
                     r->m[imin * max->nb_rows + imax], max->nb_columns - 1,
                     -strict);
      // -5. Set the equality/inequality marker to inequality.
      osl_int_set_si(CLAN_PRECISION, r->m[imin * max->nb_rows + imax], 0, 1);
    }
  }

  osl_int_free(CLAN_PRECISION, b_min, 0);
  osl_int_free(CLAN_PRECISION, a_max, 0); 
  return r;
}


/**
 * clan_relation_negate_inequality function:
 * this function replaces an inequality constraint in a relation with its
 * negation (e.g., i >= 0 will become i < 0). Note that it does not check
 * that the constraint is actually an inequality.
 * \param[in,out] relation The relation where to oppose a constraint.
 * \param[in]     row      The row corresponding to the constraint to oppose.
 */
static 
void clan_relation_negate_inequality(osl_relation_p relation, int row) {
  int i;
  
  // Oppose all constraint elements.
  for (i = 1; i < relation->nb_columns; i++)
    osl_int_oppose(CLAN_PRECISION,
                   relation->m[row], i, relation->m[row], i);
  
  // The constant term - 1.
  osl_int_decrement(CLAN_PRECISION,
                    relation->m[row], relation->nb_columns - 1,
                    relation->m[row], relation->nb_columns - 1);
}


/**
 * clan_relation_extract_constraint function:
 * this function creates and returns a new relation from a single constraint
 * of a relation. The constraint corresponds to a specified row of the
 * constraint matrix of the first element of the specified relation union.
 * \param[in] relation The input relation.
 * \param[in] row      The row corresponding to the constraint to extract.
 * \return A new relation with the extracted constraint only.
 */
static
osl_relation_p clan_relation_extract_constraint(osl_relation_p relation,
                                                int row) {
  int i;
  osl_relation_p constraint;
  
  constraint = osl_relation_pmalloc(CLAN_PRECISION, 1, relation->nb_columns);
  constraint->type           = relation->type;
  constraint->nb_output_dims = relation->nb_output_dims;
  constraint->nb_input_dims  = relation->nb_input_dims;
  constraint->nb_local_dims  = relation->nb_local_dims;
  constraint->nb_parameters  = relation->nb_parameters;

  for (i = 0; i < relation->nb_columns; i++)
    osl_int_assign(CLAN_PRECISION, constraint->m[0], i, relation->m[row], i);

  return constraint;
}


/**
 * clan_relation_is_equality function:
 * this function returns 1 if a given row of a given relation corresponds
 * to an equality constraint, 0 otherwise (which means it corresponds to
 * an inequality constraint).
 * \param[in] relation The input relation.
 * \param[in] row      The row corresponding to the constraint to check.
 * \return 1 if the constraint is an equality, 0 if it is an inequality.
 */
static
int clan_relation_is_equality(osl_relation_p relation, int row) {

  return (osl_int_zero(CLAN_PRECISION, relation->m[row], 0)) ? 1 : 0;
}


/**
 * clan_relation_tag_inequality function:
 * this function tags a given constraint of a given relation as being an
 * inequality >=0. This means in the PolyLib format, to set to 1 the very
 * first entry of the constraint row. It modifies directly the relation
 * provided as an argument.
 * \param relation The relation which includes a constraint to be tagged.
 * \param row      The row corresponding to the constraint to tag.
 */
static
void clan_relation_tag_inequality(osl_relation_p relation, int row) {
  if ((relation == NULL) || (relation->nb_rows < row))
    CLAN_error("the constraint cannot be inquality-tagged");
  osl_int_set_si(relation->precision, relation->m[row], 0, 1);
}


/**
 * clan_relation_tag_equality function:
 * this function tags a given constraint of a given relation as being an
 * equality == 0. This means in the PolyLib format, to set to 0 the very
 * first entry of the constraint row. It modifies directly the relation
 * provided as an argument.
 * \param relation The relation which includes a constraint to be tagged.
 * \param row      The row corresponding to the constraint to tag.
 */
/*
static
void clan_relation_tag_equality(osl_relation_p relation, int row) {
  if ((relation == NULL) || (relation->nb_rows < row))
    CLAN_error("the constraint cannot be equality-tagged");
  osl_int_set_si(relation->precision, relation->m[row], 0, 0);
}
*/


/**
 * clan_relation_constraint_not function:
 * this function returns the negative form of one constraint in a
 * relation (seen as a constraint set).
 * \param relation The relation set where is the constraint to negate.
 * \param row      The row number of the constraint to negate.
 * \return A new relation containing the negation of the constraint.
 */
static
osl_relation_p clan_relation_constraint_not(osl_relation_p relation, int row) {
  osl_relation_p tmp, tmp_eq = NULL;
  
  if (row > relation->nb_rows)
    return NULL;

  // Extract the constraint.
  tmp = clan_relation_extract_constraint(relation, row);

  // Negate it (inequality-style): a >= 0 becomes a < 0, i.e., -a - 1 >= 0.
  clan_relation_negate_inequality(tmp, 0);

  // If the constraint is an equality we need to build an union.
  // a == 0 becomes a > 0 || a < 0, i.e., a - 1 >= 0 || -a - 1 >= 0.
  if (clan_relation_is_equality(relation, row)) {
    
    tmp_eq = clan_relation_extract_constraint(relation, row);
    osl_int_decrement(CLAN_PRECISION,
                      tmp_eq->m[0], tmp_eq->nb_columns - 1,
                      tmp_eq->m[0], tmp_eq->nb_columns - 1);

    // Set the two constraints as inequalities and build the union.
    clan_relation_tag_inequality(tmp, 0);
    clan_relation_tag_inequality(tmp_eq, 0);
    tmp->next = tmp_eq;
  }

  return tmp;
}


/**
 * clan_relation_not function:
 * this function returns the negative form of a relation (union).
 * \param relation The relation to oppose.
 * \return A new relation corresponding to the negative form of the input.
 */
osl_relation_p clan_relation_not(osl_relation_p relation) {
  int i;
  osl_relation_p not_constraint;
  osl_relation_p not = NULL, part;
  
  while (relation != NULL) {
    // Build the negation of one relation union part.
    part = NULL;
    for (i = 0; i < relation->nb_rows; i++) {
      not_constraint = clan_relation_constraint_not(relation, i);
      osl_relation_add(&part, not_constraint);
    }

    // AND it to the previously negated parts.
    if (not == NULL) {
      not = part;
    }
    else {
      clan_relation_and(not, part);
      osl_relation_free(part);
    }
    relation = relation->next;
  } 

  return not;
}


/**
 * clan_relation_and function:
 * this function inserts the src constraints rows into every parts of dest.
 * If src is an union, the function creates exactly the right number
 * of new unions.
 * \param dest modified relation which contains the result.
 * \param src relation to be inserted.
 */
void clan_relation_and(osl_relation_p dest, osl_relation_p src) {
  osl_relation_p next_dest,
                 next_src,
	         dup_dest,
                 next_mem = NULL;
  
  // initializing
  next_src = src;
  next_dest = dest;
  dup_dest = osl_relation_clone(dest);
  if (dest == NULL || src == NULL)
    return;

  // For each union
  while (next_src != NULL) {
    // Add in each unions
    while(next_dest != NULL) {
      osl_relation_insert_constraints(next_dest, next_src, next_dest->nb_rows);
      next_mem = next_dest;
      next_dest = next_dest->next;
    }
    if (next_src->next != NULL)
      next_mem->next = osl_relation_clone(dup_dest);
    else
      next_mem->next = NULL;

    // Next union
    next_src = next_src->next;
    next_dest = next_mem->next;
  }
  osl_relation_free(dup_dest);
}


/**
 * clan_relation_existential function:
 * this function returns 1 if the relation involves an existential
 * quantifier (its coefficient is not zero), 0 otherwise.
 * \param[in] relation The relation to check.
 * \return 1 if the relation uses an existential quantifier, 0 otherwise.
 */
int clan_relation_existential(osl_relation_p relation) {
  int i, j;

  while (relation != NULL) {
    for (i = 0; i < relation->nb_rows; i++) {
      for (j = CLAN_MAX_DEPTH + 1;
           j < CLAN_MAX_DEPTH + CLAN_MAX_LOCAL_DIMS + 1;
           j++) {
        if (!osl_int_zero(CLAN_PRECISION, relation->m[i], j))
          return 1;
      }
    }
    relation = relation->next;
  }

  return 0;
}


/**
 * clan_relation_oppose_row function:
 * this function multiplies by -1 every element (except the
 * equality/inequality marker) of a given row in a given relation part.
 * \param[in,out] r   The relation to oppose a row.
 * \param[in]     row The row number to oppose.
 */
void clan_relation_oppose_row(osl_relation_p r, int row) {
  int i;
  
  if (r == NULL)
    return;

  if ((row < 0) || (row >= r->nb_rows))
    CLAN_error("bad row number");

  for (i = 1; i < r->nb_columns; i++)
    osl_int_oppose(CLAN_PRECISION, r->m[row], i, r->m[row], i);
}


/**
 * clan_relation_extract_bounding function:
 * this function separates the constraints of a given relation part
 * (not an union) into two constraints sets: one which contains the
 * constraints contributing to one bound of the loop iterator at a given
 * depth and another one which contains all the remaining constraints.
 * Equalities contributing to the bound are separated into two
 * inequalities.
 * \param[in]  r        The constraint set to separate.
 * \param[out] bound    The constraints contributing to the bound (output).
 * \param[out] notbound The constraints not contributing to the bound (output).
 * \param[in]  depth    The loop depth of the bound.
 * \param[in]  lower    1 for the lower bound, 0 for the upper bound.
 */
static
void clan_relation_extract_bounding(osl_relation_p r,
                                    osl_relation_p * bound,
                                    osl_relation_p * notbound,
                                    int depth, int lower) {
  int i;
  osl_relation_p constraint;

  if (r == NULL)
    return;

  if ((depth < 1) || (depth > CLAN_MAX_DEPTH))
    CLAN_error("bad depth");

  if ((lower < 0) || (lower > 1))
    CLAN_error("lower parameter must be 0 or 1");

  // Create two empty sets bound and notbound.
  *bound = osl_relation_pmalloc(r->precision, 0, r->nb_columns);
  osl_relation_set_attributes(*bound,
                              r->nb_output_dims,
                              r->nb_input_dims,
                              r->nb_local_dims,
                              r->nb_parameters);
  *notbound = osl_relation_pmalloc(r->precision, 0, r->nb_columns);
  osl_relation_set_attributes(*notbound,
                              r->nb_output_dims,
                              r->nb_input_dims,
                              r->nb_local_dims,
                              r->nb_parameters);

  // For each constraint in r...
  for (i = 0; i < r->nb_rows; i++) {
    constraint = clan_relation_extract_constraint(r, i);

    if (osl_int_zero(CLAN_PRECISION, constraint->m[0], depth)) {
      // If it does not involve the loop iterator => notbound set.
      osl_relation_insert_constraints(*notbound, constraint, -1);
    }
    else {
      if (osl_int_zero(CLAN_PRECISION, constraint->m[0], 0)) {
        // If this is an equality, separate it into two inequalities, then
        // put one in bound and the other one in notbound conveniently.
        osl_int_set_si(CLAN_PRECISION, constraint->m[0], 0, 1);
        osl_relation_insert_constraints(*bound, constraint, -1);
        osl_relation_insert_constraints(*notbound, constraint, -1);
        if ((lower && osl_int_pos(CLAN_PRECISION, constraint->m[0], depth)) ||
            (!lower && osl_int_neg(CLAN_PRECISION, constraint->m[0], depth)))
          clan_relation_oppose_row(*notbound, (*notbound)->nb_rows - 1);
        else
          clan_relation_oppose_row(*bound, (*bound)->nb_rows - 1);
      }
      else {
        // If it is an inequality, drive it to the right set.
        if ((lower && osl_int_pos(CLAN_PRECISION, constraint->m[0], depth)) ||
            (!lower && osl_int_neg(CLAN_PRECISION, constraint->m[0], depth)))
          osl_relation_insert_constraints(*bound, constraint, -1);
        else
          osl_relation_insert_constraints(*notbound, constraint, -1);
      }
    }
    osl_relation_free(constraint);
  }
}


/**
 * clan_relation_to_expressions function:
 * this function translates a set of inequalities involving the 
 * coefficient of the loop iterator at depth "depth" to a set of
 * expressions which would compare to the iterator alone, hence
 * not involving the loop iterator anymore. E.g., an inequality
 * "j - i + 3 >= 0" for iterator "j" will be converted to "i - 3"
 * (j >= i - 3) and "-j - i + 3 >= 0" will be converted to "-i + 3"
 * (j <= -i + 3). If the coefficient of the iterator is not +/-1,
 * it is stored in the equality/inequality marker.
 * \param[in] r     The inequality set to convert (not an union).
 * \param[in] depth Loop depth of the iterator to remove.
 */
static
void clan_relation_to_expressions(osl_relation_p r, int depth) {
  int i, coef, mark;

  for (i = 0; i < r->nb_rows; i++) {
    mark = osl_int_get_si(CLAN_PRECISION, r->m[i], 0);
    coef = osl_int_get_si(CLAN_PRECISION, r->m[i], depth);
    if ((mark != 1) || (coef == 0))
      CLAN_error("you found a bug");

    if (coef > 1)
      clan_relation_oppose_row(r, i);
    
    coef = (coef > 0) ? coef : -coef;
    if (coef > 1)
      osl_int_set_si(CLAN_PRECISION, r->m[i], 0, coef);
    else
      osl_int_set_si(CLAN_PRECISION, r->m[i], 0, 0);
    osl_int_set_si(CLAN_PRECISION, r->m[i], depth, 0);
  }
}


/**
 * clan_relation_stride function:
 * this function computes and returns a relation built from an input
 * relation modified by the contribution of a loop stride at a given
 * depth. Basically, the input relation corresponds to an iteration
 * domain with a loop stride of 1 for the input depth. It returns the
 * new iteration domain when we take into account a non-unit stride at
 * this depth.
 * \param[in] r      The relation without the stride.
 * \param[in] depth  The depth of the strided loop to take into account.
 * \param[in] stride The loop stride value.
 */
osl_relation_p clan_relation_stride(osl_relation_p r, int depth, int stride) {
  int i, lower;
  osl_relation_p contribution;
  osl_relation_p constraint;
  osl_relation_p bound, notbound;
  osl_relation_p part;
  osl_relation_p full = NULL;

  if (depth < 1)
    CLAN_error("invalid loop depth");
  else if (stride == 0)
    CLAN_error("unsupported zero stride");

  lower = (stride > 0) ? 1 : 0;
  stride = (stride > 0) ? stride : -stride;

  // Each part of the relation union will provide independent contribution.
  while (r != NULL) {
    part = NULL;

    // Separate the bounding constraints (bound) which are impacted by the
    // stride from others (notbound) which will be reinjected later.
    clan_relation_extract_bounding(r, &bound, &notbound, depth, lower);
  
    // Change the bounding constraints to a set of linear expressions
    // to make it easy to manipulate them through existing functions.
    clan_relation_to_expressions(bound, depth);
  
    // Each bound constraint contributes along with the stride.
    for (i = 0; i < bound->nb_rows; i++) {
      // -1. Extract the contributing constraint c.
      constraint = clan_relation_extract_constraint(bound, i);

      // -2. For every constaint before c, ensure the comparison at step 3
      //     will be strictly greater, by adding 1: since the different
      //     sets must be disjoint, we don't want a >= b then b >= a but
      //     a >= b then b > a to avoid a == b to be in both sets.
      //     (Resp. adding -1 for the upper case.)
      if (i > 0) {
        if (lower) {
          osl_int_add_si(CLAN_PRECISION,
                         bound->m[i - 1], bound->nb_columns - 1,
                         bound->m[i - 1], bound->nb_columns - 1, 1);
        }
        else {
          osl_int_add_si(CLAN_PRECISION,
                         bound->m[i - 1], bound->nb_columns - 1,
                         bound->m[i - 1], bound->nb_columns - 1, -1);
        }
      }

      // -3. Compute c > a && c > b && c >= c && c >= d ...
      //     We remove the c >= c row which corresponds to a trivial 0 >= 0.
      //     (Resp. c < a && c <b && c <= c && c <=d ... for the upper case.)
      if (lower)
        contribution = clan_relation_greater(constraint, bound, 0);
      else
        contribution = clan_relation_greater(bound, constraint, 0);
      osl_relation_remove_row(contribution, i);

      // -4. The iterator i of the current depth is i >= c.
      //     (Resp. c <= i for the upper case.)
      //     * 4.1 Put c at the end of the constraint set.
      osl_relation_insert_constraints(contribution, constraint, -1);
      //     * 4.2 Oppose so we have -c.
      //           (Resp. do nothing so we have c for the upper case.)
      if (lower) {
        clan_relation_oppose_row(contribution, contribution->nb_rows - 1);
      }
      //     * 4.3 Put the loop iterator so we have i - c.
      //           (Resp. -i + c for the upper case.)
      if (lower) {
        osl_int_set_si(CLAN_PRECISION,
                       contribution->m[contribution->nb_rows - 1], depth, 1);
      }
      else {
        osl_int_set_si(CLAN_PRECISION,
                       contribution->m[contribution->nb_rows - 1], depth, -1);
      }
      //     * 4.4 Set the inequality marker so we have i - c >= 0.
      //           (Resp. -i + c >= 0 for the upper case.)
      osl_int_set_si(CLAN_PRECISION,
                     contribution->m[contribution->nb_rows - 1], 0, 1);
    
      // -5. Add the contribution of the stride (same for lower and upper).
      //     * 5.1 Put c at the end of the constraint set.
      osl_relation_insert_constraints(contribution, constraint, -1);
      //     * 5.2 Put the opposed loop iterator so we have -i + c.
      osl_int_set_si(CLAN_PRECISION,
                     contribution->m[contribution->nb_rows - 1], depth, -1);
      //     * 5.3 Put stride * local dimension so we have -i + c + stride*ld.
      //           The equality marker is set so we have i == c + stride*ld.
      osl_int_set_si(CLAN_PRECISION,
                     contribution->m[contribution->nb_rows - 1],
                     CLAN_MAX_DEPTH + 1 + clan_parser_nb_ld(), stride);
    
      osl_relation_free(constraint);
      osl_relation_add(&part, contribution);
    }

    // Re-inject notbound constraints
    clan_relation_and(notbound, part);
    osl_relation_free(bound);
    osl_relation_free(part);
    osl_relation_add(&full, notbound);
    r = r->next;
  }
  clan_parser_add_ld();

  return full;
}
