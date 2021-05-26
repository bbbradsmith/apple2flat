#include <stdlib.h>
#include <stdio.h>
#include "a2f.h"

char quit = 0;

void keyboard_test()
{
	unsigned int count = 0;
	video_cls();
	text_xy(1,5);
	text_outs(
		"  DATA $C000:\n"
		"  ANY  $C010:\n"
		"       COUNT:");
	while(1)
	{
		uint8 d = kb_data(); // bit 7 = pending, bit 0-6 = key ($C000 read)
		char  a = kb_any(); // clears pending flag, bit 1 = held key ($C010 read)
		if (d & 0x80)
		{
			if ((d & 0x7F) == KB_ESC) break;
			++count;
		}
		text_xy(15,5); text_printf("%02X ' '",d);
		text_xy(19,5); text_out(d);
		text_xy(15,6); text_printf("%02X",a);
		text_xy(15,7); text_printf("%d",count);
	}
}

void paddle_test()
{
	video_cls();
	text_xy(1,5);
	text_outs(
		"  BUTTONS:\n"
		"       X0:\n"
		"       Y0:\n"
		"       X1:\n"
		"       Y1:");
	while(!kb_new() || kb_get() != KB_ESC)
	{
		paddle01_poll();
		text_xy(12,5); text_printf("%d %d %d",paddle_buttons & PADDLE_B0, paddle_buttons & PADDLE_B1, paddle_buttons & PADDLE_B2);
		text_xy(12,6); text_printf("$%02X %3d",paddle0_x,paddle0_x);
		text_xy(12,7); text_printf("$%02X %3d",paddle0_y,paddle0_y);
		text_xy(12,8); text_printf("$%02X %3d",paddle1_x,paddle1_x);
		text_xy(12,9); text_printf("$%02X %3d",paddle1_y,paddle1_y);
	}
}

void system_info()
{
	const char* t = "UNKNOWN";
	video_cls();
	text_xy(0,2);
	text_outs("  DETECTED SYSTEM:\n    ");
	switch(system_type)
	{
	case SYSTEM_APPLE2:      t = "APPLE 2"; break;
	case SYSTEM_APPLE2_PLUS: t = "APPLE 2 PLUS"; break;
	case SYSTEM_APPLE2E:     t = "APPLE 2E"; break;
	case SYSTEM_APPLE2C:     t = "APPLE 2C"; break;
	default:                 break;
	}
	text_outs(t);
	kb_get();
}

void unimplemented()
{
	video_mode_text();
	video_cls();
	text_xy(1,10);
	text_outs(" * NOT YET IMPLEMENTED\n   PRESS ESCAPE");
	// TODO beep
	while (kb_get() != KB_ESC);
}

void main_menu()
{
	video_mode_text();
	video_cls();
	text_window(1,1,39,23); // 1 space border
	text_xy(1,1);
	text_outs(
		"  APPLE2FLAT DEMO\n"
		"\n"
		"ESC - RETURN TO MENU\n"
		"  1 - VIDEO: TEXT *\n"
		"  2 - VIDEO: LORES *\n" // video tests should each have a MIXED variation to try
		"  3 - VIDEO: HIRES COLOUR *\n"
		"  4 - VIDEO: HIRES MONO *\n"
		"  5 - VIDEO: DOUBLE TEXT *\n"
		"  5 - VIDEO: DOUBLE LORES *\n"
		"  6 - VIDEO: DOUBLE HIRES COLOUR *\n"
		"  7 - VIDEO: DOUBLE HIRES MONO *\n"
		"  A - ANIMATION *\n"
		"  K - KEYBOARD\n"
		"  P - PADDLES\n"
		"  D - DISK *\n"
		"  S - SOUND *\n"
		"  T - TEXT INPUT *\n"
		"  I - SYSTEM INFO\n"
		"* = NOT YET READY\n"
		"\n"
		" HTTPS://GITHUB.COM/\n"
		"  BBBRADSMITH/APPLE2FLAT"
	);

	switch(kb_get())
	{
	case KB_ESC: quit = 1; return; // ESCAPE (TODO: keycode enums)

	case 'K': case 'k': keyboard_test(); break;
	case 'P': case 'p': paddle_test(); break;
	case 'I': case 'i': system_info(); break;

	// unimplemented
	case '1':
	case '2':
	case '3':
	case '4':
	case '5':
	case '6':
	case '7':
	case 'A': case 'a':
	case 'B': case 'b':
	case 'D': case 'd':
	case 'S': case 's':
		unimplemented(); break;

	default: break; // TODO beep
	}
}

int main()
{
	while(!quit) main_menu();
	video_mode_text();
	video_cls();
	text_window(0,0,40,24);
	text_xy(0,21);
	text_outs("\n\nEXIT TO MONITOR:");
	return 0x1234;
}
