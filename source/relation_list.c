
   /*+------- <| --------------------------------------------------------**
    **         A                     Clan                                **
    **---     /.\   -----------------------------------------------------**
    **   <|  [""M#              relation_list.c                          **
    **-   A   | #   -----------------------------------------------------**
    **   /.\ [""M#         First version: 16/04/2011                     **
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

#include <osl/relation_list.h>
#include <clan/relation.h>
#include <clan/relation_list.h>


/*+****************************************************************************
 *                            Processing functions                            *
 ******************************************************************************/


/**
 * clan_relation_lit_compact function:
 * This function compacts a relation list such that each relation inside
 * uses the right number of columns (during construction we used
 * CLAN_MAX_DEPTH and CLAN_MAX_PARAMETERS to define relation and vector sizes).
 * It modifies directly the relation list provided as parameter.
 * \param list          The relation list to compact.
 * \param nb_iterators  The true number of iterators for this relation.
 * \param nb_parameters The true number of parameters in the SCoP.
 */
void clan_relation_list_compact(osl_relation_list_p list, int nb_iterators, 
		                int nb_parameters) {
  while (list != NULL) {
     clan_relation_compact(list->elt, nb_iterators, nb_parameters);
     list = list->next;
  }
}
