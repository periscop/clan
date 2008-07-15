
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
 *       \      ::::'/     Copyright (C) 2008 Cedric Bastoul                  *
 *     :8a|    # # ##                                                         *
 *     ::88a      ###      This is free software; you can redistribute it     *
 *    ::::888a  8a ##::.   and/or modify it under the terms of the GNU Lesser *
 *  ::::::::888a88a[]:::   General Public License as published by the Free    *
 *::8:::::::::SUNDOGa8a::. Software Foundation, either version 3 of the       *
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
 * Written by Cedric Bastoul, Cedric.Bastoul@inria.fr                         *
 *                                                                            *
 ******************************************************************************/


# include <stdlib.h>
# include <stdio.h>
# include <ctype.h>
# include <string.h>
# include <clan/scop.h>
# include <clan/clan.h>
# include <parser.h>


extern int clan_castle;


/*+****************************************************************************
 *                         Structure display functions                        *
 ******************************************************************************/


/**
 * clan_scop_print_structure function:
 * Displays a clan_scop_t structure (*scop) into a file (file, possibly
 * stdout) in a way that trends to be understandable without falling in a deep
 * depression or, for the lucky ones, getting a headache... It includes an
 * indentation level (level) in order to work with others print_structure
 * functions.
 * \param file   File where informations are printed.
 * \param scop   The scop whose information have to be printed.
 * \param level  Number of spaces before printing, for each line.
 **
 * - 30/04/2008: first version.
 */
void
clan_scop_print_structure(FILE * file, clan_scop_p scop, int level)
{
  int i, j;

  if (scop != NULL)
  {
    /* Go to the right level. */
    for (j = 0; j < level; j++)
      fprintf(file,"|\t");
    fprintf(file,"+-- clan_scop_t\n");

    /* A blank line. */
    for (j = 0; j <= level+1; j++)
      fprintf(file,"|\t");
    fprintf(file,"\n");

    /* Print the context of the scop. */
    clan_matrix_print_structure(file,scop->context,level+1);

    /* Print the original parameter names. */
    for (i = 0; i <= level; i++)
      fprintf(file,"|\t");
    if (scop->nb_parameters > 0)
    {
      fprintf(file,"+-- Original parameters strings:");
      for (i = 0; i < scop->nb_parameters; i++)
        fprintf(file," %s",scop->parameters[i]);
      fprintf(file,"\n");
    }
    else
      fprintf(file,"+-- No original parameters string\n");

    /* A blank line. */
    for (j = 0; j <= level+1; j++)
      fprintf(file,"|\t");
    fprintf(file,"\n");

    /* Print the original parameter names. */
    for (i = 0; i <= level; i++)
      fprintf(file,"|\t");
    if (scop->nb_arrays > 0)
    {
      fprintf(file,"+-- Accessed array strings:");
      for (i = 0; i < scop->nb_arrays; i++)
        fprintf(file," %s",scop->arrays[i]);
      fprintf(file,"\n");
    }
    else
      fprintf(file,"+-- No accessed array string\n");

    /* A blank line. */
    for (j = 0; j <= level+1; j++)
      fprintf(file,"|\t");
    fprintf(file,"\n");

    /* Print the statements. */
    clan_statement_print_structure(file,scop->statement,level+1);
  }
  else
  {
    /* Go to the right level. */
    for (j = 0; j < level; j++)
      fprintf(file,"|\t");
    fprintf(file,"+-- NULL scop\n");
  }

  /* The last line. */
  for (j = 0; j <= level; j++)
    fprintf(file,"|\t");
  fprintf(file,"\n");
}


/**
 * clan_scop_print function:
 * This function prints the content of a clan_scop_t structure (*scop) into
 * a file (file, possibly stdout).
 * \param file   File where informations are printed.
 * \param scop   The scop whose information have to be printed.
 **
 * - 30/04/2008: first version.
 */
void
clan_scop_print(FILE * file, clan_scop_p scop)
{
  clan_scop_print_structure(file,scop,0);
}


/**
 * clan_scop_print_dot_scop function:
 * This function prints the content of a clan_scop_t structure (*scop)
 * into a file (file, possibly stdout) for the .scop format.
 * \param file    File where informations are printed.
 * \param scop    The scop whose information have to be printed.
 * \param options Options for output file printing.
 **
 * - 02/05/2008: first version.
 */
void
clan_scop_print_dot_scop(FILE * file, clan_scop_p scop, clan_options_p options)
{
  int i;

  if (options->castle)
  {
    fprintf(file,"#                                                   \n");
    fprintf(file,"#          <|                                       \n");
    fprintf(file,"#           A                                       \n");
    fprintf(file,"#          /.\\                                     \n");
    fprintf(file,"#     <|  [\"\"M#                                   \n");
    fprintf(file,"#      A   | #              Clan McCloog Castle     \n");
    fprintf(file,"#     /.\\ [\"\"M#             [File generated by Clan");
    fprintf(file," %s %s bits]\n",CLAN_RELEASE,CLAN_VERSION);
    fprintf(file,"#    [\"\"M# | #  U\"U#U                            \n");
    fprintf(file,"#     | #  | #  \\ .:/                              \n");
    fprintf(file,"#     | #  | #___| #                                \n");
    fprintf(file,"#     | \"--'     .-\"                              \n");
    fprintf(file,"#   |\"-\"-\"-\"-\"-#-#-##                          \n");
    fprintf(file,"#   |     # ## ######                               \n");
    fprintf(file,"#    \\       .::::'/                               \n");
    fprintf(file,"#     \\      ::::'/                                \n");
    fprintf(file,"#   :8a|    # # ##                                  \n");
    fprintf(file,"#   ::88a      ###                                  \n");
    fprintf(file,"#  ::::888a  8a ##::.                               \n");
    fprintf(file,"#  ::::::888a88a[]::::                              \n");
    fprintf(file,"# :::::::::SUNDOGa8a::::. ..                        \n");
    fprintf(file,"# :::::8::::888:Y8888:::::::::...                   \n");
    fprintf(file,"#::':::88::::888::Y88a______________________________");
    fprintf(file,"________________________\n");
    fprintf(file,"#:: ::::88a::::88a:Y88a                             ");
    fprintf(file,"     __---__-- __\n");
    fprintf(file,"#' .: ::Y88a:::::8a:Y88a                            ");
    fprintf(file,"__----_-- -------_-__\n");
    fprintf(file,"#  :' ::::8P::::::::::88aa.                   _ _- -");
    fprintf(file,"-  --_ --- __  --- __--\n");
    fprintf(file,"#.::  :::::::::::::::::::Y88as88a...s88aa.\n");
  }
  else
  {
    fprintf(file,"# [File generated by Clan %s %s bits]\n",
            CLAN_RELEASE,CLAN_VERSION);
  }

  fprintf(file,"\n");
  fprintf(file,"SCoP\n");
  fprintf(file,"\n");
  fprintf(file,"# =============================================== Global\n");
  fprintf(file,"# Language\n");
  fprintf(file,"C\n");
  fprintf(file,"\n");

  fprintf(file,"# Context\n");
  clan_matrix_print_dot_scop(file,scop->context,CLAN_TYPE_DOMAIN,
                             0,NULL,
			     scop->nb_parameters,scop->parameters,
			     scop->nb_arrays,scop->arrays);
  fprintf(file,"\n");

  if (scop->nb_parameters > 0)
  {
    fprintf(file,"# Parameter names are provided\n");
    fprintf(file,"1\n");
    fprintf(file,"# Parameter names\n");
    for (i = 0; i < scop->nb_parameters; i++)
      fprintf(file,"%s ",scop->parameters[i]);
    fprintf(file,"\n");
    fprintf(file,"\n");
  }
  else
  {
    fprintf(file,"# Parameter names are not provided\n");
    fprintf(file,"0\n");
    fprintf(file,"\n");
  }

  fprintf(file,"# Number of statements\n");
  fprintf(file,"%d\n",clan_statement_number(scop->statement));
  fprintf(file,"\n");

  clan_statement_print_dot_scop(file,scop->statement,
                                scop->nb_parameters,scop->parameters,
			        scop->nb_arrays,scop->arrays);

  fprintf(file,"# =============================================== Options\n");
  fprintf(file,"<Comments>\n");
  fprintf(file,"\n");
  fprintf(file,"<\\Comments>\n");
  fprintf(file,"\n");
}


/******************************************************************************
 *                               Reading function                             *
 ******************************************************************************/

/**
 * Internal function. Read 'nb_strings' strings on the input 'file'.
 *
 * FIXME should be placed somewhere else, it's duplicated in scop.c.
 */
static
char**
clan_scop_read_strings(FILE* file, int nb_strings)
{
  char str[CLAN_MAX_STRING];
  char tmp[CLAN_MAX_STRING];
  char* s;
  char** res = NULL;
  int i;
  int count;

  /* Skip blank/commented lines. */
  while (fgets(str, CLAN_MAX_STRING, file) == 0 || str[0] == '#' ||
	 isspace(str[0]))
    ;
  s = str;

  /* Allocate the array of string. Make it NULL-terminated. */
  res = (char**) malloc(sizeof(char*) * (nb_strings + 1));
  res[nb_strings] = NULL;

  /* Read the desired number of strings. */
  for (i = 0; i < nb_strings; ++i)
    {
      for (count = 0; *s && ! isspace(*s) && *s != '#'; ++count)
	tmp[count] = *(s++);
      tmp[count] = '\0';
      res[i] = strdup(tmp);
      if (*s != '#')
	++s;
    }

  return res;
}

/**
 * Internal function. Read an int on the input 'file'.
 *
 * FIXME should be placed somewhere else, it's duplicated in statement.c.
 */
static
int
clan_scop_read_int(FILE* file)
{
  char s[CLAN_MAX_STRING];
  int res;

  /* Skip blank/commented lines. */
  while (fgets(s, CLAN_MAX_STRING, file) == 0 || s[0] == '#' ||
	 isspace(s[0]))
    ;
  sscanf(s, "%d", &res);

  return res;
}


/**
 * clan_scop_generate_names function:
 * This function generates an array of size 'nb' of chars of the form
 * "seedXX" where XX goes from 1 to nb.
 * \param seed		The template for the created names
 * \param nb		The number of created items.
 */
char**
clan_scop_generate_names(char* seed, int nb)
{
  char** res = NULL;
  char buff[strlen(seed) + 16];
  int i;

  if (nb)
    {
      res = (char**) malloc(sizeof(char*)* nb);
      if (res == NULL)
	{
	  fprintf(stderr, "[Clan] Memory Overflow.\n");
	  exit(1);
	}
      for (i = 0; i < nb; ++i)
	{
	  sprintf(buff, "%s%d", seed, i + 1);
	  res[i] = strdup(buff);
	}
    }

  return res;
}


/**
 * clan_scop_read function:
 * This function reads a clan_scop_t structure from an input stream
 * (possibly stdin) corresponding to a clan SCoP dump.
 * \param file		The input stream
 * \param options	Unused
 */
clan_scop_p
clan_scop_read(FILE* file, clan_options_p options)
{
  clan_scop_p scop = NULL;

  if (file != NULL)
    {
      scop = clan_scop_malloc();
      clan_statement_p stmt = NULL;
      clan_statement_p prev = NULL;
      int nb_statements;
      char** tmp;
      int i;
      /* Backup the arrays of the program. Buffer is reajustable. */
      int nb_arr = CLAN_MAX_STRING;
      char** arrays = (char**) malloc (sizeof(char*) * nb_arr);
      for (i = 0; i < nb_arr; ++i)
	arrays[i] = NULL;

      /* Ensure the file is a .scop. */
      tmp = clan_scop_read_strings(file, 1);
      if (strcmp(*tmp, "SCoP"))
	{
	  fprintf(stderr, "[Clan] Error. The file is not a .scop\n");
	  exit (1);
	}
      free(*tmp);
      free(tmp);

      /* Read the language. */
      char** language =  clan_scop_read_strings(file, 1);
      if (strcmp(*language, "C") && strcmp(*language, "JAVA") &&
	  strcmp(*language, "C#"))
	{
	  fprintf(stderr, "[Clan] Error. The language is not recognized\n");
	  exit (1);
	}
      /* language is not used so far. */
      free(*language);
      free(language);

      /* Read the context. */
      scop->context  = clan_matrix_read (file);
      scop->nb_parameters = scop->context->NbColumns - 2;

      /* Read the parameter names, if any. */
      if (clan_scop_read_int(file) > 0)
	scop->parameters = clan_scop_read_strings (file, scop->nb_parameters);
      else
	scop->parameters = clan_scop_generate_names("M", scop->nb_parameters);

      /* Read the number of statements. */
      nb_statements = clan_scop_read_int (file);

      for (i = 0; i < nb_statements; ++i)
	{
	  /* Read each statement. */
	  stmt = clan_statement_read (file, scop->nb_parameters,
				      &arrays, &nb_arr);
	  if (scop->statement == NULL)
	    scop->statement = stmt;
	  else
	    prev->next = stmt;
	  prev = stmt;
	}

      /* Count the number of referenced arrays/variables. */
      scop->nb_arrays = 0;
      for (stmt = scop->statement; stmt; stmt = stmt->next)
	{
	  if (stmt->read)
	    for (i = 0; i < stmt->read->NbRows; ++i)
	      if (scop->nb_arrays < CLAN_get_si(stmt->read->p[i][0]))
		scop->nb_arrays = CLAN_get_si(stmt->read->p[i][0]);
	  if (stmt->write)
	    for (i = 0; i < stmt->write->NbRows; ++i)
	      if (scop->nb_arrays < CLAN_get_si(stmt->write->p[i][0]))
		scop->nb_arrays = CLAN_get_si(stmt->write->p[i][0]);
	}

      /* Fill the array of array names. */
      scop->arrays = (char**) malloc(sizeof(char*) * (scop->nb_arrays + 1));
      char** tmparrays = clan_scop_generate_names("var", scop->nb_arrays);
      for (i = 0; i < scop->nb_arrays; ++i)
	{
	  if (arrays[i] == NULL || arrays[i][0] == '\0')
	    {
	      /* Use a generated name in case no array name was parsed. */
	      scop->arrays[i] = tmparrays[i];
	      if (arrays[i])
		free(arrays[i]);
	    }
	  else
	    {
	      /* Use the parsed array name. */
	      scop->arrays[i] = arrays[i];
	      free(tmparrays[i]);
	    }
	}
      scop->arrays[i] = NULL;
      free(arrays);
      free(tmparrays);
    }

  return scop;
}



/*+****************************************************************************
 *                   Memory allocation/deallocation functions                 *
 ******************************************************************************/


/**
 * clan_scop_malloc function:
 * This function allocates the memory space for a clan_scop_t structure and
 * sets its fields with default values. Then it returns a pointer to the
 * allocated space.
 **
 * - 30/04/2008: first version.
 */
clan_scop_p
clan_scop_malloc()
{
  clan_scop_p scop;

  scop = (clan_scop_p)malloc(sizeof(clan_scop_t));
  if (scop == NULL)
  {
    fprintf(stderr, "[Clan] Memory Overflow.\n");
    exit(1);
  }

  scop->context       = NULL;
  scop->nb_parameters = 0;
  scop->parameters    = NULL;
  scop->nb_arrays     = 0;
  scop->arrays        = NULL;
  scop->statement     = NULL;

  return scop;
}


/**
 * clan_scop_free function:
 * This function frees the allocated memory for a clan_scop_t structure.
 * \param scop The pointer to the scop we want to free.
 **
 * - 30/04/2008: first version.
 */
void
clan_scop_free(clan_scop_p scop)
{
 int i;

  if (scop != NULL)
  {
    clan_matrix_free(scop->context);
    if (scop->parameters != NULL)
    {
      for (i = 0; i < scop->nb_parameters; i++)
        free(scop->parameters[i]);
      free(scop->parameters);
    }
    if (scop->arrays != NULL)
    {
      for (i = 0; i < scop->nb_arrays; i++)
        free(scop->arrays[i]);
      free(scop->arrays);
    }
    clan_statement_free(scop->statement);
    free(scop);
  }
}


/*+****************************************************************************
 *                            Processing functions                            *
 ******************************************************************************/


clan_scop_p
clan_parse(FILE *, clan_options_p);

/**
 * clan_scop_extract function:
 * this function is a wrapper clan_parse function that parses a file to
 * extract a SCoP and returns, if successful, a pointer to the clan_scop_t
 * structure.
 * \param input   The file to parse (already open).
 * \param options Options for file parsing.
 **
 * - 24/05/2008: First version.
 */
clan_scop_p
clan_scop_extract(FILE * input, clan_options_p options)
{
  return clan_parse(input,options);
}


/**
 * clan_scop_compact function:
 * This function scans the SCoP to put the right number of columns to every
 * matrix (during construction we used CLAN_MAX_DEPTH and CLAN_MAX_PARAMETERS
 * to define matrix and vector sizes).
 * \param scop The scop to scan to compact matrices.
 **
 * - 02/05/2008: first version.
 */
void
clan_scop_compact(clan_scop_p scop)
{
  clan_statement_compact(scop->statement,scop->nb_parameters);
}

