set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

set(LOCAL_SDL_LIB "dependencies/lib-SDL3-3.4.14-macos/share/cmake/SDL3/SDL3Config.cmake" CACHE STRING "" FORCE)
set(LOCAL_GTEST_LIB OFF CACHE BOOL "" FORCE)
set(CMAKE_MACOSX_RPATH ON CACHE BOOL "" FORCE)

set(CMAKE_EXE_LINKER_FLAGS "-framework IOKit -framework Carbon -framework AudioUnit -framework AudioToolbox -framework OpenGL -framework CoreFoundation -framework AppKit" CACHE STRING "" FORCE)

# How old a macOS the packages can run on. Without this the binaries inherit the
# build machine's version, so a release built on macOS 15 refuses to start on
# anything older, which is how the arm64 package ended up demanding macOS 15.
# arm64 did not exist before 11.0; the x86_64 slice of the bundled SDL3 goes
# back to 10.13, and 10.14 is where libc++ starts shipping the C++17 support
# the sources need.
if(NOT CMAKE_OSX_DEPLOYMENT_TARGET)
    if(CMAKE_OSX_ARCHITECTURES)
        set(JA2_TARGET_ARCH "${CMAKE_OSX_ARCHITECTURES}")
    else()
        set(JA2_TARGET_ARCH "${CMAKE_HOST_SYSTEM_PROCESSOR}")
    endif()
    if(JA2_TARGET_ARCH MATCHES "arm64|aarch64")
        set(CMAKE_OSX_DEPLOYMENT_TARGET "11.0" CACHE STRING "" FORCE)
    else()
        set(CMAKE_OSX_DEPLOYMENT_TARGET "10.14" CACHE STRING "" FORCE)
    endif()
endif()
