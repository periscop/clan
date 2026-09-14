cmake_minimum_required(VERSION 3.12)
project(clan VERSION 0.9.0 LANGUAGES C)


set(PACKAGE_VERSION "${PROJECT_VERSION}")
set(VERSION_MAJOR "${PROJECT_VERSION_MAJOR}")
set(VERSION_MINOR "${PROJECT_VERSION_MINOR}")
set(VERSION_REVISION "${PROJECT_VERSION_PATCH}")
set(top_srcdir "${CMAKE_CURRENT_SOURCE_DIR}")

set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)


# Honor the standard CMake build types and user-supplied compiler flags.
set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED TRUE)

include("${CMAKE_CURRENT_SOURCE_DIR}/asan.cmake")

# Build doxygen
	find_package(Doxygen)
	if(DOXYGEN_FOUND)
		configure_file("doc/Doxyfile.in" "Doxyfile")
		add_custom_target(
			doxygen
			${DOXYGEN_EXECUTABLE} ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile
			WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
			COMMENT "Generating API documentation with Doxygen" VERBATIM
		)
	else()
		message (STATUS "Doxygen not found :( API documentation can not be built")
	endif()

# Build documentation

	# doc
	find_program(texi2pdf_exe texi2pdf)
	if(texi2pdf_exe)
		add_custom_target(
			doc
			${texi2pdf_exe} ${CMAKE_CURRENT_SOURCE_DIR}/doc/clan.texi --output=clan.pdf
			WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
			COMMENT "Generating documentation (pdf) (with texi2pdf)" VERBATIM
		)
	else()
		message (STATUS "texi2pdf not found :( Documentation can not be built")
	endif()

	# Reference card
	find_program(pdflatex_exe pdflatex)
	if(pdflatex_exe)
		file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/doc/reference_card DESTINATION ${CMAKE_CURRENT_BINARY_DIR})
		add_custom_target(
			ref_card
			${pdflatex_exe} ${CMAKE_CURRENT_BINARY_DIR}/reference_card/reference_card.tex
			WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/reference_card"
			COMMENT "Generating Clan reference card (pdf) (with pdflatex)" VERBATIM
		)
	else()
		message (STATUS "pdflatex not found =( Clan reference card can not be built")
	endif()


# osl
	find_package(osl REQUIRED CONFIG)
	# CMake installations export a target; Autotools installations provide
	# the legacy OSL_LIBRARY and OSL_INCLUDE_DIR variables.
	if(TARGET osl)
		set(OSL_LIBRARY osl)
	else()
		include_directories("${OSL_INCLUDE_DIR}")
	endif()

# Flex
	find_package(BISON REQUIRED)
	find_package(FLEX REQUIRED)
	file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/source")
	BISON_TARGET(clan_parser source/parser.y ${CMAKE_CURRENT_BINARY_DIR}/source/parser.c)
	FLEX_TARGET(clan_scanner source/scanner.l ${CMAKE_CURRENT_BINARY_DIR}/source/scanner.c)
	ADD_FLEX_BISON_DEPENDENCY(clan_scanner clan_parser)
	add_custom_target(clan_generated DEPENDS
		${BISON_clan_parser_OUTPUTS} ${FLEX_clan_scanner_OUTPUTS})
	include_directories(${CMAKE_CURRENT_BINARY_DIR} ${CMAKE_CURRENT_BINARY_DIR}/source)

# Include directories (to use #include <> instead of #include "")

	# include/clan/macros.h
	configure_file("include/clan/macros.h.in" "include/clan/macros.h")
	include_directories("${CMAKE_CURRENT_BINARY_DIR}/include")
	# clan
	include_directories("./include" "./source")


# Library sources: never include generated scanner/parser files from a
# previous in-source Autotools build.
set(sources
    source/access.c
  	source/options.c
  	source/symbol.c
  	source/scop.c
  	source/statement.c
  	source/relation.c
  	source/relation_list.c
  	source/vector.c)

	# Shared
	add_library(
		clan
		SHARED
		${sources}
		${BISON_clan_parser_OUTPUTS}
		${FLEX_clan_scanner_OUTPUTS}
	)
	add_dependencies(clan clan_generated)
	target_link_libraries(clan ${OSL_LIBRARY})


	# Static
	add_library(
		clan_static
		STATIC
		${sources}
		${BISON_clan_parser_OUTPUTS}
		${FLEX_clan_scanner_OUTPUTS}
	)
	set_target_properties(clan_static PROPERTIES OUTPUT_NAME clan)
	add_dependencies(clan_static clan_generated)
	target_link_libraries(clan_static ${OSL_LIBRARY})



# Executables & tests

	message(STATUS "---") # clan

	message(STATUS "Add executable clan")
	add_executable(clan_exe "source/clan.c")
	set_target_properties(clan_exe PROPERTIES OUTPUT_NAME "clan")
	target_link_libraries(clan_exe clan_static ${OSL_LIBRARY})

# Run each fixture through the same shell checker used by make check.
enable_testing()
find_program(SH_EXECUTABLE sh)
if(NOT SH_EXECUTABLE)
  message(FATAL_ERROR "Clan tests require a POSIX shell")
endif()
add_test(NAME checker COMMAND "${SH_EXECUTABLE}"
  "${CMAKE_CURRENT_SOURCE_DIR}/tests/check_checker.sh"
  "${CMAKE_CURRENT_SOURCE_DIR}/tests/checker.sh")
add_test(NAME affine-only
  COMMAND "${CMAKE_COMMAND}" -E env
    "top_builddir=$<TARGET_FILE_DIR:clan_exe>"
    "srcdir=${CMAKE_CURRENT_SOURCE_DIR}/tests"
    "EXEEXT=${CMAKE_EXECUTABLE_SUFFIX}"
    "${SH_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/check_affine_only.sh")
file(GLOB_RECURSE tests "${CMAKE_CURRENT_SOURCE_DIR}/tests/*.c")
list(REMOVE_ITEM tests "${CMAKE_CURRENT_SOURCE_DIR}/tests/leaks-wrapper.c")
foreach(test IN LISTS tests)
  file(RELATIVE_PATH test_name "${CMAKE_CURRENT_SOURCE_DIR}/tests" "${test}")
  set(test_option "")
  if(test_name MATCHES "^autoinsert/")
    set(test_option "-autoinsert")
  elseif(test_name MATCHES "^autoscop/")
    set(test_option "-autoscop")
  endif()
  add_test(NAME "${test_name}"
    COMMAND "${CMAKE_COMMAND}" -E env
      "top_builddir=$<TARGET_FILE_DIR:clan_exe>"
      "EXEEXT=${CMAKE_EXECUTABLE_SUFFIX}"
      "${SH_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/checker.sh"
      "${test_name}" "${test}" "${test_option}" clan)
  if(test_name MATCHES "^(must_fail|nonaffine|private)/")
    add_test(NAME "${test_name}-extbody"
      COMMAND "${CMAKE_COMMAND}" -E env
        "top_builddir=$<TARGET_FILE_DIR:clan_exe>"
        "EXEEXT=${CMAKE_EXECUTABLE_SUFFIX}"
        "${SH_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/checker.sh"
        "${test_name}-extbody" "${test}" -extbody clan)
  endif()
endforeach()


# Keep leak runs separate from normal CTest runs and use the same fixtures.
configure_file(leakscheck.cmake.in leakscheck.cmake @ONLY)
add_custom_target(leakscheck
  COMMAND "${CMAKE_COMMAND}"
    "-DCLAN_TEST_BINDIR=$<TARGET_FILE_DIR:clan_exe>"
    -P "${CMAKE_CURRENT_BINARY_DIR}/leakscheck.cmake"
  DEPENDS clan_exe
  VERBATIM
  USES_TERMINAL
  COMMENT "Checking Clan fixtures with Apple's macOS leaks tool")


# Install

	install(TARGETS clan LIBRARY DESTINATION lib)
	install(TARGETS clan_static ARCHIVE DESTINATION lib)
	install(DIRECTORY include/ DESTINATION include FILES_MATCHING PATTERN "*.h")
	install(DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/include/" DESTINATION include FILES_MATCHING PATTERN "*.h")
	install(FILES "${CMAKE_CURRENT_BINARY_DIR}/source/parser.h" DESTINATION include/clan)
	install(FILES clan-config.cmake DESTINATION lib/clan)
	install(TARGETS clan_exe RUNTIME DESTINATION bin)


# Little help

	message(STATUS "You can execute:")
	message(STATUS "    make          # To compile clan library & clan")
	message(STATUS "    make test     # To execute tests")
	message(STATUS "    make install  # To install library, include and CMake module")
	message(STATUS "                  # If you need root access:")
	message(STATUS "                  #     sudo make install")
	message(STATUS "                  #     su -c \"make install\"")
	if(DOXYGEN_FOUND)
		message(STATUS "    make doxygen  # To generate the Doxygen")
	endif()
	if(texi2pdf_exe)
		message(STATUS "    make doc      # To generate the documentation")
	endif()
	if(pdflatex_exe)
		message(STATUS "    make ref_card # To generate Clan reference card")
	endif()

	message(STATUS "---")
