# - Find a Message Passing Interface (MPI) implementation
# The Message Passing Interface (MPI) is a library used to write
# high-performance distributed-memory parallel applications, and
# is typically deployed on a cluster. MPI is a standard interface
# (defined by the MPI forum) for which many implementations are
# available. All of them have somewhat different include paths,
# libraries to link against, etc., and this module tries to smooth
# out those differences.
#
# === Variables ===
#
# This module will set the following variables per language in your project,
# where <lang> is one of C, CXX, or Fortran:
#   MPI_FOUND                  TRUE if FindMPI found MPI flags for all <lang>
#   MPI_<lang>_COMPILER        MPI Compiler wrapper for <lang>
#   MPI_<lang>_COMPILE_FLAGS   Compilation flags for MPI programs (space separated)
#   MPI_<lang>_COMPILE_OPTIONS Compilation flags for MPI programs (as a list)
#   MPI_<lang>_INCLUDE_PATH    Include path(s) for MPI header
#   MPI_<lang>_LINK_FLAGS      Linking flags for MPI programs
#   MPI_<lang>_LIBRARIES       All libraries to link MPI programs against
# Additionally, FindMPI sets the following variables for running MPI
# programs from the command line:
#   MPIEXEC                    Executable for running MPI programs
# === Usage ===
#
# To use this module, simply call FindMPI from a CMakeLists.txt file, or
# run find_package(MPI), then run CMake.  If you are happy with the auto-
# detected configuration for your language, then you're done.  If not, you
# have two options:
#   1. Set MPI_<lang>_COMPILER to the MPI wrapper (mpicc, etc.) of your
#      choice and reconfigure.  FindMPI will attempt to determine all the
#      necessary variables using THAT compiler's compile and link flags.
#   2. If this fails, or if your MPI implementation does not come with
#      a compiler wrapper, then set both MPI_<lang>_LIBRARIES and
#      MPI_<lang>_INCLUDE_PATH.  You may also set any other variables
#      listed above, but these two are required.  This will circumvent
#      autodetection entirely.
# When configuration is successful, MPI_<lang>_COMPILER will be set to the
# compiler wrapper for <lang>, if it was found.  MPI_<lang>_FOUND and other
# variables above will be set if any MPI implementation was found for <lang>,
# regardless of whether a compiler was found.
#
# When using MPIEXEC to execute MPI applications, you should typically use
# all of the MPIEXEC flags as follows:
#   ${MPIEXEC} ${MPIEXEC_NUMPROC_FLAG} PROCS
#     ${MPIEXEC_PREFLAGS} EXECUTABLE ${MPIEXEC_POSTFLAGS} ARGS
# where PROCS is the number of processors on which to execute the program,
# EXECUTABLE is the MPI program, and ARGS are the arguments to pass to the
# MPI program.

#=============================================================================
# Copyright 2013 CEA, Julien Bigot <julien.bigot@cea.fr>
# Copyright 2001-2011 Kitware, Inc.
# Copyright 2010-2011 Todd Gamblin tgamblin@llnl.gov
# Copyright 2001-2009 Dave Partyka
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# * Redistributions of source code must retain the above copyright notice,
#   this list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
# * Neither the names of Kitware, Inc., the Insight Software Consortium, nor
#   the names of their contributors may be used to endorse or promote products
#   derived from this software without specific prior written  permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#=============================================================================

cmake_minimum_required(VERSION 2.8.12)

# Protect against multiple inclusion, which would fail when already imported targets are added once more.
if(NOT TARGET mpi)

# include this to handle the QUIETLY and REQUIRED arguments
include(FindPackageHandleStandardArgs)
include(GetPrerequisites)

#
# This part detects MPI compilers, attempting to wade through the mess of compiler names in
# a sensible way.
#
# The compilers are detected in this order:
#
# 1. Try to find the most generic availble MPI compiler, as this is usually set up by
#    cluster admins.  e.g., if plain old mpicc is available, we'll use it and assume it's
#    the right compiler.
#
# 2. If a generic mpicc is NOT found, then we attempt to find one that matches
#    CMAKE_<lang>_COMPILER_ID. e.g. if you are using XL compilers, we'll try to find mpixlc
#    and company, but not mpiicc.  This hopefully prevents toolchain mismatches.
#
# If you want to force a particular MPI compiler other than what we autodetect (e.g. if you
# want to compile regular stuff with GNU and parallel stuff with Intel), you can always set
# your favorite MPI_<lang>_COMPILER explicitly and this stuff will be ignored.
#

# Start out with the generic MPI compiler names, as these are most commonly used.
set(_MPI_C_COMPILER_NAMES                  mpicc_r  mpcc_r
                                           mpicc    mpcc)
set(_MPI_CXX_COMPILER_NAMES                mpicxx_r mpiCC_r mpic++_r mpcxx_r mpCC_r mpc++_r
                                           mpicxx   mpiCC   mpic++   mpcxx   mpCC   mpc++)
set(_MPI_Fortran_COMPILER_NAMES            mpif95_r mpf95_r mpif90_r mpf90_r mpif77_r mpf77_r
                                           mpif95   mpf95   mpif90   mpf90   mpif77   mpf77)

# GNU compiler names
set(_MPI_GNU_C_COMPILER_NAMES              mpigcc_r mpgcc_r
                                           mpigcc   mpgcc)
set(_MPI_GNU_CXX_COMPILER_NAMES            mpig++_r mpg++_r
                                           mpig++   mpg++)
set(_MPI_GNU_Fortran_COMPILER_NAMES        mpigfortran_r mpgfortran_r mpig77_r mpg77_r
                                           mpigfortran   mpgfortran   mpig77   mpg77)

# Intel MPI compiler names
set(_MPI_Intel_C_COMPILER_NAMES            mpiicc)
set(_MPI_Intel_CXX_COMPILER_NAMES          mpiicpc  mpiicxx mpiic++ mpiiCC)
set(_MPI_Intel_Fortran_COMPILER_NAMES      mpiifort mpiif95 mpiif90 mpiif77)

# PGI compiler names
set(_MPI_PGI_C_COMPILER_NAMES              mpipgcc mppgcc)
set(_MPI_PGI_CXX_COMPILER_NAMES            mpipgCC mppgCC)
set(_MPI_PGI_Fortran_COMPILER_NAMES        mpipgf95 mpipgf90 mppgf95 mppgf90 mpipgf77 mppgf77)

# XLC MPI Compiler names
set(_MPI_XL_C_COMPILER_NAMES               mpixlc_r mpxlc_r
                                           mpixlc   mpxlc)
set(_MPI_XL_CXX_COMPILER_NAMES             mpixlcxx_r mpixlC_r mpixlc++_r mpxlcxx_r mpxlc++_r mpxlCC_r
                                           mpixlcxx   mpixlC   mpixlc++   mpxlcxx   mpxlc++   mpxlCC)
set(_MPI_XL_Fortran_COMPILER_NAMES         mpixlf95_r mpxlf95_r mpixlf90_r mpxlf90_r
                                           mpixlf77_r mpxlf77_r mpixlf_r   mpxlf_r
                                           mpixlf95   mpxlf95   mpixlf90   mpxlf90
                                           mpixlf77   mpxlf77   mpixlf     mpxlf)

# append vendor-specific compilers to the list if we either don't know the compiler id,
# or if we know it matches the regular compiler.
foreach (lang C CXX Fortran)
  foreach (id GNU Intel PGI XL)
    if (NOT CMAKE_${lang}_COMPILER_ID OR "${CMAKE_${lang}_COMPILER_ID}" STREQUAL "${id}")
      list(APPEND _MPI_${lang}_COMPILER_NAMES ${_MPI_${id}_${lang}_COMPILER_NAMES})
    endif()
    unset(_MPI_${id}_${lang}_COMPILER_NAMES)    # clean up the namespace here
  endforeach()
endforeach()


# Names to try for MPI exec
set(_MPI_EXEC_NAMES                        mpiexec mpirun lamexec srun)

# Grab the path to MPI from the registry if we're on windows.
set(_MPI_PREFIX_PATH)
if(WIN32)
  list(APPEND _MPI_PREFIX_PATH "[HKEY_LOCAL_MACHINE\\SOFTWARE\\MPICH\\SMPD;binary]/..")
  list(APPEND _MPI_PREFIX_PATH "[HKEY_LOCAL_MACHINE\\SOFTWARE\\MPICH2;Path]")
  list(APPEND _MPI_PREFIX_PATH "$ENV{ProgramW6432}/MPICH2/")
endif()

# Build a list of prefixes to search for MPI.
foreach(SystemPrefixDir ${CMAKE_SYSTEM_PREFIX_PATH})
  foreach(MpiPackageDir ${_MPI_PREFIX_PATH})
    if(EXISTS ${SystemPrefixDir}/${MpiPackageDir})
      list(APPEND _MPI_PREFIX_PATH "${SystemPrefixDir}/${MpiPackageDir}")
    endif()
  endforeach()
endforeach()


#
# interrogate_mpi_compiler(lang try_libs)
#
# Attempts to extract compiler and linker args from an MPI compiler. The arguments set
# by this function are:
#
#   MPI_<lang>_INCLUDE_PATH    MPI_<lang>_LINK_FLAGS     MPI_<lang>_FOUND
#   MPI_<lang>_COMPILE_FLAGS   MPI_<lang>_LIBRARIES
#
# MPI_<lang>_COMPILER must be set beforehand to the absolute path to an MPI compiler for
# <lang>.  Additionally, MPI_<lang>_INCLUDE_PATH and MPI_<lang>_LIBRARIES may be set
# to skip autodetection.
#
# If try_libs is TRUE, this will also attempt to find plain MPI libraries in the usual
# way.  In general, this is not as effective as interrogating the compilers, as it
# ignores language-specific flags and libraries.  However, some MPI implementations
# (Windows implementations) do not have compiler wrappers, so this approach must be used.
#
function (interrogate_mpi_compiler lang try_libs)
  # MPI_${lang}_NO_INTERROGATE will be set to a compiler name when the *regular* compiler was
  # discovered to be the MPI compiler.  This happens on machines like the Cray XE6 that use
  # modules to set cc, CC, and ftn to the MPI compilers.  If the user force-sets another MPI
  # compiler, MPI_${lang}_COMPILER won't be equal to MPI_${lang}_NO_INTERROGATE, and we'll
  # inspect that compiler anew.  This allows users to set new compilers w/o rm'ing cache.
  string(COMPARE NOTEQUAL "${MPI_${lang}_NO_INTERROGATE}" "${MPI_${lang}_COMPILER}" interrogate)

  # If MPI is set already in the cache, don't bother with interrogating the compiler.
  if (interrogate AND ((NOT MPI_${lang}_INCLUDE_PATH) OR (NOT MPI_${lang}_LIBRARIES)))
    if (MPI_${lang}_COMPILER)
      # Check whether the -showme:compile option works. This indicates that we have either OpenMPI
      # or a newer version of LAM-MPI, and implies that -showme:link will also work.
      execute_process(
        COMMAND ${MPI_${lang}_COMPILER} -showme:compile
        OUTPUT_VARIABLE  MPI_COMPILE_CMDLINE OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_VARIABLE   MPI_COMPILE_CMDLINE ERROR_STRIP_TRAILING_WHITESPACE
        RESULT_VARIABLE  MPI_COMPILER_RETURN)

      if (MPI_COMPILER_RETURN EQUAL 0)
        # If we appear to have -showme:compile, then we should
        # also have -showme:link. Try it.
        execute_process(
          COMMAND ${MPI_${lang}_COMPILER} -showme:link
          OUTPUT_VARIABLE  MPI_LINK_CMDLINE OUTPUT_STRIP_TRAILING_WHITESPACE
          ERROR_VARIABLE   MPI_LINK_CMDLINE ERROR_STRIP_TRAILING_WHITESPACE
          RESULT_VARIABLE  MPI_COMPILER_RETURN)

        if (MPI_COMPILER_RETURN EQUAL 0)
          # We probably have -showme:incdirs and -showme:libdirs as well,
          # so grab that while we're at it.
          execute_process(
            COMMAND ${MPI_${lang}_COMPILER} -showme:incdirs
            OUTPUT_VARIABLE  MPI_INCDIRS OUTPUT_STRIP_TRAILING_WHITESPACE
            ERROR_VARIABLE   MPI_INCDIRS ERROR_STRIP_TRAILING_WHITESPACE)

          execute_process(
            COMMAND ${MPI_${lang}_COMPILER} -showme:libdirs
            OUTPUT_VARIABLE  MPI_LIBDIRS OUTPUT_STRIP_TRAILING_WHITESPACE
            ERROR_VARIABLE   MPI_LIBDIRS ERROR_STRIP_TRAILING_WHITESPACE)

        else()
          # reset things here if something went wrong.
          set(MPI_COMPILE_CMDLINE)
          set(MPI_LINK_CMDLINE)
        endif()
      endif ()

      # Older versions of LAM-MPI have "-showme". Try to find that.
      if (NOT MPI_COMPILER_RETURN EQUAL 0)
        execute_process(
          COMMAND ${MPI_${lang}_COMPILER} -showme
          OUTPUT_VARIABLE  MPI_COMPILE_CMDLINE OUTPUT_STRIP_TRAILING_WHITESPACE
          ERROR_VARIABLE   MPI_COMPILE_CMDLINE ERROR_STRIP_TRAILING_WHITESPACE
          RESULT_VARIABLE  MPI_COMPILER_RETURN)
      endif()

      # MVAPICH uses -compile-info and -link-info.  Try them.
      if (NOT MPI_COMPILER_RETURN EQUAL 0)
        execute_process(
          COMMAND ${MPI_${lang}_COMPILER} -compile-info
          OUTPUT_VARIABLE  MPI_COMPILE_CMDLINE OUTPUT_STRIP_TRAILING_WHITESPACE
          ERROR_VARIABLE   MPI_COMPILE_CMDLINE ERROR_STRIP_TRAILING_WHITESPACE
          RESULT_VARIABLE  MPI_COMPILER_RETURN)

        # If we have compile-info, also have link-info.
        if (MPI_COMPILER_RETURN EQUAL 0)
          execute_process(
            COMMAND ${MPI_${lang}_COMPILER} -link-info
            OUTPUT_VARIABLE  MPI_LINK_CMDLINE OUTPUT_STRIP_TRAILING_WHITESPACE
            ERROR_VARIABLE   MPI_LINK_CMDLINE ERROR_STRIP_TRAILING_WHITESPACE
            RESULT_VARIABLE  MPI_COMPILER_RETURN)
        endif()

        # make sure we got compile and link.  Reset vars if something's wrong.
        if (NOT MPI_COMPILER_RETURN EQUAL 0)
          set(MPI_COMPILE_CMDLINE)
          set(MPI_LINK_CMDLINE)
        endif()
      endif()

      # MPICH just uses "-show". Try it.
      if (NOT MPI_COMPILER_RETURN EQUAL 0)
        execute_process(
          COMMAND ${MPI_${lang}_COMPILER} -show
          OUTPUT_VARIABLE  MPI_COMPILE_CMDLINE OUTPUT_STRIP_TRAILING_WHITESPACE
          ERROR_VARIABLE   MPI_COMPILE_CMDLINE ERROR_STRIP_TRAILING_WHITESPACE
          RESULT_VARIABLE  MPI_COMPILER_RETURN)
      endif()

      if (MPI_COMPILER_RETURN EQUAL 0)
        # We have our command lines, but we might need to copy MPI_COMPILE_CMDLINE
        # into MPI_LINK_CMDLINE, if we didn't find the link line.
        if (NOT MPI_LINK_CMDLINE)
          set(MPI_LINK_CMDLINE ${MPI_COMPILE_CMDLINE})
        endif()
      else()
        message(STATUS "Unable to determine MPI from MPI driver ${MPI_${lang}_COMPILER}")
        set(MPI_COMPILE_CMDLINE)
        set(MPI_LINK_CMDLINE)
      endif()

      # Here, we're done with the interrogation part, and we'll try to extract args we care
      # about from what we learned from the compiler wrapper scripts.

      # If interrogation came back with something, extract our variable from the MPI command line
      if (MPI_COMPILE_CMDLINE OR MPI_LINK_CMDLINE)
        # Extract compile flags from the compile command line.
        string(REGEX MATCHALL "(^| )-[Df]([^\" ]+|\"[^\"]+\")" MPI_ALL_COMPILE_FLAGS "${MPI_COMPILE_CMDLINE}")
        set(MPI_COMPILE_FLAGS_WORK)

        foreach(FLAG ${MPI_ALL_COMPILE_FLAGS})
          if (MPI_COMPILE_FLAGS_WORK)
            set(MPI_COMPILE_FLAGS_WORK "${MPI_COMPILE_FLAGS_WORK} ${FLAG}")
          else()
            set(MPI_COMPILE_FLAGS_WORK ${FLAG})
          endif()
        endforeach()

        # Extract include paths from compile command line
        string(REGEX MATCHALL "(^| )-I([^\" ]+|\"[^\"]+\")" MPI_ALL_INCLUDE_PATHS "${MPI_COMPILE_CMDLINE}")
        foreach(IPATH ${MPI_ALL_INCLUDE_PATHS})
          string(REGEX REPLACE "^ ?-I" "" IPATH ${IPATH})
          string(REGEX REPLACE "//" "/" IPATH ${IPATH})
          list(APPEND MPI_INCLUDE_PATH_WORK ${IPATH})
        endforeach()

        # try using showme:incdirs if extracting didn't work.
        if (NOT MPI_INCLUDE_PATH_WORK)
          set(MPI_INCLUDE_PATH_WORK ${MPI_INCDIRS})
          separate_arguments(MPI_INCLUDE_PATH_WORK)
        endif()

        # If all else fails, just search for mpi.h in the normal include paths.
        if (NOT MPI_INCLUDE_PATH_WORK)
          set(MPI_HEADER_PATH "MPI_HEADER_PATH-NOTFOUND" CACHE FILEPATH "Cleared" FORCE)
          find_path(MPI_HEADER_PATH mpi.h
            HINTS ${_MPI_BASE_DIR} ${_MPI_PREFIX_PATH}
            PATH_SUFFIXES include)
          set(MPI_INCLUDE_PATH_WORK ${MPI_HEADER_PATH})
        endif()

        # Extract linker paths from the link command line
        string(REGEX MATCHALL "(^| |-Wl,)-L([^\" ]+|\"[^\"]+\")" MPI_ALL_LINK_PATHS "${MPI_LINK_CMDLINE}")
        set(MPI_LINK_PATH)
        foreach(LPATH ${MPI_ALL_LINK_PATHS})
          string(REGEX REPLACE "^(| |-Wl,)-L" "" LPATH ${LPATH})
          string(REGEX REPLACE "//" "/" LPATH ${LPATH})
          list(APPEND MPI_LINK_PATH ${LPATH})
        endforeach()

        # try using showme:libdirs if extracting didn't work.
        if (NOT MPI_LINK_PATH)
          set(MPI_LINK_PATH ${MPI_LIBDIRS})
          separate_arguments(MPI_LINK_PATH)
        endif()

        # add the compiler implicit directories because some compilers
        # such as the intel compiler have libraries that show up
        # in the show list that can only be found in the implicit
        # link directories of the compiler.
        if (DEFINED CMAKE_${lang}_IMPLICIT_LINK_DIRECTORIES)
          list(APPEND MPI_LINK_PATH "${CMAKE_${lang}_IMPLICIT_LINK_DIRECTORIES}")
        endif ()
        
        # Extract linker flags from the link command line
        string(REGEX MATCHALL "(^| )-Wl,([^\" ]+|\"[^\"]+\")" MPI_ALL_LINK_FLAGS "${MPI_LINK_CMDLINE}")
        set(MPI_LINK_FLAGS_WORK)
        foreach(FLAG ${MPI_ALL_LINK_FLAGS})
          if (MPI_LINK_FLAGS_WORK)
            set(MPI_LINK_FLAGS_WORK "${MPI_LINK_FLAGS_WORK} ${FLAG}")
          else()
            set(MPI_LINK_FLAGS_WORK ${FLAG})
          endif()
        endforeach()
				string(STRIP "${MPI_LINK_FLAGS_WORK}" MPI_LINK_FLAGS_WORK)

        # Extract the set of libraries to link against from the link command
        # line
        string(REGEX MATCHALL "(^| )(-l([^\" ]+|\"[^\"]+\")|[^ ]*\\.(a|so))( |$)" MPI_LIBNAMES "${MPI_LINK_CMDLINE}")

        # Determine full path names for all of the libraries that one needs
        # to link against in an MPI program
        foreach(LIB ${MPI_LIBNAMES})
          string(REGEX REPLACE "^ +" "" LIB ${LIB})
          string(REGEX REPLACE "^-l *" "" LIB ${LIB})
          string(REGEX REPLACE " $" "" LIB ${LIB})
          # MPI_LIB is cached by find_library, but we don't want that.  Clear it first.
          set(MPI_LIB "MPI_LIB-NOTFOUND" CACHE FILEPATH "Cleared" FORCE)
          if(EXISTS "${LIB}")
            set(MPI_LIB "${LIB}")
          else()
            find_library(MPI_LIB NAMES ${LIB} HINTS ${MPI_LINK_PATH})
          endif()

          if (MPI_LIB)
            list(APPEND MPI_LIBRARIES_WORK ${MPI_LIB})
          elseif (NOT MPI_FIND_QUIETLY)
            message(WARNING "Unable to find MPI library ${LIB}")
          endif()
        endforeach()

        # Sanity check MPI_LIBRARIES to make sure there are enough libraries
        list(LENGTH MPI_LIBRARIES_WORK MPI_NUMLIBS)
        list(LENGTH MPI_LIBNAMES MPI_NUMLIBS_EXPECTED)
        if (NOT MPI_NUMLIBS EQUAL MPI_NUMLIBS_EXPECTED)
          set(MPI_LIBRARIES_WORK "MPI_${lang}_LIBRARIES-NOTFOUND")
        endif()
      endif()

    elseif(try_libs)
      # If we didn't have an MPI compiler script to interrogate, attempt to find everything
      # with plain old find functions.  This is nasty because MPI implementations have LOTS of
      # different library names, so this section isn't going to be very generic.  We need to
      # make sure it works for MS MPI, though, since there are no compiler wrappers for that.
      find_path(MPI_HEADER_PATH mpi.h
        HINTS ${_MPI_BASE_DIR} ${_MPI_PREFIX_PATH}
        PATH_SUFFIXES include Inc)
      set(MPI_INCLUDE_PATH_WORK ${MPI_HEADER_PATH})

      # Decide between 32-bit and 64-bit libraries for Microsoft's MPI
      if("${CMAKE_SIZEOF_VOID_P}" EQUAL 8)
        set(MS_MPI_ARCH_DIR amd64)
      else()
        set(MS_MPI_ARCH_DIR i386)
      endif()

      set(MPI_LIB "MPI_LIB-NOTFOUND" CACHE FILEPATH "Cleared" FORCE)
      find_library(MPI_LIB
        NAMES         mpi mpich mpich2 msmpi
        HINTS         ${_MPI_BASE_DIR} ${_MPI_PREFIX_PATH}
        PATH_SUFFIXES lib lib/${MS_MPI_ARCH_DIR} Lib Lib/${MS_MPI_ARCH_DIR})
      set(MPI_LIBRARIES_WORK ${MPI_LIB})

      # Right now, we only know about the extra libs for C++.
      # We could add Fortran here (as there is usually libfmpich, etc.), but
      # this really only has to work with MS MPI on Windows.
      # Assume that other MPI's are covered by the compiler wrappers.
      if (${lang} STREQUAL CXX)
        set(MPI_LIB "MPI_LIB-NOTFOUND" CACHE FILEPATH "Cleared" FORCE)
        find_library(MPI_LIB
          NAMES         mpi++ mpicxx cxx mpi_cxx
          HINTS         ${_MPI_BASE_DIR} ${_MPI_PREFIX_PATH}
          PATH_SUFFIXES lib)
        if (MPI_LIBRARIES_WORK AND MPI_LIB)
          list(APPEND MPI_LIBRARIES_WORK ${MPI_LIB})
        endif()
      endif()

      if (NOT MPI_LIBRARIES_WORK)
        set(MPI_LIBRARIES_WORK "MPI_${lang}_LIBRARIES-NOTFOUND")
      endif()
    endif()
    
    if (${lang} STREQUAL Fortran)
      message(STATUS "Checking whether MPI Fortran module is available")
      set(test_file "${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/cmake_mpimodule_test.F90")
      file(WRITE "${test_file}" "
program test_mpimodule
    use mpi
    integer:: ierr
    call mpi_init(ierr)
    ierr = MPI_BOTTOM
    call mpi_finalize(ierr)
endprogram test_mpimodule
")
      try_compile(compile_result "${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}" "${test_file}"
        COMPILE_DEFINITIONS ${MPI_COMPILE_FLAGS_WORK}
        LINK_LIBRARIES ${MPI_LIBRARIES_WORK}
        CMAKE_FLAGS "-DINCLUDE_DIRECTORIES:STRING=${MPI_INCLUDE_PATH_WORK}"
        OUTPUT_VARIABLE compile_output)
      
      if (NOT compile_result)
        file(APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeError.log
            "MPI Fortran module detection failed to compile with the following output:\n"
            "${compile_output}\n")
        set(MPI_Fortran_HAS_MODULE FALSE)
        message(STATUS "Checking whether MPI Fortran module is available -- no")
      else()
        set(MPI_Fortran_HAS_MODULE TRUE)
        message(STATUS "Checking whether MPI Fortran module is available -- yes")
      endif()
      set(MPI_Fortran_HAS_MODULE "${MPI_Fortran_HAS_MODULE}" CACHE BOOLEAN "Whether MPI Fortran supports the use of the MPI module")
      mark_as_advanced(MPI_Fortran_HAS_MODULE)
      
    endif()
    
    # If we found MPI, set up all of the appropriate cache entries
    set(MPI_${lang}_COMPILE_FLAGS ${MPI_COMPILE_FLAGS_WORK} CACHE STRING "MPI ${lang} compilation flags"         FORCE)
    set(MPI_${lang}_INCLUDE_PATH  ${MPI_INCLUDE_PATH_WORK}  CACHE STRING "MPI ${lang} include path"              FORCE)
    set(MPI_${lang}_LINK_FLAGS    ${MPI_LINK_FLAGS_WORK}    CACHE STRING "MPI ${lang} linking flags"             FORCE)
    set(MPI_${lang}_LIBRARIES     ${MPI_LIBRARIES_WORK}     CACHE STRING "MPI ${lang} libraries to link against" FORCE)
    mark_as_advanced(MPI_${lang}_COMPILE_FLAGS MPI_${lang}_INCLUDE_PATH MPI_${lang}_LINK_FLAGS MPI_${lang}_LIBRARIES)

    # clear out our temporary lib/header detectionv variable here.
    set(MPI_LIB         "MPI_LIB-NOTFOUND"         CACHE INTERNAL "Scratch variable for MPI lib detection"    FORCE)
    set(MPI_HEADER_PATH "MPI_HEADER_PATH-NOTFOUND" CACHE INTERNAL "Scratch variable for MPI header detection" FORCE)
  endif()

  # finally set a found variable for each MPI language
  if (MPI_${lang}_INCLUDE_PATH AND MPI_${lang}_LIBRARIES)
    set(MPI_${lang}_FOUND TRUE PARENT_SCOPE)
  else()
    set(MPI_${lang}_FOUND FALSE PARENT_SCOPE)
  endif()
endfunction()


# This function attempts to compile with the regular compiler, to see if MPI programs
# work with it.  This is a last ditch attempt after we've tried interrogating mpicc and
# friends, and after we've tried to find generic libraries.  Works on machines like
# Cray XE6, where the modules environment changes what MPI version cc, CC, and ftn use.
function(try_regular_compiler lang success)
  set(scratch_directory ${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY})
  if (${lang} STREQUAL Fortran)
    set(test_file ${scratch_directory}/cmake_mpi_test.f90)
    file(WRITE ${test_file}
      "program hello\n"
      "include 'mpif.h'\n"
      "integer ierror\n"
      "call MPI_INIT(ierror)\n"
      "call MPI_FINALIZE(ierror)\n"
      "end\n")
  else()
    if (${lang} STREQUAL CXX)
      set(test_file ${scratch_directory}/cmake_mpi_test.cpp)
    else()
      set(test_file ${scratch_directory}/cmake_mpi_test.c)
    endif()
    file(WRITE ${test_file}
      "#include <mpi.h>\n"
      "int main(int argc, char **argv) {\n"
      "  MPI_Init(&argc, &argv);\n"
      "  MPI_Finalize();\n"
      "}\n")
  endif()
  try_compile(compiler_has_mpi ${scratch_directory} ${test_file})
  if (compiler_has_mpi)
    set(MPI_${lang}_NO_INTERROGATE ${CMAKE_${lang}_COMPILER} CACHE STRING "Whether to interrogate MPI ${lang} compiler" FORCE)
    set(MPI_${lang}_COMPILER       ${CMAKE_${lang}_COMPILER} CACHE STRING "MPI ${lang} compiler"                        FORCE)
    set(MPI_${lang}_COMPILE_FLAGS  ""                        CACHE STRING "MPI ${lang} compilation flags"               FORCE)
    set(MPI_${lang}_INCLUDE_PATH   ""                        CACHE STRING "MPI ${lang} include path"                    FORCE)
    set(MPI_${lang}_LINK_FLAGS     ""                        CACHE STRING "MPI ${lang} linking flags"                   FORCE)
    set(MPI_${lang}_LIBRARIES      ""                        CACHE STRING "MPI ${lang} libraries to link against"       FORCE)
  endif()
  set(${success} ${compiler_has_mpi} PARENT_SCOPE)
  unset(compiler_has_mpi CACHE)
endfunction()

# End definitions, commence real work here.

# Most mpi distros have some form of mpiexec which gives us something we can reliably look for.
find_program(MPIEXEC
  NAMES ${_MPI_EXEC_NAMES}
  PATHS ${_MPI_PREFIX_PATH}
  PATH_SUFFIXES bin
  DOC "Executable for running MPI programs.")

# call get_filename_component twice to remove mpiexec and the directory it exists in (typically bin).
# This gives us a fairly reliable base directory to search for /bin /lib and /include from.
get_filename_component(_MPI_BASE_DIR "${MPIEXEC}" PATH)
get_filename_component(_MPI_BASE_DIR "${_MPI_BASE_DIR}" PATH)

mark_as_advanced(MPIEXEC)

unset(_MPI_COMPILERS)
# This loop finds the compilers and sends them off for interrogation.
foreach (lang C CXX Fortran)
  if (CMAKE_${lang}_COMPILER_WORKS)
    # If the user supplies a compiler *name* instead of an absolute path, assume that we need to find THAT compiler.
    if (MPI_${lang}_COMPILER)
      is_file_executable(MPI_${lang}_COMPILER MPI_COMPILER_IS_EXECUTABLE)
      if (NOT MPI_COMPILER_IS_EXECUTABLE)
        # Get rid of our default list of names and just search for the name the user wants.
        set(_MPI_${lang}_COMPILER_NAMES ${MPI_${lang}_COMPILER})
        set(MPI_${lang}_COMPILER "MPI_${lang}_COMPILER-NOTFOUND" CACHE FILEPATH "Cleared" FORCE)
        # If the user specifies a compiler, we don't want to try to search libraries either.
        set(try_libs FALSE)
      endif()
    else()
      set(try_libs TRUE)
    endif()

    find_program(MPI_${lang}_COMPILER
      NAMES  ${_MPI_${lang}_COMPILER_NAMES}
      PATHS  "${MPI_HOME}/bin" "$ENV{MPI_HOME}/bin" ${_MPI_PREFIX_PATH})
    interrogate_mpi_compiler(${lang} ${try_libs})
    mark_as_advanced(MPI_${lang}_COMPILER)

    # last ditch try -- if nothing works so far, just try running the regular compiler and
    # see if we can create an MPI executable.
    set(regular_compiler_worked 0)
    if (NOT MPI_${lang}_LIBRARIES OR NOT MPI_${lang}_INCLUDE_PATH)
      try_regular_compiler(${lang} regular_compiler_worked)
    endif()

    list(APPEND _MPI_COMPILERS "${MPI_${lang}_COMPILER}")

    # for newer cmake, provide COMPILE_OPTIONS in addition of COMPILE_FLAGS
    string(REGEX REPLACE " +" ";" MPI_${lang}_COMPILE_OPTIONS "${MPI_${lang}_COMPILE_FLAGS}")
  endif()
endforeach()

# Create imported target
add_library(mpi UNKNOWN IMPORTED)
list(GET MPI_C_LIBRARIES 0 _MPI_C_LIBRARY)
set(_MPI_C_LIBRARIES_OTHER "${MPI_C_LIBRARIES}")
list(REMOVE_AT _MPI_C_LIBRARIES_OTHER 0)
set_target_properties(mpi PROPERTIES
  IMPORTED_LOCATION             "${_MPI_C_LIBRARY}"
  INTERFACE_COMPILE_OPTIONS     "${_MPI_C_COMPILE_OPTIONS}"
  INTERFACE_INCLUDE_DIRECTORIES "${MPI_C_INCLUDE_PATH}"
  INTERFACE_LINK_LIBRARIES      "${_MPI_C_LIBRARIES_OTHER};${MPI_C_LINK_FLAGS}"
)

find_package_handle_standard_args(MPI DEFAULT_MSG _MPI_COMPILERS)

endif(NOT TARGET mpi)

# unset these vars to cleanup namespace
unset(_MPI_COMPILERS)
unset(_MPI_PREFIX_PATH)
unset(_MPI_BASE_DIR)
foreach (lang C CXX Fortran)
  unset(_MPI_${lang}_COMPILER_NAMES)
  unset(_MPI_${lang}_LIBRARY)
  unset(_MPI_${lang}_LIBRARIES_OTHER)
endforeach()