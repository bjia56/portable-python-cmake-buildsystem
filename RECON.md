# Recon: Adding CPython 3.14 Support to portable-python-cmake-buildsystem

## 1. Version Strings, Checksums & Download URLs

**Location:** `CMakeLists.txt` (top-level, lines ~376-377)

The pattern for declaring a new Python version is straightforward:

```cmake
set(_download_3.14.0_md5 "2ba6baae1e7c56f652195327d3becd64")
```

- **Default version** (line 3): `set(PYTHON_VERSION "3.9.17" CACHE STRING ...)` — this is the default but can be overridden via `-DPYTHON_VERSION=X.Y.Z` at configure time.
- **Download URL** (lines 197-199): Built automatically from `PY_VERSION`:
  ```cmake
  set(_py_version_no_rc "${PY_VERSION_MAJOR}.${PY_VERSION_MINOR}.${_py_version_patch_no_rc}")
  set(_download_link "https://www.python.org/ftp/python/${_py_version_no_rc}/Python-${PY_VERSION}.tgz")
  ```
  This produces `https://www.python.org/ftp/python/3.14.0/Python-3.14.0.tgz`.
- **MD5 checksum** must be declared as `set(_download_3.X.Y_md5 "...")` for each minor version sub-release you want to support. The CI already includes `3.14.0` with checksum `2ba6baae1e7c56f652195327d3becd64`.

**For 3.14.x future sub-releases:** Add `set(_download_3.14.N_md5 "...")` entries following the pattern used for other versions (e.g., lines 366-375 for 3.13.x).

---

## 2. Per-Version Patch Files

**Location:** `patches/` directory, organized as:
```
patches/<PY_VERSION_MAJOR>.<PY_VERSION_MINOR>/      # e.g., patches/3.13/
patches/<PYTHON_VERSION>/                           # e.g., patches/3.13.0/
patches/<PYTHON_VERSION>/<CMAKE_SYSTEM_NAME>/       # OS-specific
patches/<PYTHON_VERSION>/<CMAKE_SYSTEM_NAME>-<CMAKE_C_COMPILER_ID>/  # Compiler-specific
```

### 3.13 Patch Files (current latest):
- `01-PC-config_minimal.patch` — Windows config_minimal.c (MS_DLL_ID)
- `02-freebsd-errno.patch` — FreeBSD _POSIX_SOURCE / errno.h workaround
- `03-cosmo-sys-random.patch` — Cosmopolitan sys/random.h include
- `04-getpath_noop-missing-stub.patch` — _Py_Get_Getpath_CodeObject stub
- `05-solaris-fcntlmodule.patch` — Solaris STR macro fix
- `06-relative-getpath-h.patch` — Relative include for getpath.h
- `07-testcapimodule-gettimeofday.patch` — sys/time.h include for test

### Portable subdirectory (`patches/3.13/portable/`):
- `01-getpath-portable-prefix.patch` — Dynamic PREFIX/EXEC_PREFIX via readlink/_NSGetExecutablePath
- `02-portable-sysconfig.patch` — Sysconfig fixup for pkgconfig and build vars
- `03-ssl.patch` — certifi cacert.pem path resolution

### Key observation — patch file evolution between 3.12 and 3.13:
- 3.12 had `04-PC-_msi.patch` (no longer needed in 3.13)
- 3.12 had `06-solaris-fcntlmodule.patch` (renumbered to 05 in 3.13)
- 3.12 had separate `02-sysconfig-build-vars.patch` and `03-sysconfig-pkgconfig.patch` in portable/
- 3.13 consolidated these into a single `02-portable-sysconfig.patch`
- 3.13 added `07-testcapimodule-gettimeofday.patch` (new for 3.13)

### For 3.14 support:
1. Copy the 3.13 patch directory as a starting point: `mkdir -p patches/3.14`
2. Copy 3.13's patches and test — some may need updating due to source changes in Python 3.14
3. Update the `portable/` subdirectory patches similarly

---

## 3. CMakeLists.txt Version Gates

The main `CMakeLists.txt` and subdirectory CMakeLists files use `VERSION_GREATER_EQUAL`, `VERSION_LESS`, and `VERSION_EQUAL` for conditional logic. Key gates relevant to 3.14:

### In `CMakeLists.txt`:
- Line 165: `if(PY_VERSION VERSION_GREATER_EQUAL "3.13")` — enables `WITH_FREE_THREADING` and `WITH_MIMALLOC` options
- Line 635: `if(PY_VERSION VERSION_GREATER_EQUAL "3.13")` — Windows pyconfig.h.in handling

### In `cmake/extensions/CMakeLists.txt`:
- Line 18: `if(PY_VERSION VERSION_GREATER_EQUAL "3.13")` — mimalloc support
- Line 26: `if(PY_VERSION VERSION_LESS "3.13")` — audioop extension (removed in 3.13+)
- Line 39: `if(PY_VERSION VERSION_LESS "3.13")` — crypt extension (renamed/removed in 3.13+)
- Line 98-115: `if(PY_VERSION VERSION_GREATER_EQUAL "3.12")` / `if(PY_VERSION VERSION_LESS "3.13")` — _testcapi sources differ by version
- Line 208: `if(PY_VERSION VERSION_GREATER_EQUAL "3.14")` — already present! Uses HACL* for _blake2
- Line 233: `if(PY_VERSION VERSION_GREATER_EQUAL "3.14")` — already present! Uses Python/_contextvars.c
- Line 285: `if(PY_VERSION VERSION_LESS "3.13")` — nis extension (removed in 3.13+)
- Line 297: `if(PY_VERSION VERSION_LESS "3.13")` — spwd extension (removed in 3.13+)
- Line 318: `if(PY_VERSION VERSION_LESS "3.13")` — ossaudiodev extension (removed in 3.13+)
- Line 332: `if(PY_VERSION VERSION_LESS "3.13")` — _msi extension (removed in 3.13+)
- Line 803: `if(PY_VERSION VERSION_GREATER_EQUAL "3.13")` — _interpreters and _sysconfig extensions (added in 3.13+)

### In `cmake/libpython/CMakeLists.txt`:
- Line 5: `if(PY_VERSION VERSION_GREATER_EQUAL "3.13")` — brc.c, crossinterp.c, gc_free_threading.c, etc.
- Line 100: `if(PY_VERSION VERSION_GREATER_EQUAL "3.13")` — Python/Python-ast.c vs Python/asdl_c.py
- Line 378: `if(PY_VERSION VERSION_GREATER_EQUAL "3.14")` — uses ast_preprocess.c instead of ast_opt.c (ALREADY PRESENT)
- Line 601: `if(PY_VERSION VERSION_GREATER_EQUAL "3.11" AND PY_VERSION VERSION_LESS "3.13")` — deepfreeze.c (skipped for 3.13+)
- Line 863: `if(PY_VERSION VERSION_LESS "3.13")` — deepfreeze.py build (skipped for 3.13+)

### In `cmake/ConfigureChecks.cmake`:
- Line 218: `if(WITH_FREE_THREADING AND PY_VERSION VERSION_GREATER_EQUAL "3.13")` — ABIFLAGS 't'

### For 3.14 support:
The build system **already has 3.14-specific branches** in several places (notably `cmake/extensions/CMakeLists.txt` lines 208, 233, and `cmake/libpython/CMakeLists.txt` line 378). Most of the `VERSION_GREATER_EQUAL "3.13"` gates will automatically apply to 3.14 as well, which is the intended behavior.

**Potential gaps to check:**
- Any `VERSION_LESS "3.13"` gates will correctly exclude 3.14 (good)
- Verify that any 3.14-specific source files exist in the Python 3.14 source tree

---

## 4. CI Workflow Files

**Location:** `.github/workflows/CI.yml`

The CI uses a **version matrix** that is already updated for 3.14:

```yaml
matrix:
  python-version: [3.9.25, 3.10.19, 3.11.14, 3.12.12, 3.13.9, 3.14.0]
```

**3.14.0 is already in the matrix.** No changes needed to CI.yml for 3.14 support.

**CircleCI** (`.circleci/config.yml`) has a separate older workflow with hardcoded job entries (3.9.17, 3.8.17, 3.7.17, 3.6.15, 2.7.18) — this is legacy and does not include 3.13 or 3.14.

---

## 5. Build Invocation & Out-of-Tree Build Support

### How the build is invoked:

```bash
# Create a build directory OUTSIDE the workspace
mkdir -p /tmp/build
cd /tmp/build

# Configure with desired Python version
cmake \
  -DCMAKE_INSTALL_PREFIX:PATH=/tmp/python-install \
  -DPYTHON_VERSION=3.14.0 \
  /redwall/workspace  # source directory

# Build
make -j$(nproc)

# Install
make install
```

### Out-of-tree build support:
**Confirmed YES.** The build system fully supports out-of-tree builds:
- Source is extracted to `<CMAKE_CURRENT_BINARY_DIR>/../Python-<version>/`
- All compiled artifacts go into the build directory tree
- The CI workflow (`CI.yml`, lines 37-45) creates a `python-build` directory and runs cmake from there
- The `cmake/PythonApplyPatches.cmake` applies patches to the source tree at configure time (with caching to avoid re-applying)

### Important: Builds MUST be outside the git workspace
The source extraction and build directories are parent-relative to the build directory. If building inside the workspace, extracted sources would pollute the repo. Always use a separate directory like `/tmp/build`.

---

## 6. Toolchain & Dependencies in Sandbox

### Available in this sandbox:
| Tool/Library | Status |
|---|---|
| **cmake** 3.31.6 | ✅ Available |
| **gcc** 14.2.0 | ✅ Available |
| **patch** (2.7+) | ✅ Available at `/usr/bin/patch` |
| **make** | ✅ Available |
| **tar** | ✅ Available |

### System libraries (all available via pkg-config):
| Library | pkg-config name | dev package |
|---|---|---|
| OpenSSL | `openssl` | `libssl-dev` |
| ZLIB | `zlib` | `zlib1g-dev` |
| libffi | `libffi` | `libffi-dev` |
| SQLite3 | `sqlite3` | `libsqlite3-dev` |
| readline | `readline` | `libreadline-dev` |
| ncurses | `ncurses` | (system) |
| bzip2 | `bzip2` | `libbz2-dev` |
| lzma (XZ) | (manual find) | `liblzma-dev` (runtime present) |
| expat | `expat` | `libexpat1-dev` |
| gdbm | (manual find) | `libgdbm-dev` |
| uuid | `uuid` | (system) |
| Tcl/Tk | `tcl8.6`, `tk8.6` | (system) |

### Potentially missing in this sandbox:
- **libgdbm-dev** — runtime `libgdbm6t64` is installed, dev package is installed
- **liblzma-dev** — only runtime (`liblzma5`) is confirmed installed via dpkg; dev package may need checking
- **tcl/tk dev headers** — pkg-config sees tcl8.6 and tk8.6, headers likely present

All critical dependencies for a standard Python build appear to be present in this sandbox.
