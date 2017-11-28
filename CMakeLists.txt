# This a sample CMakeLists.txt for compiling indicatos for Wingpanel
# http://elementaryos.org/docs/developer-guide/cmake 

cmake_minimum_required (VERSION 2.6)
cmake_policy (VERSION 2.6)

# Set the Title to use for the Indicator (May be used in future features)
set (INDICATORTITLE "Session")

# The description of what your Indicator is
set (INDICATORDESCRIPTION "Session indicator")

# Projectname
project (session)

#########################################################
# Only alter stuff below if you know what you are doing #
#########################################################

# Configuration
include (GNUInstallDirs)
set (DATADIR "${CMAKE_INSTALL_FULL_LIBDIR}/wingpanel")
set (PKGDATADIR "${DATADIR}")
set (GETTEXT_PACKAGE "${CMAKE_PROJECT_NAME}-indicator")
set (VERSION "2.0.4")
list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

set (DEPS_PACKAGES gio-2.0;gtk+-3.0;wingpanel-2.0;granite;AccountsService-1.0)

option (ENABLE_SHOW_APPS "Show running apps in the end session dialog and close them" ON)
if (ENABLE_SHOW_APPS)
    message ("-- Enabled showing apps in the end session dialog")
    set (DEPS_PACKAGES ${DEPS_PACKAGES};libbamf3;libwnck-3.0)
    set (SHOW_APPS_OPTIONS --define=HAVE_BAMF_WNCK)
else ()
    message ("-- Showing apps in the end session dialog disabled")
endif ()

# Configure file
configure_file (${CMAKE_SOURCE_DIR}/config.vala.cmake ${CMAKE_BINARY_DIR}/src/config.vala)
add_definitions (-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")

# Comment this out to enable C compiler warnings
add_definitions (-w)

# Files
file (GLOB resources "${CMAKE_CURRENT_SOURCE_DIR}/data/*")

# Traslation stuff
add_subdirectory (po)

# Code
add_subdirectory(src)

# Uninstall target
 configure_file(
     "${CMAKE_SOURCE_DIR}/cmake/Uninstall.cmake"
     "${CMAKE_CURRENT_BINARY_DIR}/Uninstall.cmake"
     IMMEDIATE @ONLY)

 add_custom_target(uninstall
     COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/Uninstall.cmake)
