include(TestBigEndian)

macro(define_python_endianness_macros)
  TEST_BIG_ENDIAN(WORDS_BIGENDIAN)

  # Test for float endianness
  try_run(RESULT_VAR COMPILE_VAR
    ${CMAKE_BINARY_DIR}/check_float_endianness_result
    ${CMAKE_SOURCE_DIR}/cmake/check_float_endianness.c
  )
  if(RESULT_VAR EQUAL 1)
    message(STATUS "System uses big-endian floating point format")
    set(FLOAT_WORDS_BIGENDIAN 1)
  else()
    message(STATUS "System uses little-endian floating point format")
    set(FLOAT_WORDS_BIGENDIAN 0)
  endif()
endmacro()
