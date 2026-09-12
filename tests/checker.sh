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

# Preserve internal blank lines, but discard printer padding and EOF blanks.
normalize_scop() {
  awk '
    { sub(/[[:blank:]]+$/, "") }
    /^$/ { blanks++; next }
    {
      for (i = 0; i < blanks; i++) print ""
      blanks = 0
      print
    }
  ' "$1"
}

output=0
nb_tests=0;

TEST_NAME="$1"    ## Name of the group of files to test

TEST_FILES="$2"   ## List of test file prefixes and individual options

TEST_OPTION="$3"  ## Option for clan

TEST_TYPE="$4"    ## - "clan" to simply test clan (default)
                  ## - "valgrind" to test the valgrind output
                  ## - "leaks" to test with Apple's macOS leaks tool

# Uncomment the following line to print the test script
#set -x verbose  #echo on

clan=$top_builddir/clan$EXEEXT

echo "[TEST] $TEST_NAME";

if [ "$TEST_TYPE" = leaks ] && ! command -v leaks >/dev/null 2>&1; then
  echo "[FAIL] Apple's macOS leaks tool is not available"
  exit 1
fi

for i in $TEST_FILES; do

  nb_tests=$(($nb_tests + 1))
  outtemp=0
  # Since -autoinsert modifies the input file, we use a random temporary file
  # before calling clan.
  input="/tmp/$$-clan-input.c";
  clanout="/tmp/$$-clan-stderr"
  cp "$i" "$input" || exit 1;

  if [ "$TEST_TYPE" = "clan" ]; then
    # Test the basic .scop generation
    filename=$(basename "$i");
    echo "[CHECK] Source parser test:== $i ==";
    "$clan" $TEST_OPTION "$input" > "$input.scop" 2>"$clanout"
    clan_status=$?
    if [ "$clan_status" -ne 0 ]; then
      printf '[FAIL] Clan exited with status %s\n' "$clan_status"
      outtemp=1
      output=1
    fi
    # Also catch reports when a caller overrides the sanitizer exit code.
    if grep -Eq 'ERROR: (AddressSanitizer|LeakSanitizer)|SUMMARY: (AddressSanitizer|LeakSanitizer)|AddressSanitizer:DEADLYSIGNAL' "$clanout"; then
      echo '[FAIL] Sanitizer diagnostic detected'
      outtemp=1
      output=1
    fi
    if [ "$TEST_OPTION" = "-autoinsert" ]; then
      normalize_scop "$input" > "$input.actual" || exit 1
      normalize_scop "$i.orig" > "$input.expected" || exit 1
      diff --ignore-matching-lines="$filename" \
           --ignore-matching-lines="$input" \
           --ignore-matching-lines='enerated' \
           "$input.actual" "$input.expected";
      z=$?;
    else
      # OpenScop's printer pads lines; references need not retain that padding.
      normalize_scop "$input.scop" > "$input.actual" || exit 1
      reference="$i.scop"
      if [ "$TEST_OPTION" = "-extbody" ] && [ -f "$i.extbody.scop" ]; then
        reference="$i.extbody.scop"
      fi
      normalize_scop "$reference" > "$input.expected" || exit 1
      diff --ignore-matching-lines="$filename" \
           --ignore-matching-lines="$input" \
           --ignore-matching-lines='enerated' \
           "$input.actual" "$input.expected";
      z=$?;
    fi
    err=`cat "$clanout"`;
    if [ "$z" -ne "0" ]; then
      printf "\033[31m[FAIL] Source parser test: Wrong output\n$z\033[0m\n";
      outtemp=1;
      output=1
    fi
    if ! [ -z "$err" ]; then
      printf '\033[33m[INFO] Source parser test stderr output:\n%s\033[0m\n' "$err";
    fi
    if [ $outtemp = "0" ]; then
      echo "[PASS] Source parser test: output OK";
    fi
  elif [ "$TEST_TYPE" = leaks ]; then
    echo "[LEAKSCHECK] Source parser test:== $i =="
    # Libtool resolves its executable wrapper before leaks launches the process.
    # --atExit enables allocation stack logging and returns nonzero on leaks
    # or tool errors. Capture stdout too, since that contains the leak report.
    if [ -f "$top_builddir/libtool" ]; then
      /bin/sh "$top_builddir/libtool" --mode=execute \
        "$top_builddir/tests/leaks-wrapper$EXEEXT" "$clan" $TEST_OPTION "$input" > "$clanout" 2>&1
    else
      leaks --atExit -- "$clan" $TEST_OPTION "$input" > "$clanout" 2>&1
    fi
    errors=$?
    if [ "$errors" -ne 0 ] ||
       ! grep -Eq '^Process [0-9]+: 0 leaks for 0 total leaked bytes\.' "$clanout"; then
      printf '[FAIL] Leak check failed (status %s)\n' "$errors"
      cat "$clanout"
      output=1
    else
      echo '[PASS] No leaks detected'
    fi
  else
    echo "[VALCHECK] Source parser test:== $i ==";
    libtool --mode=execute valgrind --error-exitcode=1 $clan $TEST_OPTIONS $input > /dev/null 2> "$clanout";
    errors=$?;
    leaks=`grep "in use at exit" "$clanout" | cut -f 2 -d ':'`
    reachable=`tail "${clanout}" | grep "still reachable:" | cut -f 2 -d ':'`
    if [ "$errors" = "1" ]; then
      printf "\033[31mMemory error detected... \033[0m\n";
      cat "$clanout";
      output="1";
    elif [ "$leaks" != " 0 bytes in 0 blocks" ]; then
      if [ "${leaks}" != "${reachable}" ]; then
        printf "\033[31mMemory leak detected... \033[0m\n";
        cat "$clanout";
        output="1";
      fi
    else
      output="0";
    fi;
  fi
  rm -f "$input" "$input.scop" "$input.actual" "$input.expected" "$clanout"
done
if [ $output = "1" ]; then
  printf "\033[31m[FAIL] $1\033[0m\n";
else
  echo "[PASS] $1 ($nb_tests tests)";
fi
exit $output
