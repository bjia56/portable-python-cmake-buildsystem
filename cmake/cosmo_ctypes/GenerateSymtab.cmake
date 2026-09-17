# Reads symbols.txt and writes cosmo_symtab.c: a sorted name->address table
# plus cosmo_symtab_lookup(), consumed by dlfcn_shim.c. Invoked from
# cmake/extensions/CMakeLists.txt via include(), not run standalone.

file(STRINGS "${CMAKE_CURRENT_LIST_DIR}/symbols.txt" _cosmo_ctypes_lines)

set(_cosmo_ctypes_symbols "")
foreach(_line ${_cosmo_ctypes_lines})
    string(STRIP "${_line}" _line)
    if(_line AND NOT _line MATCHES "^#")
        list(APPEND _cosmo_ctypes_symbols "${_line}")
    endif()
endforeach()

list(SORT _cosmo_ctypes_symbols)

set(_entries "")
foreach(_sym ${_cosmo_ctypes_symbols})
    string(APPEND _entries "    {\"${_sym}\", (void *)${_sym}},\n")
endforeach()

set(COSMO_CTYPES_SYMTAB_ENTRIES "${_entries}")

configure_file(
    "${CMAKE_CURRENT_LIST_DIR}/symtab.c.in"
    "${COSMO_CTYPES_GENERATED_DIR}/cosmo_symtab.c"
    @ONLY
)
