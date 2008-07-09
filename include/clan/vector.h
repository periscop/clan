
   /*+------- <| --------------------------------------------------------**
    **         A                     Clan                                **       
    **---     /.\   -----------------------------------------------------**    
    **   <|  [""M#                 vector.h                              **  
    **-   A   | #   -----------------------------------------------------**
    **   /.\ [""M#         First version: 01/05/2008                     **
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


#ifndef CLAN_VECTOR_H
#define CLAN_VECTOR_H
#if defined(__cplusplus)
extern "C" 
  {
#endif 


/**
 * The clan_vector_t structure stores a vector information in the PolyLib
 * format (the first entry has a specific meaning). When a vector
 * describes a linear constraint, a 0 means it is an equality == 0, a 1 means
 * an inequality >= 0. When the vector describes an array access, a number
 * different than 0 is the array identifier.
 */
struct clan_vector
{
  unsigned Size;  /**< The number of vector entries */
  Value * p;      /**< An array of values */
};
typedef struct clan_vector   clan_vector_t;
typedef struct clan_vector * clan_vector_p;


/*+****************************************************************************
 *                          Structure display function                        *
 ******************************************************************************/
void          clan_vector_print_structure(FILE *, clan_vector_p, int);
void          clan_vector_print(FILE *, clan_vector_p);


/*+****************************************************************************
 *                    Memory allocation/deallocation function                 *
 ******************************************************************************/
clan_vector_p clan_vector_malloc(unsigned);
void          clan_vector_free(clan_vector_p);


/*+****************************************************************************
 *                            Processing functions                            *
 ******************************************************************************/
clan_vector_p clan_vector_term(clan_symbol_p, int, char *);
clan_vector_p clan_vector_add_scalar(clan_vector_p, int);
clan_vector_p clan_vector_add(clan_vector_p, clan_vector_p);
clan_vector_p clan_vector_sub(clan_vector_p, clan_vector_p);
void          clan_vector_tag_inequality(clan_vector_p);
void          clan_vector_tag_equality(clan_vector_p);

#if defined(__cplusplus)
  }
#endif 
#endif /* define CLAN_VECTOR_H */
