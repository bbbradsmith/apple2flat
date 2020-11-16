@del temp\*.s
@del temp\*.o
@del temp\tapeboot0.bin
@del temp\tapeboot1.bin
@del temp\a2f_demo_tape.bin
@del temp\a2f_demo_tape.dbg
@del temp\a2f_demo_tape.map

cc65\bin\cc65 -o temp\a2f_demo.c.s -g -O a2f_demo.c || @goto error

cc65\bin\ca65 -o temp\a2f_demo.c.o -g temp\a2f_demo.c.s || @goto error

cc65\bin\ca65 -o temp\a2f_demo.o -g a2f_demo.s || @goto error

cc65\bin\ld65 -o temp\a2f_demo_tape.bin -m temp\a2f_demo_tape.map --dbgfile temp\a2f_demo_tape.dbg -C a2f_tape.cfg temp\a2f_demo.o temp\a2f_demo.c.o temp\a2f_tape.lib temp\a2f_cc65.lib || @goto error

python tape.py temp\a2f_demo.wav temp\tapeboot0.bin temp\tapeboot1.bin temp\a2f_demo_tape.bin || @goto error

@echo.
@echo.
@echo Build successful!
@pause
@goto end
:error
@echo.
@echo.
@echo Build error!
@pause
:end