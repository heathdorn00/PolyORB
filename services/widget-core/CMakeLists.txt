cmake_minimum_required(VERSION 3.20)
project(widget-core-service VERSION 1.0.0 LANGUAGES CXX)

# C++ Standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Option for building tests
option(BUILD_TESTS "Build test executables" ON)

# Find dependencies
find_package(Threads REQUIRED)

# Main executable
add_executable(widget-core-service
    src/main.cpp
)

# Include directories (optional - for future headers)
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/include")
    target_include_directories(widget-core-service PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/include
    )
endif()

target_link_libraries(widget-core-service PRIVATE
    Threads::Threads
)

# Compiler flags
target_compile_options(widget-core-service PRIVATE
    -Wall -Wextra -Wpedantic
    $<$<CONFIG:Release>:-O3>
)

# Install
install(TARGETS widget-core-service DESTINATION bin)

# Testing with GoogleTest
if(BUILD_TESTS)
    enable_testing()

    # Fetch GoogleTest
    include(FetchContent)
    FetchContent_Declare(
        googletest
        URL https://github.com/google/googletest/archive/refs/tags/v1.14.0.zip
    )
    # For Windows: Prevent overriding the parent project's compiler/linker settings
    set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
    FetchContent_MakeAvailable(googletest)

    # Test executable
    add_executable(widget-core-tests
        tests/widget_core_test.cpp
    )

    target_link_libraries(widget-core-tests PRIVATE
        GTest::gtest_main
        Threads::Threads
    )

    # Include Google Test's CMake functions
    include(GoogleTest)
    gtest_discover_tests(widget-core-tests)
endif()
