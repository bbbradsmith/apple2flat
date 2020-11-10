@del temp\*.s
@del temp\*.o
@del temp\tapeboot0.bin
@del temp\tapeboot1.bin
@del temp\a2p_demo_tape.bin
@del temp\a2p_demo_t0.bin
@del temp\a2p_demo_t0.bin
@del temp\a2p_demo_tape.dbg
@del temp\a2p_demo_tape.map

cc65\bin\ca65 -o temp\tapesys_boot.o -g a2p\tapesys_boot.s
@IF ERRORLEVEL 1 GOTO error

cc65\bin\ca65 -o temp\a2p_demo.o -g a2p_demo.s
@IF ERRORLEVEL 1 GOTO error

cc65\bin\ld65 -o temp\a2p_demo_tape.bin -m temp\a2p_demo_tape.map --dbgfile temp\a2p_demo_tape.dbg -C a2p_tape.cfg temp\tapesys_boot.o temp\a2p_demo.o
@IF ERRORLEVEL 1 GOTO error

python tape.py temp\a2p_demo.wav temp\tapeboot0.bin temp\tapeboot1.bin temp\a2p_demo_tape.bin
@IF ERRORLEVEL 1 GOTO error

@echo.
@echo.
@echo Build successful!
@pause
@GOTO end
:error
@echo.
@echo.
@echo Build error!
@pause
:end