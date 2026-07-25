# BUILD_STATUS.md

**Status: PASS**

## Confirmation

Python 3.14.0 built successfully with `make -j$(nproc)` and installed with `make install`.

## Interpreter verification

```
$ /tmp/python-install/bin/python3.14 --version
Python 3.14.0

$ /tmp/python-install/bin/python3.14 -c "import sys; print(f'Python {sys.version}')"
Python 3.14.0 (main, Jul 25 2026, 04:11:26) [GCC 14.2.0]
```

## Install location

- Executable: `/tmp/python-install/bin/python3.14`
- Library: `/tmp/python-install/lib/python3.14/`
- Shared lib: `/tmp/python-install/lib/libpython3.14.a` (static)
- Bin directory: `python`, `python3`, `python3.14`

## Changes made in this turn

In `cmake/libpython/CMakeLists.txt`, added 3 new version-gated source file lists:

1. **`PYTHON_COMMON_SOURCES` for `PY_VERSION >= 3.14`** — adds 4 new Python source files:
   - `Python/codegen.c` — provides `_Py_CArray_*`, `_PyCodegen_*`, `_PyInterpolation_InitTypes`
   - `Python/optimizer.c` — provides `_PyOptimizer_*`, `_Py_UOp*`, `_Py_Executor*`
   - `Python/optimizer_analysis.c` — analysis support
   - `Python/optimizer_symbols.c` — symbols support

2. **`OBJECT_COMMON_SOURCES` for `PY_VERSION >= 3.14`** — adds 2 new Object source files:
   - `Objects/interpolationobject.c` — provides `_PyInterpolation_Type`, `_PyInterpolation_Build`
   - `Objects/templateobject.c` — provides `_PyTemplate_Type`, `_PyTemplate_Build`, `_PyTemplateIter_Type`

3. **`MODULE_SOURCES`** — adds 2 files unconditionally (since 3.14+ is the only version using them):
   - `Modules/_datetimemodule.c` — provides `_PyDateTime_InitTypes`
   - `Python/remote_debugging.c` — provides `_PySysRemoteDebug_SendExec`

These files were identified as missing by checking CPython 3.14's `Makefile.pre.in` (`PYTHON_OBJS`, `OBJECT_OBJS`, and the dynamically-generated `MODOBJS`) and the linker error output from the first build attempt.

Note: `Python/bytecodes.c` is NOT compiled as an object file — it is a source-of-truth file used only by regeneration scripts to generate headers (`pycore_opcode_metadata.h`, etc.) that contain the actual `_PyOpcode_*` symbol definitions inline.
