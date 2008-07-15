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
# Makefile.am (or makefile if generated) of Clan, the Chunky Loop Analyser.
# Makefile.am is not a makefile, you must run the 'autogen.sh' THEN the
# configure shellscript to generate the Makefile thanks to this file.


#############################################################################
SUBDIRS 		=

#############################################################################

MAINTAINERCLEANFILES    = Makefile.in

TESTS_ENVIRONMENT       = top_builddir=$(top_builddir) SRCDIR=$(srcdir)

#############################################################################

EXTRA_DIST              = checker.sh

check_SCRIPTS		= check_unitary.sh check_complex.sh

## Replace by program names when needed
# check_PROGRAMS = ...
TESTS			= $(check_SCRIPTS)

TEST_FILES             	=			\
	$(top_srcdir)/tests/ax-do.c		\
	$(top_srcdir)/tests/gauss.c		\
	$(top_srcdir)/tests/gemver.c		\
	$(top_srcdir)/tests/iir_4_64.c		\
	$(top_srcdir)/tests/matmul.c		\
	$(top_srcdir)/tests/swim.c

UNITARY_TEST_FILES             	=			\
	$(top_srcdir)/tests/unitary/classicloop.c	\
	$(top_srcdir)/tests/unitary/simpleloop.c	\
	$(top_srcdir)/tests/unitary/basicnest.c		\
	$(top_srcdir)/tests/unitary/empty.c		\
	$(top_srcdir)/tests/unitary/simplecond.c	\
	$(top_srcdir)/tests/unitary/redefiter.c		\
	$(top_srcdir)/tests/unitary/assigniter.c	\
	$(top_srcdir)/tests/unitary/comments.c		\
	$(top_srcdir)/tests/unitary/increment.c


TEST_FILES_REF    =		 $(TEST_FILES:.c=.c.scop)
UNITARY_TEST_FILES_REF		= $(UNITARY_TEST_FILES:.c=.c.scop)

TEST_FILES_CLEAN		= $(TEST_FILES:.c=.c.test)
UNITARY_TEST_FILES_CLEAN	= $(UNITARY_TEST_FILES:.c=.c.test)


CLEANFILES			=		\
	$(TEST_FILES_CLEAN)			\
	$(UNITARY_TEST_FILES_CLEAN)


EXTRA_DIST	+=				\
	$(TEST_FILES)				\
	$(TEST_FILES_REF)			\
	$(UNITARY_TEST_FILES)			\
	$(UNITARY_TEST_FILES_REF)		\
	$(check_SCRIPTS)


TESTS_ENVIRONMENT +=					\
	CHECKER="$(top_srcdir)/tests/checker.sh"	\
	TEST_FILES="$(TEST_FILES)"			\
	UNITARY_TEST_FILES="$(UNITARY_TEST_FILES)"
