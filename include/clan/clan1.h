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


#ifndef CLAN_CLAN1_H
#define CLAN_CLAN1_H

#ifdef clan_with_osl1

#include <stdio.h>

#include <osl1/vector/scop.h>

#include "clan.h"


#if defined(__cplusplus)
extern "C"
{
#endif


// Extract
osl1_vector_scop_t clan1_extract_scops(FILE* file);

#if defined(__cplusplus)
}
#endif

#endif

#endif
