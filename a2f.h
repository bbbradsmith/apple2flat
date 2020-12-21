#ifndef A2F_H
#define A2F_H

#include <stdint.h>
#include <stdarg.h>

typedef uint16_t uint16;
typedef int16_t  sint16;
typedef uint8_t  uint8;
typedef int8_t   sint8;

//
// System
//

// system type detected at startup
#define SYSTEM_UNKNOWN     = 0
#define SYSTEM_APPLE2      = 1
#define SYSTEM_APPLE2_PLUS = 2
#define SYSTEM_APPLE2E     = 3
#define SYSTEM_APPLE2C     = 4
extern uint8 system_type;

// exits to monitor with program counter display
#define FATAL() { asm ("BRK"); }

// ASSERT that acts like a conditional FATAL with a custom message
// Define NDEBUG to remove asserts for a release build.
#ifdef NDEBUG
#define ASSERT(condition_,message_) {}
#else
extern void prepare_assert(const char* message);
#define ASSERT(condition_,message_) { if(!(condition_)) { prepare_assert((message_)); FATAL(); } }
#endif

//
// Floppy disk
//

extern uint8_t disk_read(void* dest, uint16 sector, uint8 count);
extern uint8_t disk_error; // last disk error
extern uint8_t disk_volume; // last disk volume

#define DISK_ERROR_FIND      0x01
#define DISK_ERROR_DATA      0x02
#define DISK_ERROR_PARTIAL   0x04
// FIND = could not find sector on disk
// DATA = sector address found, data field missing
// PARTIAL = sector read but only partially correct (checksum fail)

//
// Video
//

// page definitions for video_cls_page
#define CLS_LOW0    0
#define CLS_LOW1    1
#define CLS_HIGH0   2
#define CLS_HIGH1   3

extern uint8 video_text_x;
extern uint8 video_text_y;
extern uint8 video_text_w;
extern uint8 video_text_h;
extern uint8 video_text_xr;
extern uint8 video_text_yr;
extern uint8 video_page_w;
extern uint8 video_page_r;
extern uint8 text_inverse;

// video modes
extern void video_mode_text();

extern void video_cls();
extern void video_cls_page(uint8 page, uint8 fill);
// TODO video_page
// TODO video_page_flip
// TODO video_page_copy
extern void text_out(char c); // output one character at the current position
extern void text_outs(const char* s); // output a null-terminated string
extern void text_printf(const char* format, ...);
extern void text_vprintf(const char* format, va_list ap);
extern void text_scroll(sint8 lines); // positive: shift text up, clear bottom, negative: shift text down, clear top
// TODO text_charset
extern void text_window(uint8 x0, uint8 y0, uint8 x1, uint8 y1); // confine text to x0<=x<x1, y0<=y<y1
extern void draw_pixel(uint16 x, uint8 y, uint8 c);
extern uint8 draw_getpixel(uint16 x, uint8 y, uint8 c);
//extern void draw_hline(uint16 x0, uint16 x1, uint8 y, uint8 c);
//extern void draw_vline(uint16 x, uint8 y0, uint8 y1, uint8 c);
//extern void draw_box(uint16 x0, uint8 y0, uint16 x1, uint8 y1, uint8 c);
//extern void draw_fillbox(uint16 x0, uint8 y0, uint16 x1, uint8 y1, uint8 c);
//blit_tile
//blit_coarse
//blit_fine
//blit_mask

#endif
