/*
 * _freeze_importlib links config.c's builtin-module init table but never
 * dispatches through it (config._install_importlib = 0), so a stub is
 * enough to satisfy the link without pulling _ctypes/libffi into this tool.
 */
struct _object;
struct _object *PyInit__ctypes(void);
struct _object *PyInit__ctypes(void) {
    return 0;
}
