#! /bin/sh
#
#   /**------- <| --------------------------------------------------------**
#    **         A                     Clan                                **
#    **---     /.\   -----------------------------------------------------**
#    **   <|  [""M#                 checker.sh                            **
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

output=0
nb_tests=0;
TEST_FILES="$2";
TEST_OPTIONS="$3"
echo "[CHECK] $1";
for i in $TEST_FILES; do
    nb_tests=$(($nb_tests + 1))
    outtemp=0
    echo "[TEST] Source parser test:== $i ==";
    $top_builddir/clan $TEST_OPTIONS $i > $i.test 2>/tmp/clanout
    diff --ignore-matching-lines='/tests/' --ignore-matching-lines='enerated by ' $i.test $i.scop
    z=`diff --ignore-matching-lines='/tests/' --ignore-matching-lines='enerated by ' $i.test $i.scop 2>&1`
    err=`cat /tmp/clanout`;
    if ! [ -z "$z" ]; then
	echo "\033[31m[FAIL] Source parser test: Wrong .scop generated\033[0m";
	outtemp=1;
	output=1
    fi
    if ! [ -z "$err" ]; then
	echo "\033[33m[INFO] Source parser test stderr output:\n$err\033[0m";
    fi
    if [ $outtemp = "0" ]; then
	echo "[PASS] Source parser test: .scop OK";
	rm -f $i.test
    fi
    rm -f /tmp/clanout
    echo "[TEST] .SCoP parser test:== $i.scop ==";
    $top_builddir/clan -inputscop $i.scop > $i.parsetest 
    z=`diff --ignore-matching-lines='/tests/' --ignore-matching-lines='enerated by ' $i.parsetest $i.scop`
    if ! [ -z "$z" ]; then
	echo "\033[31m[FAIL] .SCoP parser test: $i\033[0m";
	outtemp=1
	output=1
    else
	echo "[PASS] .SCoP parser test: .scop re-OK";
	rm -f $i.parsetest
    fi
done
if [ $output = "1" ]; then
    echo "\033[31m[FAIL] $1\033[0m";
else
    echo "[PASS] $1 ($nb_tests + $nb_tests tests)";
fi
exit $output
