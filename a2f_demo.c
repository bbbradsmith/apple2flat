#include <stdlib.h>
#include <stdio.h>
#include "a2f.h"

int main()
{
	int i;
	video_mode_text();
	video_cls_page(CLS_LOW0,'+');
	text_window(3,4,38,19);
	for (i=0;i<10000;i++)
	{
		printf("%d_",i);
	}
	return 0x1234;
}
