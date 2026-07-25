# BUILD_STATUS.md

**Status: PASS**

Python 3.14.0 builds, installs, and passes all smoke tests.

## Smoke Test

```
$ /tmp/python-install/bin/python3.14 -c "
import ssl, sqlite3, zlib, bz2, lzma, ctypes, decimal, hashlib, sysconfig
print('sysconfig prefix:', sysconfig.get_config_var('prefix'))
print('ssl.OPENSSL_VERSION:', ssl.OPENSSL_VERSION)
ctx = ssl.create_default_context()
print('cafile in use:', ctx.get_ca_certs())
print('all imports OK')
"
sysconfig prefix: /tmp/python-install
ssl.OPENSSL_VERSION: OpenSSL 3.5.6 7 Apr 2026
cafile in use: [{'subject': (('commonName', 'GlobalSign Root CA'), ...), ...}]
all imports OK
```

## CI-style tests

```
$ /tmp/python-install/bin/python3.14 -m sysconfig
... (works)

$ /tmp/python-install/bin/python3.14 -m ensurepip
... (pip-25.2 installed)
```

## Root cause of previous segfault

The segfault was caused by `_datetimemodule.c` being compiled **twice**:
1. As an extension target (`_datetime`) in `cmake/extensions/CMakeLists.txt`
2. Into `libpython.a` via `MODULE_SOURCES` in `cmake/libpython/CMakeLists.txt`

This created an ODR (One Definition Rule) violation — two independent copies of `PyDateTime_DateType` with different memory layouts, causing the GC to see corrupted type flags.

## Fix applied

Per CPython 3.14's `configure.ac` (`PY_STDLIB_MOD_SIMPLE([_datetime])`), `_datetimemodule.c` is compiled into libpython, NOT as a separate extension. The fix:

1. **`cmake/extensions/CMakeLists.txt`**: Added `if(PY_VERSION VERSION_GREATER_EQUAL "3.14")` guard to skip the `_datetime` extension build for 3.14+
2. **`cmake/libpython/CMakeLists.txt`**: Added `if(PY_VERSION VERSION_GREATER_EQUAL "3.14")` block to compile `_datetimemodule.c` into libpython via `MODULE_SOURCES`

## Files changed

### patches/3.14/ (copied from 3.13)
- 7 main patches + 3 portable patches (all apply cleanly to 3.14 source)

### cmake/libpython/CMakeLists.txt
- Added `PYTHON_COMMON_SOURCES` block for `>= 3.14` (codegen.c, optimizer.c, optimizer_analysis.c, optimizer_symbols.c)
- Added `OBJECT_COMMON_SOURCES` block for `>= 3.14` (interpolationobject.c, templateobject.c)
- Added `MODULE_SOURCES` block for `>= 3.14` (_datetimemodule.c, remote_debugging.c)

### cmake/extensions/CMakeLists.txt
- Fixed `_datetime` extension build: skip for `>= 3.14` (now built into libpython)
- Fixed `_contextvars` extension: build as `BUILTIN` (not just `${WIN32_BUILTIN}`) for `>= 3.14`
