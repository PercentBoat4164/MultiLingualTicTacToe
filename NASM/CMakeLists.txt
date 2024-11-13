cmake_minimum_required(VERSION 3.30)
project(NASM LANGUAGES ASM_NASM)

add_executable(macOS_x64 src/main.asm)
target_include_directories(macOS_x64 PUBLIC ${CMAKE_SOURCE_DIR}/src)
target_compile_definitions(macOS_x64 PUBLIC MACOS)
target_link_options(macOS_x64 PUBLIC -static -macos_version_min 10.8)
