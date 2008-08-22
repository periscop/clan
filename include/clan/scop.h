
   /*+------- <| --------------------------------------------------------**
    **         A                     Clan                                **
    **---     /.\   -----------------------------------------------------**
    **   <|  [""M#                  scop.h                               **
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


#ifndef CLAN_SCOP_H
# define CLAN_SCOP_H

# include <unistd.h>

# include <clan/macros.h>
# include <clan/matrix.h>
# include <clan/statement.h>
# include <clan/options.h>

# if defined(__cplusplus)
extern "C"
  {
# endif


/**
 * The clan_scop_t structure stores the useful informations of a static
 * control part of a program to process it within a polyhedral framework.
 */
struct clan_scop
{
  clan_matrix_p context;      /**< Constraints on the SCoP parameters */
  int nb_parameters;          /**< Number of parameters for the SCoP */
  char ** parameters;         /**< Array of (nb_parameters) parameter names */
  int nb_arrays;              /**< Number of arrays accessed in the SCoP */
  char ** arrays;             /**< Array of (nb_arrays) array names */
  clan_statement_p statement; /**< Statement list of the SCoP */
  char* optiontags;	      /**< The content (as a 0 terminated
				 string) of the optional tags. */
  void* usr;		      /**< A user-defined field, not touched
				 by clan. */
};
typedef struct clan_scop   clan_scop_t;
typedef struct clan_scop * clan_scop_p;


/*+****************************************************************************
 *                          Structure display function                        *
 ******************************************************************************/
void        clan_scop_print_structure(FILE *, clan_scop_p, int);
void        clan_scop_print(FILE *, clan_scop_p);
void        clan_scop_print_dot_scop(FILE *, clan_scop_p, clan_options_p);


/******************************************************************************
 *                               Reading function                             *
 ******************************************************************************/
clan_scop_p clan_scop_read(FILE *, clan_options_p);
char*	    clan_scop_tag_content(clan_scop_p, char*, char*);
char*	    clan_scop_tag_content_from_string(char*, char*, char*);


/*+****************************************************************************
 *                    Memory allocation/deallocation function                 *
 ******************************************************************************/
clan_scop_p clan_scop_malloc();
void        clan_scop_free(clan_scop_p);


/*+****************************************************************************
 *                            Processing functions                            *
 ******************************************************************************/
clan_scop_p clan_scop_extract(FILE *, clan_options_p);
void        clan_scop_compact(clan_scop_p);
char**	    clan_scop_generate_names(char*, int);


# if defined(__cplusplus)
  }
# endif
#endif /* define CLAN_SCOP_H */
