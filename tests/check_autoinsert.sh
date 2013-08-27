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

#./$CHECKER "Autoinsert test suite" "$AUTOINSERT_TEST_FILES" "-autoinsert" "yes"

output=0;
nb_tests=0;
name="Autoinsert test suite"
echo "[CHECK] $name"
for i in $AUTOINSERT_TEST_FILES; do
  nb_tests=$(($nb_tests + 1));
  outiter=0
 echo "[TEST] Source parser test:== $i ==";
# Since -autoinsert modifies the input file, rename it to some random name
# before calling clan.
  fname="/tmp/$$.c";
  cp $i $fname;
  $top_builddir/clan -autoinsert $fname 2>/tmp/clanout;
  z=`diff $i.orig $fname`;
  err=`cat /tmp/clanout`;
  if ! [ -z "$z" ]; then
    echo "\033[31m[FAIL] Source parser test: wrong pragmas inserted\033[0m]";
    output=1;
    outiter=1
  fi
  if ! [ -z "$err" ]; then
    echo "\033[33m[INFO] Source parser test stderr output:\n$err\033[0m";
    outiter=1
  fi
  if [ $outiter = "0" ]; then
    echo "[PASS] Source parser test: correct pragmas inserted";
    rm -f $fname;
  fi
  rm -f /tmp/clanout;
done;
if [ $output = "1" ]; then
  echo "\033[31m[FAIL] $1\033[0m]";
else
  echo "[PASS] $name ($nb_tests + $nb_tests tests)";
fi
exit $output
