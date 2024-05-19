#include "kernel.h"
#include <stdint.h>

uint16_t* video_mem = 0;

uint16_t term_mk_char(char c, char cl) {
    return (cl << 8) | c;
}

void write_string(int cl, const char *sz ) {
    volatile char *video = (volatile char*)0xB8000;

    while (*sz != 0) {
        *video++ = *sz++;
        *video++ = cl;
    }
}

void terminal_init() {
    video_mem = (uint16_t*)(0xB8000);
    for (int y = 0; y < VGA_HEIGHT; y++) {
        for (int x = 0; x < VGA_WIDTH; x++) {
            video_mem[y * VGA_WIDTH + x] = term_mk_char(' ', 2);
        }
    }
}

void kernel_main() {
    terminal_init();
    write_string(3, "Hello World");
}
