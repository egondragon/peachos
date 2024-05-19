#include "kernel.h"
#include <stdint.h>

void kernel_main() {
    uint16_t* video_mem = (uint16_t*)(0xB8000);

    video_mem[0] = 'A';
    video_mem[1] = 3;
    video_mem[2] = 'C';
    video_mem[3] = 3;
}