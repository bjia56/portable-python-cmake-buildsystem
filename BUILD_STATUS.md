# BUILD_STATUS.md

**Status: FAIL**

## Error Summary

Linker failure in `_freeze_importlib` target — multiple undefined references to CPython 3.14 symbols.

## Last ~40 lines of build log

```
/usr/bin/ld: CMakeFiles/_freeze_importlib.dir/tmp/Python-3.14.0/Python/instruction_sequence.c.o: in function `InstructionSequenceType_get_instructions_impl':
/tmp/Python-3.14.0/Python/instruction_sequence.c:366:(.text+0x4bc): undefined reference to `_PyOpcode_opcode_metadata'
/usr/bin/ld: CMakeFiles/_freeze_importlib.dir/tmp/Python-3.14.0/Python/instruction_sequence.c.o: in function `_PyInstructionSequence_UseLabel':
/tmp/Python-3.14.0/Python/instruction_sequence.c:75:(.text+0x72c): undefined reference to `_Py_CArray_EnsureCapacity'
/usr/bin/ld: /tmp/Python-3.14.0/Python/instruction_sequence.c:75:(.text+0x835): undefined reference to `_Py_CArray_EnsureCapacity'
/usr/bin/ld: CMakeFiles/_freeze_importlib.dir/tmp/Python-3.14.0/Python/instruction_sequence.c.o: in function `instr_sequence_next_inst':
/tmp/Python-3.14.0/Python/instruction_sequence.c:48:(.text+0x904): undefined reference to `_Py_CArray_EnsureCapacity'
/usr/bin/ld: /tmp/Python-3.14.0/Python/instruction_sequence.c:48:(.text+0x9b9): undefined reference to `_Py_CArray_EnsureCapacity'
/usr/bin/ld: warning: creating DT_TEXTREL in a PIE
collect2: error: ld returned 1 exit status
make[2]: *** [CMakeBuild/libpython/CMakeFiles/_freeze_importlib.dir/build.make:2887: CMakeBuild/libpython/_freeze_importlib] Error 1
make[1]: *** [CMakeFiles/Makefile2:3655: CMakeBuild/libpython/CMakeFiles/_freeze_importlib.dir/all] Error 2
make: *** [Makefile:146: all] Error 2
```

## Root Cause Diagnosis

The `_freeze_importlib` executable links all Python source files via `LIBPYTHON_OMIT_FROZEN_SOURCES`, which aggregates `PYTHON_COMMON_SOURCES`, `OBJECT_COMMON_SOURCES`, `PARSER_COMMON_SOURCES`, and `MODULE_SOURCES`.

For Python 3.14, the CMake build system is missing several new source files that were introduced in CPython 3.14:

1. **`Python/bytecodes.c`** — defines `_PyOpcode_opcode_metadata`, `_PyOpcode_Deopt`, `_PyOpcode_num_popped`, `_PyOpcode_num_pushed`, `_PyOpcode_Caches`, `_PyInterpolation_Build`, `_PyCArray_EnsureCapacity`
2. **`Python/codegen.c`** — defines `_PyInterpolation_InitTypes`, `_PyInterpolation_Type`, `_PyTemplate_Type`, `_PyCodegen_*`
3. **`Python/optimizer.c`** — defines `_PyInterpolation_InitTypes`, `_PyInterpolation_Build`
4. **`Objects/interpolationobject.c`** — defines `_PyInterpolation_Type`, `_PyInterpolation_InitTypes`
5. **`Objects/templateobject.c`** — defines `_PyTemplate_Type`, `_PyTemplate_Build`

These files are referenced by existing 3.14 source files already in the build (`flowgraph.c`, `specialize.c`, `pylifecycle.c`, `ceval.c`, `instrumentation.c`, `instruction_sequence.c`, `ast_preprocess.c`, `assemble.c`, `compile.c`, `codeobject.c`, `frameobject.c`, `object.c`, `sysmodule.c`), but the build system has no `if(PY_VERSION VERSION_GREATER_EQUAL "3.14")` branches to add them.

## Fix Required

Add the following source files to `PYTHON_COMMON_SOURCES` for Python >= 3.14:
- `${SRC_DIR}/Python/bytecodes.c`
- `${SRC_DIR}/Python/codegen.c`
- `${SRC_DIR}/Python/optimizer.c`
- `${SRC_DIR}/Python/instruction_sequence.c` (also missing)
- Add `${SRC_DIR}/Objects/interpolationobject.c` to `OBJECT_COMMON_SOURCES` for >= 3.14
- Add `${SRC_DIR}/Objects/templateobject.c` to `OBJECT_COMMON_SOURCES` for >= 3.14
