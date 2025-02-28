include(TestBigEndian)

macro(define_python_endianness_macros)
  if (NOT DEFINED FLOAT_WORDS_BIGENDIAN)
    TEST_BIG_ENDIAN(WORDS_BIGENDIAN)

    # Test for float endianness
    try_run(FLOAT_WORDS_BIGENDIAN_RESULT_VAR FLOAT_WORDS_BIGENDIAN_COMPILE_VAR
      ${CMAKE_CURRENT_BINARY_DIR}/check_float_endianness_result
      ${PROJECT_SOURCE_DIR}/cmake/check_float_endianness.c
    )
    if(FLOAT_WORDS_BIGENDIAN_RESULT_VAR EQUAL 1)
      message(STATUS "System uses big-endian floating point format")
      set(FLOAT_WORDS_BIGENDIAN 1)
    else()
      message(STATUS "System uses little-endian floating point format")
      set(FLOAT_WORDS_BIGENDIAN 0)
    endif()
  endif()
endmacro()
