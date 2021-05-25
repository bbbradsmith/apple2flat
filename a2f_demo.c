#include <stdlib.h>
#include <stdio.h>
//#include <conio.h>
#include "a2f.h"

char quit = 0;

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
	text_xy(2,10);
	text_outs("* NOT YET IMPLEMENTED\n");
	// TODO beep
	kb_get();
}

void main_menu()
{
	video_mode_text();
	video_cls();
	text_window(1,1,39,23); // 1 space border
	text_xy(1,1);
	text_outs(
		"      APPLE2FLAT DEMO\n"
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
		"  K - KEYBOARD *\n"
		"  J - JOYSTICK *\n"
		"  D - DISK *\n"
		"  S - SOUND *\n"
		"  I - SYSTEM INFO *\n"
		"\n"
		" HTTPS://GITHUB.COM/\n"
		"  BBBRADSMITH/APPLE2FLAT\n"
		"\n"
		"  * = NOT YET READY\n"
	);

	switch(kb_get())
	{
	case 0x1B: quit = 1; return; // ESCAPE (TODO: keycode enums)

	case 'I': system_info(); break;

	// unimplemented
	case '1':
	case '2':
	case '3':
	case '4':
	case '5':
	case '6':
	case '7':
	case 'A':
	case 'B':
	case 'K':
	case 'J':
	case 'D':
	case 'S':
		unimplemented(); break;

	default: break; // TODO beep
	}
}

int main()
{
	while(!quit) main_menu();
	video_mode_text();
	video_cls();
	text_xy(0,20);
	text_outs("\n\nEXIT TO MONITOR:\n");
	return 0x1234;
}
