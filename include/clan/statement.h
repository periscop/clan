
   /*+------- <| --------------------------------------------------------**
    **         A                     Clan                                **       
    **---     /.\   -----------------------------------------------------**    
    **   <|  [""M#                statement.h                            **  
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


#ifndef CLAN_STATEMENT_H
#define CLAN_STATEMENT_H
#if defined(__cplusplus)
extern "C" 
  {
#endif 


/**
 * The clan_statement_t structure stores the useful informations of a given
 * statement to process it within a polyhedral framework.
 */
struct clan_statement
{
  clan_matrix_p domain;         /**< Iteration domain of the statement */
  clan_matrix_p schedule;       /**< Scheduling function for the statement */
  clan_matrix_p read;           /**< Array read access informations */
  clan_matrix_p write;          /**< Array write access informations */
  int nb_iterators;             /**< Original depth of the statement */
  char ** iterators;            /**< Array of (nb_iterators) iterator names */
  char * body;                  /**< Original statement body */
  struct clan_statement * next; /**< Next statement in the linked list */
};
typedef struct clan_statement   clan_statement_t;
typedef struct clan_statement * clan_statement_p;


/*+****************************************************************************
 *                          Structure display function                        *
 ******************************************************************************/
void             clan_statement_print_structure(FILE *, clan_statement_p, int);
void             clan_statement_print(FILE *, clan_statement_p);
void             clan_statement_print_dot_scop(FILE *, clan_statement_p,
                                               int, char **, int, char **);


/*+****************************************************************************
 *                    Memory allocation/deallocation function                 *
 ******************************************************************************/
clan_statement_p clan_statement_malloc();
void             clan_statement_free(clan_statement_p);


/*+****************************************************************************
 *                            Processing functions                            *
 ******************************************************************************/
void             clan_statement_add(clan_statement_p *, clan_statement_p);
void             clan_statement_compact(clan_statement_p, int);
int              clan_statement_number(clan_statement_p);


#if defined(__cplusplus)
  }
#endif 
#endif /* define CLAN_STATEMENT_H */
