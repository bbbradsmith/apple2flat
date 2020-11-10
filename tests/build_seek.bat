cd..
@del temp\*.s
@del temp\*.o
@del temp\a2p_seek.bin
@del temp\a2p_seek.dsk
@del temp\a2p_seek.dbg
@del temp\a2p_seek.map

cc65\bin\ca65 -o temp\disksys_boot.o -g a2p\disksys_boot.s
@IF ERRORLEVEL 1 GOTO error

cc65\bin\ca65 -o temp\a2p_seek.o -g tests\a2p_seek.s
@IF ERRORLEVEL 1 GOTO error

cc65\bin\ld65 -o temp\a2p_seek.bin -m temp\a2p_seek.map --dbgfile temp\a2p_seek.dbg -C a2p_disk.cfg temp\disksys_boot.o temp\a2p_seek.o
@IF ERRORLEVEL 1 GOTO error

python sector_order.py temp\a2p_seek.bin temp\a2p_seek.dsk
@IF ERRORLEVEL 1 GOTO error

python dbg_sym.py temp\a2p_seek.dbg temp\a2p_seek.sym
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