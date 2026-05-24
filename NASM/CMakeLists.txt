cmake_minimum_required(VERSION 3.30)
project(NASM LANGUAGES ASM_NASM)

unset(CMAKE_CXX_COMPILER)
unset(CMAKE_C_COMPILER)

add_executable(NASM_x64 src/main.asm)
target_include_directories(NASM_x64 PUBLIC ${CMAKE_SOURCE_DIR}/src)
if (APPLE)
    target_link_options(NASM_x64 PUBLIC -static -macos_version_min 10.8)
    target_compile_definitions(NASM_x64 PUBLIC MACOS)
elseif (UNIX)
    target_compile_definitions(NASM_x64 PUBLIC LINUX)
endif ()