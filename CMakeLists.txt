cmake_minimum_required(VERSION 2.6)


set(PACKAGE_VERSION "0.7.1")
set(top_srcdir "${CMAKE_CURRENT_SOURCE_DIR}")

set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)


# User's settings - C Flags

# 	set(release "TRUE")
	set(release "FALSE")

	# Release
	if (release)
		set(CMAKE_C_FLAGS "-O3")
	# Debug # valgrind --show-reachable=yes --leak-check=full -v exe
	else()
		set(CMAKE_C_FLAGS "-O0 -g3")
	endif()

# User's settings - General C Flags
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -Wextra -pedantic -std=c99")


# Build doxygen
	find_package(Doxygen)
	if(DOXYGEN_FOUND)
		configure_file("doc/Doxyfile.in" "Doxyfile")
		add_custom_target(
			doc
			${DOXYGEN_EXECUTABLE} ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile
			WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
			COMMENT "Generating API documentation with Doxygen" VERBATIM
		)
	endif()


# osl
	find_package(osl REQUIRED)

# Flex
	find_package(BISON)
	find_package(FLEX)
	BISON_TARGET(clan_parser source/parser.y ${CMAKE_CURRENT_BINARY_DIR}/parser.c)
	FLEX_TARGET(clan_scanner source/scanner.l  ${CMAKE_CURRENT_BINARY_DIR}/scanner.c)
	ADD_FLEX_BISON_DEPENDENCY(clan_scanner clan_parser)
	include_directories(${CMAKE_CURRENT_BINARY_DIR})

# files .c
	file(
		GLOB_RECURSE
		sources
		source/*
	)
	string(REGEX REPLACE "${CMAKE_CURRENT_SOURCE_DIR}/source/clan.c;" "" sources "${sources}") # with ;
	string(REGEX REPLACE "${CMAKE_CURRENT_SOURCE_DIR}/source/clan.c" "" sources "${sources}")  # without ;

# Include directories (to use #include <> instead of #include "")

	# include/clan/macros.h
	configure_file("include/clan/macros.h.in" "include/clan/macros.h")
	include_directories("${CMAKE_CURRENT_BINARY_DIR}/include")
	# clan
	set(clan_INCLUDE "./include")
	message(STATUS "Include clan = ${clan_INCLUDE}")
	include_directories("${clan_INCLUDE}")


# Compiler log
	message(STATUS "---")
	message(STATUS "C compiler = ${CMAKE_C_COMPILER}")
	if (release)
		message(STATUS "Mode Release")
	else()
		message(STATUS "Mode Debug")
	endif()
	message(STATUS "C flags    = ${CMAKE_C_FLAGS}")


# Library
	add_library(
		clan
		SHARED
		${sources}
		${BISON_clan_parser_OUTPUTS}
		${FLEX_clan_scanner_OUTPUTS}
	)
	target_link_libraries(clan ${OSL_LIBRARY})
	get_property(clan_lib_location TARGET clan PROPERTY LOCATION)


# Executables & tests

	enable_testing()

	message(STATUS "---") # clan

	message(STATUS "Add executable clan")
	add_executable(clan_exe "source/clan.c")
	set_target_properties(clan_exe PROPERTIES OUTPUT_NAME "clan")
	target_link_libraries(clan_exe ${clan_lib_location} ${OSL_LIBRARY})

	message(STATUS "---") # clan tests
	
	find_package(PythonInterp REQUIRED)

	file(
		GLOB_RECURSE
		tests
		tests/*.c
	)

	foreach(test ${tests})
		message(STATUS "Add Test ${test}")
		add_test(
			${test}
			"${CMAKE_CURRENT_SOURCE_DIR}/tests/check_source_result.py"
			"${test}"
			"${test}.scop"
			"${CMAKE_CURRENT_BINARY_DIR}/clan"
		)
		endforeach()
		
	message(STATUS "---")


# Install

	install(TARGETS clan LIBRARY DESTINATION lib)
	install(DIRECTORY include/ DESTINATION include FILES_MATCHING PATTERN "*.h")
	install(DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/include/" DESTINATION include FILES_MATCHING PATTERN "*.h")
	install(FILES "${CMAKE_CURRENT_BINARY_DIR}/parser.h" DESTINATION include/clan)
	install(FILES clan-config.cmake DESTINATION lib/clan)
	install(TARGETS clan_exe RUNTIME DESTINATION bin)


# Little help

	message(STATUS "You can execute:")
	message(STATUS "    make         # To compile clan library & clan")
	message(STATUS "    make test    # To execute tests")
	message(STATUS "    make install # To install library, include and CMake module")
	message(STATUS "                 # If you need root access:")
	message(STATUS "                 #     sudo make install")
	message(STATUS "                 #     su -c \"make install\"")
	message(STATUS "    make doc     # To generate the Doxygen")

	message(STATUS "---")
