#include <stdlib.h>
#include <stdio.h>
#include <conio.h>
#include "a2f.h"

int main()
{
	int i;
	video_mode_text();
	text_window(0,5,40,20);
	printf("SYSTEM: %d\n",system_type);
	printf("PRESS Q TO QUIT\n");
	cputc(cgetc());
	cputs("..");
	while(1)
	{
		char c;
		while (!kbhit());
		c = cgetc();
		cputc(c);
		if (c == 'Q') break;
	}
	return 0x1234;
}
