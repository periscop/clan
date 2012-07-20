
   /*+------- <| --------------------------------------------------------**
    **         A                     Clan                                **
    **---     /.\   -----------------------------------------------------**
    **   <|  [""M#                  clan.c                               **
    **-   A   | #   -----------------------------------------------------**
    **   /.\ [""M#         First version: 30/04/2008                     **
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

#include <stdlib.h>
#include <stdio.h>

#include <clan/clan.h>
#include <osl/scop.h>

int main(int argc, char* argv[]) {
  osl_scop_p scop = NULL;
  clan_options_p options;
  FILE* input, *output, *autopragma;
  char c;

  // Options and input/output file setting.
  options = clan_options_read(argc, argv, &input, &output);

  // Extraction of the polyhedral representation of the SCoP from the input.
  if (input != NULL) {
    if (options->inputscop)
      // Input is a .scop file.
      scop = osl_scop_read(input);
    else
      // Input is a source code.
      scop = clan_scop_extract(input, options);

    // Printing of the internal data structure of the SCoP if asked.
    if (options->structure)
      osl_scop_dump(stdout, scop);

    if (!options->autopragma) {
      // Generation of the .scop output file.
      clan_scop_print(output, scop, options);
    }
    else {
      // Output the file with inserted SCoP pragmas.
      if ((autopragma = fopen(CLAN_AUTOPRAGMA_FILE, "r")) == NULL)
        CLAN_error("cannot create the temporary file");
      while ((c = fgetc(autopragma)) != EOF)
        fputc(c, output);
      fclose(autopragma);
      remove(CLAN_AUTOPRAGMA_FILE);
    }
  }

  // Save the planet.
  clan_options_free(options);
  osl_scop_free(scop);
  fclose(output);

  return 0;
}
