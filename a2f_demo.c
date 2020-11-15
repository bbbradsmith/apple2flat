#include <stdlib.h>
#include "a2f.h"

// TODO try disk_read, read to somewhere in LOWRAM and inspect with monitor to test?

int main()
{
	video_mode_text();
	video_cls();
	text_out('1');
	video_text_x = 5;
	video_text_y = 5;
	text_out('2');
	return 0x1234;
}
