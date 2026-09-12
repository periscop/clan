
   /*+------- <| --------------------------------------------------------**
    **         A                     Clan                                **
    **---     /.\   -----------------------------------------------------**
    **   <|  [""M#                 access.c                              **
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
#include <osl/macros.h>
#include <osl/int.h>
#include <osl/vector.h>
#include <osl/relation.h>
#include <osl/relation_list.h>
#include <osl/extensions/extbody.h>
#include <clan/macros.h>
#include <clan/options.h>
#include <clan/symbol.h>
#include <clan/vector.h>
#include <clan/relation.h>
#include <clan/relation_list.h>
#include "access.h"

extern clan_symbol_p parser_symbol;
extern clan_options_p parser_options;
extern int parser_access_start;
extern int parser_access_length;
extern int parser_nb_parameters;
extern osl_extbody_p parser_access_extbody;
void yyerror(char*);

/** Combine existing parser access lists and retain an affine candidate tree. */
struct clan_access_expr* clan_access_expr_new(int op,
                                             struct clan_access_expr* left,
                                             struct clan_access_expr* right) {
  struct clan_access_expr* expr;
  CLAN_malloc(expr, struct clan_access_expr*, sizeof(*expr));
  expr->op = op;
  expr->value = 0;
  expr->start = left != NULL ? left->start : 0;
  expr->access = NULL;
  if (left != NULL) {
    expr->access = left->access;
    left->access = NULL;
  }
  if (right != NULL) {
    osl_relation_list_add(&expr->access, right->access);
    right->access = NULL;
  }
  expr->name = NULL;
  expr->left = left;
  expr->right = right;
  return expr;
}

void clan_access_expr_free(struct clan_access_expr* expr) {
  if (expr != NULL) {
    clan_access_expr_free(expr->left);
    clan_access_expr_free(expr->right);
    osl_relation_list_free(expr->access);
    free(expr->name);
    free(expr);
  }
}

osl_relation_list_p clan_access_last(osl_relation_list_p list) {
  if (list != NULL) {
    while (list->next != NULL) {
      list = list->next;
    }
  }
  return list;
}

/**
 * Classify without modifying the symbol table: zero means scalar, one means
 * affine, and minus one means general. Parameter promotion is deferred until
 * an entire dimension is known to be affine.
 */
static int clan_access_degree(struct clan_access_expr* expr) {
  int left, right;
  clan_symbol_p symbol;

  if (expr == NULL) {
    return -1;
  }
  if (expr->op == CLAN_ACCESS_INTEGER) {
    return 0;
  }
  if (expr->op == CLAN_ACCESS_ID) {
    symbol = clan_symbol_lookup(parser_symbol, expr->name);
    return (symbol == NULL || symbol->type == CLAN_UNDEFINED ||
            symbol->type == CLAN_TYPE_PARAMETER ||
            symbol->type == CLAN_TYPE_ITERATOR) ? 1 : -1;
  }
  if (expr->op == CLAN_ACCESS_PAREN) {
    return clan_access_degree(expr->left);
  }
  left = clan_access_degree(expr->left);
  if ((expr->op == '+' || expr->op == '-') && expr->right == NULL) {
    return left;
  }
  right = clan_access_degree(expr->right);
  if (left < 0 || right < 0) {
    return -1;
  }
  switch (expr->op) {
    case '+':
    case '-':
      return left > right ? left : right;
    case '*':
      return left + right <= 1 ? left + right : -1;
    case '/':
      return left == 0 && right == 0 ? 0 : -1;
    default:
      return -1;
  }
}

/** Build an affine vector only after classification has succeeded. */
static osl_vector_p clan_access_vector(struct clan_access_expr* expr) {
  int precision = parser_options->precision;
  int scalar;
  clan_symbol_p symbol;
  osl_vector_p left, right, result = NULL;

  if (expr->op == CLAN_ACCESS_INTEGER) {
    return clan_vector_term(parser_symbol, expr->value, NULL, precision);
  }
  if (expr->op == CLAN_ACCESS_ID) {
    symbol = clan_symbol_add(&parser_symbol, expr->name, CLAN_UNDEFINED);
    if (symbol->type == CLAN_UNDEFINED) {
      if (parser_nb_parameters >= CLAN_MAX_PARAMETERS) {
        yyerror("too many parameters in an array subscript");
        return NULL;
      }
      symbol->type = CLAN_TYPE_PARAMETER;
      symbol->rank = ++parser_nb_parameters;
    }
    return clan_vector_term(parser_symbol, 1, expr->name, precision);
  }
  left = clan_access_vector(expr->left);
  if (left == NULL) {
    return NULL;
  }
  if (expr->op == CLAN_ACCESS_PAREN || expr->right == NULL) {
    if (expr->op == '-') {
      result = osl_vector_mul_scalar(left, -1);
      osl_vector_free(left);
      return result;
    }
    return left;
  }
  right = clan_access_vector(expr->right);
  if (right == NULL) {
    osl_vector_free(left);
    return NULL;
  }
  switch (expr->op) {
    case '+':
      result = osl_vector_add(left, right);
      break;
    case '-':
      result = osl_vector_sub(left, right);
      break;
    case '*':
      if (osl_vector_is_scalar(left)) {
        scalar = osl_int_get_si(precision, left->v[left->size - 1]);
        result = osl_vector_mul_scalar(right, scalar);
      } else {
        scalar = osl_int_get_si(precision, right->v[right->size - 1]);
        result = osl_vector_mul_scalar(left, scalar);
      }
      break;
    case '/':
      scalar = osl_int_get_si(precision, right->v[right->size - 1]);
      if (scalar == 0) {
        yyerror("zero divisor in an array subscript");
      } else {
        scalar = osl_int_get_si(precision, left->v[left->size - 1]) / scalar;
        result = clan_vector_term(parser_symbol, scalar, NULL, precision);
      }
      break;
  }
  osl_vector_free(left);
  osl_vector_free(right);
  return result;
}

/** Reject invalid constant divisors even in an otherwise general expression. */
static int clan_access_validate(struct clan_access_expr* expr) {
  osl_vector_p divisor;
  int invalid;
  if (expr == NULL) {
    return 1;
  }
  if (expr->op == CLAN_ACCESS_EFFECT) {
    yyerror("side effects in array subscripts are unsupported");
    return 0;
  }
  if (!clan_access_validate(expr->left) || !clan_access_validate(expr->right)) {
    return 0;
  }
  if ((expr->op == '%' || expr->op == '/') &&
      clan_access_degree(expr->right) == 0) {
    divisor = clan_access_vector(expr->right);
    if (divisor == NULL) {
      return 0;
    }
    invalid = osl_int_zero(divisor->precision, divisor->v[divisor->size - 1]) ||
              (expr->op == '%' &&
               osl_int_neg(divisor->precision, divisor->v[divisor->size - 1]));
    osl_vector_free(divisor);
    if (invalid) {
      yyerror("invalid constant divisor in an array subscript");
      return 0;
    }
  }
  return 1;
}

/**
 * Append a dimension and insert its operand reads before the enclosing access.
 * The last list element remains the assignment target through every subscript.
 */
int clan_access_subscript(struct clan_access_expr* base,
                          struct clan_access_expr* expr, int marker) {
  osl_relation_list_p* tail = &base->access;
  osl_relation_list_p reads;
  osl_relation_p relation;
  osl_vector_p vector, divisor;
  struct clan_access_expr* value = expr;
  int mod = 0;

  if (*tail == NULL || !clan_access_validate(expr)) {
    return 0;
  }
  while ((*tail)->next != NULL) {
    tail = &(*tail)->next;
  }
  relation = (*tail)->elt;
  while (value->op == CLAN_ACCESS_PAREN) {
    value = value->left;
  }
  if (value->op == '%' && clan_access_degree(value->left) >= 0 &&
      clan_access_degree(value->right) == 0) {
    divisor = clan_access_vector(value->right);
    if (divisor == NULL) {
      return 0;
    }
    mod = osl_int_get_si(divisor->precision, divisor->v[divisor->size - 1]);
    osl_vector_free(divisor);
    value = value->left;
  }
  if (clan_access_degree(value) >= 0) {
    if (mod && relation->nb_local_dims >= CLAN_MAX_LOCAL_DIMS) {
      yyerror("too many local dimensions in an array access");
      return 0;
    }
    vector = clan_access_vector(value);
    if (vector == NULL) {
      return 0;
    }
    clan_relation_new_output_vector(relation, vector);
    osl_vector_free(vector);
    if (mod) {
      clan_relation_add_modulo_constraint(relation, mod);
    }
    // Affine operands are parameters or iterators, not separate memory reads.
    osl_relation_list_free(expr->access);
    expr->access = NULL;
    if (parser_options->extbody) {
      parser_access_extbody->nb_access = marker;
    }
    return 1;
  }

  if (parser_options->affine_only) {
    yyerror("non-affine array subscript with -affine-only");
    return 0;
  }

  reads = expr->access;
  expr->access = NULL;
  if (parser_options->extbody && parser_access_start != -1) {
    osl_extbody_add(parser_access_extbody, parser_access_start,
                    parser_access_length);
  }
  // A blank output column with no defining row denotes the entire dimension.
  osl_relation_insert_blank_column(relation, relation->nb_output_dims + 1);
  relation->nb_output_dims++;
  if (reads != NULL) {
    clan_access_last(reads)->next = *tail;
    *tail = reads;
  }
  return 1;
}
