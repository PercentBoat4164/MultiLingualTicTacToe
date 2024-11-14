cmake_minimum_required(VERSION 3.30)
project(NASM LANGUAGES ASM_NASM)

unset(CMAKE_CXX_COMPILER)
unset(CMAKE_C_COMPILER)

add_executable(macOS_x64 src/main.asm)
target_include_directories(macOS_x64 PUBLIC ${CMAKE_SOURCE_DIR}/src)
target_compile_definitions(macOS_x64 PUBLIC MACOS)
if (APPLE)
    target_link_options(macOS_x64 PUBLIC -static -macos_version_min 10.8)
endif ()

add_executable(Linux_x64 src/main.asm)
target_include_directories(Linux_x64 PUBLIC ${CMAKE_SOURCE_DIR}/src)
target_compile_definitions(Linux_x64 PUBLIC LINUX)