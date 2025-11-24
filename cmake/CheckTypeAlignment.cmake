# CheckTypeAlignment.cmake
#
# Provides a function to check the alignment requirement of a type.
#
# CHECK_TYPE_ALIGNMENT(TYPE VARIABLE)
#
#   TYPE     - the name of the type to check (e.g., "long", "size_t", "double")
#   VARIABLE - variable to store the result
#
# The VARIABLE will be set to the alignment requirement in bytes, or undefined
# if the type doesn't exist or the check fails.
#
# Example usage:
#   include(CheckTypeAlignment)
#   check_type_alignment(long ALIGNOF_LONG)
#   check_type_alignment(size_t ALIGNOF_SIZE_T)
#   check_type_alignment(max_align_t ALIGNOF_MAX_ALIGN_T)

include(CheckCSourceCompiles)

function(CHECK_TYPE_ALIGNMENT TYPE VARIABLE)
  if(NOT DEFINED ${VARIABLE})
    message(STATUS "Check alignment of ${TYPE}")

    # Try different alignment values from 1 to 128 bytes
    # Most systems will have alignments that are powers of 2
    set(_ALIGNMENT_VALUES 1 2 4 8 16 32 64 128)
    set(_ALIGNMENT_FOUND FALSE)

    foreach(_ALIGN ${_ALIGNMENT_VALUES})
      set(_CHECK_SOURCE "
#include <stddef.h>

#ifndef _Alignof
# ifdef __cplusplus
#  define _Alignof(type) alignof(type)
# elif defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L
#  include <stdalign.h>
#  define _Alignof(type) alignof(type)
# elif defined(__GNUC__) || defined(__clang__)
#  define _Alignof(type) __alignof__(type)
# elif defined(_MSC_VER)
#  define _Alignof(type) __alignof(type)
# else
   /* Fallback: use offsetof trick */
#  define _Alignof(type) offsetof(struct { char c; type member; }, member)
# endif
#endif

/* Compile-time assertion: array size must be positive */
typedef char check_alignment[(_Alignof(${TYPE}) == ${_ALIGN}) ? 1 : -1];

int main(void) {
  return 0;
}
")
      set(_CHECK_FILE
          "${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/check_type_alignment_${VARIABLE}_${_ALIGN}.c")
      file(WRITE "${_CHECK_FILE}" "${_CHECK_SOURCE}")

      try_compile(_COMPILE_RESULT
        ${CMAKE_BINARY_DIR}
        ${_CHECK_FILE}
        OUTPUT_VARIABLE _COMPILE_OUTPUT
      )

      if(_COMPILE_RESULT)
        set(${VARIABLE} ${_ALIGN} CACHE INTERNAL "Alignment of ${TYPE}")
        set(_ALIGNMENT_FOUND TRUE)
        message(STATUS "Check alignment of ${TYPE} - ${_ALIGN}")
        break()
      endif()
    endforeach()

    if(NOT _ALIGNMENT_FOUND)
      message(STATUS "Check alignment of ${TYPE} - failed")
      set(${VARIABLE} "" CACHE INTERNAL "Alignment of ${TYPE}")
    endif()
  endif()
endfunction()
