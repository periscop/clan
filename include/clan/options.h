
   /*+------- <| --------------------------------------------------------**
    **         A                     Clan                                **
    **---     /.\   -----------------------------------------------------**
    **   <|  [""M#                options.h                              **
    **-   A   | #   -----------------------------------------------------**
    **   /.\ [""M#         First version: 24/05/2008                     **
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


#ifndef CLAN_OPTIONS_H
# define CLAN_OPTIONS_H

# include <stdio.h>

# if defined(__cplusplus)
extern "C"
  {
# endif


/**
 * The clan_options_t structure stores the software/library options for all
 * functions. They are not too many for now, but they will come someday...
 */
struct clan_options
{
  char* name ;    /**< Name of the input file. */
  int castle;     /**< 1 to put the Clan castle in output, 0 otherwise. */
  int structure;  /**< 1 to print the clan_scop structure, 0 otherwise. */
  int autoscop;   /**< 1 to extract SCoPs automatically, 0 otherwise. */
  int autopragma; /**< 1 to output the same code as input but with SCoP
                       pragmas automatically inserted, 0 otherwise. */
  int autoinsert; /**< Same as autopragma, but the original code is updated. */
  int inputscop;  /**< 1 to read a .scop on the input, 0 to read a
                      source file (default). */
  int precision;  /**< 0 for GMP, 32 for 32 bits, 64 for 64 bits. */
  int bounded_context; /**< 1 to force global parameters >= -1 (default 0) */
  int noloopcontext;   /**< 1 to avoid inserting loop context (default 0) */
  int nosimplify;      /**< 1 to avoid simplifying domains (default 0) */

  int outscoplib;      /**< 1 print to the SCoPLib format (default 0) */

  int extbody;    /**< 1 to generate the extbody (default 0) */
};
typedef struct clan_options  clan_options_t;
typedef struct clan_options* clan_options_p;


/*+****************************************************************************
 *                          Structure display function                        *
 ******************************************************************************/
void           clan_options_print(FILE*, clan_options_p);


/*+****************************************************************************
 *                    Memory allocation/deallocation function                 *
 ******************************************************************************/
clan_options_p clan_options_malloc();
void           clan_options_free(clan_options_p);


/*+****************************************************************************
 *                               Reading function                             *
 ******************************************************************************/
clan_options_p clan_options_read(int, char**, char***, FILE**);


/*+****************************************************************************
 *                            Processing functions                            *
 ******************************************************************************/


# if defined(__cplusplus)
  }
# endif
#endif /* define CLAN_OPTIONS_H */
