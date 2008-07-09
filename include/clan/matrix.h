
   /*+------- <| --------------------------------------------------------**
    **         A                     Clan                                **       
    **---     /.\   -----------------------------------------------------**    
    **   <|  [""M#                 matrix.h                              **  
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


#ifndef CLAN_MATRIX_H
#define CLAN_MATRIX_H
#if defined(__cplusplus)
extern "C" 
  {
#endif 


/**
 * The clan_matrix_t structure stores a matrix information in the PolyLib
 * format (the first entry of each row has a specific meaning). When a row
 * describes a linear constraint, a 0 means it is an equality == 0, a 1 means
 * an inequality >= 0. When a row describes an array access, a number different
 * than 0 is the array identifier (the remainder of the row describes the
 * access function of the first dimension of this array), otherwise it means
 * the row describes access functions for next array dimensions.
 */
struct clan_matrix
{
  unsigned NbRows;    /**< The number of rows */
  unsigned NbColumns; /**< The number of columns */
  Value ** p;         /**< An array of pointers to the beginning of each row */
  Value * p_Init;     /**< The matrix is stored here, contiguously in memory */
  int p_Init_size;    /**< Needed to free the memory allocated by mpz_init. */
};
typedef struct clan_matrix   clan_matrix_t;
typedef struct clan_matrix * clan_matrix_p;


/*+****************************************************************************
 *                          Structure display function                        *
 ******************************************************************************/
void          clan_matrix_print_structure(FILE *, clan_matrix_p, int);
void          clan_matrix_print(FILE *, clan_matrix_p);
void          clan_matrix_print_dot_scop(FILE *, clan_matrix_p, int,
                                         int, char **, int, char **,
					 int, char **);


/*+****************************************************************************
 *                    Memory allocation/deallocation function                 *
 ******************************************************************************/
clan_matrix_p clan_matrix_malloc(unsigned, unsigned);
void          clan_matrix_free(clan_matrix_p);


/*+****************************************************************************
 *                            Processing functions                            *
 ******************************************************************************/
clan_matrix_p clan_matrix_ncopy(clan_matrix_p, int);
clan_matrix_p clan_matrix_copy(clan_matrix_p);
void          clan_matrix_replace_vector(clan_matrix_p, clan_vector_p, int);
void          clan_matrix_insert_vector(clan_matrix_p, clan_vector_p, int);
clan_matrix_p clan_matrix_from_vector(clan_vector_p);
void          clan_matrix_replace_matrix(clan_matrix_p, clan_matrix_p, int);
void          clan_matrix_insert_matrix(clan_matrix_p, clan_matrix_p, int);
clan_matrix_p clan_matrix_concat(clan_matrix_p, clan_matrix_p);
void          clan_matrix_tag_array(clan_matrix_p, int);
clan_matrix_p clan_matrix_scheduling(int *, int);
void          clan_matrix_compact(clan_matrix_p, int, int);

#if defined(__cplusplus)
  }
#endif 
#endif /* define CLAN_MATRIX_H */
