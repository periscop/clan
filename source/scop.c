
   /*+------- <| --------------------------------------------------------**
    **         A                     Clan                                **
    **---     /.\   -----------------------------------------------------**
    **   <|  [""M#                  scop.c                               **
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
#include <ctype.h>
#include <string.h>

#include <osl/vector.h>
#include <osl/relation.h>
#include <osl/relation_list.h>
#include <osl/statement.h>
#include <osl/strings.h>
#include <osl/extensions/scatnames.h>
#include <osl/extensions/arrays.h>
#include <osl/extensions/coordinates.h>
#include <osl/generic.h>
#include <osl/body.h>
#include <osl/scop.h>
#include <parser.h>
#include <clan/macros.h>
#include <clan/options.h>
#include <clan/statement.h>
#include <clan/scop.h>


extern int scanner_start;
extern int scanner_end;
extern int parser_indent;


/*+****************************************************************************
 *                            Processing functions                            *
 ******************************************************************************/

osl_scop_p clan_parse(FILE *, clan_options_p);

/**
 * clan_scop_extract function:
 * this function is a wrapper to the clan_parse function that parses a file to
 * extract a SCoP and returns, if successful, a pointer to the osl_scop_t
 * structure.
 * \param input   The file to parse (already open).
 * \param options Options for file parsing.
 */
osl_scop_p clan_scop_extract(FILE * input, clan_options_p options) {
  return clan_parse(input, options);
}


/**
 * clan_scop_compact function:
 * This function scans the SCoP to put the right number of columns to every
 * relation (during construction we used CLAN_MAX_DEPTH and CLAN_MAX_PARAMETERS
 * to define relation and vector sizes).
 * \param scop The scop to scan to compact matrices.
 */
void clan_scop_compact(osl_scop_p scop) {
  clan_statement_compact(scop->statement, osl_scop_get_nb_parameters(scop));
}


/**
 * clan_scop_print function:
 * this function prints the content of an osl_scop_t structure (*scop)
 * into a file (file, possibly stdout) in the OpenScop textual format.
 * \param[in] file The file where the information has to be printed.
 * \param[in] scop The scop structure whose information has to be printed.
 */
void clan_scop_print(FILE * file, osl_scop_p scop) {
  
  if (scop != NULL) {
    fprintf(file, "#                                                     \n");
    fprintf(file, "#          <|                                         \n");
    fprintf(file, "#           A                                         \n");
    fprintf(file, "#          /.\\                                       \n");
    fprintf(file, "#     <|  [\"\"M#                                     \n");
    fprintf(file, "#      A   | #            Clan McCloog Castle         \n");
    fprintf(file, "#     /.\\ [\"\"M#           [Generated by Clan ");
    fprintf(file, "%s]\n", CLAN_VERSION);
    fprintf(file, "#    [\"\"M# | #  U\"U#U                              \n");
    fprintf(file, "#     | #  | #  \\ .:/                                \n");
    fprintf(file, "#     | #  | #___| #                                  \n");
    fprintf(file, "#     | \"--'     .-\"                                \n");
    fprintf(file, "#   |\"-\"-\"-\"-\"-#-#-##                            \n");
    fprintf(file, "#   |     # ## ######                                 \n");
    fprintf(file, "#    \\       .::::'/                                 \n");
    fprintf(file, "#     \\      ::::'/                                  \n");
    fprintf(file, "#   :8a|    # # ##                                    \n");
    fprintf(file, "#   ::88a      ###                                    \n");
    fprintf(file, "#  ::::888a  8a ##::.                                 \n");
    fprintf(file, "#  ::::::888a88a[]::::                                \n");
    fprintf(file, "# :::::::::SUNDOGa8a::::. ..                          \n");
    fprintf(file, "# :::::8::::888:Y8888:::::::::...                     \n");
    fprintf(file, "#::':::88::::888::Y88a______________________________");
    fprintf(file, "________________________\n");
    fprintf(file, "#:: ::::88a::::88a:Y88a                             ");
    fprintf(file, "     __---__-- __\n");
    fprintf(file, "#' .: ::Y88a:::::8a:Y88a                            ");
    fprintf(file, "__----_-- -------_-__\n");
    fprintf(file, "#  :' ::::8P::::::::::88aa.                   _ _- -");
    fprintf(file, "-  --_ --- __  --- __--\n");
    fprintf(file, "#.::  :::::::::::::::::::Y88as88a...s88aa.\n#\n");
  }

  osl_scop_print(file, scop);
}


/**
 * clan_scop_generate_scatnames function:
 * this function generates a scatnames extension for the scop passed as
 * an argument. Since Clan use a "2d+1" scattering strategy, the
 * scattering dimension names are generated by reusing the original
 * iterator names of the deepest statement and by inserting between those
 * names some beta vector elements (the Xth beta element is called bX).
 * \param[in,out] scop The scop to add a scatnames extension to.
 */
void clan_scop_generate_scatnames(osl_scop_p scop) {
  osl_statement_p current, deepest;
  osl_scatnames_p scatnames;
  osl_strings_p iterators = NULL;
  osl_strings_p names;
  osl_generic_p extension;
  char ** string;
  char buffer[CLAN_MAX_STRING];
  int max_depth = -1;
  int i;

  // Find the deepest statement to reuse its original iterators.
  current = scop->statement;
  while (current != NULL) {
    if (current->domain->nb_output_dims > max_depth) {
      max_depth = current->domain->nb_output_dims;
      deepest = current;
      iterators = ((osl_body_p)(deepest->body->data))->iterators;
    }
    current = current->next;
  }

  // It there are no scattering dimension, do nothing.
  if (max_depth <= 0)
    return;

  // Create the NULL-terminated list of scattering dimension names.
  CLAN_malloc(string, char **, (2*max_depth + 2) * sizeof(char *));
  string[2*max_depth + 1] = NULL;
  for (i = 0; i < max_depth; i++) {
    sprintf(buffer, "b%d", i);
    CLAN_strdup(string[2*i], buffer);
    CLAN_strdup(string[2*i+1], iterators->string[i]);
  }
  sprintf(buffer, "b%d", max_depth);
  CLAN_strdup(string[2*max_depth], buffer);

  // Build the scatnames extension.
  names = osl_strings_malloc();
  names->string = string;
  scatnames = osl_scatnames_malloc();
  scatnames->names = names;

  // Build the generic extension and insert it to the extension list.
  extension = osl_generic_malloc();
  extension->interface = osl_scatnames_interface();
  extension->data = scatnames;
  osl_generic_add(&scop->extension, extension);
}


/**
 * clan_scop_generate_coordinates function:
 * this function generates a coordinates extension for the scop passed as
 * an argument.
 * \param[in]     name The name of the SCoP original file.
 * \param[in,out] scop The scop to add a scatnames extension to.
 */
void clan_scop_generate_coordinates(osl_scop_p scop, char * name) {
  osl_coordinates_p coordinates;
  osl_generic_p extension;

  // Build the coordinates extension
  coordinates = osl_coordinates_malloc();
  CLAN_strdup(coordinates->name, name);
  coordinates->start  = scanner_start;
  coordinates->end    = scanner_end;
  coordinates->indent = (parser_indent != CLAN_UNDEFINED) ? parser_indent : 0;

  // Build the generic extension and insert it to the extension list.
  extension = osl_generic_malloc();
  extension->interface = osl_coordinates_interface();
  extension->data = coordinates;
  osl_generic_add(&scop->extension, extension);
}
