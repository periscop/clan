
   /*+------- <| --------------------------------------------------------**
    **         A                     Clan                                **
    **---     /.\   -----------------------------------------------------**
    **   <|  [""M#                 symbol.c                              **
    **-   A   | #   -----------------------------------------------------**
    **   /.\ [""M#         First version: 01/05/2008                     **
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
#include <ctype.h>
#include <string.h>

#include <osl/strings.h>
#include <osl/generic.h>
#include <osl/extensions/arrays.h>
#include <clan/macros.h>
#include <clan/symbol.h>


/*+****************************************************************************
 *                               Global variables                             *
 ******************************************************************************/


int symbol_nb_iterators  = 0; /**< Current number of iterator symbols  */
int symbol_nb_parameters = 0; /**< Current number of parameter symbols */
int symbol_nb_arrays     = 0; /**< Current number of array symbols     */
int symbol_nb_functions  = 0; /**< Current number of function symbols  */


/*+****************************************************************************
 *                          Structure display function                        *
 ******************************************************************************/


/**
 * clan_symbol_print_structure function:
 * Displays a clan_symbol_t structure (*symbol) into a file (file, possibly
 * stdout) in a way that trends to be understandable without falling in a deep
 * depression or, for the lucky ones, getting a headache... It includes an
 * indentation level (level) in order to work with others print_structure
 * functions.
 * \param file   File where informations are printed.
 * \param symbol The symbol whose information have to be printed.
 * \param level  Number of spaces before printing, for each line.
 */
void clan_symbol_print_structure(FILE * file, clan_symbol_p symbol,
                                 int level) {
  int i, j, first = 1, number = 1;

  if (symbol != NULL) {
    /* Go to the right level. */
    for(j = 0; j < level; j++)
      fprintf(file, "|\t");
    fprintf(file, "+-- clan_symbol_t (node %d)\n", number);
  }
  else {
    /* Go to the right level. */
    for(j = 0; j < level; j++)
      fprintf(file, "|\t");
    fprintf(file, "+-- NULL symbol\n");
  }

  while (symbol != NULL) {
    if (!first) {
      /* Go to the right level. */
      for (j = 0; j < level; j++)
        fprintf(file, "|\t");
      fprintf(file, "|   clan_symbol_t (node %d)\n", number);
    }
    else
      first = 0;

    /* A blank line. */
    for (j = 0; j <= level+1; j++)
      fprintf(file, "|\t");
    fprintf(file, "\n");

    /* Print the identifier. */
    for (i = 0; i <= level; i++)
      fprintf(file, "|\t");
    if (symbol->identifier != NULL)
      fprintf(file, "+-- Identifier: %s\n", symbol->identifier);
    else
      fprintf(file, "+-- No identifier\n");

    /* A blank line. */
    for(j = 0; j <= level + 1; j++)
      fprintf(file, "|\t") ;
    fprintf(file, "\n") ;

    /* Go to the right level and print the type. */
    for (j = 0; j <= level; j++)
      fprintf(file, "|\t") ;
    fprintf(file, "Type: ") ;
    switch (symbol->type) {
      case CLAN_TYPE_ITERATOR : fprintf(file, "Iterator\n");  break;
      case CLAN_TYPE_PARAMETER: fprintf(file, "Parameter\n"); break;
      case CLAN_TYPE_ARRAY    : fprintf(file, "Array\n");     break;
      case CLAN_TYPE_FUNCTION : fprintf(file, "Function\n");  break;
      default : fprintf(file, "Unknown\n") ;
    }

    /* A blank line. */
    for (j = 0; j <= level + 1; j++)
      fprintf(file, "|\t");
    fprintf(file, "\n");

    /* Go to the right level and print the rank. */
    for (j = 0; j <= level; j++)
      fprintf(file, "|\t");
    fprintf(file, "Rank: %d\n", symbol->rank);

    /* A blank line. */
    for (j = 0; j <= level + 1; j++)
      fprintf(file, "|\t");
    fprintf(file, "\n");

    symbol = symbol->next;
    number++;

    /* Next line. */
    if (symbol != NULL) {
      for (j = 0; j <= level; j++)
        fprintf(file, "|\t");
      fprintf(file, "V\n");
    }
  }

  /* The last line. */
  for(j = 0; j <= level; j++)
    fprintf(file, "|\t");
  fprintf(file, "\n");
}


/**
 * clan_symbol_print function:
 * This function prints the content of a clan_symbol_t structure (*symbol) into
 * a file (file, possibly stdout).
 * \param file   File where informations are printed.
 * \param symbol The symbol whose information have to be printed.
 */
void clan_symbol_print(FILE * file, clan_symbol_p symbol) {
  clan_symbol_print_structure(file, symbol, 0);
}


/*+****************************************************************************
 *                    Memory allocation/deallocation function                 *
 ******************************************************************************/


/**
 * clan_symbol_malloc function:
 * This function allocates the memory space for a clan_symbol_t structure and
 * sets its fields with default values. Then it returns a pointer to the
 * allocated space.
 */
clan_symbol_p clan_symbol_malloc() {
  clan_symbol_p symbol;

  CLAN_malloc(symbol, clan_symbol_p, sizeof(clan_symbol_t));
  symbol->identifier = NULL;
  symbol->next       = NULL;

  return symbol;
}


/**
 * clan_symbol_free function:
 * This function frees the allocated memory for a clan_symbol_t structure.
 * \param symbol The pointer to the symbol we want to free.
 */
void clan_symbol_free(clan_symbol_p symbol) {
  clan_symbol_p next;

  while (symbol != NULL) {
    next = symbol->next;
    free(symbol->identifier);
    free(symbol);
    symbol = next;
  }
}


/*+****************************************************************************
 *                            Processing functions                            *
 ******************************************************************************/


/**
 * clan_symbol_lookup function:
 * This function searches the symbol table for a symbol with the identifier
 * provided as parameter. It returns the pointer to the symbol if it already
 * exists inside the table, NULL otherwise.
 * \param symbol     The first node of the list of symbols.
 * \param identifier The identifier we are looking for.
 */
clan_symbol_p clan_symbol_lookup(clan_symbol_p symbol, char * identifier) {
  while (symbol != NULL) {
    if (strcmp(symbol->identifier, identifier) == 0)
      return symbol;
    else
      symbol = symbol->next;
  }
  return NULL;
}

  
/**
 * clan_symbol_lookup_by_type_rank( function:
 * This function searches the symbol table for a symbol with the type and rank
 * provided as parameter. It returns the pointer to the symbol if it already
 * exists inside the table, NULL otherwise.
 * \param symbol The first node of the list of symbols.
 * \param type   The type of the searched symbol.
 * \param rank   The rank of the searched symbol.
 */
clan_symbol_p clan_symbol_lookup_by_type_rank(clan_symbol_p symbol,
                                              int type, int rank) {
  while (symbol != NULL) {
    if ((symbol->type == type) && (symbol->rank == rank))
      return symbol;
    else
      symbol = symbol->next;
  }
  return NULL;
}


/**
 * clan_symbol_add function:
 * This function adds a new clan_symbol_t in the symbol table whose address
 * is provided as a parameter. If the symbol table is empty (NULL), the new
 * node will become its first element. A new node is added only if an
 * existing node with the same identifier does not already exist. It returns
 * the pointer to the symbol table node corresponding to the identifier.
 * \param location   The address of the symbol table.
 * \param identifier The identifier of the symbol we want to add.
 * \param type       The new symbol type
 * \param rank       The new symbol rank (depth if iterator, ignored otherwise)
 */
clan_symbol_p clan_symbol_add(clan_symbol_p * location, char * identifier,
                              int type, int rank) {
  clan_symbol_p symbol;

  /* If the identifier is already in the table, do nothing. */
  symbol = clan_symbol_lookup(*location, identifier);
  if (symbol != NULL)
    return symbol;

  /* Else, we allocate and fill a new clan_symbol_t node. */
  symbol = clan_symbol_malloc();

  symbol->identifier = strdup(identifier);

  /* If the type was unknown (iterator or parameter) we know now that it is
   * a parameter, it would have been already in the table otherwise.
   */
  if (type == CLAN_TYPE_UNKNOWN)
    type = CLAN_TYPE_PARAMETER;
  symbol->type = type;

  switch (symbol->type) {
    case CLAN_TYPE_ITERATOR : symbol->rank = rank;
                              symbol_nb_iterators++;
			      break;
    case CLAN_TYPE_PARAMETER: symbol->rank = ++symbol_nb_parameters; break;
    case CLAN_TYPE_ARRAY    : symbol->rank = ++symbol_nb_arrays;     break;
    case CLAN_TYPE_FUNCTION : symbol->rank = ++symbol_nb_functions;  break;
  }

  /* We put the new symbol at the beginning of the table (easier ;-) !). */
  symbol->next = *location;
  *location = symbol;

  return symbol;
}


/**
 * clan_symbol_get_rank function:
 * This function returns the rank of the symbol with identifier "identifier"
 * in the symbol table whose first element is "symbol". If the symbol with
 * the specified identifier is not found, it returns -1.
 * \param symbol     The first node of the list of symbols.
 * \param identifier The identifier we want to know the rank.
 */
int clan_symbol_get_rank(clan_symbol_p symbol, char * identifier) {
  while (symbol != NULL) {
    if (strcmp(symbol->identifier,identifier) == 0)
      return symbol->rank;
    else
      symbol = symbol->next;
  }
  return -1;
}


/**
 * clan_symbol_get_type function:
 * This function returns the type of the symbol with identifier "identifier"
 * in the symbol table whose first element is "symbol". If the symbol with
 * the specified identifier is not found, it returns -1.
 * \param symbol     The first node of the list of symbols.
 * \param identifier The identifier we want to know the type.
 */
int clan_symbol_get_type(clan_symbol_p symbol, char * identifier) {
  while (symbol != NULL) {
    if (strcmp(symbol->identifier,identifier) == 0)
      return symbol->type;
    else
      symbol = symbol->next;
  }
  return -1;
}


/**
 * clan_symbol_array_to_strings function:
 * this functions builds (and returns a pointer to) an osl_strings_t
 * structure containing the symbol strings contained in an array of
 * symbols of length nb. The symbol string order is the same as the one
 * in the symbol array.
 * \param[in] sarray The symbol array.
 * \param[in] size   The size of the symbol array.
 * \return An osl_strings_t containing all the symbol strings.
 */
osl_strings_p clan_symbol_array_to_strings(clan_symbol_p *sarray, int size) {
  int i, length;
  char **identifiers = NULL;
  osl_strings_p strings;

  // Allocate, initialize and NULL-terminate the array of strings.
  CLAN_malloc(identifiers, char **, (size + 1) * sizeof(char *));
  for (i = 0; i <= size; i++)
    identifiers[i] = NULL;

  // Fill the array of strings.
  for (i = 0; i < size; i++) {
    length = strlen((sarray[i])->identifier) + 1;
    CLAN_malloc(identifiers[i], char *, length * sizeof(char));
    strcpy(identifiers[i], (sarray[i])->identifier);
  }

  // Build the osl_strings_t container.
  strings = osl_strings_malloc();
  strings->string = identifiers;

  return strings;
}


/**
 * clan_symbol_nb_of_type function:
 * this function returns the number of symbols of a given type in the
 * symbol table.
 * \param[in] symbol The top of the symbol table.
 * \param[in] type   The type of the elements.
 * \return The number of symbols of the provoded type in the symbol table.
 */
int clan_symbol_nb_of_type(clan_symbol_p symbol, int type) {
  int nb = 0;
  
  while (symbol != NULL) {
    if (symbol->type == type)
      nb++;
    symbol = symbol->next;
  }

  return nb;
}


/**
 * clan_symbol_to_strings function:
 * this function builds (and returns a pointer to) an osl_generic_t
 * structure containing the symbol strings of a given type in the
 * symbol table. The osl_generic_t is a shell for an osl_strings_t
 * which actually stores the symbol strings. The symbol strings are sorted
 * according to their rank. If there is no corresponding symbol in the
 * table, it returns NULL.
 * \param[in] symbol The top of the symbol table.
 * \param[in] type   The type of the elements.
 * \return An osl_generic_t with the symbol strings of the given type.
 */
osl_generic_p clan_symbol_to_strings(clan_symbol_p symbol, int type) {
  int i, length, nb_identifiers = 0;
  char **identifiers = NULL;
  osl_strings_p strings;
  osl_generic_p generic;

  nb_identifiers = clan_symbol_nb_of_type(symbol, type);
  if (nb_identifiers == 0)
    return NULL;

  // Allocate, initialize and NULL-terminate the array.
  CLAN_malloc(identifiers, char **, (nb_identifiers + 1) * sizeof(char *));
  for (i = 0; i <= nb_identifiers; i++)
    identifiers[i] = NULL;

  // We scan the table a second time to fill the identifier array
  // Not optimal to act this way but overkills are worse!
  i = 0;
  while (symbol != NULL) {
    if (symbol->type == type) {
      length = strlen(symbol->identifier) + 1;
      CLAN_malloc(identifiers[symbol->rank - 1], char *, length * sizeof(char));
      strcpy(identifiers[symbol->rank - 1], symbol->identifier);
      i++;
    }
    symbol = symbol->next;
  }

  // A basic check that there is no hole in the rank list.
  for (i = 0; i < nb_identifiers; i++)
    if (identifiers[i] == NULL)
      CLAN_error("hole in the string list");

  // Build the osl_strings_t container.
  strings = osl_strings_malloc();
  strings->string = identifiers;

  // Embed the strings in a generic shell.
  generic = osl_generic_shell(strings, osl_strings_interface());
  return generic;
}


/**
* clan_symbol_clone_one function:
* this function clones one symbol, i.e., it returns the clone of the symbol
* provided as an argument only, with a next field set to NULL.
* \param symbol The symbol to clone.
* \return The clone of the symbol (and this symbol only).
*/
clan_symbol_p clan_symbol_clone_one(clan_symbol_p symbol) {
  clan_symbol_p clone = clan_symbol_malloc();

  if (symbol->identifier != NULL)
    clone->identifier = strdup(symbol->identifier);
  clone->type = symbol->type;
  clone->rank = symbol->rank;

  return clone;
}


/**
 * clan_symbol_to_arrays function:
 * this function generates an arrays extension from the symbol table
 * passed as an argument. It embeds it in an osl_generic_t structure
 * before returning it.
 * \param[in] symbol The symbol table.
 * \return An arrays structure with all the arrays of the symbol table.
 */
osl_generic_p clan_symbol_to_arrays(clan_symbol_p symbol) {
  int i;
  int nb_arrays = 0;
  osl_arrays_p arrays = NULL;
  osl_generic_p generic = NULL;
  clan_symbol_p top = symbol;

  // A first scan to know how many arrays there are.
  while (symbol != NULL) {
    if (symbol->type == CLAN_TYPE_ARRAY)
      nb_arrays++;
    symbol = symbol->next;
  }

  // Build the arrays extension.
  if (nb_arrays > 0) {
    arrays = osl_arrays_malloc();
    CLAN_malloc(arrays->id, int *, nb_arrays * sizeof(int));
    CLAN_malloc(arrays->names, char **, nb_arrays * sizeof(char *));
    arrays->nb_names = nb_arrays;
    symbol = top;
    i = 0;
    while (symbol != NULL) {
      if (symbol->type == CLAN_TYPE_ARRAY) {
        arrays->id[i] = symbol->rank;
        CLAN_strdup(arrays->names[i], symbol->identifier);
        i++;
      }
      symbol = symbol->next;
    }
    
    // Embed the arrays in a generic shell.
    generic = osl_generic_shell(arrays, osl_arrays_interface());
  }

  return generic;
}

void yyerror(char *);

/**
 * clan_symbol_new_iterator function:
 * this function registers (or updates) an iterator in the symbol
 * table and adds it to the iterator array.
 * \param[in,out] table The symbol table.
 * \param[in,out] array The iterator array.
 * \param[in]     id    The textual name of the iterator.
 * \param[in]     depth The current loop depth.
 */
void clan_symbol_new_iterator(clan_symbol_p * table, clan_symbol_p * array,
                              char * id, int depth) {
  clan_symbol_p symbol;
  symbol = clan_symbol_add(table, id, CLAN_TYPE_ITERATOR, depth + 1);

  // Ensure that the returned symbol was either a new one,
  // either from the same type.
  if (symbol->type != CLAN_TYPE_ITERATOR) {
    yyerror("a loop iterator was previously used as a parameter");
    return;
  }
  // Update the rank, in case the symbol already exists.
  if (symbol->rank != depth + 1)
    symbol->rank = depth + 1;
  array[depth] = clan_symbol_clone_one(symbol);
}


