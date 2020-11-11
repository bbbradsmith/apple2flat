@del temp\*.s
@del temp\*.o
@del temp\a2f_demo.bin
@del temp\a2f_demo.dsk
@del temp\a2f_demo.dbg
@del temp\a2f_demo.map

cc65\bin\ca65 -o temp\a2f_demo.o -D A2F_DISK -g a2f_demo.s || @goto error

cc65\bin\ld65 -o temp\a2f_demo.bin -m temp\a2f_demo.map --dbgfile temp\a2f_demo.dbg -C a2f_disk.cfg temp\a2f_demo.o temp\a2f_disk.lib || @goto error

python sector_order.py temp\a2f_demo.bin temp\a2f_demo.dsk || @goto error

python dbg_sym.py temp\a2f_demo.dbg temp\a2f_demo.sym || @goto error

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