@del temp\*.s
@del temp\*.o
@del temp\a2f_demo.bin
@del temp\a2f_demo.dsk
@del temp\a2f_demo.dbg
@del temp\a2f_demo.map

cc65\bin\ca65 -o temp\disksys_boot.o -g a2f\disksys_boot.s
@IF ERRORLEVEL 1 GOTO error

cc65\bin\ca65 -o temp\a2f_demo.o -g a2f_demo.s
@IF ERRORLEVEL 1 GOTO error

cc65\bin\ld65 -o temp\a2f_demo.bin -m temp\a2f_demo.map --dbgfile temp\a2f_demo.dbg -C a2f_disk.cfg temp\disksys_boot.o temp\a2f_demo.o
@IF ERRORLEVEL 1 GOTO error

python sector_order.py temp\a2f_demo.bin temp\a2f_demo.dsk
@IF ERRORLEVEL 1 GOTO error

python dbg_sym.py temp\a2f_demo.dbg temp\a2f_demo.sym
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