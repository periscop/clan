// Copyright © 2015 Inria, Written by Lénaïc Bagnères, lenaic.bagneres@inria.fr

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.


#include <stdlib.h>
#include <stdio.h>

#include <clan/clan1.h>


int main(int argc, char** argv) {
  
  if (argc == 1) {
    fprintf(stderr, "# Usage: %s <source_code.c>\n", argv[0]);
    return 1;
  }
  
  FILE* file = fopen(argv[1], "r");
  
  if (file != NULL) {
    osl1_vector_scop_t scops = clan1_scop_extract(file);
    for (size_t i = 0; i < scops.size; ++i) {
      osl1_scop_print(&scops.array[i]);
    }
    osl1_vector_scop_destroy(&scops);
  }
  else {
    fprintf(stderr, "# ERROR: %s: Can not open file \"%s\"\n", argv[0], argv[1]);
    return 1;
  }
  
  return 0;
}
