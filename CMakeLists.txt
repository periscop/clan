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


cmake_minimum_required(VERSION 2.6)


# Release / Debug flags

	if (RELEASE STREQUAL "FALSE" OR RELEASE STREQUAL "DEBUG")
		set(RELEASE "FALSE")
	else()
		set(RELEASE "TRUE")
	endif()

	if (RELEASE)
		set(CMAKE_C_FLAGS "-O3 -DNDEBUG -march=native -ffast-math")
	else()
		set(CMAKE_C_FLAGS "-Og -g3")
	endif()

# General C flags
	# General
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -Wextra -Wconversion -Wsign-conversion -std=c11 -pedantic")
	# Thread support
	if ("${CMAKE_C_COMPILER_ID}" STREQUAL "GNU")
		set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fopenmp")
	else()
		link_libraries(pthread)
		message(STATUS "Your compiler id \"${CMAKE_C_COMPILER_ID}\" is not GNU, OpenMP is disabled")
	endif()


# OpenScop
	message(STATUS "---")
	find_package(osl REQUIRED)

# OpenScop 1
	message(STATUS "---")
	find_package(osl1)
	if (OSL1_FOUND)
		add_definitions("-Dclan_with_osl1")
	endif()

# Flex
	find_package(BISON REQUIRED)
	find_package(FLEX REQUIRED)
	file(COPY "source/parser.y" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/source")
	file(COPY "source/scanner.l" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/source")
	BISON_TARGET(clan_parser "${CMAKE_CURRENT_BINARY_DIR}/source/parser.y" "${CMAKE_CURRENT_BINARY_DIR}/source/parser.c")
	FLEX_TARGET(clan_scanner "${CMAKE_CURRENT_BINARY_DIR}/source/scanner.l" "${CMAKE_CURRENT_BINARY_DIR}/source/scanner.c")
	ADD_FLEX_BISON_DEPENDENCY(clan_scanner clan_parser)
	include_directories("${CMAKE_CURRENT_BINARY_DIR}/source")

# Clan
	message(STATUS "---")
	set(PACKAGE_VERSION "0.7.1")
	set(top_srcdir "${CMAKE_CURRENT_SOURCE_DIR}")
	# ./include/clan/macros.h
	configure_file("./include/clan/macros.h.in" "include/clan/macros.h")
	include_directories("${CMAKE_CURRENT_BINARY_DIR}/include")
	# ./include/*.h
	set(clan_INCLUDE "./include")
	message(STATUS "Include Clan = ${clan_INCLUDE}")
	include_directories("${clan_INCLUDE}")


# Build Clan doxygen
	message(STATUS "---")
# 	if (DOXYGEN_FOUND)
# 		message(STATUS "Doxygen found =) ${DOXYGEN_EXECUTABLE}")
# 		add_custom_target(
# 			doxygen
# 			${DOXYGEN_EXECUTABLE}
# 			WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/include"
# 			COMMENT "Generating API documentation with Doxygen" VERBATIM
# 		)
# 	else()
# 		message(STATUS "Doxygen not found :(")
# 	endif()
	find_package(Doxygen)
	if (DOXYGEN_FOUND)
		configure_file("doc/Doxyfile.in" "Doxyfile")
		add_custom_target(
			doxygen
			${DOXYGEN_EXECUTABLE} ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile
			WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
			COMMENT "Generating API documentation with Doxygen" VERBATIM
		)
	else()
		message(STATUS "Doxygen not found :(")
	endif()

# Build documentation
	
	# Documentation
	find_program(texi2pdf_exe texi2pdf)
	if (texi2pdf_exe)
		add_custom_target(
			documentation
			${texi2pdf_exe} ${CMAKE_CURRENT_SOURCE_DIR}/doc/clan.texi --output=${CMAKE_CURRENT_BINARY_DIR}/clan.pdf
			WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
			COMMENT "Generating documentation (pdf) (with texi2pdf)" VERBATIM
		)
	else()
		message (STATUS "texi2pdf not found :(")
	endif()
	
	# Reference card
	find_program(pdflatex_exe pdflatex)
	if (pdflatex_exe)
		file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/doc/reference_card DESTINATION ${CMAKE_CURRENT_BINARY_DIR})
		add_custom_target(
			reference_card
			${pdflatex_exe} ${CMAKE_CURRENT_BINARY_DIR}/reference_card/reference_card.tex
			WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/reference_card"
			COMMENT "Generating Clan reference card (pdf) (with pdflatex)" VERBATIM
		)
	else()
		message (STATUS "pdflatex not found =( Clan reference card can not be built")
	endif()


# Compiler log
	message(STATUS "---")
	message(STATUS "C compiler = ${CMAKE_C_COMPILER}")
	if (RELEASE)
		message(STATUS "Release mode")
	else()
		message(STATUS "Debug mode")
	endif()
	message(STATUS "C flags    = ${CMAKE_C_FLAGS}")


# Library Clan
	
	file(
		GLOB_RECURSE
		clan_sources
		source/*
	)
	string(REPLACE "${CMAKE_CURRENT_SOURCE_DIR}/source/clan.c;" "" sources "${sources}") # with ;
	string(REPLACE "${CMAKE_CURRENT_SOURCE_DIR}/source/clan.c" "" sources "${sources}")  # without ;
	
	# Shared
	add_library(
		clan
		SHARED
		${clan_sources}
		${BISON_clan_parser_OUTPUTS}
		${FLEX_clan_scanner_OUTPUTS}
	)
	if (OSL1_FOUND)
		target_link_libraries(clan ${OSL1_LIBRARY} ${OSL_LIBRARY})
	else()
		target_link_libraries(clan ${OSL_LIBRARY})
	endif()
	message(STATUS "Add Clan library (shared)")
	
	# Static
	add_library(
		clan_static
		STATIC
		${clan_sources}
		${BISON_clan_parser_OUTPUTS}
		${FLEX_clan_scanner_OUTPUTS}
	)
	set_target_properties(clan_static PROPERTIES OUTPUT_NAME clan)
	if (OSL1_FOUND)
		target_link_libraries(clan_static ${OSL1_LIBRARY} ${OSL_LIBRARY})
	else()
		target_link_libraries(clan_static ${OSL_LIBRARY})
	endif()
	message(STATUS "Add Clan library (static)")


# Executables & tests
	
	enable_testing()
	message(STATUS "---")

	message(STATUS "Add executable clan")
	add_executable(clan_exe "source/clan.c")
	set_target_properties(clan_exe PROPERTIES OUTPUT_NAME "clan")
	target_link_libraries(clan_exe clan_static)
	
	if (OSL1_FOUND)
		message(STATUS "Add executable clan1")
		add_executable(clan1_exe "exe/clan1.c")
		set_target_properties(clan1_exe PROPERTIES OUTPUT_NAME "clan1")
		target_link_libraries(clan1_exe clan_static)
	endif()
	
	# Valgrind
	#find_program(VALGRIND_EXE NAMES valgrind)
	
	# Python
	find_package(PythonInterp)
	if (PYTHONINTERP_FOUND)
	
		# Tests
		file(
			GLOB_RECURSE
			tests
			tests/*.c
		)
		foreach(test ${tests})
		
			message(STATUS "Add Test ${test}")
			
			if("${test}" MATCHES "autoscop")
				
				add_test(
					${test}
					"${CMAKE_CURRENT_SOURCE_DIR}/tests/check_source_result.py"
					"${test}"
					"${test}.scop"
					"${CMAKE_CURRENT_BINARY_DIR}/clan"
					"-autoscop"
				)
				
			else()
				
				add_test(
					${test}
					"${CMAKE_CURRENT_SOURCE_DIR}/tests/check_source_result.py"
					"${test}"
					"${test}.scop"
					"${CMAKE_CURRENT_BINARY_DIR}/clan"
				)
				
			endif()
			
		endforeach()
		
	endif()


# Install
	# Library
	install(TARGETS clan LIBRARY DESTINATION lib)
	install(TARGETS clan_static ARCHIVE DESTINATION lib LIBRARY DESTINATION lib)
	# Executable
	install(TARGETS clan_exe RUNTIME DESTINATION bin)
	if (OSL1_FOUND)
		install(TARGETS clan1_exe RUNTIME DESTINATION bin)
	endif()
	# .h
	install(DIRECTORY include/ DESTINATION include FILES_MATCHING PATTERN "*.h")
	install(DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/include/" DESTINATION include FILES_MATCHING PATTERN "*.h")
	# .cmake
	install(FILES cmake/clan-config.cmake DESTINATION lib/clan)
	# Doxygen
	if (IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/doc/doxygen)
		install(DIRECTORY doc/doxygen DESTINATION share/clan)
	endif()
	# Documentation
	if (EXISTS ${CMAKE_CURRENT_BINARY_DIR}/clan.pdf)
		install(FILES ${CMAKE_CURRENT_BINARY_DIR}/clan.pdf DESTINATION share/clan)
	endif()
	# Reference card
	if (EXISTS ${CMAKE_CURRENT_BINARY_DIR}/reference_card.pdf)
		install(FILES ${CMAKE_CURRENT_BINARY_DIR}/reference_card.pdf DESTINATION share/clan)
	endif()


# Little help
	message(STATUS "---")
	message(STATUS "You can execute:")
	message(STATUS "    make                # To compile Clan tests")
	message(STATUS "    make test           # To execute tests")
	message(STATUS "    make install        # To install library, include and CMake module")
	message(STATUS "                        # If you need root access:")
	message(STATUS "                        #     sudo make install")
	message(STATUS "                        #     su -c \"make install\"")
	if (DOXYGEN_FOUND)
		message(STATUS "    make doxygen        # To generate the Doxygen")
	endif()
	if (texi2pdf_exe)
		message(STATUS "    make documentation  # To generate the documentation")
	endif()
	if (pdflatex_exe)
		message(STATUS "    make reference_card # To Clan reference card")
	endif()
