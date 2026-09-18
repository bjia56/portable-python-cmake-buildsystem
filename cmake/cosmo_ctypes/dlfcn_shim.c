/*
 * Replaces ctypes' dlopen/dlsym/dlclose/dlerror with a lookup into the
 * static symtab (cosmo_symtab.c). Cosmopolitan's own dlopen() always fails
 * by design, and cosmo_dlopen() crosses into unmanaged foreign code, which
 * ctypes' calling/callback patterns aren't safe against. Everything here
 * stays inside the one statically-linked image instead.
 */

#include <string.h>

void *cosmo_symtab_lookup(const char *name);

#define COSMO_CTYPES_HANDLE ((void *)0x636f736du) /* 'cosm' */

static char cosmo_ctypes_dlerror_buf[256];

static void cosmo_ctypes_dlerror_set(const char *msg) {
    strncpy(cosmo_ctypes_dlerror_buf, msg, sizeof(cosmo_ctypes_dlerror_buf) - 1);
    cosmo_ctypes_dlerror_buf[sizeof(cosmo_ctypes_dlerror_buf) - 1] = '\0';
}

void *cosmo_ctypes_dlopen(const char *name, int mode) {
    (void)mode;
    if (name == NULL || strcmp(name, "cosmo") == 0)
        return COSMO_CTYPES_HANDLE;
    cosmo_ctypes_dlerror_set(
        "only CDLL(\"cosmo\") is supported (no host .so loading)");
    return NULL;
}

void *cosmo_ctypes_dlsym(void *handle, const char *name) {
    if (handle != COSMO_CTYPES_HANDLE) {
        cosmo_ctypes_dlerror_set("invalid handle");
        return NULL;
    }
    void *addr = cosmo_symtab_lookup(name);
    if (!addr)
        cosmo_ctypes_dlerror_set("symbol not in cosmo_ctypes allowlist");
    return addr;
}

int cosmo_ctypes_dlclose(void *handle) {
    return handle == COSMO_CTYPES_HANDLE ? 0 : -1;
}

char *cosmo_ctypes_dlerror(void) {
    return cosmo_ctypes_dlerror_buf;
}
