cmake_minimum_required(VERSION 3.20)

project(aoc2022
	VERSION 1.0
	DESCRIPTION "Advent of Code 2022"
	LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)

set(CMAKE_DISABLE_IN_SOURCE_BUILD ON)
set(CMAKE_DISABLE_SOURCE_CHANGES  ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_C_EXTENSIONS OFF)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_C_STANDARD_REQUIRED   ON)

set(PROJECT_BINARY_DIR ${CMAKE_SOURCE_DIR}/bin)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}")

foreach( OUTPUTCONFIG ${CMAKE_CONFIGURATION_TYPES} )
	string( TOUPPER ${OUTPUTCONFIG} OUTPUTCONFIG )
	set( CMAKE_RUNTIME_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${PROJECT_BINARY_DIR} )
	set( CMAKE_LIBRARY_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${PROJECT_BINARY_DIR} )
	set( CMAKE_ARCHIVE_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${PROJECT_BINARY_DIR} )
endforeach( OUTPUTCONFIG CMAKE_CONFIGURATION_TYPES )

# Some compiler configs as interface projects
add_library(common_options INTERFACE)
set(common_warnings)
if(MSVC)
	set(common_warnings /W4 /permissive- /WX)
else()
	set(common_warnings -Wall -Wextra -Werror -Wpedantic)
endif()

target_compile_options(common_options INTERFACE ${common_warnings})

set(days_list)

# Quick and dirty macro to add days
macro(add_day day_num)
	set(day day${day_num})
	add_executable(${day} src/${day}.cpp)
	target_link_libraries(${day} PUBLIC common_options)
	list(APPEND days_list ${day})
	set_target_properties(${day} PROPERTIES VS_DEBUGGER_WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/input)
endmacro()

add_day(1)
add_day(2)
add_day(3)
add_day(4)
add_day(5)
add_day(6)
add_day(7)
add_day(8)
add_day(9)
add_day(10)
add_day(11)
add_day(12)
add_day(13)
add_day(14)
