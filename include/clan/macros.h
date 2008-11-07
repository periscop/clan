
   /*+------- <| --------------------------------------------------------**
    **         A                     Clan                                **
    **---     /.\   -----------------------------------------------------**
    **   <|  [""M#                 macros.h                              **
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

#ifndef CLAN_MACROS_H
# define CLAN_MACROS_H


# if defined(LINEAR_VALUE_IS_LONGLONG)
#  define CLAN_FMT     "%4lld"
#  define CLAN_FMT_TXT "%lld"
#  define clan_int_t long long

# elif defined(LINEAR_VALUE_IS_LONG)
#  define CLAN_FMT     "%4ld"
#  define CLAN_FMT_TXT "%ld"
#  define clan_int_t long int

# elif defined(LINEAR_VALUE_IS_MP)  /* GNUMP */
#  define CLAN_FMT     "%4s"
#  define CLAN_FMT_TXT "%s"
#  define clan_int_t mpz_t

# else
#  error Define LINEAR_VALUE_IS_xxx to use this file.

# endif

# define CLAN_DEBUG             1 /* Set to 1 for debug mode, 0 otherwise */

# define CLAN_MAX_STRING     1024 /* Max string length (e.g. stmt bodies) */
# define CLAN_MAX_DEPTH         5 /* Max loop depth (max iterator number) */
# define CLAN_MAX_PARAMETERS    5 /* Max parameter number */
# define CLAN_MAX_CONSTRAINTS  10 /* Max contraint number for a domain */
# define CLAN_TRUE              1
# define CLAN_FALSE             0
# define CLAN_END              -1 /* Must be negative */
# define CLAN_TYPE_ITERATOR     1
# define CLAN_TYPE_PARAMETER    2
# define CLAN_TYPE_ARRAY        3
# define CLAN_TYPE_FUNCTION     4
# define CLAN_TYPE_DOMAIN       6
# define CLAN_TYPE_SCATTERING   7
# define CLAN_TYPE_ACCESS       8
# define CLAN_TYPE_UNKNOWN      9


/*+****************************************************************************
 *                              CLAN GMP MACROS                               *
 ******************************************************************************/
# ifdef LINEAR_VALUE_IS_MP
/* Basic Macros */
#  define CLAN_init(val)                (mpz_init((val)))
#  define CLAN_assign(v1,v2)            (mpz_set((v1),(v2)))
#  define CLAN_set_si(val,i)            (mpz_set_si((val),(i)))
#  define CLAN_get_si(val)              (mpz_get_si((val)))
#  define CLAN_init_set_si(val,i)       (mpz_init_set_si((val),(i)))
#  define CLAN_clear(val)               (mpz_clear((val)))
#  define CLAN_print(Dst,fmt,val)       { char *str; \
                                        str = mpz_get_str(0,10,(val)); \
                                        fprintf((Dst),(fmt),str); free(str); \
                                        }
#  define CLAN_sprint(Dst,fmt,val)      { char * str; \
                                        str = mpz_get_str(0,10,(val)); \
                                        sprintf((Dst),(fmt),str); free(str); \
                                        }

/* Boolean operators on 'clan_int_t' */
#  define CLAN_eq(v1,v2)                (mpz_cmp((v1),(v2)) == 0)
#  define CLAN_ne(v1,v2)                (mpz_cmp((v1),(v2)) != 0)

/* Binary operators on 'clan_int_t' */
#  define CLAN_increment(ref,val)       (mpz_add_ui((ref),(val),1))
#  define CLAN_addto(ref,val1,val2)     (mpz_add((ref),(val1),(val2)))
#  define CLAN_add_int(ref,val,vint)    (mpz_add_ui((ref),(val),(long)(vint)))
#  define CLAN_subtract(ref,val1,val2)  (mpz_sub((ref),(val1),(val2)))
#  define CLAN_oppose(ref,val)          (mpz_neg((ref),(val)))

/* Conditional operations on 'clan_int_t' */
#  define CLAN_pos_p(val)               (mpz_sgn(val) >  0)
#  define CLAN_neg_p(val)               (mpz_sgn(val) <  0)
#  define CLAN_zero_p(val)              (mpz_sgn(val) == 0)
#  define CLAN_notzero_p(val)           (mpz_sgn(val) != 0)
#  define CLAN_one_p(val)               (mpz_cmp_si(val,1)  == 0)
#  define CLAN_mone_p(val)              (mpz_cmp_si(val,-1) == 0)

/*+****************************************************************************
 *                           CLAN BASIC TYPES MACROS                          *
 ******************************************************************************/
# else
/* Basic Macros */
#  define CLAN_init(val)                ((val) = 0)
#  define CLAN_assign(v1,v2)            ((v1)  = (v2))
#  define CLAN_set_si(val,i)            ((val) = (clan_int_t)(i))
#  define CLAN_get_si(val)              ((val))
#  define CLAN_init_set_si(val,i)       ((val) = (clan_int_t)(i))
#  define CLAN_clear(val)               ((val) = 0)
#  define CLAN_print(Dst,fmt,val)       (fprintf((Dst),(fmt),(val)))
#  define CLAN_sprint(Dst,fmt,val)      (sprintf((Dst),(fmt),(val)))

/* Boolean operators on 'clan_int_t' */
#  define CLAN_eq(v1,v2)                ((v1)==(v2))
#  define CLAN_ne(v1,v2)                ((v1)!=(v2))
#  define CLAN_lt(v1,v2)                ((v1)<(v2))
#  define CLAN_gt(v1,v2)                ((v1)>(v2))

/* Binary operators on 'clan_int_t' */
#  define CLAN_increment(ref,val)       ((ref) = (val)+(clan_int_t)(1))
#  define CLAN_addto(ref,val1,val2)     ((ref) = (val1)+(val2))
#  define CLAN_add_int(ref,val,vint)    ((ref) = (val)+(clan_int_t)(vint))
#  define CLAN_subtract(ref,val1,val2)  ((ref) = (val1)-(val2))
#  define CLAN_oppose(ref,val)          ((ref) = (-(val)))

/* Conditional operations on 'clan_int_t' */
#  define CLAN_pos_p(val)               CLAN_gt(val,0)
#  define CLAN_neg_p(val)               CLAN_lt(val,0)
#  define CLAN_zero_p(val)              CLAN_eq(val,0)
#  define CLAN_notzero_p(val)           CLAN_ne(val,0)
#  define CLAN_one_p(val)               CLAN_eq(val,1)
#  define CLAN_mone_p(val)              CLAN_eq(val,-1)

# endif

#endif /* define CLAN_MACROS_H */
