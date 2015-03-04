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



#include <osl/osl.h>

#ifdef clan_with_osl1

#include <osl1/osl_to_osl1.h>

#include "../include/clan/clan1.h"
#include "../include/clan/clan.h"


// Extract

/**
 * @brief Extract SCoPs from a C file
 * @param[in] file A C file
 * @return the osl1_vector_scop_t with the SCoPs extracted
 */
osl1_vector_scop_t clan1_extract_scops(FILE* file) {
  // Create Clan options
  clan_options_t* clan_options = clan_options_malloc();
  // Extract
  osl_scop_t* scop_osl = clan_scop_extract(file, clan_options);
  // Convert
  osl1_vector_scop_t scops = osl_to_osl1(scop_osl);
  // Get first comments
  {
    fpos_t file_pos; fgetpos(file, &file_pos);
    const osl_scop_t* scop_osl_p = scop_osl;
    for (size_t i = 0; i < scops.size; ++i) {
      osl1_scop_t* scop = &scops.array[i];
      // Get coordinates extension
      const osl_coordinates_t* const coordinates =
        osl_generic_lookup(scop_osl_p->extension, "coordinates");
      // Extension
      if (coordinates != NULL) {
        // Extract first comments
        rewind(file);
        osl1_extension_comments_t comments =
          osl1_extension_comments_extract(file,
                                          (size_t)coordinates->line_start);
        // Add extension
        gho_any_t any = osl1_extension_comments_to_any(&comments);
        gho_vector_any_add(&scop->extensions, &any);
        gho_any_destroy(&any);
        // Destroy
        osl1_extension_comments_destroy(&comments);
      }
      // Next
      scop_osl_p = scop_osl_p->next;
    }
    fsetpos(file, &file_pos);
  }
  // Destroy
  clan_options_free(clan_options); clan_options = NULL;
  osl_scop_free(scop_osl); scop_osl = NULL;
  // Return
  return scops;
}

#endif
