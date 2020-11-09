@del temp\*.s
@del temp\*.o
@del temp\a2p_demo.bin
@del temp\a2p_demo.dsk
@del temp\a2p_demo.dbg
@del temp\a2p_demo.map

cc65\bin\ca65 -o temp\disksys_boot.o -g a2p\disksys_boot.s
@IF ERRORLEVEL 1 GOTO error

cc65\bin\ld65 -o temp\a2p_demo.bin -m temp\a2p_demo.map --dbgfile temp\a2p_demo.dbg -C a2p_disk.cfg temp\disksys_boot.o
@IF ERRORLEVEL 1 GOTO error

python sector_order.py temp\a2p_demo.bin temp\a2p_demo.dsk
@IF ERRORLEVEL 1 GOTO error

python dbg_sym.py temp\a2p_demo.dbg temp\a2p_demo.sym
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