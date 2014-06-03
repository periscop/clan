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
# *       \      ::::'/     Copyright (C) 2008 University Paris-Sud 11        *
# *     :8a|    # # ##                                                        *
# *     ::88a      ###      This is free software; you can redistribute it    *
# *    ::::888a  8a ##::.   and/or modify it under the terms of the GNU       *
# *  ::::::::888a88a[]:::   Lesser General Public License as published by     *
# *::8:::::::::SUNDOGa8a::. the Free Software Foundation, either version 2.1  *
# *::::::::8::::888:Y8888::                of the License, or (at your        *
# *::::':::88::::888::Y88a::::::::::::...  option) any later version.         *
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
# * Written by Cedric Bastoul, Cedric.Bastoul@u-psud.fr                       *
# *                                                                           *
# *****************************************************************************/
#
# Makefile.am (or makefile if generated) of Clan, the Chunky Loop Analyser.
# Makefile.am is not a makefile, you must run the 'autogen.sh' THEN the
# configure shellscript to generate the Makefile thanks to this file.

#############################################################################

if BUNDLED_OSL
    MAYBE_OSL = osl
    OSL_LA = $(top_builddir)/osl/libosl.la
endif

#AUTOMAKE_OPTIONS = subdir-objects # then: BUILT_SOURCES = source/parser.h
SUBDIRS         = $(MAYBE_OSL) . doc tests
DIST_SUBDIRS    = $(MAYBE_OSL) . doc tests
ACLOCAL_AMFLAGS = -I m4

#############################################################################

bin_PROGRAMS    = clan
lib_LTLIBRARIES = libclan.la

#############################################################################

pkginclude_HEADERS =                    \
	include/clan/clan.h             \
	include/clan/options.h          \
	include/clan/statement.h        \
	include/clan/vector.h           \
	include/clan/relation.h	        \
	include/clan/relation_list.h    \
	include/clan/macros.h           \
	include/clan/scop.h             \
	include/clan/symbol.h

# Add dependence on parser.h needed by source/scop.c
BUILT_SOURCES = parser.h

DEFAULT_INCLUDES = -I.
INCLUDES = -I$(top_builddir)/include -I$(top_srcdir)/include
AM_CFLAGS = $(CFLAGS_WARN)
AM_YFLAGS = -y -d

#############################################################################

libclan_la_LIBADD   = @OSL_LIBS@ $(OSL_LA)
libclan_la_CPPFLAGS = @OSL_CPPFLAGS@ -g
libclan_la_LDFLAGS  = @OSL_LDFLAGS@
libclan_la_SOURCES  =                   \
	source/parser.y                 \
	source/scanner.l                \
	source/options.c                \
	source/symbol.c                 \
	source/scop.c                   \
	source/statement.c              \
	source/relation.c               \
	source/relation_list.c          \
	source/vector.c

#############################################################################

LDADD             = @OSL_LIBS@ libclan.la
clan_CPPFLAGS     = @OSL_CPPFLAGS@ -g
clan_DEPENDENCIES = libclan.la
clan_SOURCES      = source/clan.c

#############################################################################

MAINTAINERCLEANFILES =                  \
	Makefile.in                     \
	aclocal.m4                      \
	configure                       \
	source/stamp-h.in               \
	$(AUX_DIST)

#############################################################################

dist-hook:
	(cd $(distdir) && mkdir -p $(ac_aux_dir))
	for file in $(AUX_DIST); do \
	  cp $$file $(distdir)/$$file; \
	done

#############################################################################
