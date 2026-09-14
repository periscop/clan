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

MAINTAINERCLEANFILES = Makefile.in

#############################################################################

TEST_FILES = \
	$(top_srcdir)/tests/ax-do.c \
	$(top_srcdir)/tests/gauss.c \
	$(top_srcdir)/tests/gemver.c \
	$(top_srcdir)/tests/iir_4_64.c \
	$(top_srcdir)/tests/matmul.c \
	$(top_srcdir)/tests/swim.c

UNITARY_TEST_FILES = \
	$(top_srcdir)/tests/unitary/size_t_loop.c \
	$(top_srcdir)/tests/unitary/classicloop.c \
	$(top_srcdir)/tests/unitary/simpleloop.c \
	$(top_srcdir)/tests/unitary/basicnest.c \
	$(top_srcdir)/tests/unitary/condition_and.c \
	$(top_srcdir)/tests/unitary/condition_and_else.c \
	$(top_srcdir)/tests/unitary/condition_or.c \
	$(top_srcdir)/tests/unitary/condition_or_else.c \
	$(top_srcdir)/tests/unitary/condition_not.c \
	$(top_srcdir)/tests/unitary/condition_not_else.c \
	$(top_srcdir)/tests/unitary/doublewrite.c \
	$(top_srcdir)/tests/unitary/modulo1.c \
	$(top_srcdir)/tests/unitary/modulo2.c \
	$(top_srcdir)/tests/unitary/modulo3.c \
	$(top_srcdir)/tests/unitary/stride1.c \
	$(top_srcdir)/tests/unitary/stride2.c \
	$(top_srcdir)/tests/unitary/stride3.c \
	$(top_srcdir)/tests/unitary/stride_neg1.c \
	$(top_srcdir)/tests/unitary/stride_neg2.c \
	$(top_srcdir)/tests/unitary/stride_neg3.c \
	$(top_srcdir)/tests/unitary/stride_ifmod.c \
	$(top_srcdir)/tests/unitary/infinite_loop1.c \
	$(top_srcdir)/tests/unitary/infinite_loop2.c \
	$(top_srcdir)/tests/unitary/infinite_loop3.c \
	$(top_srcdir)/tests/unitary/infinite_loop4.c \
	$(top_srcdir)/tests/unitary/multiscop1.c \
	$(top_srcdir)/tests/unitary/multiscop2.c \
	$(top_srcdir)/tests/unitary/multiscop3.c \
	$(top_srcdir)/tests/unitary/loop_context1.c \
	$(top_srcdir)/tests/unitary/loop_context2.c \
	$(top_srcdir)/tests/unitary/loop_context3.c \
	$(top_srcdir)/tests/unitary/ref1_parameter_after_reference.c \
	$(top_srcdir)/tests/unitary/ref2_parameter_before_reference.c \
	$(top_srcdir)/tests/unitary/ref3_iterator_reference.c \
	$(top_srcdir)/tests/unitary/clay.c \
	$(top_srcdir)/tests/unitary/empty.c \
	$(top_srcdir)/tests/unitary/simplecond.c \
	$(top_srcdir)/tests/unitary/twoconds.c \
	$(top_srcdir)/tests/unitary/twocondincond.c \
	$(top_srcdir)/tests/unitary/complexcond.c \
	$(top_srcdir)/tests/unitary/multiparenthcond.c \
	$(top_srcdir)/tests/unitary/maxloopsimple.c \
	$(top_srcdir)/tests/unitary/maxloopcomplex.c \
	$(top_srcdir)/tests/unitary/min.c \
	$(top_srcdir)/tests/unitary/minloopsimple.c \
	$(top_srcdir)/tests/unitary/minloopcomplex.c \
	$(top_srcdir)/tests/unitary/minmax.c \
	$(top_srcdir)/tests/unitary/negassign.c \
	$(top_srcdir)/tests/unitary/binop.c \
	$(top_srcdir)/tests/unitary/complexop.c \
	$(top_srcdir)/tests/unitary/complexprog.c \
	$(top_srcdir)/tests/unitary/noloop.c \
	$(top_srcdir)/tests/unitary/noloop2.c \
	$(top_srcdir)/tests/unitary/ternary.c \
	$(top_srcdir)/tests/unitary/functioncall.c \
	$(top_srcdir)/tests/unitary/functioncall2.c \
	$(top_srcdir)/tests/unitary/redefiter.c \
	$(top_srcdir)/tests/unitary/comments.c \
	$(top_srcdir)/tests/unitary/underscore.c \
	$(top_srcdir)/tests/unitary/parenthesis.c \
	$(top_srcdir)/tests/unitary/intaddit.c \
	$(top_srcdir)/tests/unitary/assigniter.c \
	$(top_srcdir)/tests/unitary/assigniter2.c \
	$(top_srcdir)/tests/unitary/increment.c \
	$(top_srcdir)/tests/unitary/field.c \
	$(top_srcdir)/tests/unitary/object.c \
	$(top_srcdir)/tests/unitary/nestedcurly.c \
	$(top_srcdir)/tests/unitary/float.c \
	$(top_srcdir)/tests/unitary/iterinparent.c

FAIL_TEST_FILES = \
	$(top_srcdir)/tests/must_fail/private_multiple.c \
	$(top_srcdir)/tests/must_fail/private_array.c \
	$(top_srcdir)/tests/must_fail/private_pointer.c \
	$(top_srcdir)/tests/must_fail/private_struct.c \
	$(top_srcdir)/tests/must_fail/private_union.c \
	$(top_srcdir)/tests/must_fail/private_typedef.c \
	$(top_srcdir)/tests/must_fail/private_static.c \
	$(top_srcdir)/tests/must_fail/private_extern.c \
	$(top_srcdir)/tests/must_fail/private_volatile.c \
	$(top_srcdir)/tests/must_fail/private_void.c \
	$(top_srcdir)/tests/must_fail/private_function.c \
	$(top_srcdir)/tests/must_fail/private_aggregate.c \
	$(top_srcdir)/tests/must_fail/private_duplicate.c \
	$(top_srcdir)/tests/must_fail/private_bound.c \
	$(top_srcdir)/tests/must_fail/private_condition.c \
	$(top_srcdir)/tests/must_fail/private_iterator.c \
	$(top_srcdir)/tests/must_fail/private_prior_use.c \
	$(top_srcdir)/tests/must_fail/private_bad_type.c \
	$(top_srcdir)/tests/must_fail/private_only_const.c \
	$(top_srcdir)/tests/must_fail/private_long_long_long.c \
	$(top_srcdir)/tests/must_fail/private_after_valid.c \
	$(top_srcdir)/tests/must_fail/nonaffine_loop.c \
	$(top_srcdir)/tests/must_fail/nonaffine_condition.c \
	$(top_srcdir)/tests/must_fail/indirect_iterator.c \
	$(top_srcdir)/tests/must_fail/indirect_syntax.c \
	$(top_srcdir)/tests/must_fail/indirect_side_effect.c \
	$(top_srcdir)/tests/must_fail/modulo_zero.c \
	$(top_srcdir)/tests/must_fail/modulo_negative_divisor.c \
	$(top_srcdir)/tests/must_fail/modulo_iterator.c \
	$(top_srcdir)/tests/must_fail/modulo_syntax.c \
	$(top_srcdir)/tests/must_fail/numeric_label.c \
	$(top_srcdir)/tests/must_fail/multiple_for_conditions.c \
	$(top_srcdir)/tests/must_fail/multiple_for_strides.c \
	$(top_srcdir)/tests/must_fail/error_after_scop.c \
	$(top_srcdir)/tests/must_fail/invalid_else.c \
	$(top_srcdir)/tests/must_fail/multiple_for_indices.c \
	$(top_srcdir)/tests/must_fail/zero_loop_stride.c \
	$(top_srcdir)/tests/must_fail/iterator_function.c \
	$(top_srcdir)/tests/must_fail/iterator_function_noargs.c \
	$(top_srcdir)/tests/must_fail/iterator_field.c \
	$(top_srcdir)/tests/must_fail/iterator_pointer_field.c \
	$(top_srcdir)/tests/must_fail/iterator_postincrement.c \
	$(top_srcdir)/tests/must_fail/iterator_preincrement.c \
	$(top_srcdir)/tests/must_fail/iterator_subscript.c \
	$(top_srcdir)/tests/must_fail/variable_to_iterator.c \
	$(top_srcdir)/tests/must_fail/function_call_in_affex.c \
	$(top_srcdir)/tests/must_fail/write_iterator.c \
	$(top_srcdir)/tests/must_fail/write_parameter.c

AUTOSCOP_TEST_FILES = \
	$(top_srcdir)/tests/autoscop/classicloop.c \
	$(top_srcdir)/tests/autoscop/matmul_1_bare_metal.c \
	$(top_srcdir)/tests/autoscop/matmul_2_non_static_fences.c \
	$(top_srcdir)/tests/autoscop/matmul_3_user_scop.c

MODULO_ACESS_TEST_FILES = \
	$(top_srcdir)/tests/modulo_acess/no_loop.c \
	$(top_srcdir)/tests/modulo_acess/parenthesized.c \
	$(top_srcdir)/tests/modulo_acess/multiple_dimensions.c \
	$(top_srcdir)/tests/modulo_acess/3d7pt.c \
	$(top_srcdir)/tests/modulo_acess/apop.c \
	$(top_srcdir)/tests/modulo_acess/heat-1d.c \
	$(top_srcdir)/tests/modulo_acess/heat-2d.c \
	$(top_srcdir)/tests/modulo_acess/heat-3d.c \
	$(top_srcdir)/tests/modulo_acess/life.c


NONAFFINE_TEST_FILES = \
	$(top_srcdir)/tests/nonaffine/written_scalar.c \
	$(top_srcdir)/tests/nonaffine/product.c \
	$(top_srcdir)/tests/nonaffine/modulo_arithmetic.c \
	$(top_srcdir)/tests/nonaffine/indirection.c \
	$(top_srcdir)/tests/nonaffine/functions.c

AUTOINSERT_TEST_FILES = \
	$(top_srcdir)/tests/autoinsert/trivial.c \
	$(top_srcdir)/tests/autoinsert/braces.c \
	$(top_srcdir)/tests/autoinsert/multiple.c \
	$(top_srcdir)/tests/autoinsert/weird_format.c

PRIVATE_TEST_FILES = \
	$(top_srcdir)/tests/private/branches.c \
	$(top_srcdir)/tests/private/infinite.c \
	$(top_srcdir)/tests/private/matmul.c \
	$(top_srcdir)/tests/private/multiscop.c \
	$(top_srcdir)/tests/private/nested.c \
	$(top_srcdir)/tests/private/types.c

TESTS_ENVIRONMENT = \
	top_builddir=$(top_builddir) \
	srcdir=$(srcdir) \
	EXEEXT=$(EXEEXT) \
	CHECKER="$(top_srcdir)/tests/checker.sh" \
	COMPILE="$(COMPILE)" \
	LINK="$(LINK)" \
	TEST_FILES="$(TEST_FILES)" \
	PRIVATE_TEST_FILES="$(PRIVATE_TEST_FILES)" \
	UNITARY_TEST_FILES="$(UNITARY_TEST_FILES)" \
	FAIL_TEST_FILES="$(FAIL_TEST_FILES)" \
	AUTOSCOP_TEST_FILES="$(AUTOSCOP_TEST_FILES)" \
	MODULO_ACESS_TEST_FILES="$(MODULO_ACESS_TEST_FILES)" \
	NONAFFINE_TEST_FILES="$(NONAFFINE_TEST_FILES)" \
	AUTOINSERT_TEST_FILES="$(AUTOINSERT_TEST_FILES)"

valcheck:
	$(TESTS_ENVIRONMENT) $(srcdir)/check_unitary.sh valgrind ; \
	$(TESTS_ENVIRONMENT) $(srcdir)/check_complex.sh valgrind ; \
	$(TESTS_ENVIRONMENT) $(srcdir)/check_autoscop.sh valgrind ; \
	$(TESTS_ENVIRONMENT) $(srcdir)/check_modulo_acess.sh valgrind ; \
	$(TESTS_ENVIRONMENT) $(srcdir)/check_nonaffine.sh valgrind ; \
	$(TESTS_ENVIRONMENT) $(srcdir)/check_autoinsert.sh valgrind

.PHONY: leakscheck
leakscheck:
	@if test "@enable_asan@" = yes; then \
	  echo "leakscheck requires a non-ASan build."; exit 1; \
	fi
	@command -v leaks >/dev/null 2>&1 || { echo "leakscheck requires Apple's macOS leaks tool."; exit 1; }
	@status=0; \
	for suite in private private_extbody unitary complex fail fail_extbody autoscop modulo_acess nonaffine nonaffine_extbody autoinsert; do \
	  $(TESTS_ENVIRONMENT) $(SHELL) "$(srcdir)/check_$$suite.sh" leaks || status=1; \
	done; \
	exit $$status

check_SCRIPTS = \
	check_private.sh \
	check_private_extbody.sh \
	check_affine_only.sh \
	check_checker.sh \
	check_unitary.sh \
	check_complex.sh \
	check_fail.sh \
	check_fail_extbody.sh \
	check_autoscop.sh \
	check_modulo_acess.sh \
	check_nonaffine.sh \
	check_nonaffine_extbody.sh \
	check_autoinsert.sh

## Replace by program names when needed
# check_PROGRAMS = ...
TESTS = $(check_SCRIPTS)

TEST_FILES_REF = $(TEST_FILES:.c=.c.scop)
UNITARY_TEST_FILES_REF = $(UNITARY_TEST_FILES:.c=.c.scop)
FAIL_TEST_FILES_REF = $(FAIL_TEST_FILES:.c=.c.scop)
AUTOSCOP_TEST_FILES_REF = $(AUTOSCOP_TEST_FILES:.c=.c.scop)
MODULO_ACESS_TEST_FILES_REF =$(MODULO_ACESS_TEST_FILES:.c=.c.scop)
AUTOINSERT_TEST_FILES_REF = $(AUTOINSERT_TEST_FILES:.c=.c.orig)

TEST_FILES_CLEAN = $(TEST_FILES:.c=.c.test)
UNITARY_TEST_FILES_CLEAN = $(UNITARY_TEST_FILES:.c=.c.test)
FAIL_TEST_FILES_CLEAN = $(FAIL_TEST_FILES:.c=.c.test)
AUTOSCOP_TEST_FILES_CLEAN = $(AUTOSCOP_TEST_FILES:.c=.c.test)
MODULO_ACESS_TEST_FILES_CLEAN =$(MODULO_ACESS_TEST_FILES:.c=.c.test)


CLEANFILES = \
	$(NONAFFINE_TEST_FILES:.c=.c.test) \
	$(TEST_FILES_CLEAN) \
	$(UNITARY_TEST_FILES_CLEAN) \
	$(FAIL_TEST_FILES_CLEAN) \
	$(AUTOSCOP_TEST_FILES_CLEAN) \
	$(MODULO_ACESS_TEST_FILES_CLEAN)

EXTRA_DIST = \
	$(PRIVATE_TEST_FILES) \
	$(PRIVATE_TEST_FILES:.c=.c.scop) \
	$(PRIVATE_TEST_FILES:.c=.c.extbody.scop) \
	$(NONAFFINE_TEST_FILES) \
	$(NONAFFINE_TEST_FILES:.c=.c.scop) \
	$(NONAFFINE_TEST_FILES:.c=.c.extbody.scop) \
	$(check_SCRIPTS) \
	$(srcdir)/checker.sh \
	$(TEST_FILES) \
	$(TEST_FILES_REF) \
	$(UNITARY_TEST_FILES) \
	$(UNITARY_TEST_FILES_REF) \
	$(FAIL_TEST_FILES) \
	$(FAIL_TEST_FILES_REF) \
	$(AUTOSCOP_TEST_FILES) \
	$(AUTOSCOP_TEST_FILES_REF) \
	$(MODULO_ACESS_TEST_FILES) \
	$(MODULO_ACESS_TEST_FILES_REF) \
	$(AUTOINSERT_TEST_FILES) \
	$(AUTOINSERT_TEST_FILES_REF) \
	$(check_SCRIPTS)
