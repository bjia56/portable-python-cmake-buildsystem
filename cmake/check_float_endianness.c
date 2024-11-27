#include <stdio.h>

int main() {
    // Test with a known float value (1.0f)
    float test = 1.0f;
    unsigned char *bytes = (unsigned char*)&test;

    // The float 1.0f has a known IEEE-754 representation
    // In big-endian, the first byte would be 0x3F
    // In little-endian, the first byte would be 0x00
    if (bytes[0] == 0x3F) {
        // Big-endian float
        return 1;
    } else {
        // Little-endian float
        return 0;
    }
}
