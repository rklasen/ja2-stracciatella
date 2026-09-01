message(STATUS "Entering launcher directory")

option(BUILD_LAUNCHER "Build the ja2 launcher application" ON)
option(LOCAL_FLTK_LIB "Download and build fltk library instead of using system-wide version" OFF)

if(NOT BUILD_LAUNCHER)
    return()
endif()

if (NOT LOCAL_FLTK_LIB)
    find_package(FLTK)
    if(NOT FLTK_FOUND)
        message(STATUS "FLTK not found. Disabling launcher.")
        set(BUILD_LAUNCHER OFF)
    endif()
else()
    set(FLTK_LIBRARIES "")
    set(FLTK_INCLUDE_DIR "")
    add_subdirectory("${CMAKE_SOURCE_DIR}/dependencies/lib-fltk" "${CMAKE_BINARY_DIR}/dependencies/lib-fltk" SYSTEM)
endif()
message(STATUS "Fltk Libraries: ${FLTK_LIBRARIES}")

file(GLOB LOCAL_LAUNCHER_HEADERS ${CMAKE_CURRENT_SOURCE_DIR}/*.h)

add_executable(${LAUNCHER_BINARY}
    "${CMAKE_SOURCE_DIR}/src/sgp/FileMan.cc"
    "${CMAKE_SOURCE_DIR}/src/sgp/SGPFile.cc"
    "${CMAKE_SOURCE_DIR}/src/sgp/SGPStrings.cc"
    ${LOCAL_LAUNCHER_HEADERS}
    StracciatellaLauncher.cc
    Launcher.cc
    main.cc
)

# Ensure the launcher executable is build in the same directory as the game.
set_target_properties(${LAUNCHER_BINARY}
    PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}
)

add_dependencies(${LAUNCHER_BINARY} stracciatella)

if (NOT LOCAL_FLTK_LIB AND APPLE)
    find_package(PNG REQUIRED)

    # The archives below live in the Homebrew keg, whose prefix differs between
    # Apple Silicon (/opt/homebrew) and Intel (/usr/local), so ask brew for it
    # rather than hardcoding one of the two.
    if(NOT FLTK13_PREFIX)
        find_program(BREW_EXECUTABLE brew)
        if(BREW_EXECUTABLE)
            execute_process(
                COMMAND "${BREW_EXECUTABLE}" --prefix fltk@1.3
                OUTPUT_VARIABLE FLTK13_BREW_PREFIX
                OUTPUT_STRIP_TRAILING_WHITESPACE
                ERROR_QUIET
                RESULT_VARIABLE FLTK13_BREW_RESULT)
            if(FLTK13_BREW_RESULT EQUAL 0)
                set(FLTK13_PREFIX "${FLTK13_BREW_PREFIX}" CACHE PATH "Prefix of the fltk@1.3 installation the launcher links against")
            endif()
        endif()
    endif()
    if(NOT FLTK13_PREFIX)
        message(FATAL_ERROR "Could not locate fltk@1.3. Install it with `brew install fltk@1.3`, or point FLTK13_PREFIX at a prefix that contains lib/libfltk.a.")
    endif()

    # force static linking
    set(FLTK13_STATIC_LIBRARIES "")
    foreach(FLTK13_LIBRARY fltk_forms fltk_images fltk)
        set(FLTK13_ARCHIVE "${FLTK13_PREFIX}/lib/lib${FLTK13_LIBRARY}.a")
        if(NOT EXISTS "${FLTK13_ARCHIVE}")
            message(FATAL_ERROR "Expected a static fltk@1.3 archive at ${FLTK13_ARCHIVE} but it does not exist.")
        endif()
        list(APPEND FLTK13_STATIC_LIBRARIES "${FLTK13_ARCHIVE}")
    endforeach()
    message(STATUS "Fltk static libraries: ${FLTK13_STATIC_LIBRARIES}")

    target_link_libraries(${LAUNCHER_BINARY} PRIVATE
        ${FLTK13_STATIC_LIBRARIES} ${PNG_LIBRARIES}
    )
else ()
    target_link_libraries(${LAUNCHER_BINARY} PRIVATE
        ${FLTK_LIBRARIES}
    )
endif ()

target_compile_features(${LAUNCHER_BINARY} PRIVATE cxx_std_20)

target_link_libraries(${LAUNCHER_BINARY} PRIVATE
    ${STRACCIATELLA_LIBRARIES}
    SDL3::SDL3-shared
    string_theory-internal
)

target_include_directories(${LAUNCHER_BINARY} PRIVATE
    ${FLTK_INCLUDE_DIR}
    SDL3::Headers
    "${CMAKE_SOURCE_DIR}/src/externalized"
    "${CMAKE_SOURCE_DIR}/src/game"
    "${CMAKE_SOURCE_DIR}/src/sgp"
)

add_warnings(${LAUNCHER_BINARY})

add_custom_target(run-${LAUNCHER_BINARY}
    COMMAND "$<TARGET_FILE:${LAUNCHER_BINARY}>"
    WORKING_DIRECTORY "$<TARGET_FILE_DIR:${LAUNCHER_BINARY}>"
    DEPENDS "${LAUNCHER_BINARY}"
)

if(APPLE AND NOT (LOCAL_SDL_LIB STREQUAL ""))
    add_custom_command(TARGET ${LAUNCHER_BINARY}
        POST_BUILD COMMAND
        ${CMAKE_INSTALL_NAME_TOOL} -add_rpath "@executable_path"
        "$<TARGET_FILE:${LAUNCHER_BINARY}>"
    )
endif()
