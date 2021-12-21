#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "a2f.h"

// in a2f_demo.s
extern uint8 font_bin[];
extern uint8 font_vwf_bin[];
extern uint8 font_vwf_wid[];
extern uint8 leyendecker_lr_bin[];
//extern uint8 leyendecker_hr_bin[];
extern uint8 leyendecker_dlr_bin[];
//extern uint8 leyendecker_dhr_bin[];

char quit = 0;

void cls_full() // clears both pages and sets 0,0
{
	video_page_select(video_page_r,0); // keep visible page while clearing page 0
	video_cls();
	video_page_select(0,1); // clear page 1 while viewing (clear) page 0
	video_cls();
	video_page_select(0,0); // switch to page 0 for read and write
}

void beep()
{
	sound_square(CPU_RATE/196,196/4); // 196hz beep, 1/4 second
}

void video_test_text()
{
	uint8 c = 0;
	char alt = 0;

	video_cls();
	text_xy( 1, 1); text_outs("\x0FVIDEO\x0E: TEXT PAGE 1 (F FOR PAGE 2)");
	text_xy( 4,12); text_outs("CHARACTER SET: (C TO SWITCH)");
	text_xy( 2, 3); text_outs("-- WINDOW --");
	text_xy( 2, 9); text_outs("------------");

	video_cls_page(CLS_LOW1,' '^0x80); // clear second page
	video_page_select(0,1); // write to second page
	text_xy( 1, 1); text_outs("\x0FVIDEO\x0E: TEXT PAGE 2 (F FOR PAGE 1)");
	draw_box(2,4,7,7,'+'^0x80);
	draw_hline(4,7,3,'-'^0x80);
	draw_vline(5,6,3,'|'^0x80);
	draw_fillbox(12,5,6,5,draw_getpixel(4,1));

	video_page_select(0,0); // write/view first page
	do
	{
		draw_pixel(4+(c%32),14+(c/32),c);
		++c;
	} while (c!=0);

	text_window(2,4,14,9);
	while(1)
	{
		if (kb_new())
		{
			c = kb_get();
			if      (c == KB_ESC) return;
			else if (c == 'F' || c == 'f') video_page_flip();
			else if (c == 'C' || c == 'c')
			{
				alt ^= 1;
				text_charset(alt);
			}
			c = 0;
		}
		else if (video_page_w == 0)
		{
			if      (c == 0x00) text_outs("LOW RAM");
			else if (c == 0x80) text_outs(" CHECKSUM...");
			delay(1);
			++c;
		}
	}
}

void video_test_low()
{
	char mixed = 1;
	char dmixed = 0;
	char flip = 0;
	uint8 c;

redraw:
	if      (!mixed)  video_mode_low();
	else if (!dmixed) video_mode_low_mixed();
	else if ( dmixed) video_mode_low_double_mixed();
	cls_full();

	text_outs(
		"\x0FVIDEO\x0E: LOW RESOLUTION MIXED PAGE 1\n"
		"       F FOR PAGE 2\n"
		"       M FOR NON MIXED\n"
		"       4/8 FOR 40/80 COLUMN MIXED"
	);
	draw_box(1,1,18,3,COL_WHITE);
	for (c=0; c<16; ++c) draw_pixel(2+c,2,c);
	draw_box(1,3,18,6,COL_WHITE);
	for (c=0; c<16; ++c) draw_pixel(2+c,4,draw_getpixel(2+c,2)); // test getpixel for even->even
	for (c=0; c<16; ++c) draw_pixel(2+c,5,draw_getpixel(2+c,2)); // even->odd
	for (c=0; c<16; ++c) draw_pixel(2+c,6,draw_getpixel(2+c,5)); // odd->even
	for (c=0; c<16; ++c) draw_pixel(2+c,7,draw_getpixel(2+c,5)); // odd->odd
	draw_fillbox(2,11,6,7,COL_GREEN_DARK);

	video_page_select(0,1);
	draw_fillbox(1,1,34,34,COL_GREEN_LIGHT);
	blit(2,2,leyendecker_lr_bin);
	// TODO leyendecker blit?
	// TODO fine blit? masked blit?

	video_page_select(flip,flip);
	while(1)
	{
		if (kb_new())
		{
			c = kb_get();
			if      (c == KB_ESC) break;
			else if (c == 'F' || c == 'f') { video_page_flip(); flip ^= 1; }
			else if (c == 'M' || c == 'm') { mixed = !mixed; goto redraw; }
			else if (c == '4') { mixed = 1; dmixed = 0; goto redraw; }
			else if (c == '8') { mixed = 1; dmixed = 1; goto redraw; }
			c = 0;
		}
		else if (video_page_w != 0)
		{
			if      (c == 0x00) text_outs("LOW RAM");
			else if (c == 0x80) text_outs(" CHECKSUM...");
			delay(1);
			++c;
		}
	}
}

void video_test_high_color()
{
	char mixed = 1;
	char dmixed = 0;
	char flip = 0;
	uint8 c;

redraw:
	if      (!mixed)  video_mode_high_color();
	else if (!dmixed) video_mode_high_color_mixed();
	else if ( dmixed) video_mode_high_color_double_mixed();
	cls_full();

	if (!mixed) text_window(0,20,40,24);
	text_outs(
		"\x0FVIDEO\x0E: HIGH RES COLOR PAGE 1\n"
		"       F FOR PAGE 2\n"
		"       M TO TOGGLE MIXED\n"
		"       4/8 FOR 40/80 COLUMN MIXED"
	);
	draw_fillbox( 99,5,37,35,COH_WHITE0);
	for (c=0; c<24; ++c)
	{
		draw_pixel( 10+c,11+c,COH_WHITE0);
		draw_pixel(130-c,11+c,COH_BLACK0);
		draw_pixel( 13+c,10+c,draw_getpixel( 10+c,11+c));
		draw_pixel(127-c,10+c,draw_getpixel(130-c,11+c));
	}
	#define HCSW 14
	draw_box(9,49,2+(HCSW*8),2+(2*HCSW),COH_WHITE1);
	for (c=0; c<8; ++c)
	{
		draw_fillbox(10+(c*HCSW),50     ,HCSW,HCSW,(   c &3)|((   c &4)<<5));
		draw_fillbox(10+(c*HCSW),50+HCSW,HCSW,HCSW,((7-c)&3)|(((7-c)&4)<<5));
	}

	video_page_select(0,1);
	draw_fillbox(5,7,31,52,COH_PURPLE);
	// TODO leyendecker blit?
	// TODO fine blit? masked blit?

	video_page_select(flip,flip);
	while(1)
	{
		if (kb_new())
		{
			c = kb_get();
			if      (c == KB_ESC) break;
			else if (c == 'F' || c == 'f') { video_page_flip(); flip ^= 1; }
			else if (c == 'M' || c == 'm') { mixed = !mixed; goto redraw; }
			else if (c == '4') { mixed = 1; dmixed = 0; goto redraw; }
			else if (c == '8') { mixed = 1; dmixed = 1; goto redraw; }
			c = 0;
		}
		else if (video_page_w != 0)
		{
			if      (c == 0x00) text_outs("LOW RAM");
			else if (c == 0x80) text_outs(" CHECKSUM...");
			delay(1);
			++c;
		}
	}
}

void video_test_high_mono()
{
	char mixed = 1;
	char dmixed = 0;
	char flip = 0;
	uint8 c;

redraw:
	if      (!mixed)  video_mode_high_mono();
	else if (!dmixed) video_mode_high_mono_mixed();
	else if ( dmixed) video_mode_high_mono_double_mixed();
	cls_full();

	if (!mixed) text_window(0,20,40,24);
	text_outs(
		"\x0FVIDEO\x0E: HIGH RES MONO PAGE 1\n"
		"       F FOR PAGE 2\n"
		"       M TO TOGGLE MIXED\n"
		"       4/8 FOR 40/80 COLUMN MIXED"
	);
	draw_fillbox(239,5,37,35,COM_WHITE);
	for (c=0; c<24; ++c)
	{
		draw_pixel( 10+c,11+c,COM_WHITE);
		draw_pixel(270-c,11+c,COM_BLACK);
		draw_pixel( 13+c,10+c,draw_getpixel( 10+c,11+c));
		draw_pixel(267-c,10+c,draw_getpixel(270-c,11+c));
	}

	video_page_select(0,1);
	// TODO leyendecker blit?
	// TODO fine blit? masked blit?

	video_page_select(flip,flip);
	while(1)
	{
		if (kb_new())
		{
			c = kb_get();
			if      (c == KB_ESC) break;
			else if (c == 'F' || c == 'f') { video_page_flip(); flip ^= 1; }
			else if (c == 'M' || c == 'm') { mixed = !mixed; goto redraw; }
			else if (c == '4') { mixed = 1; dmixed = 0; goto redraw; }
			else if (c == '8') { mixed = 1; dmixed = 1; goto redraw; }
			c = 0;
		}
		else if (video_page_w != 0)
		{
			if      (c == 0x00) text_outs("LOW RAM");
			else if (c == 0x80) text_outs(" CHECKSUM...");
			delay(1);
			++c;
		}
	}
}

void video_test_double_text()
{
	uint8 c = 0;
	char alt = 0;

	video_mode_double_text();
	video_cls();
	text_xy( 1, 1); text_outs("\x0FVIDEO\x0E: DOUBLE TEXT PAGE 1 (F FOR PAGE 2)");
	text_xy(44,12); text_outs("CHARACTER SET: (C TO SWITCH)");
	text_xy( 2, 3); text_outs("-- WINDOW --");
	text_xy( 2, 9); text_outs("------------");

	video_cls_page(CLS_DLOW1,' '^0x80); // clear second page
	video_page_select(0,1); // write to second page
	text_xy( 1, 1); text_outs("\x0FVIDEO\x0E: DOUBLE TEXT PAGE 2 (F FOR PAGE 1)");
	draw_box(2,4,7,7,'+'^0x80);
	draw_hline(4,7,3,'-'^0x80);
	draw_vline(5,6,3,'|'^0x80);
	draw_fillbox(12,5,6,5,draw_getpixel(4,1));

	video_page_select(0,0); // write/view first page
	do
	{
		draw_pixel(44+(c%32),14+(c/32),c);
		++c;
	} while (c!=0);

	text_window(2,4,14,9);
	while(1)
	{
		if (kb_new())
		{
			c = kb_get();
			if      (c == KB_ESC) return;
			else if (c == 'F' || c == 'f') video_page_flip();
			else if (c == 'C' || c == 'c')
			{
				alt ^= 1;
				text_charset(alt);
			}
			c = 0;
		}
		else if (video_page_w == 0)
		{
			if      (c == 0x00) text_outs("LOW RAM");
			else if (c == 0x80) text_outs(" CHECKSUM...");
			delay(1);
			++c;
		}
	}
}

void video_test_double_low()
{
	char mixed = 1;
	char flip = 0;
	uint8 c;

redraw:
	if (!mixed) video_mode_double_low();
	else        video_mode_double_low_mixed();
	cls_full();

	text_outs(
		"\x0FVIDEO\x0E: DOUBLE LOW RESOLUTION MIXED PAGE 1\n"
		"       F FOR PAGE 2\n"
		"       M FOR NON MIXED"
	);
	draw_box(1,1,18,3,COL_WHITE);
	for (c=0; c<16; ++c) draw_pixel(2+c,2,c);
	draw_box(1,3,18,6,COL_WHITE);
	for (c=0; c<16; ++c) draw_pixel(2+c,4,draw_getpixel(2+c,2)); // test getpixel for even->even
	for (c=0; c<16; ++c) draw_pixel(2+c,5,draw_getpixel(2+c,2)); // even->odd
	for (c=0; c<16; ++c) draw_pixel(2+c,6,draw_getpixel(2+c,5)); // odd->even
	for (c=0; c<16; ++c) draw_pixel(2+c,7,draw_getpixel(2+c,5)); // odd->odd
	draw_fillbox(2,11,6,7,COL_GREEN_DARK);
	
	for (c=0; c<16; ++c)
	{
		draw_pixel(2+(c*2),22,c);
		draw_pixel(3+(c*2),23,c);
		draw_pixel(60,16+c,c);
		draw_pixel(61,16+c,c);
		draw_pixel(64,17+c,c);
		draw_pixel(65,17+c,c);
		draw_pixel(68,16+c,15-c);
		draw_pixel(69,16+c,15-c);
		draw_pixel(72,17+c,15-c);
		draw_pixel(73,17+c,15-c);
	}

	video_page_select(0,1);
	draw_fillbox(1,1,34,34,COL_GREEN_LIGHT);
	// TODO leyendecker blit?
	// TODO fine blit? masked blit?

	video_page_select(flip,flip);
	while(1)
	{
		if (kb_new())
		{
			c = kb_get();
			if      (c == KB_ESC) break;
			else if (c == 'F' || c == 'f') { video_page_flip(); flip ^= 1; }
			else if (c == 'M' || c == 'm') { mixed = !mixed; goto redraw; }
			c = 0;
		}
		else if (video_page_w != 0)
		{
			if      (c == 0x00) text_outs("LOW RAM");
			else if (c == 0x80) text_outs(" CHECKSUM...");
			delay(1);
			++c;
		}
	}
}

void video_test_double_high_color()
{
	char mixed = 1;
	char flip = 0;
	uint8 c;

redraw:
	if (!mixed) video_mode_double_high_color();
	else        video_mode_double_high_color_mixed();
	cls_full();

	if (!mixed) text_window(0,20,40,24);
	text_outs(
		"\x0FVIDEO\x0E: DOUBLE HIGH RES COLOR PAGE 1\n"
		"       F FOR PAGE 2\n"
		"       M TO TOGGLE MIXED"
	);
	draw_fillbox( 99,5,37,35,COD_WHITE);
	for (c=0; c<24; ++c)
	{
		draw_pixel( 10+c,11+c,COD_WHITE);
		draw_pixel(130-c,11+c,COD_BLACK);
		draw_pixel( 13+c,10+c,draw_getpixel( 10+c,11+c));
		draw_pixel(127-c,10+c,draw_getpixel(130-c,11+c));
	}
	#define DHCSW 7
	draw_box(9,49,2+(DHCSW*16),2+(2*DHCSW),COD_WHITE);
	for (c=0; c<16; ++c)
	{
		draw_fillbox(10+(c*DHCSW),50      ,DHCSW,DHCSW,c);
		draw_fillbox(10+(c*DHCSW),50+DHCSW,DHCSW,DHCSW,c);
	}

	video_page_select(0,1);
	draw_fillbox(5,7,31,52,COD_PURPLE);
	// TODO leyendecker blit?
	// TODO fine blit? masked blit?

	video_page_select(flip,flip);
	while(1)
	{
		if (kb_new())
		{
			c = kb_get();
			if      (c == KB_ESC) break;
			else if (c == 'F' || c == 'f') { video_page_flip(); flip ^= 1; }
			else if (c == 'M' || c == 'm') { mixed = !mixed; goto redraw; }
			c = 0;
		}
		else if (video_page_w != 0)
		{
			if      (c == 0x00) text_outs("LOW RAM");
			else if (c == 0x80) text_outs(" CHECKSUM...");
			delay(1);
			++c;
		}
	}
}

void video_test_double_high_mono()
{
	char mixed = 1;
	char flip = 0;
	uint8 c;

redraw:
	if (!mixed) video_mode_double_high_mono();
	else        video_mode_double_high_mono_mixed();
	cls_full();

	if (!mixed) text_window(0,20,80,24);
	text_outs(
		"\x0FVIDEO\x0E: DOUBLE HIGH RES MONO PAGE 1\n"
		"       F FOR PAGE 2\n"
		"       M TO TOGGLE MIXED"
	);
	draw_fillbox(    239, 5,37,35,COM_WHITE);
	draw_fillbox(280+239,45,37,35,COM_WHITE);
	for (c=0; c<24; ++c)
	{
		draw_pixel(    10+c,11+c,COM_WHITE);
		draw_pixel(   270-c,11+c,COM_BLACK);
		draw_pixel(    13+c,10+c,draw_getpixel( 10+c,11+c));
		draw_pixel(   267-c,10+c,draw_getpixel(270-c,11+c));
		draw_pixel(280+ 10+c,51+c,COM_WHITE);
		draw_pixel(280+270-c,51+c,COM_BLACK);
		draw_pixel(280+ 13+c,50+c,draw_getpixel(280+ 10+c,51+c));
		draw_pixel(280+267-c,50+c,draw_getpixel(280+270-c,51+c));
	}

	video_page_select(0,1);
	// TODO leyendecker blit?
	// TODO fine blit? masked blit?

	video_page_select(flip,flip);
	while(1)
	{
		if (kb_new())
		{
			c = kb_get();
			if      (c == KB_ESC) break;
			else if (c == 'F' || c == 'f') { video_page_flip(); flip ^= 1; }
			else if (c == 'M' || c == 'm') { mixed = !mixed; goto redraw; }
			c = 0;
		}
		else if (video_page_w != 0)
		{
			if      (c == 0x00) text_outs("LOW RAM");
			else if (c == 0x80) text_outs(" CHECKSUM...");
			delay(1);
			++c;
		}
	}
}

void vwf_test()
{
	char mono = 0;
	char flip = 0;
	char c;

	text_set_font_vwf(font_vwf_wid,font_vwf_bin,0x20);

redraw:
	if (!mono) video_mode_high_color_vwf();
	else       video_mode_high_mono_vwf();
	cls_full();
	text_window(15,4,265,16);

	text_outs("VARIABLE WIDTH FONT (");
	text_outs(mono ? "MONO" : "COLOR");
	text_outs(")\n"
		"\n"
		"A font technique inspired by\n"
		"\x0FOregon Trail\x0E, allowing custom\n"
		"widths and spacing between\n"
		"character glyphs.\n"
		"\n"
		"M to toggle monochrome\n"
		"F for window test on page 2");
	text_xy(15,4);

	video_page_select(flip,flip);
	while(1)
	{
		if (kb_new())
		{
			c = kb_get();
			if      (c == KB_ESC) break;
			else if (c == 'F' || c == 'f') { video_page_flip(); flip ^= 1; }
			else if (c == 'M' || c == 'm') { mono = !mono; goto redraw; }
			c = 0;
		}
		else if (video_page_w != 0)
		{
			if      (c == 0x00) text_outs("Low RAM");
			else if (c == 0x80) text_outs(" Checksum......");
			delay(1);
			++c;
		}
	}
}

void keyboard_test()
{
	unsigned int count = 0;
	video_cls();
	text_xy(1,5);
	text_outs(
		"  DATA $C000:    ' '\n"
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
		text_xy(15,5); text_printf("%02X",d); draw_pixel(19,5,d ^ 0x80);
		text_xy(15,6); text_printf("%02X",a);
		text_xy(15,7); text_printf("%d",count);
		delay(30); // 30ms delay to reduce flicker
	}
}

void paddle_test()
{
	char j9[10];
	uint8 jx,jy;

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

		text_window(1,1,39,23);
		text_xy(12,5); text_printf("%d %d %d",
			(paddle0_b & PADDLE_B0) ? 1 : 0,
			(paddle0_b & PADDLE_B1) ? 2 : 0,
			(paddle1_b & PADDLE_B2) ? 3 : 0);
		text_xy(12,6); text_printf("$%02X %3d",paddle0_x,paddle0_x);
		text_xy(12,7); text_printf("$%02X %3d",paddle0_y,paddle0_y);
		text_xy(12,8); text_printf("$%02X %3d",paddle1_x,paddle1_x);
		text_xy(12,9); text_printf("$%02X %3d",paddle1_y,paddle1_y);

		strcpy(j9,"    X    ");
		if (paddle0_x < 128 && paddle0_y < 128)
		{
			jx = jy = 1;
			if (paddle0_x <  PADDLE_LOW ) jx -= 1;
			if (paddle0_x >= PADDLE_HIGH) jx += 1;
			if (paddle0_y <  PADDLE_LOW ) jy -= 1;
			if (paddle0_y >= PADDLE_HIGH) jy += 1;
			j9[4] = 'O';
			j9[jx+(jy*3)] = '1' ^ 0x80;
		}
		text_window(14,12,17,15); text_xy(14,12); text_outs(j9);

		strcpy(j9,"    X    ");
		if (paddle1_x < 128 && paddle1_y < 128)
		{
			jx = jy = 1;
			if (paddle1_x <  PADDLE_LOW ) jx -= 1;
			if (paddle1_x >= PADDLE_HIGH) jx += 1;
			if (paddle1_y <  PADDLE_LOW ) jy -= 1;
			if (paddle1_y >= PADDLE_HIGH) jy += 1;
			j9[4] = 'O';
			j9[jx+(jy*3)] = '2' ^ 0x80;
		}
		text_window(19,12,22,15); text_xy(19,12); text_outs(j9);
	}
}

const uint8 music_looping[] = // based on Chopin G-Major Prelude (Op. 28, No. 3)
{
	0x0F, // loop point
	0x20 + 7 - 1, // duration 7
	0x11, // pulse 1/2 (square)
	0x0E, // repeat point
	0x97, 0xA2, 0xA7, 0xA9, 0xAB, 0xA9, 0xA7, 0xB4, // G2 D3 G3 A3 B3 A3 G3 E4
	0xB2, 0xB0, 0xAB, 0xA9, 0xA7, 0xA9, 0xAB, 0xA2, // D4 C4 B3 A3 G3 A3 B3 D3
	0x16, // pulse 1/64
	0x02, // repeat 2x
	0x20 + 2 - 1, 0xFF, 0x20 + 5 - 1, // duration 2 + space 5 (detached)
	0x11, // pulse 1/2
	0x99, 0xA4, 0xA9, 0xAB, 0xB1, 0xAB, 0xA9, 0xB6, // A2 E3 A3 B3 Cs4 B3 A3 Fs4
	0xB4, 0xB2, 0xB1, 0xAB, 0xA9, 0xAB, 0xB1, 0xA4, // E4 D4 Cs4 B3 A3 B3 Cs4 E4
	0x20 + 7 - 1, 0xFF, 0x01, // duration 7 + space 0
	0x12, // pulse 1/4
	0x92, 0x99, 0xA2, 0xA4, 0xA6, 0xA4, 0xA2, 0xAB, // D2 A2 D3 E3 Fs3 E3 D3 B3
	0xA9, 0xA7, 0xA6, 0xA4, 0xA2, 0xA4, 0xA6, 0x99, // A3 G3 Fs3 E3 D3 E3 Fs3 A2
	0x0D, // loop
};

const uint8 music_oneshot[] =
{
	0x10, // noise
	0x0E, // repeat point
	0x20 + 1  - 1, 0x80, 0xC0, 0xF0, 0xC0, // snare drum
	0x20 + 3  - 1, 0x01, // rest
	0x04, // repeat 4x
	0x0E, // repeat point
	0x20 + 4  - 1, 0xFB, // cymbal
	0x20 + 3 - 1, 0x01,
	0x02, // repeat 2x
	0x20 + 14 - 1, 0x01,
	0x0E, // repeat point
	0x20 + 4 - 1,
	0x11, 0xD2, // descending D,A,D,A,D,D with narrowing duty
	0x12, 0xC9,
	0x13, 0xC2,
	0x14, 0xB9,
	0x15, 0xB2,
	0x16, 0xA2,
	0x03, // repeat 3x
	0x20 + 16 - 1, 0x11, 0xA7, // low G, square duty
	0x00, // halt
};

void raw_click()
{
	// flips the speaker bit; should only be audible on every second flip
	asm ("bit $C030");
}

void sound_test()
{
	uint8 octave = 4;
	uint8 duty = 1;
	uint8 time = 16;
	uint8 sweep = 8;

	music_reset();
	music_command(0x17+octave);
	music_command(0x10+duty);
	music_command(0x20+time-1);
	video_cls();
	text_xy(1,3);
	text_outs("SOUND TEST\n"
		"\n"
		"  [2] [3]     [5] [6] [7]\n"
		"[Q] [W] [E] [R] [T] [Y] [U]\n"
		"\n"
		"OCTAVE:  4  []\n"
		"DUTY:    1  ASDFGH (A=NOISE)\n"
		"TIME:   16  <>\n"
		"SWEEP:   8  ZX\n"
		"\n"
		"M = LOOPING MUSIC (CHOPIN OP.28 NO.3)\n"
		"N = RESUME LOOP\n"
		"B = ONE-SHOT MUSIC\n"
		"C = SWEEP DOWN\n"
		"V = SWEEP UP\n"
		"K = CLICK $C030 (SPEAKER PARITY FLIP)\n"
		);

	while(1)
	{
		switch (kb_get())
		{
			case KB_ESC: return;
			case 'Q': case 'q': music_command(0x60); break;
			case '2':           music_command(0x61); break;
			case 'W': case 'w': music_command(0x62); break;
			case '3':           music_command(0x63); break;
			case 'E': case 'e': music_command(0x64); break;
			case 'R': case 'r': music_command(0x65); break;
			case '5':           music_command(0x66); break;
			case 'T': case 't': music_command(0x67); break;
			case '6':           music_command(0x68); break;
			case 'Y': case 'y': music_command(0x69); break;
			case '7':           music_command(0x6A); break;
			case 'U': case 'u': music_command(0x6B); break;
			case '[': case '{': if (octave>0) { --octave; music_command(0x17+octave); } break;
			case ']': case '}': if (octave<8) { ++octave; music_command(0x17+octave); } break;
			case '<': case ',': if (time> 1) { --time; music_command(0x20+time-1); } break;
			case '>': case '.': if (time<64) { ++time; music_command(0x20+time-1); } break;
			case 'A': case 'a': duty = 0; music_command(0x10+duty); break;
			case 'S': case 's': duty = 1; music_command(0x10+duty); break;
			case 'D': case 'd': duty = 2; music_command(0x10+duty); break;
			case 'F': case 'f': duty = 3; music_command(0x10+duty); break;
			case 'G': case 'g': duty = 4; music_command(0x10+duty); break;
			case 'H': case 'h': duty = 5; music_command(0x10+duty); break;
			case 'M': case 'm': music_play(music_looping,2); break;
			case 'N': case 'n': music_resume(2); break;
			case 'B': case 'b': music_play(music_oneshot,0); break;
			case 'Z': case 'z': if (sweep> 1) --sweep; break;
			case 'X': case 'x': if (sweep<16) ++sweep; break;
			case 'C': case 'c': sound_sweep_down(CPU_RATE/440,440,sweep); break;
			case 'V': case 'v': sound_sweep_up(  CPU_RATE/440,440,sweep); break;
			case 'K': case 'k': raw_click(); break;
			default: break;
		}
		text_xy(10, 8); text_printf("%d",octave);
		text_xy(10, 9); text_printf("%d",duty);
		text_xy( 9,10); text_printf("%2d",time);
		text_xy( 9,11); text_printf("%2d",sweep);
	}
}

void system_info()
{
	const char* t = "UNKNOWN";

	if (system_type == SYSTEM_APPLE2GS) // change colour to demonstrate IIGS detection
		iigs_color(COL_YELLOW,COL_BLUE_DARK,COL_PINK);

	video_cls();
	text_xy(0,2);
	text_outs("  DETECTED SYSTEM:\n    ");
	switch(system_type)
	{
	case SYSTEM_APPLE2:      t = "APPLE 2"; break;
	case SYSTEM_APPLE2P:     t = "APPLE 2+"; break;
	case SYSTEM_APPLE2E:     t = "APPLE 2E"; break;
	case SYSTEM_APPLE2EE:    t = "APPLE 2E ENHANCED"; break;
	case SYSTEM_APPLE2C:     t = "APPLE 2C"; break;
	case SYSTEM_APPLE2GS:    t = "APPLE 2GS"; break;
	default:                 break;
	}
	text_outs(t);
	// TODO 80-column card detection?
	// TODO detection of vsync method?
	// TODO ram size / page count? / Need interface for banking.
	while (kb_get() != KB_ESC);
}

void unimplemented()
{
	video_mode_text();
	video_cls();
	text_xy(1,10);
	text_outs(" * NOT YET IMPLEMENTED\n   PRESS ESCAPE");
	beep();
	while (kb_get() != KB_ESC);
}

void main_menu()
{
	text_set_font(font_bin,0x20);
	if (system_type == SYSTEM_APPLE2GS)
		iigs_color(COL_WHITE,COL_BLACK,COL_BLACK);

	cls_full();
	video_mode_text();
	video_cls();
	text_window(1,0,39,24);
	text_xy(1,1);
	text_outs(
		"  APPLE2FLAT DEMO\n"
		"\n"
		"ESC - RETURN TO MENU\n"
		"  1 - VIDEO: TEXT\n"
		"  2 - VIDEO: LORES\n"
		"  3 - VIDEO: HIRES COLOUR\n"
		"  4 - VIDEO: HIRES MONO\n"
		"  5 - VIDEO: DOUBLE TEXT\n"
		"  6 - VIDEO: DOUBLE LORES\n"
		"  7 - VIDEO: DOUBLE HIRES COLOUR\n"
		"  8 - VIDEO: DOUBLE HIRES MONO\n"
		"  A - ANIMATION *\n"
		"  F - VARIABLE WIDTH FONT\n"
		"  K - KEYBOARD\n"
		"  P - PADDLES\n"
		"  D - DISK *\n"
		"  S - SOUND\n"
		"  T - TEXT INPUT *\n"
		"  I - SYSTEM INFO\n"
		"* = NOT YET READY\n"
		"\n"
		" HTTPS://GITHUB.COM/\n"
		"  BBBRADSMITH/APPLE2FLAT"
	);

	switch(kb_get())
	{
	case KB_ESC: quit = 1; return;

	case '1': video_test_text(); break;
	case '2': video_test_low(); break;
	case '3': video_test_high_color(); break;
	case '4': video_test_high_mono(); break;
	case '5': video_test_double_text(); break;
	case '6': video_test_double_low(); break;
	case '7': video_test_double_high_color(); break;
	case '8': video_test_double_high_mono(); break;
	case 'F': case 'f': vwf_test(); break;
	case 'K': case 'k': keyboard_test(); break;
	case 'P': case 'p': paddle_test(); break;
	case 'S': case 's': sound_test(); break;
	case 'I': case 'i': system_info(); break;

	// unimplemented
	case 'A': case 'a':
	case 'D': case 'd':
	case 'T': case 't':
		unimplemented(); break;

	default: beep(); break;
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
