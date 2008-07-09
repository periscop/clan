
   /*+------- <| --------------------------------------------------------**
    **         A                     Clan                                **       
    **---     /.\   -----------------------------------------------------**    
    **   <|  [""M#                statement.c                            **  
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
# include "../include/clan/clan.h"


/*+****************************************************************************
 *                         Structure display functions                        *
 ******************************************************************************/


/**
 * clan_statement_print_structure function:
 * Displays a clan_statement_t structure (*statement) into a file (file,
 * possibly stdout) in a way that trends to be understandable without falling
 * in a deep depression or, for the lucky ones, getting a headache... It
 * includes an indentation level (level) in order to work with others
 * print_structure functions.
 * \param file      File where informations are printed.
 * \param statement The statement whose information have to be printed.
 * \param level     Number of spaces before printing, for each line.
 **
 * - 30/04/2008: first version.
 */
void
clan_statement_print_structure(FILE * file, clan_statement_p statement,
                               int level)
{
  int i, j, first = 1, number = 1;

  if (statement != NULL)
  {
    /* Go to the right level. */
    for (j = 0; j < level; j++)
      fprintf(file,"|\t");
    fprintf(file,"+-- clan_statement_t (S%d)\n",number);
  }
  else
  {
    /* Go to the right level. */
    for (j = 0; j < level; j++)
      fprintf(file,"|\t");
    fprintf(file,"+-- NULL statement\n");
  }
  
  while (statement != NULL)
  { if (!first)
    {
      /* Go to the right level. */
      for (j = 0; j < level; j++)
        fprintf(file,"|\t");
      fprintf(file,"|   clan_statement_t (S%d)\n",number);
    }
    else
      first = 0;
      
    /* A blank line. */
    for (j = 0; j <= level+1; j++)
      fprintf(file,"|\t");
    fprintf(file,"\n");

    /* Print the domain of the statement. */
    clan_matrix_print_structure(file,statement->domain,level+1);

    /* Print the schedule of the statement. */
    clan_matrix_print_structure(file,statement->schedule,level+1);

    /* Print the array read access informations of the statement. */
    clan_matrix_print_structure(file,statement->read,level+1);

    /* Print the array write access informations of the statement. */
    clan_matrix_print_structure(file,statement->write,level+1);

    /* Print the original iterator names. */
    for (i=0; i<=level; i++)
      fprintf(file,"|\t");
    if (statement->nb_iterators > 0)
    {
      fprintf(file,"+-- Original iterator strings:");
      for (i = 0; i < statement->nb_iterators; i++)
        fprintf(file," %s",statement->iterators[i]);
      fprintf(file,"\n");
    }
    else
      fprintf(file,"+-- No original iterator string\n");

    /* A blank line. */
    for (i = 0; i <= level+1; i++)
      fprintf(file,"|\t");
    fprintf(file,"\n");

    /* Print the original statement body. */
    for (i = 0; i <= level; i++)
      fprintf(file,"|\t");
    if (statement->body != NULL)
      fprintf(file,"+-- Original body: %s\n",statement->body);
    else
      fprintf(file,"+-- No original body\n");

    /* A blank line. */
    for (i = 0; i <= level+1; i++)
      fprintf(file,"|\t");
    fprintf(file,"\n");

    statement = statement->next;
    number++;
    
    /* Next line. */
    if (statement != NULL)
    {
      for (j = 0; j <= level; j++)
        fprintf(file,"|\t");  
      fprintf(file,"V\n");
    }
  }

  /* The last line. */
  for (j = 0; j <= level; j++)
    fprintf(file,"|\t");
  fprintf(file,"\n");
}


/**
 * clan_statement_print function:
 * This function prints the content of a clan_statement_t structure
 * (*statement) into  a file (file, possibly stdout).
 * \param file      File where informations are printed.
 * \param statement The statement whose information have to be printed.
 **
 * - 30/04/2008: first version.
 */
void
clan_statement_print(FILE * file, clan_statement_p statement)
{ 
  clan_statement_print_structure(file,statement,0);
}


/**
 * clan_statement_print_dot_scop function:
 * This function prints the content of a clan_statement_t structure
 * (*statement) into a file (file, possibly stdout) for the .scop format.
 * \param file          File where informations are printed.
 * \param statement     The statement whose information have to be printed.
 * \param nb_parameters The number of parameters in the SCoP.
 * \param parameters    An array containing all parameters names.
 * \param nb_arrays     The number of arrays accessed in the SCoP.
 * \param arrays        An array containing all accessed array names.
 **
 * - 02/05/2008: first version.
 */
void
clan_statement_print_dot_scop(FILE * file, clan_statement_p statement,
                              int nb_parameters, char ** parameters,
			      int nb_arrays, char ** arrays)
{ 
  int i, number = 1;

  while (statement != NULL)
  {
    fprintf(file,"# =============================================== ");
    fprintf(file,"Statement %d\n",number);
   
    fprintf(file,"# ---------------------------------------------- ");
    fprintf(file,"%2d.1 Domain\n",number);
    fprintf(file,"# Iteration domain\n");
    fprintf(file,"1\n");
    clan_matrix_print_dot_scop(file,statement->domain,CLAN_TYPE_DOMAIN,
                               statement->nb_iterators,statement->iterators,
                               nb_parameters,parameters,
			       nb_arrays,arrays);
    fprintf(file,"\n");  
    
    fprintf(file,"# ---------------------------------------------- ");
    fprintf(file,"%2d.2 Scattering\n",number);
    fprintf(file,"# Scattering function is provided\n");
    fprintf(file,"1\n");
    fprintf(file,"# Scattering function\n");
    clan_matrix_print_dot_scop(file,statement->schedule,CLAN_TYPE_SCATTERING,
                               statement->nb_iterators,statement->iterators,
                               nb_parameters,parameters,
			       nb_arrays,arrays);
    fprintf(file,"\n");  
    
    fprintf(file,"# ---------------------------------------------- ");
    fprintf(file,"%2d.3 Access\n",number);
    fprintf(file,"# Access informations are provided\n");
    fprintf(file,"1\n");
    fprintf(file,"# Read access informations\n");
    clan_matrix_print_dot_scop(file,statement->read,CLAN_TYPE_ACCESS,
                               statement->nb_iterators,statement->iterators,
                               nb_parameters,parameters,
			       nb_arrays,arrays);
    fprintf(file,"# Write access informations\n");
    clan_matrix_print_dot_scop(file,statement->write,CLAN_TYPE_ACCESS,
                               statement->nb_iterators,statement->iterators,
                               nb_parameters,parameters,
			       nb_arrays,arrays);
    fprintf(file,"\n");  
         
    fprintf(file,"# ---------------------------------------------- ");
    fprintf(file,"%2d.4 Body\n",number);
    fprintf(file,"# Statement body is provided\n");
    fprintf(file,"1\n");
    if (statement->nb_iterators > 0)
    {
      fprintf(file,"# Original iterator names\n");
      for (i = 0; i < statement->nb_iterators; i++)
        fprintf(file,"%s ",statement->iterators[i]);
      fprintf(file,"\n");
    }
    else
      fprintf(file,"# No original iterator names\n");
    fprintf(file,"# Statement body\n");
    fprintf(file,"%s\n",statement->body);
    fprintf(file,"\n\n");  

    statement = statement->next;
    number++;
  }
}


/*+****************************************************************************
 *                   Memory allocation/deallocation functions                 *
 ******************************************************************************/


/**
 * clan_statement_malloc function:
 * This function allocates the memory space for a clan_statement_t structure
 * and sets its fields with default values. Then it returns a pointer to the
 * allocated space.
 **
 * - 30/04/2008: first version.
 */
clan_statement_p
clan_statement_malloc()
{
  clan_statement_p statement;
  
  statement = (clan_statement_p)malloc(sizeof(clan_statement_t));
  if (statement == NULL) 	
  {
    fprintf(stderr, "[Clan] Memory Overflow.\n");
    exit(1);
  }

  statement->domain    = NULL;
  statement->schedule  = NULL;
  statement->read      = NULL;
  statement->write     = NULL;
  statement->nb_iterators = 0;
  statement->iterators = NULL;
  statement->body      = NULL;
  statement->next      = NULL;
  
  return statement;
}


/**
 * clan_statement_free function:
 * This function frees the allocated memory for a clan_statement_t structure.
 * \param statement The pointer to the statement we want to free.
 **
 * - 30/04/2008: first version.
 */
void
clan_statement_free(clan_statement_p statement)
{ 
  int i;
  clan_statement_p next;
  
  while (statement != NULL)
  {
    next = statement->next;
    clan_matrix_free(statement->domain);
    clan_matrix_free(statement->schedule);
    clan_matrix_free(statement->read);
    clan_matrix_free(statement->write);
    if (statement->iterators != NULL)
    {
      for (i = 0; i < statement->nb_iterators; i++)
        free(statement->iterators[i]);
      free(statement->iterators);
    }
    if (statement->body != NULL)
      free(statement->body);
    free(statement);
    statement = next;
  }
}


/*+****************************************************************************
 *                            Processing functions                            *
 ******************************************************************************/


/**
 * clan_statement_add function:
 * This function adds a statement "statement" at the end of the statement
 * list pointed by "location". 
 * \param location  Address of the first element of the statement list.
 * \param statement The statement to add to the list.
 **
 * - 30/04/2008: first version.
 */
void
clan_statement_add(clan_statement_p * location, clan_statement_p statement)
{
  while (*location != NULL)
    location = &((*location)->next);
  
  *location = statement;
}


/**
 * clan_statement_compact function:
 * This function scans the statement list to put the right number of columns
 * to every matrix (during construction we used CLAN_MAX_DEPTH and
 * CLAN_MAX_PARAMETERS to define matrix and vector sizes). 
 * \param statement     The first statement to scan to compact matrices.
 * \param nb_parameters The true number of parameters in the SCoP.
 **
 * - 02/05/2008: first version.
 */
void
clan_statement_compact(clan_statement_p statement, int nb_parameters)
{ 
  int nb_iterators;
  
  while (statement != NULL)
  {
    nb_iterators = statement->nb_iterators;
    clan_matrix_compact(statement->domain,nb_iterators,nb_parameters);
    clan_matrix_compact(statement->schedule,nb_iterators,nb_parameters);
    clan_matrix_compact(statement->read,nb_iterators,nb_parameters);
    clan_matrix_compact(statement->write,nb_iterators,nb_parameters);
    statement = statement->next;
  }
}


/**
 * clan_statement_number function:
 * This function returns the number of statements in the statement list
 * provided as parameter. 
 * \param statement The first element of the statement list.
 **
 * - 03/05/2008: first version.
 */
int
clan_statement_number(clan_statement_p statement)
{ 
  int number = 0;
  
  while (statement != NULL)
  {
    number++;
    statement = statement->next;
  }
  return number;
}



















