cmake_minimum_required(VERSION 3.24)

project(qmlogout VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_INCLUDE_CURRENT_DIR ON)

include(CheckCXXCompilerFlag)
if(NOT CMAKE_CROSSCOMPILING)
    string(TOLOWER "${CMAKE_HOST_SYSTEM_PROCESSOR}" QMLOGOUT_HOST_PROCESSOR)
    string(TOLOWER "${CMAKE_SYSTEM_PROCESSOR}" QMLOGOUT_TARGET_PROCESSOR)
    if(QMLOGOUT_HOST_PROCESSOR MATCHES "^(x86_64|amd64)$"
       AND QMLOGOUT_TARGET_PROCESSOR MATCHES "^(x86_64|amd64)$")
        check_cxx_compiler_flag("-march=x86-64-v3" QMLOGOUT_HAS_X86_64_V3)
        if(QMLOGOUT_HAS_X86_64_V3)
            add_compile_options($<$<COMPILE_LANGUAGE:CXX>:-march=x86-64-v3>)
        endif()
    endif()
endif()

set(QT_NO_PRIVATE_MODULE_WARNING ON CACHE BOOL
    "MauiKit uses Qt's private WaylandClient API" FORCE)

find_package(ECM 6.13 REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})
include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)
include(ECMFindQmlModule)
include(FeatureSummary)

find_package(Qt6 6.6 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2)
find_package(KF6 6.13 REQUIRED COMPONENTS CoreAddons)
find_package(MauiKit4 4.0.5 REQUIRED)
find_package(LayerShellQt 6.0 REQUIRED)
ecm_find_qmlmodule(org.mauikit.controls 1.0)

add_executable(qmlogout
    src/main.cpp
    src/sessionmanager.cpp
    src/sessionmanager.h
    qmlogout.qrc)

target_link_options(qmlogout PRIVATE -Wl,--no-as-needed)
target_link_libraries(qmlogout PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    KF6::CoreAddons
    MauiKit4
    LayerShellQt::Interface)

if(CMAKE_BUILD_TYPE STREQUAL "Release")
    target_compile_definitions(qmlogout PRIVATE QT_NO_DEBUG_OUTPUT)
endif()

install(TARGETS qmlogout RUNTIME DESTINATION ${KDE_INSTALL_BINDIR})

if(NOT TARGET uninstall)
    configure_file(
        "${CMAKE_CURRENT_SOURCE_DIR}/cmake_uninstall.cmake.in"
        "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
        IMMEDIATE @ONLY)
    add_custom_target(uninstall
        COMMAND ${CMAKE_COMMAND} -P "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake")
endif()

feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)
