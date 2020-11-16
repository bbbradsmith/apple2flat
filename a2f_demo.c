#include <stdlib.h>
#include <stdio.h>
#include "a2f.h"

int main()
{
	int i;
	video_mode_text();
	video_cls();
	for (i=0;i<10000;i++)
	{
		printf("%d_",i);
	}
	return 0x1234;
}
