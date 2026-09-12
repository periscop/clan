
   /*+------- <| --------------------------------------------------------**
    **         A                     Clan                                **
    **---     /.\   -----------------------------------------------------**
    **   <|  [""M#              leaks-wrapper.c                          **
    **-   A   | #   -----------------------------------------------------**
    **   /.\ [""M#         First version: 12/09/2026                     **
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
#include <string.h>
#include <unistd.h>

#ifdef __APPLE__
#include <mach-o/dyld.h>
#endif


/*+****************************************************************************
 *                            Processing functions                            *
 ******************************************************************************/


/**
 * main function:
 * This function preserves Libtool's loader path across macOS's protected leaks
 * executable. The first invocation passes DYLD_LIBRARY_PATH as an argument to
 * a second invocation launched by leaks. The second invocation restores the
 * loader path and the at-exit instrumentation before executing Clan.
 * \param argc Number of command-line arguments.
 * \param argv Command-line arguments, including the executable to check.
 * \return 2 if the arguments are invalid or launching a process fails.
 */
int main(int argc, char* argv[]) {
  char** command;
  const char* library_path;
  int i;

  if (argc >= 4 && !strcmp(argv[1], "--exec")) {
#ifdef __APPLE__
    unsigned int image;
    const char* at_exit_library = NULL;
    const char* name;

    // The injected library removes DYLD_INSERT_LIBRARIES at startup. Reinsert
    // the loaded library before replacing this helper with Clan, so the scan
    // happens at Clan's exit rather than being lost at exec.
    for (image = 0; image < _dyld_image_count(); image++) {
      name = _dyld_get_image_name(image);
      if (name && strstr(name, "/libLeaksAtExit.dylib"))
        at_exit_library = name;
    }
    if (!at_exit_library) {
      fprintf(stderr, "leaks did not inject its at-exit instrumentation\n");
      return 2;
    }
    if (setenv("DYLD_INSERT_LIBRARIES", at_exit_library, 1)) {
      perror("setenv");
      return 2;
    }
#endif
    if (setenv("DYLD_LIBRARY_PATH", argv[2], 1)) {
      perror("setenv");
      return 2;
    }
    execvp(argv[3], argv + 3);
    perror(argv[3]);
    return 2;
  }
  if (argc < 2) {
    fprintf(stderr, "usage: %s executable [arguments...]\n", argv[0]);
    return 2;
  }

  // Launch leaks with the loader path saved as an argument.
  library_path = getenv("DYLD_LIBRARY_PATH");
  command = calloc((size_t)argc + 6, sizeof(*command));
  if (!command) {
    perror("calloc");
    return 2;
  }
  command[0] = "leaks";
  command[1] = "--atExit";
  command[2] = "--";
  command[3] = argv[0];
  command[4] = "--exec";
  command[5] = (char*)(library_path ? library_path : "");
  for (i = 1; i < argc; i++)
    command[i + 5] = argv[i];
  execvp(command[0], command);
  perror("leaks");

  // Release the command array if launching leaks failed.
  free(command);
  return 2;
}
