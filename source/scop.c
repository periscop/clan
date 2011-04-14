
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
#include <osl/generic.h>
#include <osl/body.h>
#include <osl/scop.h>
#include <parser.h>
#include <clan/macros.h>
#include <clan/options.h>
#include <clan/statement.h>
#include <clan/scop.h>


/*+****************************************************************************
 *                            Processing functions                            *
 ******************************************************************************/

osl_scop_p
clan_parse(FILE *, clan_options_p);

/**
 * clan_scop_extract function:
 * this function is a wrapper clan_parse function that parses a file to
 * extract a SCoP and returns, if successful, a pointer to the osl_scop_t
 * structure.
 * \param input   The file to parse (already open).
 * \param options Options for file parsing.
 **
 * - 24/05/2008: First version.
 */
osl_scop_p
clan_scop_extract(FILE * input, clan_options_p options)
{
  return clan_parse(input, options);
}


/**
 * clan_scop_compact function:
 * This function scans the SCoP to put the right number of columns to every
 * relation (during construction we used CLAN_MAX_DEPTH and CLAN_MAX_PARAMETERS
 * to define relation and vector sizes).
 * \param scop The scop to scan to compact matrices.
 **
 * - 02/05/2008: first version.
 */
void
clan_scop_compact(osl_scop_p scop)
{
  clan_statement_compact(scop->statement, osl_scop_get_nb_parameters(scop));
}


/**
 * clan_scop_print function:
 * this function prints the content of an osl_scop_t structure (*scop)
 * into a file (file, possibly stdout) in the OpenScop textual format.
 * \param[in] file The file where the information has to be printed.
 * \param[in] scop The scop structure whose information has to be printed.
 */
void
clan_scop_print(FILE * file, osl_scop_p scop) {

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

  osl_scop_print(file, scop);
}


/**
 * clan_scop_generate_scatnames function:
 * this function generates a scatnames extension for the scop passed as
 * an argument. Since Clan use a "2d+1" scattering strategy, the
 * scattering dimension names are generated by reusing the original
 * iterator names of the deepest statement and by inserting between those
 * names some beta vector elements (the Xth beta element is called bX).
 * \param[in] scop The scop to add a scatnames extension to.
 */
void
clan_scop_generate_scatnames(osl_scop_p scop) {
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
  // Try to avoid the fakeiter if possible.
  current = scop->statement;
  while (current != NULL) {
    if ((current->domain->nb_output_dims > max_depth) ||
        ((max_depth == 1) && (!strcmp(iterators->string[0], CLAN_FAKEITER)))) {
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


//TODO: Put back the option support
#if 0
/**
 * clan_scop_fill_options:
 * This function stores the list of variables id in 'varlist' in the
 * option tag of the scop, enclosed by
 * <local-vars></local-vars>.
 *
 */
void
clan_scop_fill_options(osl_scop_p scop, int* localvars, int* liveoutvars)
{
  /* Build the string of ids. */
  int i, size;
  char* tag = NULL;
  char* tag1 = NULL;
  char* tag2 = NULL;
  if (localvars && localvars[0] != -1)
    {
      /* localvars is a -1-terminated array. */
      for (i = 0; localvars[i] != -1; ++i)
	;
      size = i;
      char* ids = (char*)malloc(((size * 5) + 1) * sizeof(char));
      ids[0] = '\0';
      char buffer[16];
      for (i = 0; i < size; ++i)
	{
	  if (i == 0)
	    sprintf(buffer, "%d", localvars[i]);
	  else
	    sprintf(buffer, " %d", localvars[i]);
	  strcat(ids, buffer);
	}
      size = strlen("<local-vars>\n") + strlen (ids) +
	strlen ("</local-vars>\n");
      tag1 = (char*)malloc((size + 1) * sizeof(char));
      strcpy(tag1, "<local-vars>\n");
      strcat(tag1, ids);
      strcat(tag1, "\n");
      strcat(tag1, "</local-vars>\n");
      free(ids);
    }

  if (liveoutvars && liveoutvars[0] != -1)
    {
      /* liveoutvars is a -1-terminated array. */
      for (i = 0; liveoutvars[i] != -1; ++i)
	;
      size = i;
      char* ids = (char*)malloc(((size * 5) + 1) * sizeof(char));
      ids[0] = '\0';
      char buffer[16];
      for (i = 0; i < size; ++i)
	{
	  if (i == 0)
	    sprintf(buffer, "%d", liveoutvars[i]);
	  else
	    sprintf(buffer, " %d", liveoutvars[i]);
	  strcat(ids, buffer);
	}
      size = strlen("<live-out-vars>\n") + strlen (ids) +
	strlen ("</live-out-vars>\n");
      tag2 = (char*)malloc((size + 1) * sizeof(char));
      strcpy(tag2, "<live-out-vars>\n");
      strcat(tag2, ids);
      strcat(tag2, "\n");
      strcat(tag2, "</live-out-vars>\n");
      free(ids);
    }

  /* Concatenate the tags. */
  if (tag1 || tag2)
    {
      if (tag1 == NULL)
	tag = tag2;
      else if (tag2 == NULL)
	tag = tag1;
      else
	{
	  tag = (char*)malloc((strlen(tag1) + strlen(tag2) + 1));
	  strcpy(tag, tag1);
	  strcat(tag, tag2);
	  free(tag1);
	  free(tag2);
	}
    }

  if (scop->optiontags == NULL)
    scop->optiontags = tag;
  else
    {
      char* newtag = (char*)malloc((strlen(tag) + strlen(scop->optiontags) + 2)
				   * sizeof(char));
      strcpy(newtag, scop->optiontags);
      strcat(newtag, "\n");
      strcat(newtag, tag);
      free(scop->optiontags);
      scop->optiontags = newtag;
    }
}
#endif
