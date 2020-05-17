# Copyright © 2015 Inria, Written by Lénaïc Bagnères, lenaic.bagneres@inria.fr

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# Try to find the Clan library

# CLAN_FOUND       - System has Clan library
# CLAN_INCLUDE_DIR - The Clan include directory
# CLAN_LIBRARY     - Library needed to use Clan


find_library(CLAN_LIBRARY clan)
find_file(CLAN_INCLUDE_DIR "clan/clan.h")

if (CLAN_LIBRARY AND CLAN_INCLUDE_DIR)
	
	string(REPLACE "/clan/clan.h" "" CLAN_INCLUDE_DIR ${CLAN_INCLUDE_DIR})
	
	set(CLAN_FOUND "TRUE")
	
	include_directories(${CLAN_INCLUDE_DIR})
	
	message(STATUS "Library Clan found =) ${CLAN_INCLUDE_DIR} | ${CLAN_LIBRARY}")
	
	find_package(osl1)
	if (OSL1_FOUND)
		add_definitions("-Dclan_with_osl1")
	endif()
	
else()
	
	set(CLAN_FOUND "FALSE")
	
	message(STATUS "Library Clan not found :(")
	
endif()
