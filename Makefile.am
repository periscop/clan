#
#   /**------- <| --------------------------------------------------------**
#    **         A                     Clan                                **       
#    **---     /.\   -----------------------------------------------------**    
#    **   <|  [""M#                makefile.am                            **  
#    **-   A   | #   -----------------------------------------------------**
#    **   /.\ [""M#         First version: 30/04/2008                     **
#    **- [""M# | #  U"U#U  -----------------------------------------------**        
#         | #  | #  \ .:/    
#         | #  | #___| #     
# ******  | "--'     .-"  *****************************************************
# *     |"-"-"-"-"-#-#-##   Clan : the Chunky Loop Analyser (experimental)    *
# ****  |     # ## ######  ****************************************************
# *      \       .::::'/                                                      *
# *       \      ::::'/     Copyright (C) 2008 Cedric Bastoul                 *
# *     :8a|    # # ##                                                        *
# *     ::88a      ###      This is free software; you can redistribute it    *
# *    ::::888a  8a ##::.   and/or modify it under the terms of the GNU       *
# *  ::::::::888a88a[]:::   Lesser General Public License as published by     *
# *::8:::::::::SUNDOGa8a::. the Free Software Foundation, either version 3 of *
# *::::::::8::::888:Y8888::                the License, or (at your option)   *
# *::::':::88::::888::Y88a::::::::::::...  any later version.                 *
# *::'::..    .   .....   ..   ...  .                                         *
# * This software is distributed in the hope that it will be useful, but      *
# * WITHOUT ANY WARRANTY; without even the implied warranty of                *
# * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General *
# * Public License  for more details.	                                      *
# *                                                                           *
# * You should have received a copy of the GNU Lesser General Public          *
# * License along with software; if not, write to the Free Software           *
# * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA  *
# *                                                                           *
# * Clan, the Chunky Loop Analyser                                            *
# * Written by Cedric Bastoul, Cedric.Bastoul@inria.fr                        *
# *                                                                           *
# *****************************************************************************/
#
# makefile.am (or makefile if generated) of Clan, the Chunky Loop Analyser.
# makefile.am is not a makefile, you must run the 'autogen.sh' shellscript to
# generate the makefile thanks to this file.


bin_PROGRAMS = clan
lib_LTLIBRARIES = libclan.la

INCLUDES = -I$(top_builddir)/include -I$(top_srcdir)/include
AM_CFLAGS = -Wall -fomit-frame-pointer -g 
libclan_la_SOURCES = \
	source/parser.y \
	source/scanner.l \
	source/options.c \
	source/symbol.c \
	source/scop.c \
	source/statement.c \
	source/matrix.c \
	source/vector.c
LDADD = libclan.la

clan_SOURCES = source/clan.c
YFLAGS = -y -d

pkginclude_HEADERS = \
	include/clan/clan.h

#/*****************************************************************************
# *                                   Rules                                   *
# *****************************************************************************/

doc:
	@echo "             /*-----------------------------------------------*"
	@echo "              *        Generating Clan's documentation        *"
	@echo "              *-----------------------------------------------*/"
	doxygen ./autoconf/Doxyfile
